import hashlib
import json
import os
import re
import sys
import tempfile
import threading
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
from functools import partial

for _stream in (sys.stdout, sys.stderr):
    if hasattr(_stream, "reconfigure"):
        _stream.reconfigure(encoding="utf-8", errors="backslashreplace")

from PyQt6.QtCore import QObject, Qt, QTimer, QRectF, pyqtSignal as Signal, pyqtSlot as Slot  # type: ignore
from PyQt6.QtGui import QColor, QFont, QFontDatabase, QImage, QPainter, QPen, QPixmap  # type: ignore
from PyQt6.QtWidgets import (
    QApplication,
    QComboBox,
    QFrame,
    QGridLayout,
    QHBoxLayout,
    QLabel,
    QLineEdit,
    QMainWindow,
    QPushButton,
    QScrollArea,
    QVBoxLayout,
    QWidget,
    QToolButton,
)

NOW_UTC = datetime.now(timezone.utc)
TODAY_UTC = NOW_UTC.date()

# ---------------- CONFIG ----------------

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))  # scripts/cadre
CONFIG_FILE = os.path.join(BASE_DIR, "cadre.conf")
WATCH_DATA_FILE = os.path.join(BASE_DIR, "data", "cadre_stream_state.json")
os.makedirs(os.path.dirname(WATCH_DATA_FILE), exist_ok=True)

try:
    with open(CONFIG_FILE, encoding="utf-8") as fh:
        _cfg = json.load(fh).get("stream", {})
except Exception:
    _cfg = {}

TMDB_API_KEY = _cfg.get("tmdb_api_key", "")
TORRENTIO_BASE = _cfg.get("torrentio_base", "https://torrentio.strem.fun")
TORRENTIO_CONFIG = _cfg.get("torrentio_config", "")

IMAGE_EXECUTOR = ThreadPoolExecutor(max_workers=8)
IMG_DIR = os.path.join(tempfile.gettempdir(), "cadre_stream_img")
os.makedirs(IMG_DIR, exist_ok=True)

# ---------------- CACHE & STATE ----------------

IMAGE_CACHE = {}  # (url, (w, h)) -> QPixmap  (main thread only)


def load_state():
    if os.path.exists(WATCH_DATA_FILE):
        try:
            with open(WATCH_DATA_FILE, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            pass
    return {"continue": [], "watchlater": []}


def save_state(state):
    temp_path = f"{WATCH_DATA_FILE}.tmp"
    with open(temp_path, "w", encoding="utf-8") as f:
        json.dump(state, f, ensure_ascii=False, indent=2)
    os.replace(temp_path, WATCH_DATA_FILE)


def is_in_watchlater(state, item):
    for it in state["watchlater"]:
        if it["type"] == item["type"] and str(it["tmdb_id"]) == str(item["tmdb_id"]):
            return True
    return False


def toggle_watchlater_state(state, item):
    if is_in_watchlater(state, item):
        state["watchlater"] = [
            it for it in state["watchlater"]
            if not (it["type"] == item["type"] and str(it["tmdb_id"]) == str(item["tmdb_id"]))
        ]
        return False
    if "vote_average" not in item:
        try:
            details = tmdb_details(item["type"], item["tmdb_id"])
            item["vote_average"] = details.get("vote_average", 0.0)
        except Exception:
            item["vote_average"] = 0.0
    state["watchlater"].insert(0, item)
    state["watchlater"] = state["watchlater"][:50]
    return True


def add_to_continue(state, item):
    for i, it in enumerate(state["continue"]):
        if it["type"] == item["type"] and str(it["tmdb_id"]) == str(item["tmdb_id"]):
            state["continue"].pop(i)
            break
    state["continue"].insert(0, item)
    state["continue"] = state["continue"][:50]


# ---------------- HTTP & TMDB ----------------

def http_get(url):
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=15) as resp:
        return json.loads(resp.read())


def tmdb_trending(time_window="day"):
    url = f"https://api.themoviedb.org/3/trending/all/{time_window}?api_key={TMDB_API_KEY}"
    return http_get(url).get("results", [])


def tmdb_search(query):
    url = f"https://api.themoviedb.org/3/search/multi?api_key={TMDB_API_KEY}&query={urllib.parse.quote(query)}"
    return http_get(url).get("results", [])


def tmdb_details(media_type, tmdb_id):
    return http_get(f"https://api.themoviedb.org/3/{media_type}/{tmdb_id}?api_key={TMDB_API_KEY}")


def tmdb_external_ids(media_type, tmdb_id):
    return http_get(f"https://api.themoviedb.org/3/{media_type}/{tmdb_id}/external_ids?api_key={TMDB_API_KEY}")


def tmdb_season_details(tmdb_id, season_number):
    return http_get(f"https://api.themoviedb.org/3/tv/{tmdb_id}/season/{season_number}?api_key={TMDB_API_KEY}")


def torrentio_streams(media_type, imdb_id, season=None, episode=None):
    if media_type == "movie":
        url = f"{TORRENTIO_BASE}/{TORRENTIO_CONFIG}/stream/movie/{imdb_id}.json"
    else:
        url = f"{TORRENTIO_BASE}/{TORRENTIO_CONFIG}/stream/series/{imdb_id}:{season}:{episode}.json"
    try:
        return http_get(url).get("streams", [])
    except Exception:
        return []

RECHECK_TBA_SEC = 24 * 3600
RECHECK_DATED_SEC = 7 * 24 * 3600


def _find_ep(tmdb_id, season, episode):
    eps = tmdb_season_details(tmdb_id, season).get("episodes", [])
    return next((x for x in eps if int(x.get("episode_number", -1)) == episode), None)


def _find_next_episode(tmdb_id, season, episode):
    next_ep = _find_ep(tmdb_id, season, episode + 1)
    if next_ep:
        return season, next_ep

    next_ep = _find_ep(tmdb_id, season + 1, 1)
    if next_ep:
        return season + 1, next_ep
    return None, None


def needs_recheck(it, force=False):
    if force:
        return True

    now_ts = datetime.now(timezone.utc).timestamp()
    age = now_ts - float(it.get("_checked_at", 0) or 0)

    limit = RECHECK_DATED_SEC if it.get("_next_air_date") else RECHECK_TBA_SEC
    return age >= limit

def _apply_next(it, season, episode, air_date):
    it["season"] = int(season)
    it["episode"] = int(episode)
    it["_ep_resolved"] = True
    it["_next_air_date"] = air_date or None
    it.pop("url", None)
    it.pop("start_time", None)


