import io
import json
import multiprocessing
import os
import queue
import re
import socket
import subprocess
import sys
import threading
import time
from collections import deque
from datetime import datetime
from difflib import SequenceMatcher
from urllib.parse import urlparse

from huggingface_hub import hf_hub_download

try:
    import psutil
except ImportError:
    psutil = None


# -----------------------
# Configuration
# -----------------------

CONF_PATH = sys.argv[1] if len(sys.argv) > 1 else None

CADRE_CONF = {}

if CONF_PATH:
    try:
        with open(CONF_PATH, "r", encoding="utf-8") as file:
            CADRE_CONF = json.load(file)
    except Exception as exc:
        print(f"Could not read cadre.conf: {exc}")

LIVECAP_CONF = CADRE_CONF.get("livecap", {})
WEBDAV_CONF = CADRE_CONF.get("webdav_browser", {})

IPC_PIPE = r"\\.\pipe\mpv-livecap"
WORKER_PORT = 57654

MODEL_SIZE = (
    (LIVECAP_CONF.get("whisper_model") or "").strip()
    or "large-v3-turbo"
)
DEVICE = (LIVECAP_CONF.get("device") or "auto").strip().lower()
COMPUTE_TYPE = (LIVECAP_CONF.get("compute_type") or "default").strip().lower()

source_language_conf = LIVECAP_CONF.get("source_language")

if isinstance(source_language_conf, str):
    source_language_conf = source_language_conf.strip()

SOURCE_LANGUAGE = source_language_conf or None
TARGET_LANGUAGE = (LIVECAP_CONF.get("target_language") or "").strip() or "en"

WEBDAV_URL_PREFIX = WEBDAV_CONF.get("url", "")
WEBDAV_USERNAME = WEBDAV_CONF.get("user", "")
WEBDAV_PASSWORD = WEBDAV_CONF.get("pass", "")
MPV_PATH = LIVECAP_CONF.get("mpv_path", "").strip() or "mpv"
LOG_ENABLED = LIVECAP_CONF.get("log_enabled", True)
LOG_MAX_BYTES = int(LIVECAP_CONF.get("log_max_mb", 2) * 1024 * 1024)

HY_MT2_MODEL_OPTIONS = {
    "Hy-MT2-1.8B-Q4_K_M",
    "Hy-MT2-1.8B-Q6_K",
    "Hy-MT2-1.8B-Q8_0",
}


def resolve_hy_mt2_model(configured_model):
    configured_model = (configured_model or "").strip()
    if configured_model in HY_MT2_MODEL_OPTIONS:
        return "tencent/Hy-MT2-1.8B-GGUF", configured_model
    if configured_model:
        return configured_model, "Hy-MT2-1.8B-Q6_K"
    return "tencent/Hy-MT2-1.8B-GGUF", "Hy-MT2-1.8B-Q6_K"


HY_MT2_REPO, HY_MT2_MODEL = resolve_hy_mt2_model(
    LIVECAP_CONF.get("hy_mt2_model")
)
HY_MT2_FILE = HY_MT2_MODEL + ".gguf"
HY_MT2_N_GPU_LAYERS = -1
HY_MT2_N_CTX = 2048
HY_MT2_N_BATCH = 256
HY_MT2_TRANSLATION_BATCH_SIZE = 8

LOOKAHEAD_SECONDS = 300.0
CHUNK_SECONDS = float(LIVECAP_CONF.get("caption_block_length", 45.0))
OVERLAP_SECONDS = 2.0
CAPTION_LEAD_SECONDS = 2.5
PRIME_SECONDS = float(LIVECAP_CONF.get("prime_seconds", 45.0))
AUTO_RESUME_AFTER_PREROLL = LIVECAP_CONF.get(
    "auto_resume_after_preroll",
    True,
)
CONTEXT_WINDOW = int(LIVECAP_CONF.get("context_window", 0))

SAVE_SRT = bool(LIVECAP_CONF.get("save_srt", False))
OSD_STATUS = bool(LIVECAP_CONF.get("osd_status", False))
SUBTITLE_SAVE_MODE = (LIVECAP_CONF.get("subtitle_save_mode", "cache") or "cache").strip().lower()

SENTENCE_MAX_CHARS = 130
SENTENCE_MAX_SECONDS = 6.0
SENTENCE_SILENCE_GAP = 1.2

GROUP_GAP_SECONDS = 1.2
GROUP_MAX_CHARS = 110
GROUP_MIN_CHARS = 25
ABBREVIATION_REGEX = re.compile(r"^[^\s\d\W]{1,3}\.$", re.UNICODE)

MIN_CAPTION_SECONDS = 3.0
MAX_CAPTION_SECONDS = 8.0
MAX_LATE_CAPTION_SECONDS = 4.0
CAPTION_DELAY = -0.25
CAPTION_LATE_GRACE_SECONDS = 1.5

FFMPEG_TIMEOUT = 60
WORKER_HEARTBEAT_TIMEOUT = 45

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
LOG_FILE = os.path.join(SCRIPT_DIR, "livecap.log")
FLAG_FILE = os.path.normpath(
    os.path.join(SCRIPT_DIR, "..", "data", "livecap.enabled")
)
DEFAULT_MODEL_DIR = os.path.normpath(
    os.path.join(SCRIPT_DIR, "..", "data", "models")
)
configured_models_dir = (LIVECAP_CONF.get("models_dir") or "").strip()
MODEL_DIR = (
    os.path.normpath(configured_models_dir)
    if configured_models_dir
    else DEFAULT_MODEL_DIR
)
SUBS_CACHE_DIR = os.path.normpath(
    os.path.join(SCRIPT_DIR, "..", "data", "subs-cache")
)
SUBS_DIR = (LIVECAP_CONF.get("subs_dir") or "").strip()
SUBS_DIR = os.path.normpath(SUBS_DIR) if SUBS_DIR else SUBS_CACHE_DIR

REMOTE_PREFIXES = (
    "http://",
    "https://",
    "dav://",
    "davs://",
    "sftp://",
    "ftp://",
    "ftps://",
)

TEXT_SUBTITLE_CODECS = {
    "subrip",
    "srt",
    "ass",
    "ssa",
    "webvtt",
    "vtt",
    "mov_text",
    "text",
}

IMAGE_SUBTITLE_CODECS = {
    "hdmv_pgs_subtitle",
    "dvd_subtitle",
    "dvb_subtitle",
    "vobsub",
    "dvdsub",
    "pgssub",
}

SUBTITLE_LANGUAGE_ALIASES = {
    "ara": "ar",
    "chi": "zh",
    "ces": "cs",
    "cze": "cs",
    "deu": "de",
    "ger": "de",
    "ell": "el",
    "gre": "el",
    "eng": "en",
    "fra": "fr",
    "fre": "fr",
    "heb": "he",
    "hin": "hi",
    "ita": "it",
    "jpn": "ja",
    "kor": "ko",
    "dut": "nl",
    "nld": "nl",
    "pol": "pl",
    "por": "pt",
    "rus": "ru",
    "spa": "es",
    "swe": "sv",
    "tha": "th",
    "tur": "tr",
    "ukr": "uk",
    "vie": "vi",
    "zho": "zh",
}


def normalize_subtitle_language(language):
    normalized = str(language or "").strip().lower().replace("_", "-")
    if not normalized:
        return ""

    base = normalized.split("-", 1)[0]
    named_languages = {
        "arabic": "ar",
        "chinese": "zh",
        "czech": "cs",
        "danish": "da",
        "dutch": "nl",
        "english": "en",
        "finnish": "fi",
        "french": "fr",
        "german": "de",
        "greek": "el",
        "hebrew": "he",
        "hindi": "hi",
        "hungarian": "hu",
        "italian": "it",
        "japanese": "ja",
        "korean": "ko",
        "norwegian": "no",
        "polish": "pl",
        "portuguese": "pt",
        "russian": "ru",
        "spanish": "es",
        "swedish": "sv",
        "thai": "th",
        "turkish": "tr",
        "ukrainian": "uk",
        "vietnamese": "vi",
    }
    return SUBTITLE_LANGUAGE_ALIASES.get(
        base,
        named_languages.get(base, base),
    )


# -----------------------
# Live setting updates
# -----------------------

LIVECAP_SETTING_SPECS = {
    "source_language": str,
    "target_language": str,
    "device": str,
    "compute_type": str,
    "source_language": str,
    "whisper_model": str,
    "hy_mt2_model": str,
    "models_dir": str,
    "auto_start": bool,
    "caption_block_length": float,
    "context_window": int,
    "prime_seconds": float,
    "auto_resume_after_preroll": bool,
    "save_srt": bool,
    "osd_status": bool,
    "subtitle_save_mode": str,
    "subs_dir": str,
    "overlay.align": int,
    "overlay.margin_x": int,
    "overlay.margin_y": int,
    "overlay.font": str,
    "overlay.font_size": int,
    "overlay.color": str,
    "overlay.border_color": str,
    "overlay.border_width": int,
    "overlay.shadow": int,
    "overlay.max_duration": float,
}

LIVECAP_WORKER = {"process": None}


def coerce_livecap_setting(key, value):
    if key not in LIVECAP_SETTING_SPECS:
        raise ValueError(f"Unsupported setting: {key}")

    if key == "source_language" and value is None:
        return None

    expected = LIVECAP_SETTING_SPECS[key]

    if expected is bool:
        if isinstance(value, bool):
            return value

        if isinstance(value, str):
            lowered = value.strip().lower()

            if lowered in ("1", "true", "yes", "on"):
                return True

            if lowered in ("0", "false", "no", "off"):
                return False

        raise ValueError(f"{key} must be true or false")

    if expected is int:
        converted = int(value)
        limits = {
            "overlay.align": (1, 9),
            "overlay.margin_x": (0, 1000),
            "overlay.margin_y": (0, 1000),
            "overlay.font_size": (8, 200),
            "overlay.border_width": (0, 20),
            "overlay.shadow": (0, 10),
        }
        if key in limits:
            minimum, maximum = limits[key]
            if not minimum <= converted <= maximum:
                raise ValueError(f"{key} must be between {minimum} and {maximum}")
        return converted

    if expected is float:
        converted = float(value)
        if key == "overlay.max_duration" and not 0.2 <= converted <= 60:
            raise ValueError("overlay.max_duration must be between 0.2 and 60 seconds")
        return converted

    text = str(value).strip()

    if not text:
        if key in (
            "subs_dir",
            "models_dir",
            "whisper_model",
            "hy_mt2_model",
            "overlay.font",
        ):
            return ""
        if key == "source_language":
            return None

        raise ValueError(f"{key} cannot be empty")

    return text


def save_livecap_settings(settings):
    if not CONF_PATH:
        raise RuntimeError("cadre.conf path was not provided")

    if not isinstance(settings, dict) or not settings:
        raise ValueError("settings must be a non-empty object")

    values = {
        key: coerce_livecap_setting(key, value)
        for key, value in settings.items()
    }

    with open(CONF_PATH, "r", encoding="utf-8") as file:
        data = json.load(file)

    if not isinstance(data, dict):
        raise ValueError("cadre.conf must contain a JSON object")

    livecap = data.get("livecap")

    if not isinstance(livecap, dict):
        if livecap is not None:
            raise ValueError("cadre.conf livecap section must be an object")
        livecap = {}

    for key, value in values.items():
        persisted_value = "" if key == "source_language" and value is None else value
        if key.startswith("overlay."):
            overlay = livecap.get("overlay")
            if not isinstance(overlay, dict):
                raise ValueError("cadre.conf livecap.overlay section must be an object")
            overlay[key.split(".", 1)[1]] = persisted_value
        else:
            livecap[key] = persisted_value
    data["livecap"] = livecap

    temp_path = CONF_PATH + ".tmp"

    with open(temp_path, "w", encoding="utf-8") as file:
        json.dump(data, file, indent=2, ensure_ascii=False)
        file.write("\n")

    os.replace(temp_path, CONF_PATH)

    return values


def save_livecap_setting(key, value):
    return save_livecap_settings({key: value})[key]


