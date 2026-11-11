import sys, os, re, json, socket, subprocess, argparse
from PyQt6.QtCore import Qt, QThread, pyqtSignal, QSize, QUrl
from PyQt6.QtGui import QPixmap, QIcon, QShortcut, QKeySequence, QColor
from PyQt6.QtNetwork import QNetworkAccessManager, QNetworkRequest
from PyQt6.QtWidgets import (QApplication, QWidget, QVBoxLayout, QHBoxLayout, QLineEdit,
    QComboBox, QListWidget, QListWidgetItem, QListView, QLabel,
    QAbstractItemView, QPushButton, QStackedWidget, QGridLayout)
from pathlib import Path
from datetime import datetime, timezone

FEEDS = [
    ("home", "Home / Recommended", "https://www.youtube.com/feed/recommended"),
    ("subscriptions", "Subscriptions", "https://www.youtube.com/feed/subscriptions"),
    ("history", "Watch history", "https://www.youtube.com/feed/history"),
    ("watch_later", "Watch Later", "https://www.youtube.com/playlist?list=WL"),
    ("liked", "Liked videos", "https://www.youtube.com/playlist?list=LL"),
]
THUMB_W, THUMB_H = 320, 180
PAGE_SIZE = 12
SEARCH_TOTAL = 60
FEED_TOTAL = 96
MIX_LIMIT = 50  # used only if ytdl-raw-options has no playlist-end
if getattr(sys, "frozen", False):
    BASE_DIR = Path(sys.executable).parent
else:
    BASE_DIR = Path(__file__).resolve().parent.parent  # scripts/cadre

DATA_DIR = BASE_DIR / "data"
DATA_DIR.mkdir(parents=True, exist_ok=True)
RECENT_FILE = DATA_DIR / "cadre_youtube_recent_searches.json"
RECENT_MAX = 12
FEED_ICONS = {"home": "🏠", "subscriptions": "📺", "history": "🕘",
              "watch_later": "⏰", "liked": "👍"}

STYLE = """
QWidget { background:#121212; color:#eee; font-size:13px; }
QLineEdit, QComboBox { background:#1e1e1e; border:1px solid #333; padding:6px; border-radius:4px; }
QPushButton { background:#252525; border:1px solid #3a3a3a; padding:7px 16px; border-radius:4px; }
QPushButton:hover { background:#303030; }
QPushButton:disabled { color:#666; background:#1a1a1a; }
QPushButton#primary { background:#0b6fa4; border-color:#0b8fd0; }
QPushButton#primary:hover { background:#0d82c0; }
QPushButton#primary:disabled { background:#1a2a33; color:#666; }
QListWidget { border:none; outline:0; }
QListWidget::item { padding:6px; border-radius:6px; color:#ddd; }
QListWidget::item:selected { background:#1d3b53; border:2px solid #00d0ff; color:white; }
QListWidget::item:hover { background:#222; }
QScrollBar:vertical { background:#121212; width:12px; }
QScrollBar::handle:vertical { background:#444; border-radius:5px; min-height:30px; }
QScrollBar::add-line:vertical, QScrollBar::sub-line:vertical { height:0; }
QPushButton#card { background:#1a1a1a; border:1px solid #2c2c2c; border-radius:12px;
    font-size:16px; padding:28px 16px; min-width:200px; }
QPushButton#card:hover { background:#222; border-color:#00d0ff; }
QPushButton#chip { background:#1e1e1e; border:1px solid #333; border-radius:14px; padding:5px 14px; }
QPushButton#chip:hover { border-color:#00d0ff; }
QLabel#h { font-size:15px; color:#9ab; padding-top:14px; }
"""

def fmt_duration(sec):
    if not sec:
        return "VIDEO"
    sec = int(sec)
    h, m, s = sec // 3600, sec % 3600 // 60, sec % 60
    return f"{h}:{m:02d}:{s:02d}" if h else f"{m}:{s:02d}"


