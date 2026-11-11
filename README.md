# cadre-player-lite

A modular, themeable UI layer for [mpv](https://mpv.io): custom on-screen controller, playlist, title bar, music mode, YouTube and streaming browsers, subtitle search, A-B loop export and session restore. It is written in Lua, with two small Qt helper apps for the YouTube and Stream windows.


## Theme Previews

| Theme | Preview |
|---|---|
| Default | ![Default](https://raw.githubusercontent.com/Lunedor/cadre-player-lite/refs/heads/main/screenshots/Default.png "Default") |
| MacOsish | ![MacOsish](https://raw.githubusercontent.com/Lunedor/cadre-player-lite/refs/heads/main/screenshots/MacOsish.png "MacOsish") |
| PillGlassy | ![PillGlassy](https://raw.githubusercontent.com/Lunedor/cadre-player-lite/refs/heads/main/screenshots/PillGlassy.png "PillGlassy") |
| Terminal | ![Terminal](https://raw.githubusercontent.com/Lunedor/cadre-player-lite/refs/heads/main/screenshots/Terminal.png "Terminal") |
| GnomeLibadwaita | ![GnomeLibadwaita](https://raw.githubusercontent.com/Lunedor/cadre-player-lite/refs/heads/main/screenshots/GnomeLibadwaita.png "GnomeLibadwaita") |
| NetflixCinema | ![NetflixCinema](https://raw.githubusercontent.com/Lunedor/cadre-player-lite/refs/heads/main/screenshots/NetflixCinema.png "NetflixCinema") |
| Plexed | ![Plexed](https://raw.githubusercontent.com/Lunedor/cadre-player-lite/refs/heads/main/screenshots/Plexed.png "Plexed") |
| Spotilike | ![Spotilike](https://raw.githubusercontent.com/Lunedor/cadre-player-lite/refs/heads/main/screenshots/Spotilike.png "Spotilike") |
| UltraCompact | ![UltraCompact](https://raw.githubusercontent.com/Lunedor/cadre-player-lite/refs/heads/main/screenshots/UltraCompact.png "UltraCompact") |
| VHSRetro | ![VHSRetro](https://raw.githubusercontent.com/Lunedor/cadre-player-lite/refs/heads/main/screenshots/VHSRetro.png "VHSRetro") |
| WinampNostalgia | ![WinampNostalgia](https://raw.githubusercontent.com/Lunedor/cadre-player-lite/refs/heads/main/screenshots/WinampNostalgia.png "WinampNostalgia") |
| YouTubePlayer | ![YouTubePlayer](https://raw.githubusercontent.com/Lunedor/cadre-player-lite/refs/heads/main/screenshots/YouTubePlayer.png "YouTubePlayer") |
| ZenGlass | ![ZenGlass](https://raw.githubusercontent.com/Lunedor/cadre-player-lite/refs/heads/main/screenshots/ZenGlass.png "ZenGlass") |

## Table of Contents
1. [Features](#features)
2. [Folder Structure](#folder-structure)
3. [Installation](#installation)
4. [Configuration (`cadre.conf`)](#configuration-cadreconf)
5. [Module Setup](#module-setup)
6. [Default Keybindings](#default-keybindings)
7. [Thumbnail Previews](#thumbnail-previews-thumbfast)
8. [Troubleshooting](#troubleshooting)
9. [License](#license)

## Features

| Module | Config key | Description | External requirements |
|---|---|---|---|
| OSC | `osc` | Custom on-screen controller | none |
| Playlist | `playlist` | Playlist panel with add file/folder/URL | `zenity` or `kdialog` on Linux for dialogs |
| Title bar | `titlebar` | Custom title bar (sets `border=no`) | none |
| Music mode | `music_mode` | Music-focused window layout | none |
| YouTube | `youtube` | Qt browser: search, home, subscriptions, history, watch later, liked | PyQt6, yt-dlp, Firefox cookies (browse feeds) |
| Stream | `stream` | Qt browser for movies/series (TMDB + Torrentio), continue watching, "Up Next" button | PySide6, TMDB API key, Torrentio config |
| Subtitles | `subs` | OpenSubtitles search and per-file cache | OpenSubtitles API key, `curl` |
| Live Captions | `livecap` | Transcribe and translate audio into live captions or full subtitle files | Python, FFmpeg, Whisper and Hy-MT2 dependencies |
| A-B loop | `ab_loop` | A-B loop queue and clip export | `ffmpeg` on PATH |
| Keep session | `keep_session` | Saves the playlist on exit, can restore it | none |
| Context menu | `menu` | Themeable right-click menu with Cadre and playback actions | none |

### Modular UI

Enable or disable components through `main.modules` in `cadre.conf`; you do not need to move individual Lua files into or out of mpv's `scripts` directory. `main.lua` is the entry point, and the shared helpers and theme code remain inside `cadre/scripts/`.

Optional content-aware themes can be enabled in the `auto_theme` section of `cadre.conf`. Set `enabled` to `true` and choose theme file names (without `.lua`) for images and music. The saved `main.theme` remains the fallback for video and other content. `music_mode_counts_as_music` lets an explicitly active Cadre Music Mode use the music theme even when a stream also has video, such as a YouTube music video. `themes/Image.lua` and `themes/Music.lua` are editable sample themes.

The OSC, playlist and title bar coordinate mouse input and window dragging. The OSC uses Cadre's playlist navigation when that module is enabled and falls back to mpv's normal previous/next commands otherwise.

### On-screen controller

- Floating or full-width control bar with configurable dimensions, margins and insets.
- Seekbar with hover expansion, draggable seeking, chapter markers and chapter-name tooltips.
- Optional seek previews through thumbfast.
- Volume flyout with a vertical slider.
- Native add-file, add-folder and add-URL dialogs.
- Previous, play/pause, next, stop, fullscreen and playlist controls.
- Configurable left, center and right button groups. Supported items include `prev`, `play`, `play_only`, `pause`, `next`, `stop`, `seekbar_back`, `seekbar_forward`, `volume`, `volume_slider`, `mute`, `time`, `title`, `seekbar`, `add`, `subtitle`, `subtitle_list`, `audio_list`, `fullscreen`, `frame_back_step`, `frame_step`, `chapter_prev`, `chapter_next` `settings`, `speed_down`, `speed_reset`, `speed_up`, `ab_loop` `playlist`, `stream`, `youtube`, `music_mode`, `info`, `screenshot`, `pin`, `pip`, `ontop`, `separator` and `quit`.
- Optional 10-second seek buttons and a YouTube-style time display.
- Settings dialog for subtitle and audio tracks, quality/edition/title selection, subtitle delay, scale, position, outline and shadow, plus playback speed, aspect ratio and display mode.
- Subtitle button to toggle the visibility of the selected subtitle.
- YouTube chapter loading when `yt-dlp` is available.

### Live Captions

When `main.modules.livecap` is enabled and Live Captions is turned on with the CC toggle, the subtitle popup keeps the CC toggle and OpenSubtitles button in its header and shows caption actions below. The Settings dialog adds a **Captions** tab while captions are on. The tab leads with viewer-facing appearance choices: caption position, font, size, margins, text and outline colors, outline thickness, shadow and display time. The side margin keeps long caption lines inside a safe area on both sides of the video, including when captions are centered. Use the `+`/`−` controls to cycle position and colors or adjust numeric values. Changes are staged in the tab and saved with **Done**; **Reset** stages the defaults from `cadre.conf`.

Spoken and caption languages and the speech and translation model dropdowns follow the appearance controls. Speech models include `tiny`, `base`, `small`, `medium`, `large-v3-turbo` and `large-v3`; translation offers the Q4_K_M, Q6_K and Q8_0 variants of [Hy-MT2-1.8B](https://huggingface.co/tencent/Hy-MT2-1.8B-GGUF). Leave spoken language empty for automatic detection. Language changes apply at a caption-block boundary, while controls are locked during full-file jobs. Model changes are saved as pending until **Restart** is selected. Less common processing and status options are grouped under **Advanced processing options**.

**Save live transcript** appends captions to a language-tagged `.srt` file during playback. Replayed sections do not add duplicate entries for the same timings and text. When that saved SRT is loaded, it is selected and the live-caption overlay is suppressed; new, non-duplicate captions can still be appended. This does not disable **Create subtitles from audio**, which always writes a full subtitle file. **Save to cache folder** chooses between the configured cache folder and the local video's folder (remote media always uses cache), and **Cache folder** sets the cache location. **Start captions automatically** controls whether captions are enabled at mpv launch.

With `prime_seconds` set to 45, playback pauses while that much audio is transcribed and translated after a video starts or you seek. Playback resumes when the captions are ready; turn off **Auto-resume when ready** to keep it paused for manual playback. The buffer length is configurable under **Advanced processing options**.

#### Live Captions configuration

The following settings are under the top-level `livecap` object in `cadre.conf`. Empty path and language values use the described automatic or built-in defaults.

| Setting | Explanation |
| --- | --- |
| `mpv_path` | Path to the mpv executable used for Live Captions' audio-processing subprocess. Set this when mpv is not available as `mpv` on `PATH`. |
| `python_path` | Python executable used to run the Live Captions worker. Empty uses `python` from `PATH`. |
| `source_language` | Language spoken in the audio. Empty lets Whisper detect it automatically; otherwise use a language code such as `en`. |
| `target_language` | Language to translate captions into, specified by language code. The example value `tr` means Turkish. |
| `device` | Compute device for Whisper, such as `cpu` or `cuda`. Empty selects automatically. |
| `compute_type` | Whisper numeric precision/compute mode, such as `int8` or `float16`. Empty lets faster-whisper choose its default for the selected device. |
| `log_enabled` | Whether the Live Captions worker writes diagnostic logs. |
| `log_max_mb` | Maximum worker-log size in megabytes; the log is cleared when it reaches this limit. |
| `models_dir` | Directory for downloaded speech and translation models. Empty uses `data/models` beside the Cadre scripts. |
| `whisper_model` | Speech-recognition model name, for example `tiny`, `base`, `small`, `medium`, `large-v3-turbo` or `large-v3`. Empty uses `large-v3-turbo`. |
| `hy_mt2_model` | Hy-MT2 translation model variant. The supported names include `Hy-MT2-1.8B-Q4_K_M`, `Hy-MT2-1.8B-Q6_K` and `Hy-MT2-1.8B-Q8_0`; the selected model is downloaded if needed. |
| `auto_start` | Starts Live Captions automatically when mpv launches. |
| `prime_seconds` | Amount of audio, in seconds, prepared after a video starts or a seek before playback resumes. Set to `0` to disable this preparation step. |
| `auto_resume_after_preroll` | Resumes playback automatically when the preparation period finishes. When false, playback stays paused. |
| `caption_block_length` | Audio block length, in seconds, used for ongoing transcription and translation. Larger blocks can reduce processing overhead but captions arrive less frequently. |
| `subtitle_extraction_timeout` | Maximum time, in seconds, allowed to extract an embedded subtitle track from a local video with FFmpeg. Defaults to `60`; embedded subtitle extraction is disabled for remote videos to avoid reading the video over the network. |
| `context_window` | Number of recent source/translated caption pairs provided as context to translation. `0` disables this context. |
| `save_srt` | Appends live captions to an SRT subtitle file during playback. |
| `osd_status` | Shows Live Captions status messages in mpv's on-screen display. |
| `subtitle_save_mode` | Where generated subtitle files for local videos are saved: `auto` saves beside the video; `cache` saves in the configured subtitle cache. Remote videos use the cache either way. |
| `subs_dir` | Subtitle cache directory. Empty uses Cadre's `data/subs-cache` directory. |

The nested `overlay` settings control the appearance of live captions:

| Setting | Explanation |
| --- | --- |
| `align` | ASS alignment number from `1` to `9`: bottom, middle or top row, with left, center or right alignment. `2` is bottom-center. |
| `margin_x` | Horizontal inset from the left/right edge, in pixels; also limits the available caption text width. |
| `margin_y` | Inset from the vertical edge corresponding to `align`, in pixels. |
| `font` | Font family used to render captions. |
| `font_size` | Caption font size in mpv's ASS overlay. |
| `color` | Caption text color in ASS color notation (`&HAABBGGRR&`). `&H00FFFFFF&` is opaque white. |
| `border_color` | Outline color in ASS color notation. `&H00000000&` is opaque black. |
| `border_width` | Outline thickness. |
| `shadow` | Shadow depth; `0` disables the shadow. |
| `max_duration` | Maximum time, in seconds, that a caption is displayed. |

This module needs following libraries be installed on the system. It select optimum device and compute type for working device but you can override those settings by cadre.conf file.

```
faster-whisper
llama-cpp-python
huggingface-hub
psutil
```

### Playlist

- Searchable, scrollable playlist overlay.
- Ctrl-click for multiple selection and Shift-click for range selection.
- Double-click to play an item.
- Drag-and-drop reordering, including selected groups.
- Remove selected entries without deleting their files, or move selected local files to the platform trash/recycle bin.
- Shuffle playback order without rearranging the visible playlist.
- Repeat off, repeat playlist and repeat current modes.
- Auto Next to advance to the next file in the folder when the playlist reaches its end.
- Save and load M3U/M3U8 playlists.
- Per-item durations when mpv has reported them.
- Themeable rows, selection/current-item highlights, indices, titles, durations, toolbar, search field and scrollbar.

| Key | Playlist action |
|---|---|
| `Del` | Remove selected entries from the playlist without deleting files |
| `Shift+Del` | Move selected local files to the trash/recycle bin and remove them from the playlist |

URLs and streams cannot be moved to the trash/recycle bin.

#### Shuffle-aware keyboard navigation

Native mpv playlist commands bypass Cadre's custom shuffle order. To make your next/previous shortcuts use that order, add bindings like these to `input.conf` while the playlist module is enabled:

```ini
ENTER      script-message playlist-next
KP_ENTER   script-message playlist-next
>          script-message playlist-next
PGDN       script-message playlist-next
<          script-message playlist-prev
PGUP       script-message playlist-prev
```

The OSC routes its previous/next buttons through the playlist module automatically when it is enabled.

### Title bar

- Custom title bar for borderless mpv windows, with minimize, maximize/restore and close controls.
- Configurable left-side or right-side window buttons, with standard symbols or macOS-style colored traffic-light dots.
- Configurable title alignment and startup visibility.
- Coordinates dragging with the OSC and playlist so controls do not interfere with window movement.

The title bar module sets `border=no`; you do not need the old manual border configuration for this module.

Set `M.titlebar_button_style_tb = "macos"` in a theme to use colored traffic-light buttons. This style defaults to left-side placement; `titlebar_button_side_tb` can override it. The circles are drawn shapes and need no additional font.

### Theme customization

Select the active theme with `main.theme` in `cadre.conf`. Theme styling includes colors, transparency, fonts, typography, component dimensions, spacing, radii and visibility behavior.

The UI supports configurable OSC panel placement, seekbar and button insets, button-row anchoring, button-group alignment, icon backgrounds and borders, group capsules, seekbar/thumb borders, playlist row spacing and padding, and title-bar sizing.

Themes can optionally blur the video behind the OSC, playlist, and title bar. Set `glass_blur = true` to enable all three; `glass_blur_osc`, `glass_blur_pl`, or `glass_blur_tb` can override the shared toggle for an individual panel. Set `glass_blur_radius` for a shared radius or use the component-specific `glass_blur_radius_*` settings. The effect requires `vo=gpu-next`; other video outputs keep the UI working with its normal translucent panels. Blur remains enabled during video rotation, with a coordinate flip for 180°. Panel alpha controls the tint and transparency over the blur. Start around a radius of 8–12 and tune it for your GPU and preference. Larger radii cost more GPU work within the blurred panels. See `themes/FrostGlass.lua` for a working example.

Fluent System Icons Regular and Filled use built-in glyph maps when `font_icon` (or a component-specific icon font setting) exactly matches `FluentSystemIcons-Regular` or `FluentSystemIcons-Filled`. Changing between icon font families while mpv is running can still produce stale glyphs or libass missing-glyph messages on some builds. If a restart does not clear the mismatch, verify that the active theme's font family is the font's internal family name and that every Cadre script is loading the same theme; custom fonts can define `icon_codepoints` in the theme. OSC, playlist, and titlebar panel outlines use the `*_border_color_*`, `*_border_alpha_*`, and `*_border_width_*` settings documented in `scripts/cadre_theme.lua`. Set a border width to `0` to disable it.

```lua
M.glass_blur = true -- Enable blur on all three panels.
M.glass_blur_osc = false -- Optional: disable blur for just the osc.
M.glass_blur_tb = false -- Optional: disable blur for just the titlebar.
M.glass_blur_pl = false -- Optional: disable blur for just the playlist.
M.radius_glass_blur = 12
M.alpha_panel_bg = "68" -- ASS transparency: 00 opaque, FF transparent
```

The older standalone-script `M.theme_variant` instructions are not the theme-selection instructions for this version. Use `main.theme`; this README does not assume the old theme lookup paths or replacement/merge behavior still apply.

## Folder Structure
```
mpv/
├── scripts/
│   ├── thumbfast.lua # unmodified upstream thumbfast (seekbar thumbnails)
│   └── cadre/
│       ├── main.lua # entry point, loads enabled modules
│       ├── cadre.conf # single JSON config file
│       ├── scripts/
│       │   ├── cadre_common.lua
│       │   ├── cadre_theme.lua
│       │   ├── cadre_osc.lua
│       │   ├── cadre_playlist.lua
│       │   ├── cadre_titlebar.lua
│       │   ├── cadre_music_mode.lua
│       │   ├── cadre_ab_loop.lua
│       │   ├── cadre_keep_session.lua
│       │   ├── cadre_youtube.lua
│       │   ├── cadre_stream.lua
│       │   └── cadre_subs.lua
│       ├── tools/
│       │   ├── cadre_stream.py
│       │   └── cadre_youtube-qt.py
│       ├── fonts/ # Inter, Material Icons, Segoe MDL2
│       └── data/ # created by scripts (state, caches, sessions)
└── script-opts/
    └── thumbfast.conf # optional: thumbfast settings
```

## Requirements

- A current mpv build.
- Bundled icon/UI fonts, installed through `main.install_fonts`. The bundle includes Inter, Material Icons and Segoe MDL2 fonts.
- Optional integrations need only the dependencies listed for their modules; Python and Qt are not required just to use the core Lua UI.
- `yt-dlp` for the YouTube module and automatic YouTube chapters.
- `ffmpeg` for A-B loop clip export.
- `curl` for subtitle search.

### Native dialogs and trash integration

The core UI supports Windows and Linux; individual optional modules may have narrower platform support.

On Windows, native file/folder/URL dialogs and Recycle Bin integration use PowerShell.

On Linux, install a graphical dialog backend. Cadre tries `zenity` first and falls back to `kdialog` if the first backend cannot start. Canceling a dialog does not open the fallback backend.

```bash
# Debian/Ubuntu: choose a backend
sudo apt install zenity
# or
sudo apt install kdialog
```

Equivalent packages are available through other distributions' package managers, for example `sudo dnf install zenity` on Fedora or `sudo pacman -S zenity` on Arch. Linux trash integration uses `gio trash`, then `trash-put` when available.

Missing optional helpers affect their corresponding features, not the entire UI. WSL graphics warnings and trash failures on Windows-mounted `/mnt/*` paths are environmental limitations rather than supported native Linux behavior.

## Installation

1. Download or clone this repository.
2. Put the `cadre` folder **and** `thumbfast.lua` inside mpv's `scripts` folder:
   - Windows: `%APPDATA%\mpv\scripts\` (portable: `<mpv folder>\portable_config\scripts\`)
   - Linux: `~/.config/mpv/scripts/`
   Result: `scripts/cadre/` and `scripts/thumbfast.lua`.
3. Start mpv. `main.lua` loads automatically.
4. On first start, fonts are copied to mpv's `fonts` folder if `install_fonts` is `true`. Restart mpv once when the "fonts installed" message appears. The flag is then set back to `false` automatically.
5. Optional: set `osc=no` in `mpv.conf` so the stock OSC is not loaded. Otherwise `main.lua` hides it for you.

Modules are switched on in `cadre.conf` under `main.modules`. The default config enables `osc`, `playlist`, `titlebar` and `music_mode`. Enable the others after finishing their setup below.

## Configuration (`cadre.conf`)

Default file:

```json
{
  "main": {
    "theme": "Default",
    "install_fonts": true,
    "modules": {
      "osc": true, "playlist": true, "titlebar": true, "stream": false,
      "youtube": false, "music_mode": true, "ab_loop": false, "subs": false,
      "keep_session": false, "menu": false
    }
  },
  "keys": {
    "playlist": "p",
    "osc": "o",
    "titlebar": "t",
    "music_mode": "alt+m",
    "youtube": "ctrl+y",
    "stream": "ctrl+s",
    "subs_search": "ctrl+u"
  },
  "subs": {
    "api_key": "",
    "languages": ["tr"],
    "max_results": 5
  },
  "youtube": {
    "python_path": "",
    "yt_dlp_path": "yt-dlp",
    "pipe_prefix": "cadre_youtube"
  },
  "stream": {
    "python_path": "",
    "tmdb_api_key": "",
    "torrentio_base": "https://torrentio.strem.fun",
    "torrentio_config": "",
    "next_btn_align": "right",
    "next_btn_margin_bottom": 120,
    "next_btn_w": 460,
    "next_btn_h": 128
  },
  "music_mode": {
    "win_w": 1280, "win_h": 720,
    "resize_window": true
  }
}
```

### Context menu

Enable the menu with `"menu": true` under `main.modules` in `cadre.conf`. Right-click to open it; use the mouse or arrow keys and Enter to navigate, and Escape to go back or close it. The built-in entries are stored in `data/cadre_menu_default.conf`.

The default menu includes Open actions, playlist controls, Cadre controls, and Audio Tracks, Subtitle Tracks, Editions, and Chapters sections. Empty sections show a dimmed message. Long labels are shortened to fit; long lists show up to 12 entries with a scrollbar that can be clicked or dragged. Hover opens submenus after a short pause. The wheel scrolls the visible list independently of the selected item, while keyboard navigation keeps the selection in view.

Create `menu.conf` beside `cadre.conf` to hide built-in entries or add your own commands. Hiding a submenu hides all its children. `hide_all` clears the built-in entries while keeping commands and submenus defined in `menu.conf`, so use it to replace the default menu. User entries use `command #! Menu > Item`; an optional stable ID can be supplied as `command #! stable.id | Menu > Item`. Without one, the ID is generated from the menu path (for example, `Cadre Scripts > YouTube` becomes `cadre_scripts.youtube`). Actions use mpv's command syntax and are passed to mpv intact, so command prefixes such as `no-osd`, command arguments, script bindings, and semicolon-separated commands are supported. Use `separator #! stable.id | root` for a root-level separator, or `separator #! stable.id | Submenu` for one inside a submenu. Place the separator line where it belongs in `menu.conf`; entries in a submenu follow file order. A leading separator inside a submenu is omitted.

Supported dynamic sources are `audio_tracks`, `subtitle_tracks`, `editions`, `chapters`, `playlist_actions`, `playback_speed`, `ab_loop`, `video_rotation`, `video_mirror`, `video_zoom_pan`, `video_filters`, and `audio_channels`. Dynamic sections with no available content show a dimmed placeholder.

```ini
# Hide a submenu and everything inside it
hide audio_tracks

# Or hide one entry
hide playlist.actions.repeat

# Hide every built-in menu item
# hide_all

# Add a separator before the new submenu, then add its commands
separator #! cadre_scripts.separator | root
script-message mpv-youtube-search-open #! Cadre Scripts > YouTube
script-message cadre-stream-open #! Cadre Scripts > Stream
script-message music-mode-toggle #! Cadre Scripts > Music Mode
```

### Reference

| Section | Key | Meaning |
|---|---|---|
| `main` | `theme` | Active theme name |
| `main` | `install_fonts` | Copy bundled fonts to mpv's `fonts` folder on next start, then reset to `false` |
| `main` | `modules.*` | Turn each module on or off |
| `keys` | `*` | Key for each module. Use `""` or `"none"` for no key |
| `subs` | `api_key` | OpenSubtitles API key |
| `subs` | `languages` | Language codes, e.g. `["en","tr"]` |
| `subs` | `max_results` | Results shown (1-9 selectable by number key) |
| `youtube` / `stream` | `python_path` | Python executable that runs the helper. See [Python path](#python-path) |
| `youtube` | `yt_dlp_path` | `yt-dlp` command or full path |
| `youtube` | `pipe_prefix` | Prefix of the IPC pipe or socket mpv exposes to the helper |
| `stream` | `tmdb_api_key` | TMDB API key (required) |
| `stream` | `torrentio_base` / `torrentio_config` | Torrentio addon URL and your config string |
| `stream` | `next_btn_*` | "Up Next" card alignment (`left`/`center`/`right`), size and margins on a 1920x1080 canvas. `next_btn_margin_x` is also supported |
| `music_mode` | `win_w`, `win_h`, `resize_window` | Window size used in music mode |

## Module Setup

### Python path

`python_path` depends on your system. On Windows `pythonw` is the recommended value because it opens no console window. If it does not work, set the exact path:

```json
"python_path": "C:\\Users\\<you>\\AppData\\Local\\Programs\\Python\\Python312\\pythonw.exe"
```

On Linux use `python3` or the full path, such as `/usr/bin/python3`.

If you leave the Stream `python_path` empty, it falls back to `python`.

### Qt requirements (YouTube and Stream)

Install the binding imported by the helper, using the same Python interpreter configured in `python_path`.

Dependency clarification: the current module table lists PyQt6 for YouTube and PySide6 for Stream, but the current Stream setup instructions specify PyQt6. This cannot be resolved from the READMEs alone. Check the imports in `tools/cadre_stream.py` before choosing the Stream dependency.

On Windows, for YouTube:

```powershell
python -m pip install PyQt6
```

For Stream, install the binding its helper imports:

```powershell
# If cadre_stream.py imports PySide6:
python -m pip install PySide6

# If cadre_stream.py imports PyQt6 instead:
python -m pip install PyQt6
```

On Linux, a distribution package is one option. Debian/Ubuntu example for YouTube:

```bash
sudo apt install python3-pyqt6
```

Alternatively, use a Python environment containing the required binding and set `python_path` to that environment's interpreter. The important requirement is that the configured interpreter can import the helper's Qt binding.

### YouTube (`ctrl+y`)

1. Install PyQt6 (above) and set `youtube.python_path`.
2. Make sure `yt-dlp` is available. If it is not on your PATH, set `youtube.yt_dlp_path` to its full path.
3. To use every layout **except Search** (Home, Subscriptions, Watch history, Watch Later, Liked videos), add this line to `mpv.conf`:

```ini
ytdl-raw-options=cookies-from-browser=firefox,yes-playlist=,playlist-items=1:50
```

4. Log in to YouTube in Firefox. Firefox is the browser specified by this setup; support for other browsers is not documented here.
5. Set `"youtube": true` in `main.modules`.

Search works without the `mpv.conf` line. The helper reads your `ytdl-raw-options` and passes them to yt-dlp.

### Stream (`ctrl+s`)

1. Install the Qt binding imported by `tools/cadre_stream.py` (see the dependency clarification above) and set `stream.python_path`.
2. Create a free [TMDB](https://www.themoviedb.org/settings/api) API key and set `stream.tmdb_api_key`.
3. Keep `stream.torrentio_base` unless you host your own Torrentio. Fill in `stream.torrentio_config` with the config string from your Torrentio setup. Only sources that return a direct playable URL are listed.
4. Set `"stream": true` in `main.modules`.

Sections: Trending, Continue Watching, My List, and search. Near the end of a series episode (95%), the next episode is fetched and an "Up Next" button appears. Click it, or press `Shift+N`, to jump. Progress is saved in `data/cadre_stream_state.json`.

### Subtitles (`ctrl+u`)

1. Create an [OpenSubtitles](https://www.opensubtitles.com) API key.
2. Set `subs.api_key` and `subs.languages`.
3. Make sure `curl` is available.
4. Set `"subs": true`.

Press `ctrl+u`, then choose a result with number keys `1`-`9`, or `Esc` to cancel. Subtitles are cached in `data/subs-cache/` and reloaded for the same file.

### A-B loop

Requires `ffmpeg` on PATH for export. Exports are local files only and go to a `Cadre Exports` folder next to the source video, as H.264/AAC MP4.

| Key | Action |
|---|---|
| `a` / `q` | Set A / set B and start looping |
| `z` | Clear an unsaved loop, or stop a saved loop |
| `w` | Save loop to queue |
| `Shift+w` | Show queue |
| `Shift+a` / `Shift+q` | Previous / next queued loop |
| `Ctrl+z` | Remove last queued loop |
| `Ctrl+Backspace` | Remove selected queued loop |
| `Shift+z` | Clear queue |
| `e` / `Shift+e` | Export active loop / export all queued loops |

### Keep session

The playlist is saved when mpv closes, to `data/prev-session`. Defaults: `auto_save = true`, `auto_load = false`, `load_playlist = true`, `maintain_pos = true`. To change them, create `script-opts/keep_session.conf`, for example:

```ini
auto_load=yes
```

You can also trigger it manually, for example from `input.conf`:

```ini
F5 script-message save-session
F6 script-message reload-session
```
## Thumbnail Previews (thumbfast)

The OSC shows seekbar thumbnails through [thumbfast](https://github.com/po5/thumbfast). The repository includes an unmodified copy of `thumbfast.lua`. All credit goes to its authors.

- `thumbfast.lua` goes directly in `scripts/`, next to the `cadre` folder, not inside it. mpv auto-loads it from there. `main.lua` does not load it.
- It is not a Cadre module, so there is no switch for it in `cadre.conf`. To disable thumbnails, remove `thumbfast.lua`.
- Which sources get thumbnails is decided by thumbfast itself. See the upstream README for its limits and options.
- Thumbfast options go in `script-opts/thumbfast.conf`, for example:

```ini
max_height=200
max_width=200
```

If you already have thumbfast installed, keep only one copy so it doesn't load twice.

## Default Keybindings

| Key | Action |
|---|---|
| `o` | Toggle OSC |
| `p` | Toggle playlist |
| `t` | Toggle title bar |
| `Alt+m` | Music mode |
| `Ctrl+y` | YouTube |
| `Ctrl+s` | Stream |
| `Ctrl+u` | Subtitle search |
| `Ctrl+Shift+c` | Toggle live captions |
| `Ctrl+Shift+t` | Translate the selected/available text subtitle |
| `Ctrl+Shift+s` | Create subtitles from audio |
| `Shift+n` | Play next episode now (Stream) |

The module-toggle/search shortcuts listed in the `keys` section can be changed in `cadre.conf`. For live captions, set `keys.livecap_toggle`; use `""` or `"none"` to disable its default shortcut. Key changes take effect after reloading the script or restarting mpv. Subtitle translation and audio-to-SRT creation can start their worker even while live captions are off; their progress is shown in the OSD when `livecap.osd_status` is enabled. The Stream `Shift+n` shortcut and A-B loop shortcuts are documented separately; they are not entries in the shown `keys` section. Module-specific shortcuts require the corresponding module to be enabled.

## Troubleshooting

- **YouTube or Stream window does not open:** check `python_path`. Use the exact path to `pythonw.exe` or `python3`, and confirm the Qt package is installed for that interpreter.
- **YouTube browse feeds are empty or fail:** check the `ytdl-raw-options` line in `mpv.conf`, that you are logged in to YouTube in Firefox, and that `yt-dlp` resolves.
- **Stream shows no sources:** check `tmdb_api_key` and `torrentio_config`.
- **Fonts or icons look wrong:** set `install_fonts` to `true` and restart mpv twice.
- **Config ignored:** `cadre.conf` must be valid JSON. If it cannot be parsed, defaults are used.

## Upgrading from the standalone-script layout

- Use `scripts/cadre/main.lua` and the bundled directory structure rather than placing each `cadre_*.lua` file directly in mpv's `scripts` directory.
- Remove old standalone copies of Cadre scripts from `scripts/` to avoid loading duplicate UI components.
- Enable or disable modules in `cadre.conf` instead of adding or removing individual component files.
- Select the theme using `main.theme`, not the old `M.theme_variant` instructions.
- Review old `input.conf` bindings before keeping them; the new module-toggle keys are configured in `cadre.conf`.
- Keep just one `thumbfast.lua`, directly in mpv's `scripts` directory.
- Restart mpv after changing module configuration, theme selection or the installed scripts.

## Optional: uosc menu integration

Cadre can run alongside uosc as a menu provider. Disable uosc’s visible UI in script-opts/uosc.conf:

```
top_bar=never
title=no
timeline=no
volume=no
disable_elements=idle_indicator
controls=
```

Then add those to input.conf:

```
MBTN_RIGHT script-binding uosc/menu
menu       script-binding uosc/menu
```

Cadre remains the primary UI; uosc provides its right-click menu and script integrations.

## External projects

- [WEBDAV-browser-MPV](https://github.com/0xSilentNeo/WEBDAV-browser-MPV) by 0xSilentNeo provides the WebDAV poster browser in `external/`. Cadre integration and configuration changes are maintained here.

## License

MIT License. See [LICENSE](LICENSE).