def apply_runtime_setting(key, value):
    global SOURCE_LANGUAGE
    global TARGET_LANGUAGE
    global DEVICE
    global COMPUTE_TYPE
    global MODEL_SIZE
    global HY_MT2_REPO
    global HY_MT2_MODEL
    global HY_MT2_FILE
    global CHUNK_SECONDS
    global CONTEXT_WINDOW
    global PRIME_SECONDS
    global AUTO_RESUME_AFTER_PREROLL
    global SAVE_SRT
    global OSD_STATUS
    global SUBTITLE_SAVE_MODE
    global SUBS_DIR

    value = coerce_livecap_setting(key, value)
    if key.startswith("overlay."):
        overlay = LIVECAP_CONF.setdefault("overlay", {})
        overlay[key.split(".", 1)[1]] = value
    elif key == "source_language":
        SOURCE_LANGUAGE = value
    elif key == "target_language":
        TARGET_LANGUAGE = value
    elif key == "device":
        DEVICE = value
    elif key == "compute_type":
        COMPUTE_TYPE = value
    elif key == "whisper_model":
        MODEL_SIZE = value or "large-v3-turbo"
    elif key == "models_dir":
        configured_dir = value or ""
        MODEL_DIR = os.path.normpath(configured_dir) if configured_dir else DEFAULT_MODEL_DIR
    elif key == "hy_mt2_model":
        HY_MT2_REPO, HY_MT2_MODEL = resolve_hy_mt2_model(value)
        HY_MT2_FILE = HY_MT2_MODEL + ".gguf"
    elif key == "caption_block_length":
        CHUNK_SECONDS = value
    elif key == "context_window":
        CONTEXT_WINDOW = value
    elif key == "prime_seconds":
        PRIME_SECONDS = value
    elif key == "auto_resume_after_preroll":
        AUTO_RESUME_AFTER_PREROLL = value
    elif key == "save_srt":
        SAVE_SRT = value
    elif key == "osd_status":
        OSD_STATUS = value
    elif key == "subtitle_save_mode":
        SUBTITLE_SAVE_MODE = value.strip().lower() or "auto"
    elif key == "subs_dir":
        configured_dir = value or ""
        SUBS_DIR = os.path.normpath(configured_dir) if configured_dir else SUBS_CACHE_DIR

    LIVECAP_CONF[key] = value
    return value


def register_livecap_worker(process):
    LIVECAP_WORKER["process"] = process


def restart_livecap_worker():
    process = LIVECAP_WORKER.get("process")

    if process is not None and process.is_alive():
        process.terminate()
        process.join(timeout=5.0)

    LIVECAP_WORKER["process"] = None

# -----------------------
# Logging
# -----------------------

class Tee:
    def __init__(self, path):
        self.path = path
        self.enabled = LOG_ENABLED
        self.file = None

        if self.enabled:
            self.file = open(path, "a", encoding="utf-8", buffering=1)

        self.stdout = sys.stdout

    def _rotate_if_needed(self):
        if not self.enabled or self.file is None:
            return

        try:
            if os.path.getsize(self.path) >= LOG_MAX_BYTES:
                self.file.close()

                with open(self.path, "w", encoding="utf-8") as file:
                    file.write("")

                self.file = open(
                    self.path,
                    "a",
                    encoding="utf-8",
                    buffering=1,
                )
        except Exception:
            pass

    def write(self, data):
        self._rotate_if_needed()

        if self.file is not None:
            try:
                self.file.write(data)
            except Exception:
                pass

        if self.stdout is not None:
            try:
                self.stdout.write(data)
            except Exception:
                pass

    def flush(self):
        if self.file is not None:
            try:
                self.file.flush()
            except Exception:
                pass

        if self.stdout is not None:
            try:
                self.stdout.flush()
            except Exception:
                pass


sys.stdout = Tee(LOG_FILE)
sys.stderr = sys.stdout

import logging

logging.basicConfig(
    stream=sys.stdout,
    level=logging.WARNING,
    force=True,
)


def log(message):
    stamp = datetime.now().strftime("%H:%M:%S")
    print(f"[{stamp}] {message}")


# -----------------------
# CUDA DLLs for Whisper
# -----------------------

def add_cuda_dll_dirs():
    try:
        import nvidia.cublas
        import nvidia.cudnn

        for module in (nvidia.cublas, nvidia.cudnn):
            dll_dir = os.path.join(list(module.__path__)[0], "bin")

            if os.path.isdir(dll_dir):
                os.add_dll_directory(dll_dir)
                os.environ["PATH"] = (
                    dll_dir + os.pathsep + os.environ.get("PATH", "")
                )
                log(f"Added CUDA DLL directory: {dll_dir}")

    except Exception as exc:
        log(f"CUDA DLL setup failed: {exc}")


add_cuda_dll_dirs()


# -----------------------
# Single instance
# -----------------------

def ensure_single_instance():
    try:
        guard = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        guard.bind(("127.0.0.1", WORKER_PORT))
        guard.listen(1)
        return guard
    except OSError:
        log("livecap.py is already running.")
        sys.exit(0)


def get_livecap_enabled():
    try:
        with open(FLAG_FILE, "r", encoding="utf-8") as file:
            return file.read().strip() == "1"
    except FileNotFoundError:
        return False


# -----------------------
# mpv IPC
# -----------------------

class MpvIPC:
    def __init__(self, path, connect_timeout=5.0):
        self.pipe = self._open_with_timeout(path, connect_timeout)
        self.request_id = 0
        self.lock = threading.Lock()

    @staticmethod
    def _open_with_timeout(path, timeout):
        result = {}

        def opener():
            try:
                result["pipe"] = open(path, "r+b", buffering=0)
            except Exception as exc:
                result["error"] = exc

        thread = threading.Thread(target=opener, daemon=True)
        thread.start()
        thread.join(timeout)

        if thread.is_alive():
            raise TimeoutError(
                f"Timed out connecting to mpv IPC: {path}"
            )

        if "error" in result:
            raise result["error"]

        return result["pipe"]

    def _read_response(self, wanted_id, timeout=5.0):
        deadline = time.time() + timeout

        while time.time() < deadline:
            line = self.pipe.readline()

            if not line:
                raise RuntimeError("mpv IPC connection closed")

            try:
                message = json.loads(line)
            except json.JSONDecodeError:
                continue

            if message.get("request_id") != wanted_id:
                continue

            if message.get("error", "success") != "success":
                raise RuntimeError(message.get("error"))

            return message.get("data")

        raise TimeoutError(
            f"mpv IPC response timeout for request {wanted_id}"
        )

    def command(self, *command, timeout=5.0):
        self.request_id += 1
        request = {
            "command": list(command),
            "request_id": self.request_id,
        }

        with self.lock:
            try:
                self.pipe.write(
                    (json.dumps(request) + "\n").encode("utf-8")
                )
            except OSError:
                raise RuntimeError("mpv IPC connection closed")

        return self._read_response(self.request_id, timeout)

    def get(self, prop, timeout=5.0):
        return self.command("get_property", prop, timeout=timeout)

    def close(self):
        try:
            self.pipe.close()
        except Exception:
            pass


# -----------------------
# Audio extraction
# -----------------------

def webdav_auth_headers():
    if not (
        WEBDAV_URL_PREFIX
        and WEBDAV_USERNAME
        and WEBDAV_PASSWORD
    ):
        return []

    import base64

    token = base64.b64encode(
        f"{WEBDAV_USERNAME}:{WEBDAV_PASSWORD}".encode("ascii")
    ).decode("ascii")

    return [f"Authorization: Basic {token}"]


def extract_audio_with_mpv(path, start, duration):
    if path.startswith(("http://", "https://")) and (
        "youtube.com/" in path
        or "youtu.be/" in path
    ):
        log("Worker: YouTube URL; using mpv extractor.")

    os.makedirs(os.path.join(SCRIPT_DIR, "data"), exist_ok=True)

    log_path = os.path.join(
        SCRIPT_DIR,
        "data",
        "mpv-extract.log",
    )

    command = [
        MPV_PATH,
        "--config=no",
        f"--log-file={log_path}",
        f"--start={max(0.0, start):.3f}",
        f"--length={duration:.3f}",
        "--o=-",
        "--of=wav",
        "--oac=pcm_s16le",
    ]

    if (
        WEBDAV_URL_PREFIX
        and WEBDAV_USERNAME
        and WEBDAV_PASSWORD
        and path.startswith(WEBDAV_URL_PREFIX)
    ):
        import base64

        token = base64.b64encode(
            f"{WEBDAV_USERNAME}:{WEBDAV_PASSWORD}".encode("ascii")
        ).decode("ascii")

        command.append(
            "--http-header-fields=Authorization: Basic " + token
        )

    command.append(path)

    try:
        result = subprocess.run(
            command,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=FFMPEG_TIMEOUT,
        )
    except subprocess.TimeoutExpired:
        raise RuntimeError(
            f"mpv audio extraction timed out at {start:.2f}s"
        )

    stderr = result.stderr.decode("utf-8", errors="ignore").strip()

    if result.returncode != 0:
        mpv_log = ""

        try:
            with open(
                log_path,
                "r",
                encoding="utf-8",
                errors="ignore",
            ) as file:
                mpv_log = file.read()[-4000:]
        except Exception:
            pass

        raise RuntimeError(
            f"mpv audio extraction failed at {start:.2f}s "
            f"(exit {result.returncode}): {stderr}\n"
            f"--- mpv-extract.log tail ---\n{mpv_log}"
        )

    if result.stdout is None:
        raise RuntimeError(
            f"mpv returned no audio data at {start:.2f}s: {stderr}"
        )

    if not result.stdout:
        raise RuntimeError(
            f"mpv returned empty audio at {start:.2f}s: {stderr}"
        )

    try:
        os.remove(log_path)
    except FileNotFoundError:
        pass

    return result.stdout


def extract_audio(path, start, duration):
    command = [
        "ffmpeg",
        "-hide_banner",
        "-loglevel",
        "error",
    ]

    if (
        WEBDAV_URL_PREFIX
        and WEBDAV_USERNAME
        and WEBDAV_PASSWORD
        and path.startswith(WEBDAV_URL_PREFIX)
    ):
        import base64

        token = base64.b64encode(
            f"{WEBDAV_USERNAME}:{WEBDAV_PASSWORD}".encode("ascii")
        ).decode("ascii")

        command += [
            "-headers",
            f"Authorization: Basic {token}\r\n",
        ]

    command += [
        "-ss",
        f"{max(0.0, start):.3f}",
        "-i",
        path,
        "-t",
        f"{duration:.3f}",
        "-vn",
        "-ac",
        "1",
        "-ar",
        "16000",
        "-f",
        "wav",
        "pipe:1",
    ]

    try:
        result = subprocess.run(
            command,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=FFMPEG_TIMEOUT,
        )
    except subprocess.TimeoutExpired as exc:
        stderr = (
            exc.stderr.decode("utf-8", errors="ignore")
            if exc.stderr
            else ""
        )
        raise RuntimeError(
            f"FFmpeg timed out at {start:.2f}s: {stderr.strip()}"
        )

    stderr = result.stderr.decode("utf-8", errors="ignore").strip()

    if result.returncode != 0:
        raise RuntimeError(
            f"FFmpeg failed at {start:.2f}s "
            f"(exit {result.returncode}): {stderr}"
        )

    if result.stdout is None:
        raise RuntimeError(
            f"FFmpeg returned no audio data at {start:.2f}s: {stderr}"
        )

    if len(result.stdout) == 0:
        raise RuntimeError(
            f"FFmpeg returned empty audio at {start:.2f}s: {stderr}"
        )

    return result.stdout


def extract_audio_for_path(path, start, duration):
    if path.startswith(("http://", "https://")):
        return extract_audio_with_mpv(path, start, duration)

    return extract_audio(path, start, duration)


def playback_position_was_seeked(previous, current, elapsed, speed):
    position_delta = current - previous
    expected_advance = max(0.0, float(speed)) * max(0.0, elapsed)
    return (
        position_delta < -1.5
        or position_delta > expected_advance + 1.5
    )


def is_sentence_end(text):
    return text.endswith(
        (".", "!", "?", "。", "！", "？")
    )


def format_caption(text, max_line_length=70):
    words = text.split()

    if len(text) <= max_line_length:
        return text

    best_i = 1
    best_diff = float("inf")

    for i in range(1, len(words)):
        line1 = " ".join(words[:i])
        line2 = " ".join(words[i:])

        if len(line1) > max_line_length or len(line2) > max_line_length:
            continue

        diff = abs(len(line1) - len(line2))

        if diff < best_diff:
            best_diff = diff
            best_i = i

    if best_diff == float("inf"):
        return text

    return " ".join(words[:best_i]) + "\n" + " ".join(words[best_i:])


# -----------------------
# Caption engine
# -----------------------

def normalize_caption_text(text):
    return "".join(
        ch for ch in text.lower()
        if ch.isalnum() or ch.isspace()
    ).strip()