def _is_future_air_date(air_date, today=TODAY_UTC):
    if not air_date:
        return False
    try:
        return datetime.strptime(air_date, "%Y-%m-%d").date() > today
    except (TypeError, ValueError):
        return False


def _has_aired(air_date, today=TODAY_UTC):
    if not air_date:
        return False
    try:
        return datetime.strptime(air_date, "%Y-%m-%d").date() <= today
    except (TypeError, ValueError):
        return False


def _set_episode_availability(item, air_date, today=TODAY_UTC):
    item["_next_air_date"] = air_date or None
    status = str(item.get("show_status", "")).lower()
    ended = status in ("ended", "canceled", "cancelled")
    if not ended and _is_future_air_date(air_date, today):
        item["_is_upcoming"] = True
        item["_upcoming_unknown"] = False
    elif not ended and not air_date and not item.get("_ep_resolved"):
        item["_is_upcoming"] = True
        item["_upcoming_unknown"] = True
    else:
        item.pop("_is_upcoming", None)
        item.pop("_upcoming_unknown", None)


def recheck_upcoming(it):
    it["_checked_at"] = datetime.now(timezone.utc).timestamp()
    tid = it["tmdb_id"]
    s, e = int(it.get("season", 1)), int(it.get("episode", 1))

    d = tmdb_details("tv", tid)
    it["show_status"] = d.get("status", it.get("show_status", ""))

    if it.get("_ep_resolved", bool(it.get("_next_air_date"))):
        ep = _find_ep(tid, s, e)
        if ep:
            it["_next_air_date"] = ep.get("air_date") or None
    else:
        next_season, ep = _find_next_episode(tid, s, e)
        if ep:
            _apply_next(it, next_season, ep["episode_number"], ep.get("air_date"))


def _stream_matches_episode(stream, title, season, episode, year=None):
    source = " ".join((str(stream.get("name", "")), str(stream.get("title", ""))))
    compact = "".join(char.lower() for char in source if char.isalnum())
    expected_title = "".join(char.lower() for char in title if char.isalnum())
    if not expected_title or expected_title not in compact:
        return False

    marker = rf"\bs0*{season}[\s._-]*e0*{episode}(?!\d)"
    if not re.search(marker, source, flags=re.IGNORECASE):
        return False

    tagged_year = re.search(
        rf"{re.escape(title)}\s*[\(\[]((?:19|20)\d{{2}})[\)\]]",
        source,
        flags=re.IGNORECASE,
    )
    if tagged_year and year and tagged_year.group(1) != str(year):
        return False
    return True

def upcoming_sort_key(it):
    d = it.get("_next_air_date")
    try:
        return (
            0,
            datetime.strptime(d, "%Y-%m-%d").date().toordinal(),
            str(it.get("title", "")).lower(),
        )
    except (TypeError, ValueError):
        return (1, 0, str(it.get("title", "")).lower())

# ---------------- THREAD -> UI BRIDGE ----------------

class Bridge(QObject):
    sig = Signal(object)

    def __init__(self):
        super().__init__()
        self.sig.connect(self._run)

    @Slot(object)
    def _run(self, fn):
        try:
            fn()
        except Exception as e:
            print(f"UI callback error: {e}", file=sys.stderr)


BRIDGE = None


def post(fn, *args):
    BRIDGE.sig.emit(partial(fn, *args))


# ---------------- ASYNC IMAGE LOADER ----------------

def _set_pm(label, pm):
    try:
        label.setPixmap(pm)
    except RuntimeError:
        pass  # widget already deleted


def _apply_pixmap(label, key, data, size):
    pm = QPixmap()
    if not pm.loadFromData(data):
        return
    pm = pm.scaled(size[0], size[1], Qt.AspectRatioMode.IgnoreAspectRatio, Qt.TransformationMode.SmoothTransformation)
    IMAGE_CACHE[key] = pm
    _set_pm(label, pm)


def load_image_async(url, size, label):
    if not url:
        return
    key = (url, tuple(size))
    if key in IMAGE_CACHE:
        _set_pm(label, IMAGE_CACHE[key])
        return

    def _download():
        path = os.path.join(IMG_DIR, hashlib.md5(url.encode()).hexdigest())
        try:
            if os.path.exists(path):
                with open(path, "rb") as f:
                    data = f.read()
            else:
                req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
                with urllib.request.urlopen(req, timeout=10) as resp:
                    data = resp.read()
                with open(path, "wb") as f:
                    f.write(data)
            post(_apply_pixmap, label, key, data, size)
        except Exception:
            pass

    IMAGE_EXECUTOR.submit(_download)


# ---------------- STYLE ----------------

QSS = """
QMainWindow { background: #0F0F0F; }
QScrollArea { border: none; background: transparent; }
#gridhost { background: #0F0F0F; }
#detailhost { background: #151515; }
#top { background: #141414; }
QLabel { background: transparent; }

QLineEdit { background: #222; border: 1px solid #333; border-radius: 6px; padding: 0 10px; color: #fff; }
QLineEdit:focus { border-color: #E50914; }

QPushButton { border: none; border-radius: 6px; padding: 6px 14px; font-weight: bold; color: #fff; }
QPushButton#nav { background: transparent; color: #e5e5e5; font-size: 13px; }
QPushButton#nav:hover { background: #2a2a2a; }
QPushButton#red { background: #E50914; font-size: 14px; }
QPushButton#red:hover { background: #b20710; }
QPushButton#small { background: #E50914; font-size: 12px; padding: 4px 10px; }
QPushButton#small:hover { background: #b20710; }
QPushButton#grey { background: #333; font-size: 14px; }
QPushButton#grey:hover { background: #444; }
QPushButton#outline { background: transparent; border: 2px solid #555; font-size: 14px; }
QPushButton#outline:hover { background: #222; }
QPushButton#refresh { background: #333; font-size: 12px; padding: 0 12px; border-radius: 6px; }
QPushButton#refresh:hover { background: #444; }
QToolButton#remove_continue { background: rgba(0, 0, 0, 150); color: #bbb; border: none; border-radius: 10px; font-size: 9px; font-weight: bold; padding: 0; }
QToolButton#remove_continue:hover { background: #E50914; color: #fff; }

QComboBox { background: #222; border: 1px solid #333; border-radius: 6px; padding: 4px 10px; color: #fff; min-width: 70px; }
QComboBox QAbstractItemView { background: #222; color: #fff; selection-background-color: #E50914; }

#card { background: #181818; border: 1px solid #2a2a2a; border-radius: 8px; }
#card:hover { border: 1px solid #E50914; }
#poster { background: #222; border-radius: 6px; }
#barbg { background: #333; }
#barfg { background: #E50914; }
#ep { background: #1a1a1a; border-radius: 8px; }
#row { background: #1a1a1a; border-radius: 6px; }

QScrollBar:vertical { background: transparent; width: 10px; margin: 0; }
QScrollBar::handle:vertical { background: #3a3a3a; border-radius: 5px; min-height: 30px; }
QScrollBar::handle:vertical:hover { background: #555; }
QScrollBar::add-line:vertical, QScrollBar::sub-line:vertical { height: 0; }
QScrollBar::add-page:vertical, QScrollBar::sub-page:vertical { background: transparent; }
"""