def fix_mix(url):
    if not url:
        return url
    m = re.search(r"[?&]list=(RD[\w-]+)", url)
    if m and not re.search(r"[?&]v=", url) and len(m.group(1)) == 13:
        lst = m.group(1)
        return f"https://www.youtube.com/watch?v={lst[2:]}&list={lst}&start_radio=1"
    return url

def fmt_ago(e):
    ts = e.get("release_timestamp") or e.get("timestamp")
    if not ts and e.get("upload_date"):
        try:
            ts = datetime.strptime(e["upload_date"], "%Y%m%d").replace(tzinfo=timezone.utc).timestamp()
        except ValueError:
            ts = None
    if not ts:
        return ""
    is_release = bool(e.get("release_timestamp"))
    pad = 0 if is_release else (86400 if ts % 86400 == 0 else 3600 if ts % 3600 == 0 else 60 if ts % 60 == 0 else 0)
    d = max(0, datetime.now(timezone.utc).timestamp() - ts + pad)
    for sec, name in ((31536000, "year"), (2592000, "month"), (604800, "week"),
                      (86400, "day"), (3600, "hour"), (60, "minute")):
        if d >= sec:
            n = int(d // sec)
            return f"{n} {name}{'s' if n != 1 else ''} ago"
    return "just now"


def fmt_views(n):
    if not n:
        return ""
    for div, suf in ((1e9, "B"), (1e6, "M"), (1e3, "K")):
        if n >= div:
            return f"{n / div:.1f}".rstrip("0").rstrip(".") + f"{suf} views"
    return f"{int(n)} views"


def meta_line(e):
    ch = e.get("channel") or e.get("uploader") or ""
    parts = [ch, "LIVE" if e.get("live_status") == "is_live" else fmt_duration(e.get("duration")),
             fmt_ago(e), fmt_views(e.get("view_count"))]
    return "  |  ".join(x for x in parts if x)

def entry_url(e):
    u = e.get("url")
    if u and u.startswith(("http://", "https://")):
        return fix_mix(u)
    i = e.get("id")
    if i:
        if i.startswith("RD"):
            return fix_mix(f"https://www.youtube.com/playlist?list={i}")
        if e.get("ie_key") == "YoutubePlaylist" or e.get("_type") == "playlist":
            return f"https://www.youtube.com/playlist?list={i}"
        return f"https://www.youtube.com/watch?v={i}"
    return fix_mix(e.get("webpage_url") or e.get("url"))


def mpv_send(ipc, *commands):
    data = b"".join(
        (json.dumps({"command": command}) + "\n").encode("utf-8")
        for command in commands
    )

    if os.name == "nt":
        with open(ipc, "r+b", buffering=0) as f:
            f.write(data)
            f.flush()
        return

    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.settimeout(5.0)
        s.connect(ipc)
        s.sendall(data)

        # Read mpv's responses before closing the socket.
        received = b""

        while received.count(b"\n") < len(commands):
            chunk = s.recv(4096)

            if not chunk:
                break

            received += chunk


class Fetcher(QThread):
    done = pyqtSignal(list, str)

    def __init__(self, args):
        super().__init__()
        self.args = args

    def run(self):
        try:
            flags = 0x08000000 if os.name == "nt" else 0
            p = subprocess.run(self.args, capture_output=True, creationflags=flags)
            if p.returncode != 0 or not p.stdout:
                self.done.emit([], p.stderr.decode("utf-8", "replace")[-400:] or "yt-dlp failed")
                return
            data = json.loads(p.stdout.decode("utf-8", "replace"))
            self.done.emit(data.get("entries") or [], "")
        except Exception as ex:
            self.done.emit([], str(ex))


class Expander(QThread):
    """Expands mixes/playlists into individual video URLs so each becomes its own playlist entry."""
    done = pyqtSignal(list)

    def __init__(self, entries, base):
        super().__init__()
        self.entries, self.base = entries, base

    @staticmethod
    def is_list(e, url):
        i = str(e.get("id") or "")
        return (e.get("_type") == "playlist" or e.get("ie_key") == "YoutubePlaylist"
                or i.startswith(("RD", "PL")) or "list=RD" in url or "/playlist?" in url)

    def run(self):
        urls = []
        flags = 0x08000000 if os.name == "nt" else 0
        for e in self.entries:
            u = entry_url(e)
            if not self.is_list(e, u):
                urls.append(u)
                continue
            try:
                p = subprocess.run(self.base + [u], capture_output=True, creationflags=flags)
                data = json.loads(p.stdout.decode("utf-8", "replace"))
                sub = [f"https://www.youtube.com/watch?v={x['id']}"
                       for x in (data.get("entries") or []) if x.get("id")]
                urls.extend(sub or [u])
            except Exception:
                urls.append(u)
        self.done.emit(urls)


class Window(QWidget):
    def __init__(self, a):
        super().__init__()
        self.a = a
        self.extra = json.loads(a.extra) if a.extra else []
        self.fetcher = None
        self.expander = None
        self.nam = QNetworkAccessManager(self)
        self.entries = []
        self.page = 0
        self.selected = {}
        self.rendering = False
        self.setWindowTitle("Cadre YouTube")
        self.resize(1080, 720)
        self.setStyleSheet(STYLE)

        self.combo = QComboBox()
        self.combo.addItem("Browse", "__browse__")
        self.combo.addItem("Search", None)
        for k, label, _ in FEEDS:
            self.combo.addItem(label, k)
        self.edit = QLineEdit()
        self.edit.setPlaceholderText("Search YouTube and press Enter...")
        self.btn_search = QPushButton("Search")
        top = QHBoxLayout()
        top.addWidget(self.combo)
        top.addWidget(self.edit, 1)
        top.addWidget(self.btn_search)

        self.status = QLabel("")
        self.list = QListWidget()
        self.list.setViewMode(QListView.ViewMode.IconMode)
        self.list.setResizeMode(QListView.ResizeMode.Adjust)
        self.list.setMovement(QListView.Movement.Static)
        self.list.setSelectionMode(QAbstractItemView.SelectionMode.MultiSelection)
        self.list.setIconSize(QSize(THUMB_W, THUMB_H))
        self.list.setGridSize(QSize(THUMB_W + 28, THUMB_H + 84))
        self.list.setWordWrap(True)
        self.list.setUniformItemSizes(True)
        self.list.setTextElideMode(Qt.TextElideMode.ElideRight)
        self.list.setSpacing(4)
        self.list.setVerticalScrollMode(QAbstractItemView.ScrollMode.ScrollPerPixel)

        self.btn_prev = QPushButton("< Prev")
        self.btn_next = QPushButton("Next >")
        self.lbl_page = QLabel("")
        self.btn_all = QPushButton("Select page")
        self.btn_clear = QPushButton("Clear selection")
        self.lbl_sel = QLabel("0 selected")
        self.btn_add = QPushButton("Add to playlist")
        self.btn_play = QPushButton("Play")
        self.btn_play.setObjectName("primary")
        bottom = QHBoxLayout()
        for w in (self.btn_prev, self.lbl_page, self.btn_next):
            bottom.addWidget(w)
        bottom.addSpacing(20)
        bottom.addWidget(self.btn_all)
        bottom.addWidget(self.btn_clear)
        bottom.addWidget(self.lbl_sel)
        bottom.addStretch(1)
        bottom.addWidget(self.btn_add)
        bottom.addWidget(self.btn_play)

        lay = QVBoxLayout(self)
        lay.addLayout(top)
        lay.addWidget(self.status)
        self.build_browse()
        self.stack = QStackedWidget()
        self.stack.addWidget(self.browse)
        self.stack.addWidget(self.list)
        lay.addWidget(self.stack, 1)
        lay.addLayout(bottom)

        self.edit.returnPressed.connect(self.do_search)
        self.btn_search.clicked.connect(self.do_search)
        self.combo.activated.connect(self.on_combo)
        self.btn_prev.clicked.connect(lambda: self.goto(self.page - 1))
        self.btn_next.clicked.connect(lambda: self.goto(self.page + 1))
        self.btn_all.clicked.connect(self.list.selectAll)
        self.btn_clear.clicked.connect(self.clear_selection)
        self.btn_add.clicked.connect(lambda: self.send_items(False))
        self.btn_play.clicked.connect(lambda: self.send_items(True))
        self.list.itemSelectionChanged.connect(self.on_sel_changed)
        self.list.itemDoubleClicked.connect(lambda it: self.send_items(True, [it]))
        QShortcut(QKeySequence("Escape"), self, activated=self.on_escape)
        QShortcut(QKeySequence("Alt+Home"), self, activated=self.go_browse)
        QShortcut(QKeySequence("Alt+Left"), self, activated=self.go_browse)
        self.update_buttons()
        self.show_browse()
        self.edit.setFocus()

    def go_browse(self):
        if self.fetcher and self.fetcher.isRunning():
            self.fetcher.done.disconnect()
        self.entries, self.page = [], 0
        self.selected.clear()
        self.list.clear()
        self.update_buttons()
        self.show_browse()

    def on_escape(self):
        if self.stack.currentWidget() is self.list and (self.entries or self.status.text()):
            self.go_browse()
        else:
            self.close()

    def load_recent(self):
        try:
            d = json.loads(RECENT_FILE.read_text("utf-8"))
            return [x for x in d if isinstance(x, str) and x.strip()][:RECENT_MAX]
        except Exception:
            return []

    def _write_recent(self, items):
        try:
            DATA_DIR.mkdir(parents=True, exist_ok=True)
            tmp = RECENT_FILE.with_suffix(".tmp")
            tmp.write_text(json.dumps(items, ensure_ascii=False, indent=1), "utf-8")
            os.replace(tmp, RECENT_FILE)   # atomic, no corrupt file on crash
        except OSError as ex:
            self.status.setText(f"History not saved: {ex}")

    def save_recent(self, q):
        q = " ".join(q.split())
        r = [x for x in self.load_recent() if x.lower() != q.lower()]
        r.insert(0, q)
        self._write_recent(r[:RECENT_MAX])

    def remove_recent(self, q):
        self._write_recent([x for x in self.load_recent() if x != q])
        self.show_browse()

    def clear_recent(self):
        try:
            RECENT_FILE.unlink(missing_ok=True)
        except OSError as ex:
            self.status.setText(f"Could not clear: {ex}")
        self.show_browse()

    def build_browse(self):
        self.browse = QWidget()
        self.browse_lay = QVBoxLayout(self.browse)
        self.browse_lay.setContentsMargins(20, 10, 20, 10)

    def show_browse(self):
        lay = self.browse_lay
        while lay.count():
            w = lay.takeAt(0)
            if w.widget():
                w.widget().deleteLater()
            elif w.layout():
                while w.layout().count():
                    x = w.layout().takeAt(0)
                    if x.widget():
                        x.widget().deleteLater()
        t = QLabel("Browse"); t.setObjectName("h"); lay.addWidget(t)
        grid = QGridLayout(); grid.setSpacing(14)
        for i, (k, label, _) in enumerate(FEEDS):
            b = QPushButton(f"{FEED_ICONS.get(k, '')}\n{label}")
            b.setObjectName("card")
            b.clicked.connect(lambda _, k=k: self.pick_feed(k))
            grid.addWidget(b, i // 3, i % 3)
        lay.addLayout(grid)
        rec = self.load_recent()
        if rec:
            hdr = QHBoxLayout()
            h = QLabel("Recent searches"); h.setObjectName("h")
            clr = QPushButton("Clear history"); clr.setObjectName("chip")
            clr.clicked.connect(self.clear_recent)
            hdr.addWidget(h); hdr.addStretch(1); hdr.addWidget(clr)
            lay.addLayout(hdr)
            row = QHBoxLayout()
            for q in rec[:8]:
                c = QPushButton(q); c.setObjectName("chip")
                c.setToolTip("Click: search | Right-click: remove")
                c.clicked.connect(lambda _, q=q: (self.edit.setText(q), self.do_search()))
                c.setContextMenuPolicy(Qt.ContextMenuPolicy.CustomContextMenu)
                c.customContextMenuRequested.connect(lambda _, q=q: self.remove_recent(q))
                row.addWidget(c)
            row.addStretch(1)
            lay.addLayout(row)
        lay.addStretch(1)
        self.combo.setCurrentIndex(0)
        self.status.setText("")
        self.stack.setCurrentWidget(self.browse)

    def pick_feed(self, k):
        self.combo.setCurrentIndex(next(i for i in range(self.combo.count())
                                        if self.combo.itemData(i) == k))
        self.load_feed(k)
        
    def ytdlp(self, tail):
        return [self.a.yt_dlp, "--no-warnings", "-J", "--flat-playlist",
                "--extractor-args", "youtubetab:approximate_date", *self.extra, *tail]

    def on_combo(self, _):
        k = self.combo.currentData()
        if k == "__browse__":
            self.entries, self.page = [], 0
            self.show_browse()
        elif k:
            self.load_feed(k)
        else:
            self.stack.setCurrentWidget(self.list)
            self.edit.setFocus()

    def do_search(self):
        q = self.edit.text().strip()
        if not q:
            return
        self.save_recent(q)
        self.combo.setCurrentIndex(1)   # "Search" is now index 1
        self.start(self.ytdlp([f"ytsearch{SEARCH_TOTAL}:{q}"]), f"Searching: {q}")

    def load_feed(self, key):
        url = next(u for k, _, u in FEEDS if k == key)
        label = next(l for k, l, _ in FEEDS if k == key)
        self.start(self.ytdlp(["--extractor-args", "youtube:flat-playlist=true",
                               "--playlist-end", str(FEED_TOTAL), url]), f"Fetching {label}...")

    def start(self, args, msg):
        if self.fetcher and self.fetcher.isRunning():
            self.fetcher.done.disconnect()
        self.stack.setCurrentWidget(self.list)
        self.entries, self.page = [], 0
        self.selected.clear()
        self.render()
        self.status.setText(msg)
        self.fetcher = Fetcher(args)
        self.fetcher.done.connect(self.on_results)
        self.fetcher.start()

    def on_results(self, entries, err):
        if err and not entries:
            self.status.setText("Failed: " + err)
            return
        self.entries = entries
        self.page = 0
        self.status.setText(f"{len(entries)} results")
        self.render()

    def pages(self):
        return max(1, -(-len(self.entries) // PAGE_SIZE))

    def goto(self, p):
        if 0 <= p < self.pages():
            self.page = p
            self.render()
            self.list.verticalScrollBar().setValue(0)

    def render(self):
        self.rendering = True
        self.list.clear()
        blank = QPixmap(THUMB_W, THUMB_H)
        blank.fill(QColor("#222"))
        chunk = self.entries[self.page * PAGE_SIZE:(self.page + 1) * PAGE_SIZE]
        for e in chunk:
            ch = e.get("channel") or e.get("uploader") or ""
            text = f"{e.get('title') or '(no title)'}\n{meta_line(e)}"
            it = QListWidgetItem(QIcon(blank), text)
            it.setData(Qt.ItemDataRole.UserRole, e)
            it.setToolTip(text)
            it.setSizeHint(QSize(THUMB_W + 20, THUMB_H + 70))
            self.list.addItem(it)
            if entry_url(e) in self.selected:
                it.setSelected(True)
            vid = e.get("id")
            if vid and not str(vid).startswith(("RD", "PL", "UC")):
                self.fetch_thumb(vid, it)
        self.rendering = False
        self.update_buttons()

    def on_sel_changed(self):
        if self.rendering:
            return
        for i in range(self.list.count()):
            it = self.list.item(i)
            e = it.data(Qt.ItemDataRole.UserRole)
            u = entry_url(e)
            if it.isSelected():
                self.selected.setdefault(u, e)
            else:
                self.selected.pop(u, None)
        self.update_buttons()

    def clear_selection(self):
        self.selected.clear()
        self.list.clearSelection()
        self.update_buttons()

    def update_buttons(self):
        n = len(self.selected)
        busy = bool(self.expander and self.expander.isRunning())
        self.lbl_page.setText(f"Page {self.page + 1} / {self.pages()}")
        self.btn_prev.setEnabled(self.page > 0)
        self.btn_next.setEnabled(self.page < self.pages() - 1)
        self.btn_all.setEnabled(self.list.count() > 0)
        self.btn_clear.setEnabled(n > 0)
        self.btn_add.setEnabled(self.list.count() > 0 and not busy)
        self.btn_play.setEnabled(self.list.count() > 0 and not busy)
        self.lbl_sel.setText(f"{n} selected")
        self.btn_add.setText(f"Add to playlist ({n})" if n > 1 else "Add to playlist")
        self.btn_play.setText("Play")

    def fetch_thumb(self, vid, item):
        rep = self.nam.get(QNetworkRequest(QUrl(f"https://i.ytimg.com/vi/{vid}/mqdefault.jpg")))

        def finished():
            data = rep.readAll()
            rep.deleteLater()
            pm = QPixmap()
            if pm.loadFromData(bytes(data)):
                try:
                    pm = pm.scaled(THUMB_W, THUMB_H, Qt.AspectRatioMode.KeepAspectRatioByExpanding,
                                   Qt.TransformationMode.SmoothTransformation).copy(0, 0, THUMB_W, THUMB_H)
                    item.setIcon(QIcon(pm))
                except RuntimeError:
                    pass
        rep.finished.connect(finished)

    def send_items(self, play, items=None):
        if items is not None:
            entries = [i.data(Qt.ItemDataRole.UserRole) for i in items]
        elif self.selected:
            entries = list(self.selected.values())
        else:
            cur = self.list.currentItem()
            entries = [cur.data(Qt.ItemDataRole.UserRole)] if cur else []
        entries = [e for e in entries if entry_url(e)]
        if not entries:
            self.status.setText("Nothing selected")
            return
        extra = list(self.extra)
        if "--playlist-end" not in extra:
            extra += ["--playlist-end", str(MIX_LIMIT)]
        base = [self.a.yt_dlp, "--no-warnings", "-J", "--flat-playlist", *extra]
        self.status.setText("Preparing items...")
        self.expander = Expander(entries, base)
        self.expander.done.connect(lambda urls: self.finish_send(play, urls))
        self.expander.start()
        self.update_buttons()

    def finish_send(self, play, urls):
        self.update_buttons()
        if not urls:
            self.status.setText("Nothing to add")
            return
        try:
            if play:
                cmds = [["loadfile", urls[0], "replace"]] + [["loadfile", u, "append"] for u in urls[1:]]
                mpv_send(self.a.ipc, *cmds)
                self.close()
            else:
                cmds = [["loadfile", u, "append-play"] for u in urls]
                cmds.append(["show-text", f"Added {len(urls)} item(s) to playlist", 2000])
                mpv_send(self.a.ipc, *cmds)
                self.status.setText(f"Added {len(urls)} item(s) to playlist")
                self.clear_selection()
        except Exception as ex:
            self.status.setText(f"IPC error: {ex}")


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--ipc", required=True)
    p.add_argument("--yt-dlp", default="yt-dlp")
    p.add_argument("--extra", default="[]")
    a, _ = p.parse_known_args()
    app = QApplication(sys.argv[:1])
    w = Window(a)
    w.show()
    w.raise_()
    w.activateWindow()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