class CaptionEngine:
    def __init__(self):
        self.words = []
        self.pending_group = []
        self.ready_captions = []
        self.last_block_end = None

    def feed_words(self, words, block_start, block_end):
        for word in words:
            self._feed_word(word)

        self.last_block_end = block_end
        self._maybe_close_group(hard=False)

    def notify_block_end(self, block_end):
        self._maybe_close_group(hard=True)

    def _feed_word(self, word):
        text = word["text"].strip()

        if not text:
            return

        if self.words:
            prev = self.words[-1]

            same_time = (
                abs(word["start"] - prev["start"]) < 0.08
                and abs(word["end"] - prev["end"]) < 0.12
            )
            same_text = self._normalize(prev["text"]) == self._normalize(text)
            contained = (
                self._normalize(text) in self._normalize(prev["text"])
                or self._normalize(prev["text"]) in self._normalize(text)
            )

            if same_time and (same_text or contained):
                if len(text) > len(prev["text"]):
                    prev["text"] = text
                    prev["end"] = max(prev["end"], word["end"])
                return

        if self.words:
            silence_gap = word["start"] - self.words[-1]["end"]
            has_punctuation = self._is_sentence_end(self.words[-1]["text"])
            
            # Require at least 1.5s silence gap to break an unpunctuated phrase inside a chunk
            required_gap = SENTENCE_SILENCE_GAP if has_punctuation else 1.5

            if silence_gap > required_gap:
                self._complete_sentence()

        self.words.append(
            {
                "start": word["start"],
                "end": word["end"],
                "text": text,
            }
        )

        sentence_text = " ".join(w["text"] for w in self.words)
        sentence_duration = self.words[-1]["end"] - self.words[0]["start"]

        if (
            self._is_sentence_end(text)
            or len(sentence_text) >= SENTENCE_MAX_CHARS
            or sentence_duration >= SENTENCE_MAX_SECONDS
        ):
            self._complete_sentence()

    def _maybe_close_group(self, hard):
        if not self.pending_group:
            return

        # Hard flush only on seek/EOF/file change
        if hard:
            self._complete_group()
            return

        last_item = self.pending_group[-1]
        has_terminal = self._is_sentence_end(last_item["text"])

        # If the pending sentence has terminal punctuation (. ! ?), flush it
        if has_terminal:
            if self.words:
                gap = self.words[0]["start"] - last_item["end"]
                if gap > GROUP_GAP_SECONDS:
                    self._complete_group()
            else:
                self._complete_group()
            return

        # If the pending sentence lacks punctuation (e.g., "Of", "Come", "It's"):
        # DO NOT flush at chunk boundaries. Hold until new words arrive with a large gap (>2.5s)
        if self.words:
            gap = self.words[0]["start"] - last_item["end"]
            if gap > 2.5:
                self._complete_group()

    def _add_sentence_to_group(self, sentence):
        if self.pending_group:
            prev = self.pending_group[-1]
            gap = sentence["start"] - prev["end"]
            combined_len = len(prev["text"]) + 1 + len(sentence["text"])
            prev_has_terminal = self._is_sentence_end(prev["text"])

            # Merge if total length fits AND (tight gap OR previous phrase has no terminal punctuation)
            if combined_len <= GROUP_MAX_CHARS:
                if not prev_has_terminal or gap <= GROUP_GAP_SECONDS:
                    prev["text"] = f"{prev['text']} {sentence['text']}".strip()
                    prev["end"] = sentence["end"]
                    return

            self._complete_group()

        self.pending_group.append(sentence)

    def _complete_sentence(self):
        if not self.words:
            return

        text = " ".join(w["text"] for w in self.words).strip()
        start = self.words[0]["start"]
        end = self.words[-1]["end"]

        self.words = []

        if not text:
            return

        sentence = {
            "start": start,
            "end": end,
            "text": text,
        }

        self._add_sentence_to_group(sentence)

    def _complete_group(self):
        if not self.pending_group:
            return

        group = self.pending_group
        self.pending_group = []

        self.ready_captions.append(
            {
                "start": group[0]["start"],
                "end": group[-1]["end"],
                "text": " ".join(x["text"] for x in group),
                "shown": False,
            }
        )
        log(
            f"GROUP: {group[0]['text']} {group[0]['start']} {group[-1]['end']}"
        )

    def pop_ready_captions(self):
        captions = self.ready_captions
        self.ready_captions = []
        return captions

    def reset(self):
        self.words = []
        self.pending_group = []
        self.ready_captions = []
        self.last_block_end = None

    @classmethod
    def _is_sentence_end(cls, text):
        clean = text.strip()
        if not clean:
            return False

        if cls._is_abbreviation(clean):
            return False

        return clean.endswith((".", "!", "?", "。", "！", "？", "…"))

    @staticmethod
    def _is_abbreviation(text):
        return bool(ABBREVIATION_REGEX.match(text))

    @staticmethod
    def _normalize(text):
        return "".join(
            ch for ch in text.lower() if ch.isalnum() or ch.isspace()
        ).strip()
    
# -----------------------
# Hy-MT2 translator
# -----------------------

def is_bad_translation(source, output, skip_same_check=False):
    output = (output or "").strip()

    if not output:
        return True

    if not skip_same_check and output == source.strip():
        return True

    if len(output) < max(2, len(source) * 0.15):
        return True

    return False