def make_label(text, size=12, color="#fff", bold=False, wrap=False, align=None):
    lbl = QLabel(text)
    lbl.setStyleSheet(f"color:{color}; font-size:{size}px; font-weight:{'bold' if bold else 'normal'};")
    lbl.setWordWrap(wrap)
    if align is not None:
        lbl.setAlignment(align)
    return lbl


def clear_layout(layout):
    while layout.count():
        it = layout.takeAt(0)
        w = it.widget()
        if w is not None:
            w.setParent(None)
            w.deleteLater()
        elif it.layout() is not None:
            clear_layout(it.layout())


# ---------------- GUI COMPONENTS ----------------

POSTER_W, POSTER_H = 160, 240


class MediaCard(QFrame):
    def __init__(self, item, on_click, on_remove=None):
        super().__init__()
        self._on_click = on_click
        self._on_remove = on_remove
        self.setObjectName("card")
        self.setFixedWidth(POSTER_W + 18)
        self.setCursor(Qt.CursorShape.PointingHandCursor)

        lay = QVBoxLayout(self)
        lay.setContentsMargins(8, 8, 8, 8)
        lay.setSpacing(6)

        self.poster_label = QLabel()
        self.poster_label.setObjectName("poster")
        self.poster_label.setFixedSize(POSTER_W, POSTER_H)
        lay.addWidget(self.poster_label)

        # Add × button if on_remove is provided
        if on_remove is not None:
            self.remove_button = QToolButton(self.poster_label)
            self.remove_button.setObjectName("remove_continue")
            self.remove_button.setText("X")
            self.remove_button.setFixedSize(20, 20)
            self.remove_button.setCursor(Qt.CursorShape.PointingHandCursor)
            self.remove_button.setToolTip("Remove from Continue Watching")
            self.remove_button.move(POSTER_W - 26, 6)
            
            self.remove_button.clicked.connect(lambda _=False: on_remove(item))

        try:
            time_pos = float(item.get("time_pos", 0))
            duration = float(item.get("duration", 0))
        except (TypeError, ValueError):
            time_pos, duration = 0.0, 0.0

        if duration > 0 and time_pos > 0:
            ratio = min(time_pos / duration, 1.0)
            bar_bg = QFrame(self.poster_label)
            bar_bg.setObjectName("barbg")
            bar_bg.setGeometry(0, POSTER_H - 4, POSTER_W, 4)
            bar_fg = QFrame(bar_bg)
            bar_fg.setObjectName("barfg")
            bar_fg.setGeometry(0, 0, int(POSTER_W * ratio), 4)

        poster_path = item.get("poster_path")
        if poster_path:
            load_image_async(f"https://image.tmdb.org/t/p/w342{poster_path}", (POSTER_W, POSTER_H), self.poster_label)

        title = item.get("title", "Unknown")
        year = item.get("year", "")
        mt = item.get("type", "movie").upper()
        try:
            rating = round(float(item.get("vote_average", 0)), 1)
        except (TypeError, ValueError):
            rating = 0.0

        title_lbl = make_label(title, 12, "#ffffff", True, wrap=True)
        title_lbl.setToolTip(title)
        lay.addWidget(title_lbl)

        sub = QHBoxLayout()
        sub.setContentsMargins(0, 0, 0, 0)
        grey = "#808080"
        rating_lbl = make_label(f"⭐ {rating}", 10, "#e5a900", True) if rating > 0 else None

        if item.get("_is_upcoming", False):
            air_date = item.get("_next_air_date")
            if air_date:
                try:
                    air_text = datetime.strptime(air_date, "%Y-%m-%d").strftime("%d.%m.%Y")
                except (TypeError, ValueError):
                    air_text = air_date
            else:
                air_text = "TBA"

            se = f"S{int(item.get('season', 0)):02d} E{int(item.get('episode', 0)):02d}"
            resolved = item.get("_ep_resolved", bool(item.get("_next_air_date")))
            sub_text = f"{se} • {air_text}" if resolved else f"After {se}"

            sub.addWidget(make_label(sub_text, 10, grey))
            sub.addStretch()
            if rating_lbl:
                sub.addWidget(rating_lbl)
        elif mt == "TV" and item.get("season") is not None:
            sub.addWidget(make_label(f"S{int(item.get('season', 0)):02d} E{int(item.get('episode', 0)):02d}", 10, grey))
            sub.addStretch()
            if rating_lbl:
                sub.addWidget(rating_lbl)
        else:
            sub.addWidget(make_label(mt, 10, grey, True))
            sub.addStretch()
            if year:
                sub.addWidget(make_label(year, 10, grey))
                sub.addStretch()
            if rating_lbl:
                sub.addWidget(rating_lbl)
        lay.addLayout(sub)
        lay.addStretch()

    def mousePressEvent(self, e):
        if e.button() == Qt.MouseButton.LeftButton:
            self._on_click()
        super().mousePressEvent(e)