class HyMT2Translator:
    def __init__(self):
        os.makedirs(MODEL_DIR, exist_ok=True)

        log(
            f"Downloading/loading Hy-MT2 model: {HY_MT2_FILE}"
        )

        local_model_path = os.path.join(MODEL_DIR, HY_MT2_FILE)

        if os.path.exists(local_model_path):
            model_path = local_model_path
            log(f"Using local Hy-MT2 model: {model_path}")
        else:
            model_path = hf_hub_download(
                repo_id=HY_MT2_REPO,
                filename=HY_MT2_FILE,
                local_dir=MODEL_DIR,
            )

        log(f"Hy-MT2 model path: {model_path}")

        from llama_cpp import Llama

        self.llm = Llama(
            model_path=model_path,
            n_ctx=HY_MT2_N_CTX,
            n_batch=HY_MT2_N_BATCH,
            n_gpu_layers=HY_MT2_N_GPU_LAYERS,
            verbose=False,
        )

        log("Hy-MT2 translator loaded.")
        self.recent_source = []
        self.recent_target = []

    @staticmethod
    def _target_language_name():
        normalized = normalize_subtitle_language(TARGET_LANGUAGE)
        
        language_names = {
            "ar": "Arabic",
            "zh": "Chinese",
            "cs": "Czech",
            "da": "Danish",
            "nl": "Dutch",
            "en": "English",
            "fi": "Finnish",
            "fr": "French",
            "de": "German",
            "el": "Greek",
            "he": "Hebrew",
            "hi": "Hindi",
            "hu": "Hungarian",
            "it": "Italian",
            "ja": "Japanese",
            "ko": "Korean",
            "no": "Norwegian",
            "pl": "Polish",
            "pt": "Portuguese",
            "ru": "Russian",
            "es": "Spanish",
            "sv": "Swedish",
            "th": "Thai",
            "tr": "Turkish",
            "uk": "Ukrainian",
            "vi": "Vietnamese",
        }
        
        return language_names.get(normalized, TARGET_LANGUAGE.title())

    def _translation_context(self):
        return "\n".join(
            f"Source: {source_text}\nTranslation: {translated_text}"
            for source_text, translated_text in (
                zip(
                    self.recent_source[-CONTEXT_WINDOW:],
                    self.recent_target[-CONTEXT_WINDOW:],
                )
                if CONTEXT_WINDOW > 0
                else ()
            )
        )

    def _remember_translation(self, source_text, translated_text):
        self.recent_source.append(source_text.strip())
        self.recent_target.append(translated_text)

        if CONTEXT_WINDOW <= 0:
            self.recent_source.clear()
            self.recent_target.clear()
        elif len(self.recent_source) > CONTEXT_WINDOW * 2:
            self.recent_source.pop(0)
            self.recent_target.pop(0)

    def translate(self, text, source_language):
        source = source_language or "the original"
        target_name = self._target_language_name()
        context = self._translation_context()

        chat_prompt = (
            f"Task: translation.\n"
            f"Source language: {source}.\n"
            f"Target language: {target_name}.\n"
            f"Translate the current subtitle into {target_name}.\n"
            f"The source text comes from automatic speech recognition "
            f"and may contain small recognition errors.\n"
            f"Use the sentence context to choose the intended word when "
            f"there is an obvious recognition error.\n"
            f"Preserve names, places, and technical terms.\n"
            f"Do not explain. Return only the {target_name} translation.\n\n"
        )

        if context:
            chat_prompt += f"Previous subtitles:\n{context}\n\n"

        chat_prompt += f"Current subtitle:\n{text}"

        output = self._generate_chat(chat_prompt)

        if self._is_bad_raw_output(output, text):
            retry_prompt = (
                f"Translate this {source} sentence into {target_name}.\n"
                f"Do not repeat the original text.\n"
                f"Return only the {target_name} translation.\n\n"
                f"{text}"
            )

            output = self._generate_chat(retry_prompt)

        if self._is_bad_raw_output(output, text):
            plain_prompt = (
                f"Translate to {target_name}. "
                f"Return only the translation.\n"
                f"{text}"
            )

            output = self._generate_plain(plain_prompt)

        if self._is_bad_raw_output(output, text):
            return None

        final_output = output.strip()
        self._remember_translation(text, final_output)

        return final_output

    def translate_batch(self, texts, source_language):
        if not texts:
            return []

        if len(texts) == 1:
            return [self.translate(texts[0], source_language)]

        translations = []

        for offset in range(
            0,
            len(texts),
            HY_MT2_TRANSLATION_BATCH_SIZE,
        ):
            batch = texts[
                offset:offset + HY_MT2_TRANSLATION_BATCH_SIZE
            ]
            translations.extend(
                self._translate_batch(batch, source_language)
            )

        return translations

    def _translate_batch(self, texts, source_language):
        source = source_language or "the original"
        target_name = self._target_language_name()
        context = self._translation_context()
        input_json = json.dumps(texts, ensure_ascii=False)
        prompt = (
            f"Task: translation.\n"
            f"Source language: {source}.\n"
            f"Target language: {target_name}.\n"
            f"Translate each subtitle into {target_name} independently "
            f"and preserve their order.\n"
            f"The source text comes from automatic speech recognition "
            f"and may contain small recognition errors. Use the context "
            f"to choose the intended word when there is an obvious "
            f"recognition error. Preserve names, places, and technical "
            f"terms. Do not explain.\n"
            f"Return only a JSON array containing exactly "
            f"{len(texts)} translated strings in the same order.\n"
        )

        if context:
            prompt += f"\nPrevious subtitles:\n{context}\n"

        prompt += f"\nSubtitles:\n{input_json}"

        max_tokens = min(
            1024,
            max(128, len(input_json) // 2 + len(texts) * 24),
        )
        output = self._generate_chat(prompt, max_tokens=max_tokens)

        parsed = None
        if output:
            try:
                parsed = json.loads(output)
            except json.JSONDecodeError:
                start = output.find("[")
                end = output.rfind("]")
                if start >= 0 and end > start:
                    try:
                        parsed = json.loads(output[start:end + 1])
                    except json.JSONDecodeError:
                        parsed = None

        if (
            isinstance(parsed, dict)
            and isinstance(parsed.get("translations"), list)
        ):
            parsed = parsed["translations"]

        if not isinstance(parsed, list) or len(parsed) != len(texts):
            log(
                "Hy-MT2 returned an invalid translation batch; "
                "retrying individually."
            )
            parsed = [None] * len(texts)

        translations = []
        for text, candidate in zip(texts, parsed):
            if not isinstance(candidate, str) or self._is_bad_raw_output(
                candidate,
                text,
            ):
                translated = self.translate(text, source_language)
            else:
                translated = candidate.strip()
                self._remember_translation(text, translated)

            translations.append(translated)

        return translations

    def _generate_chat(self, prompt, max_tokens=64):
        try:
            result = self.llm.create_chat_completion(
                messages=[
                    {
                        "role": "user",
                        "content": prompt,
                    }
                ],
                max_tokens=max_tokens,
                temperature=0.0,
                top_p=1.0,
                repeat_penalty=1.0,
            )

            choice = result["choices"][0]
            message = choice.get("message", {})
            content = message.get("content")

            return (
                content.strip()
                if isinstance(content, str)
                else None
            )

        except Exception as exc:
            log(f"Hy-MT2 chat completion failed: {exc}")
            return None

    def _generate_plain(self, prompt):
        try:
            result = self.llm.create_completion(
                prompt=prompt,
                max_tokens=256,
                temperature=0.0,
                top_p=1.0,
                repeat_penalty=1.0,
                stop=["\n", "Source:", "Translation:"],
            )

            content = result["choices"][0].get("text")

            return (
                content.strip()
                if isinstance(content, str)
                else None
            )

        except Exception as exc:
            log(f"Hy-MT2 plain completion failed: {exc}")
            return None

    @staticmethod
    def _is_bad_raw_output(output, source):
        output = (output or "").strip()

        if not output:
            return True

        if output == source.strip():
            return True

        if len(output) < max(2, len(source.strip()) * 0.15):
            return True

        return False


# -----------------------
# Status and output helpers
# -----------------------

class StatusSender:
    def __init__(self, status_queue):
        self.status_queue = status_queue
        self.last_message = None
        self.job_running = False

    def send(
        self,
        message,
        progress=None,
        current=None,
        total=None,
        block=None,
        blocks=None,
        load_subtitle=None,
        job_running=None,
        active_model=None,
        setting_saved=None,
        setting_error=None,
        pause_playback=None,
        preroll_complete=None,
        resume_playback=None,
        timeline_generation=None,
    ):
        if job_running is not None:
            self.job_running = job_running

        if (
            not OSD_STATUS
            and not self.job_running
            and job_running is None
            and active_model is None
            and pause_playback is None
            and preroll_complete is None
            and resume_playback is None
            and timeline_generation is None
        ):
            return

        payload = {
            "message": message,
            "job_running": self.job_running,
        }

        if progress is not None:
            payload["progress"] = round(float(progress), 1)

        if current is not None:
            payload["current"] = current

        if total is not None:
            payload["total"] = total

        if block is not None:
            payload["block"] = block

        if blocks is not None:
            payload["blocks"] = blocks

        if load_subtitle:
            payload["load_subtitle"] = load_subtitle

        if active_model is not None:
            payload["active_model"] = active_model

        if setting_saved is not None:
            payload["setting_saved"] = setting_saved

        if setting_error is not None:
            payload["setting_error"] = setting_error

        if pause_playback is not None:
            payload["pause_playback"] = pause_playback

        if preroll_complete is not None:
            payload["preroll_complete"] = preroll_complete

        if resume_playback is not None:
            payload["resume_playback"] = resume_playback

        if timeline_generation is not None:
            payload["timeline_generation"] = timeline_generation

        encoded = json.dumps(payload, ensure_ascii=False)

        if encoded == self.last_message:
            return

        self.last_message = encoded

        try:
            self.status_queue.put_nowait(payload)
        except Exception as exc:
            log(f"Could not queue Live Captions status: {exc}")

def is_remote_path(path):
    if not path:
        return False

    if path.startswith(REMOTE_PREFIXES):
        return True

    return bool(
        WEBDAV_URL_PREFIX
        and path.startswith(WEBDAV_URL_PREFIX)
    )


def media_base_name(path):
    try:
        parsed = urlparse(path)

        if parsed.scheme:
            name = os.path.basename(parsed.path)
        else:
            name = os.path.basename(path)
    except Exception:
        name = os.path.basename(path)

    name = os.path.splitext(name)[0]

    if not name:
        name = "subtitle"

    return name


def ensure_writable_dir(directory):
    try:
        os.makedirs(directory, exist_ok=True)

        test_path = os.path.join(
            directory,
            ".livecap-write-test",
        )

        with open(test_path, "w", encoding="utf-8") as file:
            file.write("")

        os.remove(test_path)
        return True
    except Exception:
        return False


def subtitle_output_path(
    media_path,
    source_language,
    target_language,
    translated=False,
    extension=".srt",
    input_path=None,
):
    base = media_base_name(media_path)
    source = (source_language or "unknown").lower()
    target = (target_language or TARGET_LANGUAGE).lower()

    if translated:
        filename = f"{base}.{target}{extension}"
    else:
        filename = f"{base}.{source}{extension}"

    if is_remote_path(media_path):
        output_dir = SUBS_DIR
    else:
        output_dir = os.path.dirname(os.path.abspath(media_path))

        if SUBTITLE_SAVE_MODE == "cache":
            output_dir = SUBS_DIR

    if not ensure_writable_dir(output_dir):
        requested_dir = output_dir
        if requested_dir != SUBS_CACHE_DIR and ensure_writable_dir(
            SUBS_CACHE_DIR
        ):
            log(
                f"Subtitle directory is not writable: {requested_dir}; "
                f"using cache {SUBS_CACHE_DIR}."
            )
            output_dir = SUBS_CACHE_DIR
        else:
            raise RuntimeError(
                f"Subtitle output directory is not writable: {requested_dir}"
            )

    output_path = os.path.join(output_dir, filename)

    if (
        input_path
        and os.path.abspath(output_path)
        == os.path.abspath(input_path)
    ):
        filename = f"{base}.{target}.translated{extension}"
        output_path = os.path.join(output_dir, filename)

    return output_path


def srt_timestamp(seconds):
    seconds = max(0.0, float(seconds))
    hours = int(seconds // 3600)
    minutes = int((seconds % 3600) // 60)
    secs = int(seconds % 60)
    millis = int(round((seconds - int(seconds)) * 1000))

    if millis == 1000:
        millis = 0
        secs += 1

    return (
        f"{hours:02d}:{minutes:02d}:{secs:02d},"
        f"{millis:03d}"
    )


def write_srt_file(path, captions):
    with open(path, "w", encoding="utf-8", newline="\r\n") as file:
        for index, caption in enumerate(captions, start=1):
            file.write(f"{index}\n")
            file.write(
                f"{srt_timestamp(caption['start'])} --> "
                f"{srt_timestamp(caption['end'])}\n"
            )
            file.write(caption["text"].strip() + "\n\n")


def format_clock(seconds):
    seconds = max(0, int(float(seconds)))
    hours = seconds // 3600
    minutes = (seconds % 3600) // 60
    secs = seconds % 60

    if hours:
        return f"{hours:02d}:{minutes:02d}:{secs:02d}"

    return f"{minutes:02d}:{secs:02d}"


def is_youtube_url(path):
    return bool(
        path
        and path.startswith(("http://", "https://"))
        and (
            "youtube.com/" in path
            or "youtu.be/" in path
        )
    )


# -----------------------
# Worker process
# -----------------------

def should_translate(detected_language):
    if not detected_language:
        return True

    return detected_language.lower() != TARGET_LANGUAGE.lower()


def transcribe_audio(
    whisper,
    audio_bytes,
    block_start,
):
    segments, info = whisper.transcribe(
        io.BytesIO(audio_bytes),
        task="transcribe",
        language=SOURCE_LANGUAGE,
        beam_size=3,
        best_of=3,
        temperature=[0.0, 0.2, 0.4],
        word_timestamps=True,
        vad_filter=True,
        condition_on_previous_text=False,
        no_speech_threshold=0.6,
        log_prob_threshold=-1.0,
        vad_parameters={
            "threshold": 0.5,
            "min_speech_duration_ms": 250,
            "min_silence_duration_ms": 500,
            "speech_pad_ms": 200, 
        },
        initial_prompt=(
            "Transcribe natural spoken speech accurately. "
            "Do not repeat words or invent sentences."
        ),
    )

    words = []

    for segment in segments:
        for word in segment.words or []:
            absolute_start = block_start + word.start
            absolute_end = block_start + word.end
            text = word.word.strip()

            if not text:
                continue

            words.append(
                {
                    "start": absolute_start,
                    "end": absolute_end,
                    "text": text,
                }
            )

    return words, info


def translate_captions(
    translator,
    captions,
    detected_language,
    status,
    progress_start=0.0,
    progress_end=1.0,
    batch_size=1,
):
    translated_captions = []
    total = len(captions)
    batch_size = max(1, batch_size)

    for batch_start in range(0, total, batch_size):
        batch = captions[batch_start:batch_start + batch_size]
        source_texts = [caption["text"] for caption in batch]

        if should_translate(detected_language):
            if len(source_texts) > 1:
                translations = translator.translate_batch(
                    source_texts,
                    detected_language,
                )
            else:
                translations = [
                    translator.translate(
                        source_texts[0],
                        detected_language,
                    )
                ]
        else:
            translations = source_texts

        if len(translations) != len(batch):
            raise RuntimeError(
                "Translator returned an unexpected number of captions."
            )

        for batch_index, (caption, source_text, translated) in enumerate(
            zip(batch, source_texts, translations)
        ):
            if is_bad_translation(
                source_text,
                translated,
                skip_same_check=True,
            ):
                log(
                    "Hy-MT2 rejected output; caption skipped: "
                    f"{source_text!r}"
                )
            else:
                new_caption = caption.copy()
                new_caption["text"] = translated
                translated_captions.append(new_caption)

            if status and total:
                index = batch_start + batch_index
                ratio = (index + 1) / total
                progress = (
                    progress_start
                    + (progress_end - progress_start) * ratio
                )

                status.send(
                    "Translating…",
                    progress=progress * 100.0,
                )

    return translated_captions


def create_full_srt(
    whisper,
    translator,
    media_path,
    duration,
    status,
):
    engine = CaptionEngine()
    processed_pos = 0.0
    block_index = 0
    detected_language = SOURCE_LANGUAGE

    estimated_blocks = max(
        1,
        int(
            duration
            / max(1.0, CHUNK_SECONDS - OVERLAP_SECONDS)
        )
        + 1,
    )

    status.send(
        "Creating subtitles…",
        progress=0.0,
        current=0,
        total=int(duration),
        block=0,
        blocks=estimated_blocks,
    )

    while processed_pos < duration - 0.25:
        block_start = max(
            0.0,
            processed_pos - OVERLAP_SECONDS,
        )
        block_end = min(
            duration,
            processed_pos + CHUNK_SECONDS,
        )
        block_duration = block_end - block_start

        if block_duration <= 0.25:
            break

        block_index += 1

        try:
            if is_youtube_url(media_path) or (
                WEBDAV_URL_PREFIX
                and media_path.startswith(WEBDAV_URL_PREFIX)
            ):
                wav_bytes = extract_audio_with_mpv(
                    media_path,
                    block_start,
                    block_duration,
                )
            elif media_path.startswith(("http://", "https://")):
                wav_bytes = extract_audio_with_mpv(
                    media_path,
                    block_start,
                    block_duration,
                )
            else:
                wav_bytes = extract_audio(
                    media_path,
                    block_start,
                    block_duration,
                )

            words, info = transcribe_audio(
                whisper,
                wav_bytes,
                block_start,
            )

            detected_language = (
                info.language or detected_language
            )

            words = [
                word
                for word in words
                if word["start"] >= processed_pos - 0.20
            ]

            engine.feed_words(
                words,
                block_start,
                block_end,
            )
            engine.notify_block_end(block_end)

            processed_pos = block_end

            progress = (
                processed_pos / duration * 100.0
                if duration
                else 0.0
            )

            status.send(
                "Creating subtitles…",
                progress=progress,
                current=int(processed_pos),
                total=int(duration),
                block=block_index,
                blocks=estimated_blocks,
            )

        except Exception as exc:
            log(
                f"Full SRT transcription failed at "
                f"{processed_pos:.2f}s: {exc}"
            )
            processed_pos += 2.0

    engine.notify_block_end(duration)
    captions = engine.pop_ready_captions()

    if not captions:
        raise RuntimeError("No speech captions were produced.")

    captions = translate_captions(
        translator,
        captions,
        detected_language,
        status,
        progress_start=0.80,
        progress_end=0.98,
        batch_size=HY_MT2_TRANSLATION_BATCH_SIZE,
    )

    output_path = subtitle_output_path(
        media_path,
        detected_language,
        TARGET_LANGUAGE,
        translated=should_translate(detected_language),
    )

    log(f"Full SRT output path: {output_path}")
    log(f"Full SRT caption count: {len(captions)}")

    try:
        write_srt_file(output_path, captions)
    except Exception as exc:
        log(f"Could not write SRT file {output_path}: {exc}")
        raise RuntimeError(
            f"Could not write SRT file: {output_path} ({exc})"
        )

    if not os.path.isfile(output_path):
        log(f"SRT file was not created: {output_path}")
        raise RuntimeError(
            f"SRT file was not created: {output_path}"
        )

    file_size = os.path.getsize(output_path)
    log(f"SRT file created successfully: {output_path} ({file_size} bytes)")

    status.send(
        "Subtitles created: " + os.path.basename(output_path),
        load_subtitle=output_path,
    )
    return output_path, detected_language


def extract_embedded_subtitle(
    media_path,
    ff_index,
    codec,
    output_path,
):
    if codec in ("ass", "ssa"):
        subtitle_format = "ass"
    else:
        subtitle_format = "srt"

    command = [
        "ffmpeg",
        "-hide_banner",
        "-loglevel",
        "error",
        "-y",
        "-i",
        media_path,
        "-map",
        f"0:s:{ff_index}",
        "-c:s",
        subtitle_format,
        output_path,
    ]

    result = subprocess.run(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=FFMPEG_TIMEOUT,
    )

    if result.returncode != 0:
        stderr = result.stderr.decode(
            "utf-8",
            errors="ignore",
        ).strip()

        raise RuntimeError(
            f"FFmpeg subtitle extraction failed: {stderr}"
        )

    return output_path


def parse_srt_captions(path):
    captions = []

    with open(
        path,
        "r",
        encoding="utf-8",
        errors="replace",
    ) as file:
        content = file.read()

    blocks = re.split(r"\r?\n\r?\n", content.strip())

    time_pattern = re.compile(
        r"(\d{1,2}):(\d{2}):(\d{2})[,.](\d{1,3})\s*-->\s*"
        r"(\d{1,2}):(\d{2}):(\d{2})[,.](\d{1,3})"
    )

    for block in blocks:
        lines = [
            line.strip()
            for line in block.splitlines()
            if line.strip()
        ]

        if len(lines) < 2:
            continue

        match = time_pattern.search(lines[1])

        if not match:
            continue

        start = (
            int(match.group(1)) * 3600
            + int(match.group(2)) * 60
            + int(match.group(3))
            + int(match.group(4).ljust(3, "0")) / 1000.0
        )

        end = (
            int(match.group(5)) * 3600
            + int(match.group(6)) * 60
            + int(match.group(7))
            + int(match.group(8).ljust(3, "0")) / 1000.0
        )

        text = "\n".join(lines[2:])

        if text:
            captions.append(
                {
                    "start": start,
                    "end": end,
                    "text": text,
                }
            )

    return captions


def write_srt_captions(path, captions):
    with open(
        path,
        "w",
        encoding="utf-8",
        newline="\r\n",
    ) as file:
        for index, caption in enumerate(captions, start=1):
            file.write(f"{index}\n")
            file.write(
                f"{srt_timestamp(caption['start'])} --> "
                f"{srt_timestamp(caption['end'])}\n"
            )
            file.write(caption["text"].strip() + "\n\n")


def live_srt_caption_signature(caption):
    return (
        srt_timestamp(caption["start"]),
        srt_timestamp(caption["end"]),
    )


def append_live_srt_caption(path, caption, saved_state):
    state = saved_state.get(path)

    if state is None:
        existing = (
            parse_srt_captions(path)
            if os.path.isfile(path)
            else []
        )
        state = {
            "count": len(existing),
            "signatures": {
                live_srt_caption_signature(item)
                for item in existing
            },
        }
        saved_state[path] = state

    signature = live_srt_caption_signature(caption)

    if signature in state["signatures"]:
        return False

    existing_size = os.path.getsize(path) if os.path.isfile(path) else 0

    with open(
        path,
        "a",
        encoding="utf-8",
        newline="\r\n",
    ) as output:
        if existing_size:
            with open(path, "rb") as existing_file:
                existing_file.seek(-min(4, existing_size), os.SEEK_END)
                trailing_bytes = existing_file.read()

            normalized_trailing_bytes = trailing_bytes.replace(
                b"\r\n",
                b"\n",
            )

            if not normalized_trailing_bytes.endswith(b"\n\n"):
                output.write(
                    "\n"
                    if normalized_trailing_bytes.endswith(b"\n")
                    else "\n\n"
                )

        index = state["count"] + 1
        output.write(f"{index}\n")
        output.write(
            f"{srt_timestamp(caption['start'])} --> "
            f"{srt_timestamp(caption['end'])}\n"
        )
        output.write(caption["text"].strip() + "\n\n")

    state["count"] = index
    state["signatures"].add(signature)
    return True


def translate_srt_file(
    translator,
    input_path,
    output_path,
    source_language,
    status,
):
    captions = parse_srt_captions(input_path)

    if not captions:
        raise RuntimeError("No readable SRT entries found.")

    total = len(captions)

    for batch_start in range(
        0,
        total,
        HY_MT2_TRANSLATION_BATCH_SIZE,
    ):
        batch_end = min(
            total,
            batch_start + HY_MT2_TRANSLATION_BATCH_SIZE,
        )
        batch_captions = captions[batch_start:batch_end]
        source_lines = []
        line_positions = []

        for caption_index, caption in enumerate(batch_captions):
            for line_index, line in enumerate(
                caption["text"].splitlines()
            ):
                if line.strip():
                    source_lines.append(line)
                    line_positions.append((caption_index, line_index))

        if len(source_lines) > 1:
            translated_lines = translator.translate_batch(
                source_lines,
                source_language,
            )
        elif source_lines:
            translated_lines = [
                translator.translate(source_lines[0], source_language)
            ]
        else:
            translated_lines = []

        if len(translated_lines) != len(source_lines):
            raise RuntimeError(
                "Translator returned an unexpected number of SRT lines."
            )

        translated_by_position = dict(
            zip(line_positions, translated_lines)
        )

        for caption_index, caption in enumerate(batch_captions):
            original_lines = caption["text"].splitlines()
            caption["text"] = "\n".join(
                (
                    translated_by_position[(caption_index, line_index)]
                    or line
                )
                if line.strip()
                else line
                for line_index, line in enumerate(original_lines)
            )

            if status:
                index = batch_start + caption_index
                status.send(
                    "Translating existing subtitles…",
                    progress=(index + 1) / total * 100.0,
                )

    write_srt_captions(output_path, captions)
    return output_path


def translate_ass_file(
    translator,
    input_path,
    output_path,
    source_language,
    status,
):
    with open(
        input_path,
        "r",
        encoding="utf-8",
        errors="replace",
    ) as file:
        lines = file.readlines()

    output_lines = []
    dialogue_count = 0

    for line in lines:
        stripped = line.rstrip("\r\n")

        if not stripped.startswith("Dialogue:"):
            output_lines.append(line)
            continue

        parts = stripped.split(",", 9)

        if len(parts) < 10:
            output_lines.append(line)
            continue

        text = parts[9]
        tags = re.findall(r"\{[^}]*\}", text)
        visible_text = re.sub(r"\{[^}]*\}", "", text).strip()

        if not visible_text:
            output_lines.append(line)
            continue

        translated = translator.translate(
            visible_text,
            source_language,
        )

        if translated:
            parts[9] = "".join(tags) + translated
            dialogue_count += 1

        output_lines.append(",".join(parts) + "\n")

        if status:
            status.send(
                "Translating existing subtitles…",
                progress=None,
            )

    with open(
        output_path,
        "w",
        encoding="utf-8",
        newline="\n",
    ) as file:
        file.writelines(output_lines)

    if dialogue_count == 0:
        raise RuntimeError("No translatable ASS dialogue lines found.")

    return output_path


def translate_existing_subtitle(
    translator,
    media_path,
    track_info,
    status,
):
    source_language = (
        track_info.get("language")
        or SOURCE_LANGUAGE
        or "unknown"
    )

    codec = (track_info.get("codec") or "").lower()
    external_file = track_info.get("external_filename")

    temp_dir = os.path.join(SCRIPT_DIR, "data")
    os.makedirs(temp_dir, exist_ok=True)

    if external_file and os.path.isfile(external_file):
        input_path = external_file
        extension = os.path.splitext(external_file)[1].lower()
    else:
        ff_index = track_info.get("ff_index")

        if ff_index is None:
            raise RuntimeError("Subtitle track has no FFmpeg index.")

        extension = ".ass" if codec in ("ass", "ssa") else ".srt"
        input_path = os.path.join(
            temp_dir,
            f"livecap-source-subtitle{extension}",
        )

        extract_embedded_subtitle(
            media_path,
            ff_index,
            codec,
            input_path,
        )

    extension = ".ass" if extension == ".ass" else ".srt"

    output_path = subtitle_output_path(
        media_path,
        source_language,
        TARGET_LANGUAGE,
        translated=True,
        extension=extension,
    )

    if extension == ".ass":
        result_path = translate_ass_file(
            translator,
            input_path,
            output_path,
            source_language,
            status,
        )
    else:
        result_path = translate_srt_file(
            translator,
            input_path,
            output_path,
            source_language,
            status,
        )

    return result_path


def worker_process(
    heartbeat,
    caption_queue,
    mpv_state_queue,
    job_queue,
    status_queue,
    timeline_generation,
):
    add_cuda_dll_dirs()

    status = StatusSender(status_queue)

    status.send("Waiting for media…")

    try:
        mpv_state_queue.get(timeout=60.0)
    except queue.Empty:
        log("Worker: no initial playback state; exiting.")
        return

    from faster_whisper import WhisperModel

    status.send("Loading Whisper model…")

    log(f"Worker loading Whisper: {MODEL_SIZE} on {DEVICE}")

    whisper = WhisperModel(
        MODEL_SIZE,
        device=DEVICE,
        compute_type=COMPUTE_TYPE,
        download_root=MODEL_DIR,
    )

    log("Whisper loaded.")

    status.send("Loading translation model…")

    translator = HyMT2Translator()

    engine = CaptionEngine()
    srt_created_files = set()
    live_disabled_files = set()
    live_overlay_disabled_files = set()
    current_file = None
    transcribe_pos = 0.0
    last_timeline_generation = None
    preroll_pending = False
    last_queued_caption = None
    last_detected_language = None
    last_state_time = time.time()
    job_active = False
    job_was_live = False

    status.send(
        "Models ready; waiting for media.",
        active_model=MODEL_SIZE,
    )

    live_srt_state = {}

    def save_live_caption(caption, detected_language):
        if not SAVE_SRT:
            return True

        translated = should_translate(detected_language)
        output_path = subtitle_output_path(
            caption.get("file") or current_file,
            detected_language,
            TARGET_LANGUAGE,
            translated=translated,
            extension=".srt",
        )

        try:
            return append_live_srt_caption(
                output_path,
                caption,
                live_srt_state,
            )
        except Exception as exc:
            log(f"Could not save live captions to {output_path}: {exc}")
            status.send(f"Could not save live-caption SRT: {exc}")
            return True

    def publish_caption(caption, detected_language, path, generation):
        nonlocal last_queued_caption

        with timeline_generation.get_lock():
            if timeline_generation.value != generation:
                return None

            caption["file"] = path
            caption["timeline_generation"] = generation

            if not save_live_caption(caption, detected_language):
                return False

            last_queued_caption = caption.copy()
            if path not in live_overlay_disabled_files:
                caption_queue.put(caption)

        return True

    def prepare_preroll(path, position, duration, generation):
        nonlocal last_detected_language
        nonlocal last_queued_caption

        start = max(0.0, position - CAPTION_LEAD_SECONDS)
        end = position + PRIME_SECONDS

        if duration:
            end = min(end, duration)

        if end <= start:
            return start, last_detected_language

        status.send(
            "Preparing captions: transcribing audio…",
            timeline_generation=generation,
        )

        audio = extract_audio_for_path(path, start, end - start)

        if timeline_generation.value != generation:
            return None

        words, info = transcribe_audio(
            whisper,
            audio,
            start,
        )

        if timeline_generation.value != generation:
            return None

        last_detected_language = info.language
        engine.feed_words(words, start, end)
        engine.notify_block_end(end)

        captions = engine.pop_ready_captions()
        status.send(
            "Preparing captions: translating…",
            timeline_generation=generation,
        )
        captions = translate_captions(
            translator,
            captions,
            info.language,
            None,
        )

        if timeline_generation.value != generation:
            return None

        for caption in captions:
            if publish_caption(
                caption,
                info.language,
                path,
                generation,
            ) is None:
                return None

        if timeline_generation.value != generation:
            return None
        return end, info.language

    while True:
        time.sleep(0.20)

        enabled = get_livecap_enabled()

        try:
            state = mpv_state_queue.get(timeout=1.0)
            last_state_time = time.time()
        except queue.Empty:
            if time.time() - last_state_time > 15.0:
                log(
                    "Worker: supervisor stopped sending playback "
                    "state; exiting."
                )
                return

            continue

        path = state.get("path")
        pos = state.get("pos")
        duration = state.get("duration")
        paused = state.get("paused", False)
        core_idle = state.get("core_idle", False)
        eof_reached = state.get("eof", False)

        try:
            command = job_queue.get_nowait()
        except queue.Empty:
            command = None

        if command:
            action = command.get("action")

            if job_active and action == "update_setting":
                status.send(
                    "Settings are locked while a subtitle job runs.",
                    setting_error=command.get("key"),
                )
            elif job_active:
                status.send(
                    "A subtitle job is already running. "
                    "Wait for it to finish."
                )
            elif action == "update_setting":
                key = command.get("key")
                value = command.get("value")

                if key == "whisper_model":
                    status.send(
                        "Whisper model change is pending; restart the worker."
                    )
                else:
                    try:
                        value = apply_runtime_setting(key, value)
                        if key in ("source_language", "target_language"):
                            engine.reset()
                            translator.recent_source.clear()
                            translator.recent_target.clear()
                            last_queued_caption = None
                            while True:
                                try:
                                    caption_queue.get_nowait()
                                except queue.Empty:
                                    break
                            if key == "target_language":
                                live_disabled_files.discard(current_file)
                        status.send(
                            f"Applied {key} at the next caption block."
                        )
                    except Exception as exc:
                        log(f"Worker setting update failed for {key}: {exc}")
                        status.send(
                            f"Could not apply {key}: {exc}",
                            setting_error=key,
                        )
            elif action == "disable_live_for_file":
                command_path = command.get("path")

                if command_path:
                    live_disabled_files.add(command_path)

                    if current_file == command_path:
                        engine.reset()

                    log(
                        "Worker: live captions disabled for file with "
                        f"target-language subtitle: {command_path}"
                    )

            elif action == "disable_live_overlay_for_file":
                command_path = command.get("path")

                if command_path:
                    live_overlay_disabled_files.add(command_path)
                    log(
                        "Worker: live-caption overlay disabled for file "
                        f"with saved SRT: {command_path}"
                    )

            elif action == "enable_live_overlay_for_file":
                command_path = command.get("path")

                if command_path:
                    live_overlay_disabled_files.discard(command_path)

            elif action == "create_srt":
                job_active = True
                job_was_live = enabled
                status.send("Creating subtitles…", job_running=True)

                if job_was_live:
                    status.send(
                        "Live captions paused for subtitle creation."
                    )

                try:
                    if not path or not duration:
                        raise RuntimeError(
                            "No media duration available."
                        )

                    output_path, detected_language = create_full_srt(
                        whisper,
                        translator,
                        path,
                        duration,
                        status,
                    )

                    if output_path:
                        srt_created_files.add(path)

                        status.send(
                            "Subtitles created: "
                            + os.path.basename(output_path),
                            load_subtitle=output_path,
                        )

                        command_data = json.dumps(
                            {
                                "action": "load_srt",
                                "path": output_path,
                            },
                            ensure_ascii=False,
                        )

                        try:
                            import ctypes

                            supervisor_queue = command.get(
                                "reply_queue"
                            )

                            if supervisor_queue:
                                supervisor_queue.put(command_data)
                        except Exception:
                            pass

                except Exception as exc:
                    log(f"Full SRT creation failed: {exc}")
                    status.send(
                        "Subtitle creation failed: "
                        + str(exc)
                    )

                job_active = False

                engine.reset()
                current_file = path
                transcribe_pos = max(
                    0.0,
                    (pos or 0.0) - 0.25,
                )

                status.send(
                    "Live captions resumed"
                    if job_was_live and enabled
                    else "Ready",
                    job_running=False,
                )

            elif action == "translate_subs":
                job_active = True
                job_was_live = enabled
                status.send(
                    "Translating existing subtitles…",
                    job_running=True,
                )

                if job_was_live:
                    status.send(
                        "Live captions paused for subtitle translation."
                    )

                try:
                    output_path = translate_existing_subtitle(
                        translator,
                        path,
                        command.get("track", {}),
                        status,
                    )

                    status.send(
                        "Subtitles translated: "
                        + os.path.basename(output_path)
                    )

                except Exception as exc:
                    log(f"Subtitle translation failed: {exc}")
                    status.send(
                        "Subtitle translation failed: "
                        + str(exc)
                    )

                job_active = False

                engine.reset()
                current_file = path
                transcribe_pos = max(
                    0.0,
                    (pos or 0.0) - 0.25,
                )

                status.send(
                    "Live captions resumed"
                    if job_was_live and enabled
                    else "Ready",
                    job_running=False,
                )

        state_generation = state.get("timeline_generation", 0)
        if (
            current_file != path
            or state_generation != last_timeline_generation
        ):
            current_file = path
            engine.reset()
            translator.recent_source.clear()
            translator.recent_target.clear()
            last_queued_caption = None
            last_detected_language = None
            last_timeline_generation = state_generation
            transcribe_pos = max(
                0.0,
                (pos or 0.0) - CAPTION_LEAD_SECONDS,
            )

            while True:
                try:
                    caption_queue.get_nowait()
                except queue.Empty:
                    break

            log(
                f"Worker: active file set/changed: {path} "
                f"@ {(pos or 0.0):.2f}s "
                f"(timeline {state_generation})"
            )
            preroll_pending = bool(
                path and enabled and PRIME_SECONDS > 0
            )

            if preroll_pending:
                status.send(
                    f"Preparing captions for the next "
                    f"{PRIME_SECONDS:.0f}s…",
                    timeline_generation=state_generation,
                )
            elif path and enabled:
                status.send(
                    "Ready",
                    active_model=MODEL_SIZE,
                    timeline_generation=state_generation,
                )

        if job_active:
            with heartbeat.get_lock():
                heartbeat.value = time.time()

            continue

        if preroll_pending:
            if pos is None or (core_idle and not duration):
                time.sleep(0.25)
                continue

            with heartbeat.get_lock():
                heartbeat.value = time.time()

            try:
                prepared = prepare_preroll(
                    path,
                    pos or 0.0,
                    duration,
                    state_generation,
                )

                if prepared is None:
                    engine.reset()
                    translator.recent_source.clear()
                    translator.recent_target.clear()
                    continue

                transcribe_pos, last_detected_language = prepared
                preroll_pending = False
                resume_playback = bool(
                    AUTO_RESUME_AFTER_PREROLL
                    and state.get("resume_after_preroll")
                )
                status.send(
                    (
                        "Ready — resuming playback"
                        if resume_playback
                        else "Ready — press play"
                    ),
                    active_model=MODEL_SIZE,
                    preroll_complete=True,
                    resume_playback=resume_playback,
                    timeline_generation=state_generation,
                )
                log(
                    f"Worker: prepared captions through "
                    f"{transcribe_pos:.2f}s for {path}"
                )
            except Exception as exc:
                preroll_pending = False
                engine.reset()
                log(f"Worker: caption preparation failed: {exc}")
                status.send(
                    f"Caption preparation failed: {exc}",
                    timeline_generation=state_generation,
                )

            continue

        if core_idle or pos is None:
            last_seen_path = path
            last_seen_pos = pos
            time.sleep(0.25)
            continue

        if not path or pos is None:
            continue

        if eof_reached or (
            duration and pos >= duration - 0.25
        ):
            engine.notify_block_end(duration or pos)

            for caption in engine.pop_ready_captions():
                if timeline_generation.value != state_generation:
                    engine.reset()
                    break

                try:
                    source_text = caption["text"]

                    if not should_translate(
                        last_detected_language
                    ):
                        translated = source_text
                    else:
                        translated = translator.translate(
                            source_text,
                            last_detected_language,
                        )

                    if is_bad_translation(
                        source_text,
                        translated,
                        skip_same_check=True,
                    ):
                        continue

                    caption["text"] = translated

                except Exception as exc:
                    log(f"Hy-MT2 translation failed: {exc}")
                    continue

                if publish_caption(
                    caption,
                    last_detected_language,
                    current_file,
                    state_generation,
                ) is None:
                    engine.reset()
                    break

            time.sleep(0.5)
            continue

        if (
            pos is not None
            and transcribe_pos < pos - 45.0
        ):
            log(
                f"Worker: too far behind playback; "
                f"skipping from {transcribe_pos:.2f}s "
                f"to {pos:.2f}s"
            )

            engine.reset()
            transcribe_pos = max(0.0, pos - 0.25)

        if not enabled:
            continue

        if (
            current_file in srt_created_files
            or current_file in live_disabled_files
        ):
            with heartbeat.get_lock():
                heartbeat.value = time.time()

            engine.reset()
            time.sleep(0.5)
            continue

        if duration and transcribe_pos >= duration - 0.5:
            time.sleep(0.5)
            continue

        if (
            duration
            and transcribe_pos
            > pos + LOOKAHEAD_SECONDS + CHUNK_SECONDS
        ):
            time.sleep(0.25)
            continue

        block_start = max(
            0.0,
            transcribe_pos - OVERLAP_SECONDS,
        )

        if transcribe_pos < 5.0:
            chunk_seconds = 3.0
        elif current_file.startswith(("http://", "https://")):
            chunk_seconds = min(CHUNK_SECONDS, 15.0)
        else:
            chunk_seconds = CHUNK_SECONDS

        block_end = transcribe_pos + chunk_seconds
        block_duration = block_end - block_start
        work_generation = timeline_generation.value

        try:
            with heartbeat.get_lock():
                heartbeat.value = time.time()

            wav_bytes = extract_audio_for_path(
                current_file,
                block_start,
                block_duration,
            )

            if timeline_generation.value != work_generation:
                engine.reset()
                continue

            status.send(
                "Transcribing…",
                timeline_generation=work_generation,
            )

            words, info = transcribe_audio(
                whisper,
                wav_bytes,
                block_start,
            )

            if timeline_generation.value != work_generation:
                engine.reset()
                translator.recent_source.clear()
                translator.recent_target.clear()
                continue

            last_detected_language = info.language

            words = [
                word
                for word in words
                if word["start"] >= transcribe_pos - 0.20
            ]

            engine.feed_words(
                words,
                block_start,
                block_end,
            )

            for caption in engine.pop_ready_captions():
                if timeline_generation.value != work_generation:
                    engine.reset()
                    translator.recent_source.clear()
                    translator.recent_target.clear()
                    break

                if last_queued_caption is not None:
                    time_overlap = (
                        min(
                            caption["end"],
                            last_queued_caption["end"],
                        )
                        - max(
                            caption["start"],
                            last_queued_caption["start"],
                        )
                    )

                    shorter_duration = min(
                        caption["end"] - caption["start"],
                        last_queued_caption["end"]
                        - last_queued_caption["start"],
                    )

                    text_a = normalize_caption_text(
                        caption["text"]
                    )
                    text_b = normalize_caption_text(
                        last_queued_caption["text"]
                    )

                    similarity = SequenceMatcher(
                        None,
                        text_a,
                        text_b,
                    ).ratio()

                    time_overlap_ratio = (
                        time_overlap / shorter_duration
                        if shorter_duration > 0
                        else 0.0
                    )

                    if (
                        time_overlap > 0.5
                        and time_overlap_ratio > 0.4
                        and similarity > 0.55
                    ):
                        continue

                try:
                    source_text = caption["text"]

                    if not should_translate(info.language):
                        translated = source_text
                    else:
                        status.send(
                            "Translating…",
                            timeline_generation=work_generation,
                        )

                        translated = translator.translate(
                            source_text,
                            info.language,
                        )

                    if is_bad_translation(
                        source_text,
                        translated,
                        skip_same_check=True,
                    ):
                        continue

                    caption["text"] = translated

                except Exception as exc:
                    log(f"Hy-MT2 translation failed: {exc}")
                    continue

                published = publish_caption(
                    caption,
                    info.language,
                    current_file,
                    work_generation,
                )
                if published is None:
                    engine.reset()
                    translator.recent_source.clear()
                    translator.recent_target.clear()
                    break
                if not published:
                    continue

            if timeline_generation.value == work_generation:
                transcribe_pos = block_end

        except Exception as exc:
            log(
                f"Worker: transcription failed at "
                f"{transcribe_pos:.2f}s: {exc}"
            )
            transcribe_pos += 2.0


# -----------------------
# Supervisor
# -----------------------

def start_worker(
    heartbeat,
    caption_queue,
    mpv_state_queue,
    job_queue,
    status_queue,
    timeline_generation,
):
    process = multiprocessing.Process(
        target=worker_process,
        args=(
            heartbeat,
            caption_queue,
            mpv_state_queue,
            job_queue,
            status_queue,
            timeline_generation,
        ),
        daemon=True,
    )

    process.start()

    log(
        f"Started transcription worker, PID {process.pid}."
    )
    return process


def stop_worker(worker, caption_queue):
    if worker is None:
        return

    log("Stopping worker.")

    worker.terminate()
    worker.join(timeout=5)

    if worker.is_alive():
        log(
            "Worker did not exit after terminate(); killing it."
        )
        worker.kill()
        worker.join(timeout=5)

    caption_queue.cancel_join_thread()


def wait_for_mpv_ipc(
    mpv_pid=None,
    timeout=30.0,
    exit_when_lost=False,
):
    log("Waiting for mpv IPC pipe...")

    deadline = time.time() + timeout
    last_log = 0.0

    while True:
        if mpv_pid and psutil:
            try:
                process = psutil.Process(mpv_pid)

                if not process.is_running():
                    log("mpv process is no longer running.")
                    return None
            except psutil.NoSuchProcess:
                log("mpv process is no longer running.")
                return None

        try:
            mpv = MpvIPC(
                IPC_PIPE,
                connect_timeout=2.0,
            )
            log("Supervisor connected to mpv.")
            return mpv
        except TimeoutError:
            if time.time() >= deadline:
                log(
                    "mpv IPC pipe exists but did not accept a connection; "
                    "mpv appears hung. Restart mpv."
                )
                return None
        except OSError:
            if exit_when_lost:
                log("mpv IPC pipe disappeared; mpv was closed.")
                return None

        if time.time() - last_log >= 5.0:
            log("mpv IPC pipe not available yet.")
            last_log = time.time()

        time.sleep(0.5)


def is_text_subtitle_track(track):
    codec = (track.get("codec") or "").lower()
    return codec in TEXT_SUBTITLE_CODECS


def is_image_subtitle_track(track):
    codec = (track.get("codec") or "").lower()
    return codec in IMAGE_SUBTITLE_CODECS


def send_status_to_mpv(mpv, payload):
    try:
        if payload.get("resume_playback") is True:
            mpv.command("set_property", "pause", False)
        elif payload.get("pause_playback") is True:
            mpv.command("set_property", "pause", True)
    except Exception as exc:
        log(f"Could not update playback pause state: {exc}")

    try:
        mpv.command(
            "set",
            "user-data/livecap/status",
            json.dumps(payload, ensure_ascii=False),
        )
        if "job_running" in payload:
            job = {
                "running": payload["job_running"],
                "message": payload.get("message", ""),
            }
            if "progress" in payload:
                job["progress"] = payload["progress"]
            mpv.command(
                "set",
                "user-data/livecap/job",
                json.dumps(job, ensure_ascii=False),
            )
        if payload.get("active_model"):
            mpv.command(
                "set",
                "user-data/livecap/active-model",
                payload["active_model"],
            )
    except Exception as exc:
        log(f"Could not send status to mpv: {exc}")

    message = payload.get("message")
    if (
        OSD_STATUS
        and isinstance(message, str)
        and message
        and (
            payload.get("job_running") is True
            or message not in ("Transcribing…", "Translating…")
        )
    ):
        osd_message = message
        progress = payload.get("progress")
        if payload.get("job_running") is True and progress is not None:
            try:
                osd_message += f" ({float(progress):.0f}%)"
            except (TypeError, ValueError):
                log(f"Invalid Live Captions progress value: {progress!r}")

        try:
            duration = "10000" if message.startswith("Ready") else "5000"
            mpv.command("show-text", osd_message, duration)
        except Exception as exc:
            log(f"Could not display Live Captions status: {exc}")


def send_setting_result_to_mpv(mpv, request_id, key, value=None, error=None):
    if not request_id:
        return

    result = {
        "request_id": request_id,
        "key": key,
        "success": error is None,
    }
    if error is None:
        result["value"] = value
    else:
        result["error"] = str(error)

    try:
        mpv.command(
            "script-message-to",
            "cadre_osc",
            "cadre-livecap-settings-result",
            json.dumps(result, ensure_ascii=False),
        )
    except Exception as exc:
        log(f"Could not send Live Captions confirmation message to mpv: {exc}")

    try:
        mpv.command(
            "set",
            "user-data/livecap/setting-result",
            json.dumps(result, ensure_ascii=False),
        )
    except Exception as exc:
        log(f"Could not send Live Captions setting result to mpv: {exc}")


def is_livecap_srt_track(track, display_path):
        external_path = track.get("external-filename")

        if not external_path:
            return False

        try:
            expected_path = subtitle_output_path(
                display_path,
                TARGET_LANGUAGE,
                TARGET_LANGUAGE,
                translated=True,
                extension=".srt",
            )
        except RuntimeError as exc:
            log(f"Could not resolve saved live-caption SRT path: {exc}")
            return False

        return os.path.normcase(
            os.path.abspath(external_path)
        ) == os.path.normcase(
            os.path.abspath(expected_path)
        )


def check_existing_subtitles(
        mpv,
        display_path,
    status_queue,
    job_queue,
    tracks=None,
):
    if tracks is None:
        try:
            tracks = mpv.get("track-list") or []
        except Exception:
            return None

    text_tracks = [
        track
        for track in tracks
        if track.get("type") == "sub"
        and is_text_subtitle_track(track)
    ]

    image_tracks = [
        track
        for track in tracks
        if track.get("type") == "sub"
        and is_image_subtitle_track(track)
    ]

    live_srt_tracks = [
        track
        for track in text_tracks
        if is_livecap_srt_track(track, display_path)
    ]

    if live_srt_tracks:
        track = live_srt_tracks[0]

        try:
            mpv.command(
                "set",
                "sid",
                track.get("id"),
            )
        except Exception:
            pass

        send_status_to_mpv(
            mpv,
            {
                "message": (
                    "Saved live-caption SRT is being used; "
                    "live-caption overlay is disabled."
                )
            },
        )

        job_queue.put(
            {
                "action": "disable_live_overlay_for_file",
                "path": display_path,
            }
        )

        return True

    job_queue.put(
        {
            "action": "enable_live_overlay_for_file",
            "path": display_path,
        }
    )

    target_tracks = [
        track
        for track in text_tracks
        if normalize_subtitle_language(track.get("lang"))
        == normalize_subtitle_language(TARGET_LANGUAGE)
    ]

    english_tracks = [
        track
        for track in text_tracks
        if normalize_subtitle_language(track.get("lang")) == "en"
    ]

    if target_tracks:
        track = target_tracks[0]

        try:
            mpv.command(
                "set",
                "sid",
                track.get("id"),
            )
        except Exception:
            pass

        send_status_to_mpv(
            mpv,
            {
                "message": (
                    "Target-language subtitle exists and is being used."
                )
            },
        )

        job_queue.put(
            {
                "action": "disable_live_for_file",
                "path": display_path,
            }
        )

        return False

    if text_tracks:
        preferred = (
            english_tracks[0]
            if english_tracks
            else text_tracks[0]
        )

        language = preferred.get("lang") or "unknown"

        send_status_to_mpv(
            mpv,
            {
                "message": (
                    f"Text subtitle found ({language}). "
                    "Press Ctrl+Shift+t to translate it."
                )
            },
        )
        return False

    if image_tracks:
        send_status_to_mpv(
            mpv,
            {
                "message": (
                    "Only image-based subtitles found. "
                    "Press Ctrl+Shift+s to create subtitles from audio."
                )
            },
        )
        return False

    send_status_to_mpv(
        mpv,
        {
            "message": (
                "No subtitle found. "
                "Press Ctrl+Shift+s to create subtitles from audio."
            )
        },
    )
    return False

def resolve_subtitle_track(mpv):
    try:
        tracks = mpv.get("track-list") or []
    except Exception:
        return None

    text_tracks = [
        track
        for track in tracks
        if track.get("type") == "sub"
        and is_text_subtitle_track(track)
    ]

    if not text_tracks:
        return None

    selected_id = None

    try:
        selected_id = mpv.get("sid")
    except Exception:
        pass

    english_tracks = [
        track
        for track in text_tracks
        if (track.get("lang") or "").lower() == "en"
    ]

    selected_tracks = [
        track
        for track in text_tracks
        if track.get("id") == selected_id
    ]

    if english_tracks:
        track = english_tracks[0]
    elif selected_tracks:
        track = selected_tracks[0]
    else:
        track = text_tracks[0]

    ff_index = track.get("ff-index")

    if ff_index is None:
        ff_index = track.get("src-id")

    return {
        "track_id": track.get("id"),
        "ff_index": ff_index,
        "codec": track.get("codec"),
        "language": track.get("lang"),
        "external": track.get("external", False),
        "external_filename": track.get("external-filename"),
    }


last_livecap_command = {
    "raw": None,
    "time": 0.0,
}


def poll_command(mpv, job_queue, caption_queue, captions):
    global last_livecap_command

    try:
        raw = mpv.get("user-data/livecap/command")
    except Exception:
        return

    if not raw:
        return

    try:
        mpv.command(
            "set",
            "user-data/livecap/command",
            "",
        )
    except Exception as exc:
        log(f"Could not clear livecap command property: {exc}")

    now = time.time()

    if (
        raw == last_livecap_command["raw"]
        and now - last_livecap_command["time"] < 5.0
    ):
        log("Supervisor: ignored duplicate livecap command.")
        return

    last_livecap_command["raw"] = raw
    last_livecap_command["time"] = now

    try:
        command = json.loads(raw)
    except Exception as exc:
        log(f"Invalid livecap command: {raw!r} ({exc})")
        return

    log(f"Supervisor: accepted livecap command: {command!r}")

    if command.get("action") == "apply_settings":
        settings = command.get("settings")
        request_id = command.get("request_id")

        try:
            job = mpv.get("user-data/livecap/job")
            if isinstance(job, str):
                job = json.loads(job) if job else {}
        except Exception:
            job = {}

        if isinstance(job, dict) and job.get("running"):
            error = "Settings are locked while a subtitle job runs."
            send_setting_result_to_mpv(
                mpv, request_id, "batch", error=error
            )
            send_status_to_mpv(
                mpv,
                {
                    "message": error,
                    "setting_error": "batch",
                    "request_id": request_id,
                    "job_running": True,
                },
            )
            return

        try:
            values = save_livecap_settings(settings)
            for key, value in values.items():
                apply_runtime_setting(key, value)
                if key.startswith("overlay."):
                    mpv.command(
                        "script-message-to",
                        "cadre_livecap",
                        "cadre-livecap-reload-overlay",
                    )
                elif key not in (
                    "whisper_model",
                    "hy_mt2_model",
                    "auto_start",
                ):
                    process = LIVECAP_WORKER.get("process")
                    if process is not None and process.is_alive():
                        job_queue.put(
                            {
                                "action": "update_setting",
                                "key": key,
                                "value": value,
                            }
                        )

            if {"source_language", "target_language"} & values.keys():
                captions.clear()
                while True:
                    try:
                        caption_queue.get_nowait()
                    except queue.Empty:
                        break
        except Exception as exc:
            error = f"Could not save Live Captions settings: {exc}"
            log(f"Supervisor: apply_settings failed: {exc}")
            send_setting_result_to_mpv(
                mpv, request_id, "batch", error=error
            )
            send_status_to_mpv(
                mpv,
                {
                    "message": error,
                    "setting_error": "batch",
                    "request_id": request_id,
                },
            )
            return

        send_setting_result_to_mpv(
            mpv, request_id, "batch", value=values
        )
        send_status_to_mpv(
            mpv,
            {
                "message": "Saved Live Captions settings.",
                "setting_saved": "batch",
                "request_id": request_id,
            },
        )
        return "target_language" if "target_language" in values else "settings_applied"

    if command.get("action") == "set_setting":
        key = command.get("key")
        value = command.get("value")
        request_id = command.get("request_id")

        try:
            job = mpv.get("user-data/livecap/job")
            if isinstance(job, str):
                job = json.loads(job) if job else {}
        except Exception:
            job = {}

        if isinstance(job, dict) and job.get("running"):
            error = "Settings are locked while a subtitle job runs."
            send_status_to_mpv(
                mpv,
                {
                    "message": error,
                    "setting_error": key,
                    "job_running": True,
                },
            )
            send_setting_result_to_mpv(
                mpv, request_id, key, error=error
            )
            return

        try:
            value = save_livecap_setting(key, value)
            apply_runtime_setting(key, value)
        except Exception as exc:
            error = f"Could not save {key}: {exc}"
            send_status_to_mpv(
                mpv,
                {
                    "message": error,
                    "setting_error": key,
                },
            )

            log(f"Supervisor: set_setting failed: {exc}")
            send_setting_result_to_mpv(
                mpv, request_id, key, error=error
            )
            return None

        if key.startswith("overlay."):
            mpv.command(
                "script-message-to",
                "cadre_livecap",
                "cadre-livecap-reload-overlay",
            )
        elif key not in (
            "whisper_model",
            "hy_mt2_model",
            "auto_start",
        ):
            process = LIVECAP_WORKER.get("process")
            if process is not None and process.is_alive():
                job_queue.put(
                    {
                        "action": "update_setting",
                        "key": key,
                        "value": value,
                    }
                )

        if key in ("source_language", "target_language"):
            captions.clear()
            while True:
                try:
                    caption_queue.get_nowait()
                except queue.Empty:
                    break

        send_status_to_mpv(
            mpv,
            {
                "message": (
                    "Saved model; restart the worker to apply."
                    if key in ("whisper_model", "hy_mt2_model")
                    else f"Saved {key}."
                ),
                "setting_saved": key,
            },
        )
        send_setting_result_to_mpv(
            mpv, request_id, key, value=value
        )
        return key

    if command.get("action") == "restart_worker":
        try:
            job = mpv.get("user-data/livecap/job")
            if isinstance(job, str):
                job = json.loads(job) if job else {}
        except Exception:
            job = {}

        if isinstance(job, dict) and job.get("running"):
            send_status_to_mpv(
                mpv,
                {
                    "message": "Wait for the current subtitle job to finish.",
                    "job_running": True,
                },
            )
            return None

        process = LIVECAP_WORKER.get("process")
        worker_running = process is not None and process.is_alive()
        restart_livecap_worker()
        send_status_to_mpv(
            mpv,
            {
                "message": (
                    "Restarting Live Captions worker…"
                    if worker_running
                    else "Saved settings will apply at the next worker start."
                )
            },
        )
        return None

    if command.get("action") == "translate_subs":
        track = resolve_subtitle_track(mpv)
        if track is None:
            send_status_to_mpv(
                mpv,
                {
                    "message": (
                        "No text subtitle is available. "
                        "Create subtitles from audio instead."
                    )
                },
            )
            return None
        command["track"] = track

    job_queue.put(command)
    return None

def supervisor(mpv_pid=None):
    log(f"Flag file: {FLAG_FILE}")
    log(f"Flag exists: {os.path.exists(FLAG_FILE)}")
    log(f"Target language: {TARGET_LANGUAGE}")

    multiprocessing.set_start_method("spawn", force=True)

    heartbeat = multiprocessing.Value("d", 0.0)
    caption_queue = multiprocessing.Queue()
    mpv_state_queue = multiprocessing.Queue()
    job_queue = multiprocessing.Queue()
    status_queue = multiprocessing.Queue()
    timeline_generation = multiprocessing.Value("i", 0)

    while True:
        worker = None
        was_enabled = False

        mpv = wait_for_mpv_ipc(
            mpv_pid,
            timeout=30.0,
            exit_when_lost=False,
        )

        if mpv is None:
            log(
                "Exiting supervisor because mpv is gone or hung."
            )
            return

        log("Supervisor connected to mpv.")
        log("Press Ctrl+t in mpv to toggle live captions.")

        captions = deque()
        last_display_path = None
        last_sample_path = None
        last_sample_pos = None
        last_sample_time = None
        last_sample_paused = None
        livecap_preparing = False
        resume_after_preroll = False
        last_subtitle_track_signature = None
        live_srt_overlay_active = False
        ipc_failure_count = 0
        ipc_ever_succeeded = False
        startup_deadline = time.time() + 30.0

        while True:
            time.sleep(0.10)

            enabled = get_livecap_enabled()
            worker_started_this_tick = False

            if worker is not None and not worker.is_alive():
                log("Worker stopped; starting a fresh worker session.")
                worker = None
                captions.clear()

            if enabled and worker is None:
                worker = start_worker(
                    heartbeat,
                    caption_queue,
                    mpv_state_queue,
                    job_queue,
                    status_queue,
                    timeline_generation,
                )
                register_livecap_worker(worker)
                was_enabled = True
                worker_started_this_tick = True

            if was_enabled and not enabled:
                log("Live captions disabled. Stopping worker.")

                stop_worker(worker, caption_queue)
                worker = None
                was_enabled = False
                captions.clear()

                if livecap_preparing and resume_after_preroll:
                    send_status_to_mpv(
                        mpv,
                        {
                            "message": "Live captions disabled.",
                            "resume_playback": True,
                        },
                    )

                livecap_preparing = False
                resume_after_preroll = False

            try:
                display_path = mpv.get("path")
            except Exception:
                display_path = None

            try:
                while True:
                    caption = caption_queue.get_nowait()
                    caption_generation = caption.get(
                        "timeline_generation"
                    )

                    if (
                        caption_generation is not None
                        and caption_generation != timeline_generation.value
                    ):
                        log(
                            "Supervisor: discarded caption from "
                            "an outdated playback timeline."
                        )
                    elif caption.get("file") == display_path:
                        if live_srt_overlay_active:
                            log(
                                "Supervisor: discarded live caption "
                                "because its saved SRT is active."
                            )
                        else:
                            captions.append(caption)
                    else:
                        log(
                            "Supervisor: discarded caption from "
                            "previous file."
                        )
            except queue.Empty:
                pass

            if display_path != last_display_path:
                captions.clear()
                last_display_path = display_path
                last_subtitle_track_signature = None
                live_srt_overlay_active = False

                if display_path:
                    log(
                        "Supervisor: cleared captions for new file: "
                        f"{display_path}"
                    )

            try:
                subtitle_tracks = mpv.get("track-list") or []
                subtitle_track_signature = json.dumps(
                    [
                        (
                            track.get("id"),
                            track.get("type"),
                            track.get("lang"),
                            track.get("codec"),
                            track.get("external-filename"),
                        )
                        for track in subtitle_tracks
                        if isinstance(track, dict)
                        and track.get("type") == "sub"
                    ],
                    sort_keys=True,
                    ensure_ascii=False,
                )
            except Exception:
                subtitle_tracks = None
                subtitle_track_signature = None

            if (
                display_path
                and subtitle_track_signature is not None
                and subtitle_track_signature
                != last_subtitle_track_signature
            ):
                last_subtitle_track_signature = subtitle_track_signature
                saved_srt_active = check_existing_subtitles(
                    mpv,
                    display_path,
                    status_queue,
                    job_queue,
                    tracks=subtitle_tracks,
                )
                if saved_srt_active is not None:
                    live_srt_overlay_active = saved_srt_active
                    if live_srt_overlay_active:
                        captions.clear()

            try:
                while True:
                    payload = status_queue.get_nowait()

                    payload_generation = payload.get(
                        "timeline_generation"
                    )
                    if (
                        payload_generation is not None
                        and payload_generation != timeline_generation.value
                    ):
                        continue

                    send_status_to_mpv(mpv, payload)

                    if payload.get("preroll_complete"):
                        livecap_preparing = False
                        resume_after_preroll = False

                    load_subtitle = payload.get("load_subtitle")

                    if load_subtitle and os.path.isfile(load_subtitle):
                        try:
                            mpv.command(
                                "sub-add",
                                load_subtitle,
                                "select",
                            )

                            captions.clear()

                            log(
                                "Supervisor: loaded created subtitle: "
                                f"{load_subtitle}"
                            )

                        except Exception as exc:
                            log(
                                "Supervisor: could not load created "
                                f"subtitle {load_subtitle}: {exc}"
                            )

            except queue.Empty:
                pass

            setting_changed = poll_command(
                mpv,
                job_queue,
                caption_queue,
                captions,
            )
            if setting_changed == "target_language" and display_path:
                saved_srt_active = check_existing_subtitles(
                    mpv,
                    display_path,
                    status_queue,
                    job_queue,
                )
                if saved_srt_active is not None:
                    live_srt_overlay_active = saved_srt_active
                    if live_srt_overlay_active:
                        captions.clear()

            try:
                pos = mpv.get("time-pos")

                ipc_failure_count = 0
                ipc_ever_succeeded = True

                try:
                    state = {
                        "path": display_path,
                        "pos": pos,
                        "duration": mpv.get("duration"),
                        "paused": mpv.get("pause"),
                        "core_idle": mpv.get("core-idle"),
                        "speed": mpv.get("speed") or 1.0,
                        "eof": mpv.get("eof-reached"),
                    }
                except Exception:
                    state = {
                        "path": display_path,
                        "pos": pos,
                        "duration": None,
                        "paused": False,
                        "core_idle": False,
                        "speed": 1.0,
                        "eof": False,
                    }

                sample_time = time.monotonic()
                path_changed = (
                    display_path != last_sample_path
                    or (
                        worker_started_this_tick
                        and bool(display_path)
                    )
                )
                elapsed = (
                    sample_time - last_sample_time
                    if last_sample_time is not None
                    else 0.0
                )
                seeked = bool(
                    pos is not None
                    and last_sample_pos is not None
                    and (
                        playback_position_was_seeked(
                            last_sample_pos,
                            pos,
                            elapsed,
                            state["speed"],
                        )
                    )
                )

                if path_changed or seeked:
                    with timeline_generation.get_lock():
                        timeline_generation.value += 1

                    captions.clear()
                    while True:
                        try:
                            caption_queue.get_nowait()
                        except queue.Empty:
                            break

                    if (
                        enabled
                        and display_path
                        and PRIME_SECONDS > 0
                    ):
                        if not livecap_preparing:
                            was_paused = (
                                last_sample_paused
                                if display_path != last_sample_path
                                and last_sample_paused is not None
                                else state["paused"]
                            )
                            resume_after_preroll = bool(
                                AUTO_RESUME_AFTER_PREROLL
                                and not was_paused
                            )
                        elif not AUTO_RESUME_AFTER_PREROLL:
                            resume_after_preroll = False
                        elif not state["paused"]:
                            resume_after_preroll = True

                        livecap_preparing = True
                        send_status_to_mpv(
                            mpv,
                            {
                                "message": (
                                    f"Preparing captions at "
                                    f"{(pos or 0.0):.0f}s…"
                                ),
                                "pause_playback": True,
                                "timeline_generation": (
                                    timeline_generation.value
                                ),
                            },
                        )
                    else:
                        livecap_preparing = False
                        resume_after_preroll = False

                    log(
                        "Supervisor: playback timeline changed "
                        f"({('file' if path_changed else 'seek')}); "
                        f"generation {timeline_generation.value}."
                    )

                last_sample_path = display_path
                last_sample_pos = pos
                last_sample_time = sample_time
                last_sample_paused = state["paused"]
                state["timeline_generation"] = timeline_generation.value
                state["resume_after_preroll"] = resume_after_preroll

                while not mpv_state_queue.empty():
                    try:
                        mpv_state_queue.get_nowait()
                    except queue.Empty:
                        break

                mpv_state_queue.put(state)

            except RuntimeError as exc:
                message = str(exc)

                if "IPC connection closed" in message:
                    log(
                        "mpv closed. Stopping worker; waiting for mpv."
                    )

                    stop_worker(worker, caption_queue)
                    worker = None
                    return

                if (
                    "property" in message.lower()
                    or "unavailable" in message.lower()
                ):
                    continue

                ipc_failure_count += 1

                if (
                    ipc_failure_count >= 100
                    and ipc_ever_succeeded
                    and time.time() > startup_deadline
                ):
                    log("mpv IPC repeatedly failed; reconnecting.")

                    stop_worker(worker, caption_queue)
                    worker = None

                    try:
                        mpv.close()
                    except Exception:
                        pass

                    mpv = wait_for_mpv_ipc(
                        mpv_pid,
                        timeout=15.0,
                        exit_when_lost=True,
                    )

                    if mpv is None:
                        return

                    ipc_failure_count = 0
                    ipc_ever_succeeded = False
                    startup_deadline = time.time() + 30.0
                    continue

                continue

            except Exception:
                ipc_failure_count += 1

                if (
                    ipc_failure_count >= 100
                    and ipc_ever_succeeded
                    and time.time() > startup_deadline
                ):
                    log(
                        "mpv IPC repeatedly failed; reconnecting."
                    )

                    stop_worker(worker, caption_queue)
                    worker = None

                    try:
                        mpv.close()
                    except Exception:
                        pass

                    break

                continue

            if pos is None:
                continue

            playback = pos + CAPTION_DELAY

            while captions:
                current = captions[0]

                if (
                    current["shown"]
                    and playback > current["end"] + 0.35
                ):
                    captions.popleft()
                    continue

                if (
                    not current["shown"]
                    and playback
                    > current["end"]
                    + CAPTION_LATE_GRACE_SECONDS
                ):
                    log(
                        "Supervisor: dropped late caption: "
                        f"{current['text']!r}"
                    )
                    captions.popleft()
                    continue

                break

            if not captions:
                continue

            while (
                len(captions) > 1
                and playback > captions[0]["end"] + 1.0
            ):
                skipped = captions.popleft()

                if not skipped["shown"]:
                    log(
                        "Supervisor: skipped stale caption: "
                        f"{skipped['text']!r}"
                    )

            caption = captions[0]

            if caption["shown"]:
                continue

            if playback < caption["start"] - 0.10:
                continue

            try:
                speed = mpv.get("speed") or 1.0
            except Exception:
                speed = 1.0

            if len(captions) > 1:
                next_caption = captions[1]

                if next_caption["start"] >= caption["end"]:
                    latest_end = min(
                        caption["end"],
                        next_caption["start"],
                    )
                else:
                    latest_end = caption["end"]
            else:
                latest_end = caption["end"]

            if playback > caption["end"]:
                duration = min(
                    MAX_LATE_CAPTION_SECONDS,
                    max(
                        MIN_CAPTION_SECONDS,
                        (
                            caption["end"] - caption["start"]
                        )
                        / speed,
                    ),
                )
            else:
                remaining_video_seconds = max(
                    0.0,
                    latest_end - playback,
                )

                duration = max(
                    MIN_CAPTION_SECONDS,
                    min(
                        remaining_video_seconds / speed,
                        MAX_CAPTION_SECONDS,
                    ),
                )

            try:
                mpv.command(
                    "set",
                    "user-data/livecap/caption",
                    json.dumps(
                        {
                            "text": caption["text"],
                            "start": caption["start"],
                            "end": caption["end"],
                        },
                        ensure_ascii=False,
                    ),
                )

                caption["shown"] = True

            except Exception as exc:
                log(f"Caption property set FAILED: {exc!r}")
                continue


if __name__ == "__main__":
    guard_socket = ensure_single_instance()

    multiprocessing.freeze_support()

    mpv_pid = None

    if len(sys.argv) > 1:
        try:
            mpv_pid = int(sys.argv[1])
        except ValueError:
            mpv_pid = None

    log(f"Received mpv PID: {mpv_pid!r}")
    log(f"Received argv: {sys.argv!r}")

    try:
        supervisor(mpv_pid)
    except KeyboardInterrupt:
        log("Stopped by Ctrl+C.")