class EpisodeRow(QFrame):
    def __init__(self, episode_data, on_play):
        super().__init__()
        self.setObjectName("ep")

        ep_num = episode_data.get("episode_number", "?")
        name = episode_data.get("name") or f"Episode {ep_num}"
        overview = episode_data.get("overview") or "No description available."
        still_path = episode_data.get("still_path")
        air_date_str = episode_data.get("air_date")

        is_aired = False
        air_text = ""
        if air_date_str:
            try:
                air_date_obj = datetime.strptime(air_date_str, "%Y-%m-%d").date()
                is_aired = air_date_obj <= TODAY_UTC
                air_text = f" • {air_date_obj.strftime('%d.%m.%Y')} •"
            except (TypeError, ValueError):
                pass

        thumb_w, thumb_h = 140, 78
        grid = QGridLayout(self)
        grid.setContentsMargins(10, 10, 10, 10)
        grid.setHorizontalSpacing(10)

        self.thumb = QLabel()
        self.thumb.setFixedSize(thumb_w, thumb_h)
        self.thumb.setStyleSheet("background:#222;")
        grid.addWidget(self.thumb, 0, 0, 2, 1, Qt.AlignmentFlag.AlignTop)
        if still_path:
            load_image_async(f"https://image.tmdb.org/t/p/w300{still_path}", (thumb_w, thumb_h), self.thumb)

        title_color = "#fff" if is_aired else "#666"
        desc_color = "#a0a0a0" if is_aired else "#444"

        header = QHBoxLayout()
        full_title = f"{ep_num}. {name}"
        title_lbl = make_label(full_title, 14, title_color, True, wrap=True)
        title_lbl.setToolTip(full_title)
        header.addWidget(title_lbl, 1)
        if is_aired:
            btn = QPushButton("▶ Play")
            btn.setObjectName("small")
            btn.setCursor(Qt.CursorShape.PointingHandCursor)
            btn.clicked.connect(lambda _=False: on_play())
            header.addWidget(btn)
        else:
            header.addWidget(make_label("UNAIRED", 11, "#555", True))
        grid.addLayout(header, 0, 1)

        desc = make_label(overview + "\n" + air_text, 11, desc_color, wrap=True)
        desc.setAlignment(Qt.AlignmentFlag.AlignTop | Qt.AlignmentFlag.AlignLeft)
        grid.addWidget(desc, 1, 1)
        grid.setColumnStretch(1, 1)


class App(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Cadre Stream")
        self.resize(1000, 600)

        self.app_state = load_state()
        self.current_items = []
        self.selected_item = None
        self.detail_visible = False
        self.streams_container = None
        self.ep_list_layout = None
        self._gen = 0
        self._last_grid_type = "normal"

        root = QWidget()
        self.setCentralWidget(root)
        v = QVBoxLayout(root)
        v.setContentsMargins(0, 0, 0, 0)
        v.setSpacing(0)
        v.addWidget(self._build_top_bar())

        body = QHBoxLayout()
        body.setContentsMargins(10, 10, 10, 10)
        body.setSpacing(10)
        v.addLayout(body, 1)

        self.grid_scroll = QScrollArea()
        self.grid_scroll.setWidgetResizable(True)
        host = QWidget()
        host.setObjectName("gridhost")
        self.grid = QGridLayout(host)
        self.grid.setContentsMargins(0, 0, 0, 0)
        self.grid.setSpacing(16)
        self.grid_scroll.setWidget(host)
        body.addWidget(self.grid_scroll, 4)

        self.detail_scroll = QScrollArea()
        self.detail_scroll.setWidgetResizable(True)
        dhost = QWidget()
        dhost.setObjectName("detailhost")
        self.detail_layout = QVBoxLayout(dhost)
        self.detail_layout.setContentsMargins(0, 0, 0, 0)
        self.detail_layout.setAlignment(Qt.AlignmentFlag.AlignTop)
        self.detail_scroll.setWidget(dhost)
        body.addWidget(self.detail_scroll, 6)
        self.detail_scroll.hide()

        self.show_trending()

    # ---------- TOP BAR ----------

    def _build_top_bar(self):
        top = QFrame()
        top.setObjectName("top")
        top.setFixedHeight(60)
        h = QHBoxLayout(top)
        h.setContentsMargins(20, 0, 20, 0)
        h.setSpacing(10)

        h.addWidget(make_label("Cadre Stream", 22, "#E50914", True))
        h.addSpacing(10)

        self.search_entry = QLineEdit()
        self.search_entry.setPlaceholderText("Titles, people, genres")
        self.search_entry.setFixedSize(300, 36)
        self.search_entry.returnPressed.connect(self.do_search)
        h.addWidget(self.search_entry)
        h.addStretch()

        def nav_btn(text, fn):
            b = QPushButton(text)
            b.setObjectName("nav")
            b.setCursor(Qt.CursorShape.PointingHandCursor)
            b.clicked.connect(lambda _=False: fn())
            h.addWidget(b)
            return b

        self.btn_trending = nav_btn("Trending", self.show_trending)
        self.btn_continue = nav_btn("Continue Watching", self.show_continue)
        self.btn_list = nav_btn("My List", self.show_watchlater)
        return top

    def set_active_nav(self, active_btn):
        for btn in (self.btn_trending, self.btn_continue, self.btn_list):
            btn.setStyleSheet("color:#E50914;" if btn is active_btn else "")

    def hide_detail(self):
        self.detail_visible = False
        self.detail_scroll.hide()

    def show_detail(self):
        was_hidden = not self.detail_visible
        self.detail_visible = True
        self.detail_scroll.show()
        if was_hidden and self.current_items:
            if self._last_grid_type == "continue":
                self.build_continue_grid(self.current_items)
            else:
                self.build_grid(self.current_items)

    # ---------- GRID ----------

    def clear_grid(self):
        clear_layout(self.grid)
        for i in range(12):
            self.grid.setColumnStretch(i, 0)
            self.grid.setRowStretch(i * 4, 0)
        self.selected_item = None
        self.grid_scroll.verticalScrollBar().setValue(0)

    def set_grid_loading(self, text="Loading..."):
        self.clear_grid()
        self.grid.addWidget(make_label(text, 16, "#888", align=Qt.AlignmentFlag.AlignCenter), 0, 0)

    def _if_current(self, gen, fn, *args):
        if gen == self._gen:
            fn(*args)

    def _grid_job(self, loading_text, loader, builder):
        self._gen += 1
        gen = self._gen
        self.set_grid_loading(loading_text)

        def work():
            try:
                result = loader()
            except Exception as e:
                post(self._if_current, gen, self.set_grid_loading, f"Error: {e}")
                return
            post(self._if_current, gen, builder, result)

        threading.Thread(target=work, daemon=True).start()

    def _max_cols(self):
        return 2 if self.detail_visible else 5

    def _place_cards(self, items, start_row, max_cols):
        for i, it in enumerate(items):
            row, col = divmod(i, max_cols)
            on_remove = self.remove_continue_item if self._last_grid_type == "continue" else None
            card = MediaCard(it, lambda d=it: self.select_item(d), on_remove)
            self.grid.addWidget(card, start_row + row, col, Qt.AlignmentFlag.AlignTop | Qt.AlignmentFlag.AlignLeft)
        return start_row + (len(items) + max_cols - 1) // max_cols

    def build_grid(self, items):
        self.clear_grid()
        self.current_items = items
        self._last_grid_type = "normal"
        max_cols = self._max_cols()

        if not items:
            self.grid.addWidget(make_label("No items found.", 16, "#555", align=Qt.AlignmentFlag.AlignCenter), 0, 0, 1, max_cols)
            self.clear_detail()
            return

        end_row = self._place_cards(items, 0, max_cols)
        self.grid.setColumnStretch(max_cols, 1)
        self.grid.setRowStretch(end_row, 1)
        
    def build_continue_grid(self, items):
        self.clear_grid()
        self.current_items = items
        self._last_grid_type = "continue"
        max_cols = self._max_cols()

        active_items = [i for i in items if not i.get("_is_upcoming", False)]
        upcoming_items = sorted((i for i in items if i.get("_is_upcoming", False)), key=upcoming_sort_key)

        if not active_items and not upcoming_items:
            self.grid.addWidget(make_label("No items found.", 16, "#555", align=Qt.AlignmentFlag.AlignCenter), 0, 0, 1, max_cols)
            self.clear_detail()
            return

        row = self._place_cards(active_items, 0, max_cols)
        if upcoming_items:
            bar = QWidget()
            bar.setStyleSheet("background: transparent;")
            hb = QHBoxLayout(bar)
            hb.setContentsMargins(8, 20, 0, 0)
            hb.addWidget(make_label("UPCOMING", 16, "#E50914", True))
            hb.addStretch()
            rb = QPushButton("↻ Refresh")
            rb.setObjectName("refresh")
            rb.setFixedHeight(30)
            rb.setToolTip("Re-check release dates now")
            rb.setCursor(Qt.CursorShape.PointingHandCursor)
            rb.clicked.connect(lambda _=False: self.show_continue(force=True))
            hb.addWidget(rb)
            self.grid.addWidget(bar, row, 0, 1, max_cols)
            row = self._place_cards(upcoming_items, row + 1, max_cols)

        self.grid.setColumnStretch(max_cols, 1)
        self.grid.setRowStretch(row, 1)

    def remove_continue_item(self, item):
        key_type = str(item.get("type", ""))
        key_id = str(item.get("tmdb_id", ""))
        state = load_state()
        before = state.get("continue", [])
        state["continue"] = [
            it for it in before
            if not (str(it.get("type", "")) == key_type
                    and str(it.get("tmdb_id", "")) == key_id)
        ]
        if len(state["continue"]) == len(before):
            return
        save_state(state)
        self.app_state = state
        self.selected_item = None
        self.show_continue()

    def _map_tmdb_items(self, items):
            mapped = []
            for it in items[:40]:
                mt = it.get("media_type") or it.get("type")
                if mt not in ("movie", "tv"):
                    continue
                mapped.append({
                    "type": mt,
                    "tmdb_id": str(it.get("id") or it.get("tmdb_id")),
                    "title": it.get("title") or it.get("name") or "Unknown",
                    "year": (it.get("release_date") or it.get("first_air_date") or "")[:4],
                    "poster_path": it.get("poster_path"),
                    "vote_average": round(it.get("vote_average", 0), 1),
                })
            return mapped

    def show_trending(self):
        self.set_active_nav(self.btn_trending)
        self.hide_detail()
        self._grid_job("Fetching trending content...",
                       lambda: self._map_tmdb_items(tmdb_trending("week")), self.build_grid)

    def do_search(self):
        q = self.search_entry.text().strip()
        if q:
            self.set_active_nav(None)
            self.hide_detail()
            self._grid_job(f"Searching for '{q}'...",
                           lambda: self._map_tmdb_items(tmdb_search(q)), self.build_grid)

    def show_watchlater(self):
        self.set_active_nav(self.btn_list)
        self.hide_detail()
        self._gen += 1
        self.app_state = load_state()
        self.build_grid(self.app_state.get("watchlater", []))

    def show_continue(self, force=False):
        self.set_active_nav(self.btn_continue)
        self.hide_detail()
        self.app_state = load_state()
        self._grid_job("Loading watch history...",
                            lambda: self._process_continue(force), self.build_continue_grid)

    def _process_continue(self, force=False):
        stored_items = self.app_state.get("continue", [])
        processed = []
        saved_items = []
        state_changed = False
        today = TODAY_UTC
        seen_media = set()

        for original in stored_items:
            it = dict(original)

            media_key = f"{str(it.get('type', '')).lower()}_{str(it.get('tmdb_id', ''))}"
            if media_key in seen_media:
                state_changed = True
                continue
            seen_media.add(media_key)

            if it.get("_is_upcoming"):
                if needs_recheck(it, force):
                    try:
                        recheck_upcoming(it)
                        state_changed = True
                    except Exception as e:
                        print(f"Recheck failed for {it.get('title')}: {e}")

                air_date_str = it.get("_next_air_date")
                previous_availability = (
                    it.get("_is_upcoming"),
                    it.get("_upcoming_unknown"),
                    it.get("_next_air_date"),
                )
                _set_episode_availability(it, air_date_str, today)
                if previous_availability != (
                        it.get("_is_upcoming"),
                        it.get("_upcoming_unknown"),
                        it.get("_next_air_date")):
                    state_changed = True

                processed.append(it)
                saved_items.append(it)
                continue

            try:
                time_pos = float(it.get("time_pos", 0))
                duration = float(it.get("duration", 0))
                progress = time_pos / duration if duration > 0 else 0.0
                finished = progress >= 0.95

                if it.get("type") == "movie":
                    if finished:
                        state_changed = True
                        continue
                    it.pop("_is_upcoming", None)
                    it.pop("_next_air_date", None)
                    processed.append(it)
                    saved_items.append(it)
                    continue

                if it.get("type") != "tv":
                    processed.append(it)
                    saved_items.append(it)
                    continue

                current_s = int(it.get("season", 1))
                current_e = int(it.get("episode", 1))

                if duration == 0 and time_pos == 0:
                    air_date_str = it.get("_next_air_date")
                    _set_episode_availability(it, air_date_str, today)

                    processed.append(it)
                    saved_items.append(it)
                    if it != original:
                        state_changed = True
                    continue

                if not finished:
                    it.pop("_is_upcoming", None)
                    it.pop("_next_air_date", None)
                    it.pop("_upcoming_unknown", None)
                    processed.append(it)
                    saved_items.append(it)
                    continue

                try:
                    target_s, next_ep = _find_next_episode(
                        it["tmdb_id"], current_s, current_e)
                except Exception as e:
                    print(f"Season lookup failed for {it.get('title')}: {e}")
                    target_s, next_ep = None, None

                if not next_ep:
                    show_status = str(it.get("show_status", "")).lower()
                    if show_status in ("ended", "canceled", "cancelled"):
                        state_changed = True
                        continue

                    upcoming = dict(it)
                    upcoming["time_pos"] = 0
                    upcoming["duration"] = 0
                    upcoming["_is_upcoming"] = True
                    upcoming["_next_air_date"] = None
                    upcoming["_upcoming_unknown"] = True
                    upcoming["_ep_resolved"] = False

                    try:
                        recheck_upcoming(upcoming)
                    except Exception as e:
                        print(f"Initial recheck failed for {it.get('title')}: {e}")

                    _set_episode_availability(
                        upcoming, upcoming.get("_next_air_date"), today)
                    status = str(upcoming.get("show_status", "")).lower()
                    if not upcoming.get("_ep_resolved") and status in ("ended", "canceled", "cancelled"):
                        state_changed = True
                        continue

                    processed.append(upcoming)
                    saved_items.append(upcoming)
                    state_changed = True
                    continue

                air_date_str = next_ep.get("air_date")
                next_item = dict(it)
                next_item["season"] = target_s
                next_item["episode"] = int(next_ep["episode_number"])
                next_item["time_pos"] = 0
                next_item["duration"] = 0
                next_item.pop("url", None)
                next_item.pop("start_time", None)
                next_item["_ep_resolved"] = True
                _set_episode_availability(next_item, air_date_str, today)

                processed.append(next_item)
                saved_items.append(next_item)
                if next_item != original:
                    state_changed = True

            except Exception as e:
                print(f"Error processing {it.get('title')}: {e}")
                processed.append(it)
                saved_items.append(it)

        if state_changed or saved_items != stored_items:
            self.app_state["continue"] = saved_items
            save_state(self.app_state)

        return [dict(i, _from_continue=True) for i in processed]

    # ---------- DETAIL ----------

    def clear_detail(self):
        clear_layout(self.detail_layout)
        self.streams_container = None
        self.ep_list_layout = None

    def _detail_message(self, text, color="#a0a0a0", bold=False):
        self.clear_detail()
        lbl = make_label(text, 13, color, bold, wrap=True, align=Qt.AlignmentFlag.AlignCenter)
        lbl.setContentsMargins(20, 40, 20, 40)
        self.detail_layout.addWidget(lbl)

    def _new_streams_container(self):
        c = QWidget()
        c.setStyleSheet("background: transparent;")
        lay = QVBoxLayout(c)
        lay.setContentsMargins(20, 0, 20, 20)
        lay.setSpacing(4)
        self.detail_layout.addWidget(c)
        self.streams_container = lay
        return lay

    def select_item(self, item):
        self.show_detail()
        self.selected_item = item
        self.clear_detail()

        try:
            time_pos = float(item.get("time_pos", 0))
            duration = float(item.get("duration", 0))
        except (TypeError, ValueError):
            time_pos = duration = 0
        progress = time_pos / duration if duration > 0 else 0.0

        if (item.get("_from_continue") and not item.get("_is_upcoming")
                and duration > 0 and progress < 0.95 and item.get("url")):
            self.play_url(item["url"], item, item.get("season"), item.get("episode"), start_time=time_pos)
            return

        if (item.get("_from_continue") and not item.get("_is_upcoming")
                and item.get("type") == "tv" and duration == 0
                and item.get("season") is not None and item.get("episode") is not None):
            self._open_continue_episode_streams(item)
            return

        self._detail_message("Loading details...", "#888")

        def _fetch():
            try:
                details = tmdb_details(item["type"], item["tmdb_id"])
                ext = tmdb_external_ids(item["type"], item["tmdb_id"])
                post(self._render_detail, item, details, ext.get("imdb_id"))
            except Exception as e:
                post(self._detail_message, f"Could not load details: {e}")

        threading.Thread(target=_fetch, daemon=True).start()

    def _open_continue_episode_streams(self, item):
        season = int(item["season"])
        episode = int(item["episode"])
        self._detail_message(f"Searching streams for S{season:02d} E{episode:02d}...", "#E50914", True)

        def _fetch():
            try:
                ext = tmdb_external_ids("tv", item["tmdb_id"])
                imdb_id = ext.get("imdb_id")
                if not imdb_id:
                    post(self._detail_message, "No IMDb ID found for this series.")
                    return
                search_item = dict(item)
                search_item["imdb_id"] = imdb_id
                streams = torrentio_streams("tv", imdb_id, season, episode)
                post(self._render_continue_streams, streams, search_item, season, episode)
            except Exception as e:
                post(self._detail_message, f"Stream search failed: {e}")

        threading.Thread(target=_fetch, daemon=True).start()

    def _render_continue_streams(self, streams, item, season, episode):
        self.clear_detail()
        hdr = make_label(f"{item.get('title', 'Series')} • S{season:02d} E{episode:02d}", 20, "#fff", True, wrap=True)
        hdr.setContentsMargins(20, 20, 20, 8)
        self.detail_layout.addWidget(hdr)
        self._new_streams_container()
        self._render_streams(streams, item, season, episode)

    def _render_detail(self, item, details, imdb_id):
        self.clear_detail()
        if self.selected_item is not None:
            self.selected_item["imdb_id"] = imdb_id

        backdrop_path = details.get("backdrop_path")
        if backdrop_path:
            hero_w, hero_h = 560, 315
            hero = QLabel()
            hero.setFixedSize(hero_w, hero_h)
            hero.setStyleSheet("background:#111;")
            self.detail_layout.addWidget(hero, 0, Qt.AlignmentFlag.AlignHCenter)
            load_image_async(f"https://image.tmdb.org/t/p/w780{backdrop_path}", (hero_w, hero_h), hero)

        meta = QWidget()
        meta.setStyleSheet("background: transparent;")
        m = QVBoxLayout(meta)
        m.setContentsMargins(20, 20, 20, 20)
        self.detail_layout.addWidget(meta)

        title = details.get("title") or details.get("name") or item["title"]
        m.addWidget(make_label(title, 26, "#fff", True, wrap=True))

        year = (details.get("release_date") or details.get("first_air_date") or "")[:4]
        rating = round(details.get("vote_average", 0), 1)
        genres = ", ".join(g["name"] for g in details.get("genres", [])[:3])
        if item["type"] == "movie" and details.get("runtime"):
            dur = f"{details.get('runtime')} min"
        else:
            dur = f"{details.get('number_of_seasons', 1)} Seasons"
        sub = make_label(f"{year} • ⭐ {rating} • {dur} • {genres}", 12, "#a3a3a3", True, wrap=True)
        sub.setContentsMargins(0, 4, 0, 10)
        m.addWidget(sub)

        m.addWidget(make_label(details.get("overview") or "No description available.", 13, "#d2d2d2", wrap=True))

        btns = QHBoxLayout()
        btns.setContentsMargins(0, 16, 0, 0)
        if item["type"] == "movie":
            label = "▶ Continue" if item.get("time_pos") else "▶ Play Movie"
            b = QPushButton(label)
            b.setObjectName("red")
            b.clicked.connect(lambda _=False: self.on_play_direct(item))
        else:
            b = QPushButton("View Episodes")
            b.setObjectName("grey")
            b.clicked.connect(lambda _=False: self._render_episodes(item, details))
        b.setFixedHeight(40)
        b.setCursor(Qt.CursorShape.PointingHandCursor)
        btns.addWidget(b)

        in_list = is_in_watchlater(self.app_state, item)
        self.list_btn = QPushButton("- Remove List" if in_list else "+ My List")
        self.list_btn.setObjectName("outline")
        self.list_btn.setFixedHeight(40)
        self.list_btn.setCursor(Qt.CursorShape.PointingHandCursor)
        self.list_btn.clicked.connect(lambda _=False: self.on_watchlater(item))
        btns.addWidget(self.list_btn)
        btns.addStretch()
        m.addLayout(btns)

        self._new_streams_container()

    def on_watchlater(self, item):
        is_now_in = toggle_watchlater_state(self.app_state, item)
        save_state(self.app_state)
        self.list_btn.setText("- Remove List" if is_now_in else "+ My List")

    def _render_episodes(self, item, tv_details):
        clear_layout(self.streams_container)
        seasons = [s["season_number"] for s in tv_details.get("seasons", []) if s["season_number"] > 0]
        if not seasons:
            self.streams_container.addWidget(make_label("No seasons available.", 12, "#a0a0a0"))
            return

        header = QHBoxLayout()
        header.addWidget(make_label("Episodes", 18, "#fff", True))
        header.addStretch()
        combo = QComboBox()
        combo.addItems([str(s) for s in seasons])
        target = item.get("season") if item.get("season") in seasons else seasons[0]
        combo.setCurrentText(str(target))
        combo.currentTextChanged.connect(lambda v: self._load_season(item, int(v)))
        header.addWidget(combo)
        self.streams_container.addLayout(header)

        ep_host = QWidget()
        ep_host.setStyleSheet("background: transparent;")
        self.ep_list_layout = QVBoxLayout(ep_host)
        self.ep_list_layout.setContentsMargins(0, 0, 0, 0)
        self.ep_list_layout.setSpacing(8)
        self.streams_container.addWidget(ep_host)
        self._load_season(item, target)

    def _load_season(self, item, season_num):
        layout = self.ep_list_layout
        clear_layout(layout)
        layout.addWidget(make_label("Loading episodes...", 12, "#888", align=Qt.AlignmentFlag.AlignCenter))
        self._season_token = getattr(self, "_season_token", 0) + 1
        token = self._season_token

        def _fetch():
            try:
                data = tmdb_season_details(item["tmdb_id"], season_num)
                eps = data.get("episodes", [])
            except Exception:
                eps = []
            post(self._render_season_episodes, token, layout, item, season_num, eps)

        threading.Thread(target=_fetch, daemon=True).start()

    def _render_season_episodes(self, token, layout, item, season_num, episodes):
        if token != self._season_token or layout is not self.ep_list_layout:
            return
        clear_layout(layout)
        if not episodes:
            layout.addWidget(make_label("No episodes found.", 12, "#888"))
            return
        for ep in episodes:
            ep_no = ep["episode_number"]
            layout.addWidget(EpisodeRow(ep, lambda e=ep_no: self.on_play_direct(item, season_num, e)))

    # ---------- PLAYBACK ----------

    def on_play_direct(self, item, season=None, episode=None):
        if not item.get("imdb_id") or self.streams_container is None:
            return
        clear_layout(self.streams_container)
        self.streams_container.addWidget(
            make_label("Searching streams...", 13, "#E50914", True, align=Qt.AlignmentFlag.AlignCenter))

        def _fetch():
            streams = torrentio_streams(item["type"], item["imdb_id"], season, episode)
            post(self._render_streams, streams, item, season, episode)

        threading.Thread(target=_fetch, daemon=True).start()

    def _render_streams(self, streams, item, season, episode):
        if self.streams_container is None:
            return
        clear_layout(self.streams_container)

        if not streams:
            self.streams_container.addWidget(
                make_label("No streams found.", 12, "#a0a0a0", align=Qt.AlignmentFlag.AlignCenter))
            return

        self.streams_container.addWidget(make_label(f"Select Source ({len(streams)} found)", 14, "#fff", True))

        for st in streams[:40]:
            if not st.get("url"):
                continue

            raw_name = st.get("name", "Stream").replace("\\n", "\n")
            raw_title = st.get("title", "").replace("\\n", "\n")
            name_parts = raw_name.split("\n")
            provider = name_parts[0] if name_parts else "Unknown"
            quality = name_parts[1] if len(name_parts) > 1 else ""
            title_parts = raw_title.split("\n")
            filename = title_parts[0] if title_parts else "Unknown File"
            stats = title_parts[1] if len(title_parts) > 1 else ""

            row = QFrame()
            row.setObjectName("row")
            h = QHBoxLayout(row)
            h.setContentsMargins(10, 8, 10, 8)

            info = QVBoxLayout()
            info.setSpacing(2)
            top_line = f"{quality} • {provider}" if quality else provider
            for text, size, bold, color, limit in (
                (top_line, 13, True, "#E50914", 60),
                (filename, 11, False, "#e0e0e0", 70),
                (stats, 10, False, "#808080", 80),
            ):
                if not text:
                    continue
                shown = text if len(text) <= limit else text[:limit - 1].rstrip() + "…"
                lbl = make_label(shown, size, color, bold)
                if len(text) > limit:
                    lbl.setToolTip(text)
                info.addWidget(lbl)
            h.addLayout(info, 1)

            btn = QPushButton("▶ Play")
            btn.setObjectName("small")
            btn.setCursor(Qt.CursorShape.PointingHandCursor)
            btn.clicked.connect(lambda _=False, u=st["url"]: self.play_url(u, item, season, episode))
            h.addWidget(btn)

            self.streams_container.addWidget(row)

    def play_url(self, url, item, season, episode, start_time=0):
        payload = {
            "url": url,
            "type": item.get("type"),
            "tmdb_id": item.get("tmdb_id"),
            "title": item.get("title"),
            "year": item.get("year", ""),
            "poster_path": item.get("poster_path"),
            "season": season,
            "episode": episode,
            "start_time": start_time,
        }
        print(f"PLAY_DATA:{json.dumps(payload)}", flush=True)
        QTimer.singleShot(200, self.close)


def fetch_next(tmdb_id, curr_season, curr_episode):
    try:
        target_s, next_ep = _find_next_episode(tmdb_id, curr_season, curr_episode)
        if not next_ep or not _has_aired(next_ep.get("air_date")):
            print("NEXT_PLAY_DATA:NONE", flush=True)
            return

        target_e = int(next_ep["episode_number"])
        imdb_id = tmdb_external_ids("tv", tmdb_id).get("imdb_id")
        if not imdb_id:
            return

        details = tmdb_details("tv", tmdb_id)
        title = details.get("name") or details.get("title") or "Unknown"
        year = (details.get("first_air_date") or "")[:4]
        valid = next(
            (
                stream for stream in torrentio_streams(
                    "tv", imdb_id, target_s, target_e)
                if stream.get("url") and _stream_matches_episode(
                    stream, title, target_s, target_e, year)
            ),
            None,
        )
        if valid:
            payload = {
                "url": valid["url"],
                "type": "tv",
                "tmdb_id": tmdb_id,
                "title": title,
                "episode_name": next_ep.get("name") or "",
                "year": year,
                "poster_path": details.get("poster_path"),
                "still_path": next_ep.get("still_path"),
                "season": target_s,
                "episode": target_e,
                "start_time": 0,
            }
            print(f"NEXT_PLAY_DATA:{json.dumps(payload)}", flush=True)
    except Exception:
        pass


def render_next_image(image_url, output_path, width, height):
    request = urllib.request.Request(image_url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(request, timeout=20) as response:
        image = QImage.fromData(response.read())
    if image.isNull():
        raise ValueError("TMDB returned an unreadable image")
    scaled = image.scaled(
        width, height,
        Qt.AspectRatioMode.KeepAspectRatioByExpanding,
        Qt.TransformationMode.SmoothTransformation,
    )
    x = max(0, (scaled.width() - width) // 2)
    y = max(0, (scaled.height() - height) // 2)
    bgra = scaled.copy(x, y, width, height).convertToFormat(QImage.Format.Format_ARGB32)
    bits = bgra.bits()
    bits.setsize(bgra.sizeInBytes())
    with open(output_path, "wb") as output:
        output.write(bytes(bits))


def render_next_timer(output_path, width, height, remaining, filled, font_size):
    """Render the countdown and its progress ring into one transparent bitmap."""
    image = QImage(width, height, QImage.Format.Format_ARGB32)
    image.fill(Qt.GlobalColor.transparent)
    painter = QPainter(image)
    painter.setRenderHint(QPainter.RenderHint.Antialiasing, True)
    center = width / 2
    radius = min(width, height) / 2 - 4
    stroke = max(1.0, width / 16)
    circle = QRectF(center - radius, center - radius, radius * 2, radius * 2)
    painter.setBrush(Qt.BrushStyle.NoBrush)

    def draw_segments(count, color):
        painter.setPen(QPen(color, stroke, Qt.PenStyle.SolidLine, Qt.PenCapStyle.RoundCap))
        for index in range(count):
            start = 90 * 16 - round(index * 360 * 16 / 48)
            span = -round(0.78 * 360 * 16 / 48)
            painter.drawArc(circle, start, span)

    draw_segments(48, QColor(64, 55, 71, 220))
    if filled > 0:
        draw_segments(max(0, min(48, filled)), QColor(255, 143, 184, 255))

    font_path = os.path.join(BASE_DIR, "fonts", "Inter-VariableFont_opsz,wght.ttf")
    font_id = QFontDatabase.addApplicationFont(font_path)
    families = QFontDatabase.applicationFontFamilies(font_id) if font_id >= 0 else []
    font = QFont(families[0] if families else "Arial")
    font.setPixelSize(max(1, font_size))
    font.setBold(True)
    painter.setFont(font)
    painter.setPen(QColor(255, 255, 255, 255))
    painter.drawText(QRectF(0, 0, width, height), Qt.AlignmentFlag.AlignCenter, remaining)
    painter.end()

    bgra = image.convertToFormat(QImage.Format.Format_ARGB32)
    bits = bgra.bits()
    bits.setsize(bgra.sizeInBytes())
    with open(output_path, "wb") as output:
        output.write(bytes(bits))


if __name__ == "__main__":
    if len(sys.argv) == 8 and sys.argv[1] == "--render-next-timer":
        try:
            os.environ["QT_QPA_PLATFORM"] = "offscreen"
            qt_app = QApplication([])
            render_next_timer(sys.argv[2], int(sys.argv[3]), int(sys.argv[4]),
                              sys.argv[5], int(sys.argv[6]), int(sys.argv[7]))
        except Exception as exc:
            print(f"next timer: {exc}", file=sys.stderr, flush=True)
            sys.exit(1)
        sys.exit(0)
    if len(sys.argv) == 6 and sys.argv[1] == "--render-next-image":
        try:
            render_next_image(sys.argv[2], sys.argv[3], int(sys.argv[4]), int(sys.argv[5]))
        except Exception as exc:
            print(f"next image: {exc}", file=sys.stderr, flush=True)
            sys.exit(1)
        sys.exit(0)
    if len(sys.argv) > 1 and sys.argv[1] == "--fetch-next":
        if len(sys.argv) == 5:
            fetch_next(sys.argv[2], int(sys.argv[3]), int(sys.argv[4]))
        sys.exit(0)

    qt_app = QApplication(sys.argv)
    qt_app.setStyleSheet(QSS)
    BRIDGE = Bridge()
    win = App()
    win.show()
    sys.exit(qt_app.exec())
