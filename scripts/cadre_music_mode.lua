-- cadre_music_mode.lua: Spotify-style lyrics, cover + visualizer, click-to-seek

local mp = require "mp"
local utils = require "mp.utils"
local common = dofile(mp.command_native({"expand-path", "~~/scripts/cadre/scripts/cadre_common.lua"}))

local O = {
    key = "Alt+m",
    key_vis = "Alt+v",
    key_later = "Alt+.",
    key_earlier = "Alt+,",
    audio_format = "bestaudio/best",
    fps = 30,
    font = "",
    api = "https://lrclib.net/api",
    duration_tolerance = 5,
    cache_dir = "~~/scripts/cadre/data/music-cache/",
    cover = true,
    ffmpeg = "ffmpeg",
    visualizer = true,
    vis_graph = "[aid1]asplit[ao][a];[a]showcqt=s=640x360:fps=30:axis=0:sono_h=0:bar_v=7,format=yuv420p[vo]",
    lyrics_x = 0.06,
    lyrics_w = 0.50,
    panel_x = 0.62,
    panel_w = 0.32,
    char_w = 0.55,
    win_w = 1280,
    win_h = 720,
    resize_window = true
}

O = common.section("music_mode", O)

local active, saved = false, {}
local lyrics, status = nil, ""
local gen, pending_seek = 0, nil
local offset, scroll, hl, last_tick = 0, 1, 1, nil
local browse_idx, browse_until = 1, 0
local layout, geo_cache, hits = nil, nil, {}
local meta = {title = "", artist = ""}
local cover = {have = false, file = nil, cur = nil}
local ov = mp.create_osd_overlay("ass-events")
local timer, resize_timer
local last_w, last_h = 0, 0
local cover_shown = true

local function clamp(x, a, b)
    return math.max(a, math.min(b, x))
end
local function trim(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end
local function ulen(s)
    return #s:gsub("[\128-\191]", "")
end

local function osd_size()
    local W, H = mp.get_osd_size()
    if not W or W == 0 or not H or H == 0 then
        return O.win_w, O.win_h
    end
    return W, H
end

local function cpath(name)
    return mp.command_native({"expand-path", O.cache_dir .. name})
end

local function ensure_dir()
    local d = mp.command_native({"expand-path", O.cache_dir})
    if utils.file_info(d) then
        return
    end
    local win = package.config:sub(1, 1) == "\\"
    mp.command_native(
        {
            name = "subprocess",
            playback_only = false,
            args = win and {"cmd", "/c", "mkdir", (d:gsub("/", "\\"))} or {"mkdir", "-p", d}
        }
    )
end

-- ---------- metadata ----------
local junk = {"official", "lyric", "video", "audio", "visuali", "remaster", "hd", "4k", "mv", "clip"}
local function is_junk(s)
    s = s:lower()
    for _, w in ipairs(junk) do
        if s:find(w, 1, true) then
            return true
        end
    end
    return false
end

local function clean_title(t)
    t =
        t:gsub(
        "%b()",
        function(s)
            return is_junk(s) and "" or s
        end
    )
    t =
        t:gsub(
        "%b[]",
        function(s)
            return is_junk(s) and "" or s
        end
    )
    return trim((t:gsub("%s+", " ")))
end

local function get_meta()
    local md = mp.get_property_native("metadata") or {}
    local function g(k)
        for key, v in pairs(md) do
            if type(key) == "string" and key:lower() == k and type(v) == "string" and v ~= "" then
                return v
            end
        end
    end
    local title = g("title") or mp.get_property("media-title") or ""
    local artist = g("artist") or g("album_artist") or ""
    artist = trim(artist:gsub(" %- Topic$", ""))
    title = clean_title(title)
    local a, t = title:match("^(.-)%s+[-–—]%s+(.+)$")
    if a and t then
        if artist == "" or a:lower():find(artist:lower(), 1, true) then
            artist = (artist ~= "" and artist) or a
            title = t
        end
    end
    return {title = trim(title), artist = artist}
end

-- ---------- LRC ----------
local function parse_lrc(s)
    local items = {}
    for line in s:gmatch("[^\r\n]+") do
        local rest, ts = line, {}
        while true do
            local m, sec, r = rest:match("^%s*%[(%d+):(%d+%.?%d*)%](.*)$")
            if not m then
                break
            end
            ts[#ts + 1] = tonumber(m) * 60 + tonumber(sec)
            rest = r
        end
        if #ts > 0 then
            local text = trim(rest)
            for _, t in ipairs(ts) do
                items[#items + 1] = {t = t, text = text}
            end
        end
    end
    table.sort(
        items,
        function(a, b)
            return a.t < b.t
        end
    )
    return items
end

-- ---------- network ----------
local function http_get(base, params, cb)
    local args = {"curl", "-s", "-L", "--max-time", "10", "-A", "mpv-music-mode/1.0", "-G", base}
    for k, v in pairs(params) do
        if v and v ~= "" then
            args[#args + 1] = "--data-urlencode"
            args[#args + 1] = k .. "=" .. v
        end
    end
    mp.command_native_async(
        {
            name = "subprocess",
            args = args,
            capture_stdout = true,
            playback_only = false
        },
        function(ok, res)
            if ok and res and res.status == 0 and res.stdout then
                cb(utils.parse_json(res.stdout))
            else
                cb(nil)
            end
        end
    )
end

local function download(url, dest, cb)
    mp.command_native_async(
        {
            name = "subprocess",
            playback_only = false,
            args = {"curl", "-s", "-L", "--fail", "--max-time", "10", "-o", dest, url}
        },
        function(ok, res)
            cb(ok and res and res.status == 0)
        end
    )
end

local function pick(list, dur)
    local best, bd
    if type(list) ~= "table" then
        return nil
    end
    for _, r in ipairs(list) do
        if type(r) == "table" and type(r.syncedLyrics) == "string" and #r.syncedLyrics > 0 then
            local d = dur and math.abs((tonumber(r.duration) or 0) - dur) or 0
            if d <= O.duration_tolerance and (not bd or d < bd) then
                best, bd = r, d
            end
        end
    end
    return best
end

local function track_key()
    return ((mp.get_property("path") or "x"):gsub("[^%w]", "_")):sub(-80)
end

local function load_lyrics()
    gen = gen + 1
    local my = gen
    lyrics, layout, scroll, hl = nil, nil, 1, 1
    browse_until = 0
    meta = get_meta()
    status = "Searching lyrics..."

    local cp = cpath("lyrics_" .. track_key() .. ".lrc")
    local f = io.open(cp, "r")
    if f then
        local s = f:read("*a")
        f:close()
        local items = parse_lrc(s)
        if #items > 0 then
            lyrics, status = items, ""
            return
        end
    end

    local dur = mp.get_property_number("duration")
    dur = dur and math.floor(dur + 0.5) or nil

    local function done(r)
        if my ~= gen then
            return
        end
        if r then
            local items = parse_lrc(r.syncedLyrics)
            if #items > 0 then
                lyrics, status = items, ""
                local w = io.open(cp, "w")
                if w then
                    w:write(r.syncedLyrics)
                    w:close()
                end
                return
            end
        end
        status = "No synced lyrics found"
    end

    http_get(
        O.api .. "/search",
        {track_name = meta.title, artist_name = meta.artist},
        function(list)
            if my ~= gen then
                return
            end
            local r = pick(list, dur)
            if r then
                return done(r)
            end
            http_get(
                O.api .. "/search",
                {q = (meta.artist .. " " .. meta.title)},
                function(list2)
                    done(pick(list2, dur))
                end
            )
        end
    )
end

-- ---------- geometry ----------
local function geo(W, H)
    local g = {lx = W * O.lyrics_x, lw = W * O.lyrics_w, px = W * O.panel_x, pw = W * O.panel_w}
    g.cs = O.cover and (math.floor(math.min(g.pw, H * 0.46) / 2) * 2) or 0
    g.cx = math.floor(g.px + (g.pw - g.cs) / 2)
    g.cy = math.floor(H * 0.14)
    g.vy0 = g.cy + (g.cs > 0 and (g.cs + H * 0.1) or 0)
    g.vy1 = H * 0.90
    return g
end

local function apply_margins(_)
    local W, H = osd_size()
    local l, r, t, b = 0, 0, 0, 0
    if active then
        local g = geo(W, H)
        l, r = g.px / W, (W - g.px - g.pw) / W
        t, b = g.vy0 / H, (H - g.vy1) / H
    end
    mp.set_property_number("video-margin-ratio-left", l)
    mp.set_property_number("video-margin-ratio-right", r)
    mp.set_property_number("video-margin-ratio-top", t)
    mp.set_property_number("video-margin-ratio-bottom", b)
end

local function show_vis(on)
    if on then
        mp.set_property_number("brightness", saved.brightness or 0)
    else
        mp.set_property_number("brightness", -100)
    end
end

-- ---------- cover ----------
local function video_id()
    local p = mp.get_property("path") or ""
    return p:match("[?&]v=([%w_-]+)") or p:match("youtu%.be/([%w_-]+)") or p:match("/shorts/([%w_-]+)")
end

local function cover_clear()
    cover.have = false
    mp.commandv("overlay-remove", "1")
    if cover.cur then
        os.remove(cover.cur)
        cover.cur = nil
    end
end

local function place_cover(my)
    if not cover_shown then
        return
    end
    if not (active and cover.have) then
        return
    end
    local W, H = osd_size()
    local g = geo(W, H)
    if g.cs <= 0 then
        return
    end
    local out = cpath(string.format("cover_%d_%d.bgra", my, g.cs))
    mp.command_native_async(
        {
            name = "subprocess",
            playback_only = false,
            args = {
                O.ffmpeg,
                "-y",
                "-v",
                "error",
                "-i",
                cover.file,
                "-vf",
                string.format(
                    "scale=%d:%d:force_original_aspect_ratio=decrease,pad=%d:%d:(ow-iw)/2:(oh-ih)/2,format=bgra",
                    g.cs,
                    g.cs,
                    g.cs,
                    g.cs
                ),
                "-frames:v",
                "1",
                "-f",
                "rawvideo",
                out
            }
        },
        function(ok, res)
            if my ~= gen or not active or not cover_shown then
                os.remove(out)
                return
            end
            local W2, H2 = osd_size()
            if geo(W2, H2).cs ~= g.cs then
                os.remove(out)
                return
            end
            if ok and res and res.status == 0 then
                mp.commandv(
                    "overlay-add",
                    "1",
                    tostring(g.cx),
                    tostring(g.cy),
                    out,
                    "0",
                    "bgra",
                    tostring(g.cs),
                    tostring(g.cs),
                    tostring(g.cs * 4)
                )
                if cover.cur and cover.cur ~= out then
                    os.remove(cover.cur)
                end
                cover.cur = out
            else
                mp.msg.warn("cover: ffmpeg failed (is it on PATH?)")
            end
        end
    )
end

local function extract_cover(my, src, dir, cb)
    local out = cpath("cover_src.jpg")
    os.remove(out)
    mp.command_native_async(
        {
            name = "subprocess",
            playback_only = false,
            args = {
                O.ffmpeg,
                "-y",
                "-v",
                "error",
                "-i",
                src,
                "-an",
                "-map",
                "0:v:0",
                "-frames:v",
                "1",
                "-q:v",
                "2",
                out
            }
        },
        function(ok, res)
            if my ~= gen then
                return
            end
            if ok and res and res.status == 0 and utils.file_info(out) then
                return cb(out)
            end
            if dir then
                for _, n in ipairs(
                    {
                        "cover.jpg",
                        "cover.png",
                        "folder.jpg",
                        "folder.png",
                        "front.jpg",
                        "front.png",
                        "albumart.jpg",
                        "AlbumArt.jpg"
                    }
                ) do
                    local f = utils.join_path(dir, n)
                    if utils.file_info(f) then
                        return cb(f)
                    end
                end
            end
            mp.msg.warn("cover: no embedded art found")
        end
    )
end

local function load_cover()
    cover_clear()
    if not O.cover then
        return
    end
    local my = gen
    local id = video_id()

    local function show(file)
        if my ~= gen then
            return
        end
        cover.file, cover.have = file, true
        place_cover(my)
    end

    if id then
        local jpg = cpath("cover_src.jpg")
        local function got(ok)
            if my ~= gen or not ok then
                return
            end
            show(jpg)
        end
        download(
            "https://i.ytimg.com/vi/" .. id .. "/maxresdefault.jpg",
            jpg,
            function(ok)
                if my ~= gen then
                    return
                end
                if ok then
                    return got(true)
                end
                download("https://i.ytimg.com/vi/" .. id .. "/hqdefault.jpg", jpg, got)
            end
        )
        return
    end

    local path = mp.get_property("path") or ""
    if path:match("^%a[%w+.-]*://") then
        local url =
            path:gsub("^davs://", "https://"):gsub("^dav://", "http://"):gsub("^webdavs://", "https://"):gsub(
            "^webdav://",
            "http://"
        )
        local head = cpath("cover_head.bin")
        os.remove(head)
        mp.command_native_async(
            {
                name = "subprocess",
                playback_only = false,
                args = {
                    "curl",
                    "-s",
                    "-L",
                    "--max-time",
                    "20",
                    "-r",
                    "0-12000000",
                    "-o",
                    head,
                    url
                }
            },
            function(ok, res)
                if my ~= gen then
                    return
                end
                if not (ok and res and res.status == 0 and utils.file_info(head)) then
                    mp.msg.warn("cover: curl failed for " .. url)
                    return
                end
                extract_cover(my, head, nil, show)
            end
        )
        return
    end

    extract_cover(my, path, (utils.split_path(path)), show)
end

-- ---------- layout / rendering ----------
local function wrap(text, maxchars)
    if text == "" then
        return {"♪"}
    end
    local lines, cur = {}, ""
    for word in text:gmatch("%S+") do
        if cur == "" then
            cur = word
        elseif ulen(cur) + 1 + ulen(word) <= maxchars then
            cur = cur .. " " .. word
        else
            lines[#lines + 1] = cur
            cur = word
        end
    end
    if cur ~= "" then
        lines[#lines + 1] = cur
    end
    return lines
end

local function esc(s)
    return (s:gsub("\\", "\\\\"):gsub("{", "\\{"):gsub("}", "\\}"))
end

local function build_layout(W, H, g)
    local S = H / 720
    local fs = 34 * S
    local lh, gap = fs * 1.2, fs * 0.8
    local maxchars = math.max(8, math.floor(g.lw / (fs * O.char_w)))
    local L = {W = W, H = H, fs = fs, gap = gap, entries = {}, center = {}, h = {}}
    local y = 0
    for i, it in ipairs(lyrics) do
        local ls = wrap(it.text, maxchars)
        local h = #ls * lh
        for j = 1, #ls do
            ls[j] = esc(ls[j])
        end
        L.entries[i], L.h[i], L.center[i] = table.concat(ls, "\\N"), h, y + h / 2
        y = y + h + gap
    end
    return L
end

local function active_index(t)
    local lo, hi, idx = 1, #lyrics, 0
    while lo <= hi do
        local mid = math.floor((lo + hi) / 2)
        if lyrics[mid].t <= t then
            idx = mid
            lo = mid + 1
        else
            hi = mid - 1
        end
    end
    return idx
end

local function mouse()
    local m = mp.get_property_native("mouse-pos")
    if m and m.hover then
        return m.x, m.y
    end
end

local function render()
    local W, H = osd_size()
    ov.res_x, ov.res_y = W, H
    local S = H / 720
    local g = geo(W, H)
    geo_cache = g
    local font = O.font ~= "" and ("\\fn" .. O.font) or ""
    local out = {}
    hits = {}

    out[#out + 1] =
        string.format(
        "{\\an7\\pos(%.1f,%.1f)%s\\fs%.0f\\b1\\1c&HFFFFFF&\\bord0\\shad0}%s",
        g.lx,
        H * 0.06,
        font,
        26 * S,
        esc(meta.title)
    )
    out[#out + 1] =
        string.format(
        "{\\an7\\pos(%.1f,%.1f)%s\\fs%.0f\\1c&HB0B0B0&\\bord0\\shad0}%s",
        g.lx,
        H * 0.06 + 32 * S,
        font,
        20 * S,
        esc(meta.artist)
    )

    if not lyrics then
        out[#out + 1] =
            string.format(
            "{\\an4\\pos(%.1f,%.1f)%s\\fs%.0f\\1c&HA0A0A0&\\bord0\\shad0}%s",
            g.lx,
            H / 2,
            font,
            28 * S,
            esc(status)
        )
        ov.data = table.concat(out, "\n")
        ov:update()
        return
    end

    if not layout or layout.W ~= W or layout.H ~= H then
        layout = build_layout(W, H, g)
    end
    local n = #lyrics
    local now = mp.get_time()
    local t = (mp.get_property_number("time-pos") or 0) + offset + 0.05
    local playing = clamp(active_index(t), 1, n)
    local target = (now < browse_until) and clamp(browse_idx, 1, n) or playing

    local dt = math.min(now - (last_tick or now), 0.1)
    last_tick = now
    if math.abs(target - scroll) > 8 then
        scroll = target
    else
        scroll = scroll + (target - scroll) * (1 - math.exp(-dt * 9))
    end
    if math.abs(playing - hl) > 8 then
        hl = playing
    else
        hl = hl + (playing - hl) * (1 - math.exp(-dt * 12))
    end

    local i0 = clamp(math.floor(scroll), 1, n)
    local i1 = clamp(i0 + 1, 1, n)
    local fr = scroll - math.floor(scroll)
    local c = layout.center[i0] + (layout.center[i1] - layout.center[i0]) * fr
    local anchor = H * 0.45
    local mx, my = mouse()
    local cl = string.format("\\clip(0,%.0f,%.0f,%.0f)", H * 0.17, g.lx + g.lw + W * 0.03, H * 0.97)

    for k = 1, n do
        local y = anchor + layout.center[k] - c
        if y > -layout.fs * 4 and y < H + layout.fs * 4 then
            local y0, y1 = y - layout.h[k] / 2 - layout.gap / 2, y + layout.h[k] / 2 + layout.gap / 2
            hits[#hits + 1] = {k = k, y0 = y0, y1 = y1}
            local dc = math.abs(k - scroll)
            local fh = clamp(1 - math.abs(k - hl), 0, 1)
            local sc = 82 + 18 * fh
            local alpha = (1 - fh) * 0x70 + clamp(dc - 1, 0, 3) * 0x28
            local blur = clamp((dc - 1) * 0.7, 0, 3)
            local color = (fh > 0.5) and "FFFFFF" or "D8D8D8"
            if mx and mx >= g.lx and mx <= g.lx + g.lw and my >= y0 and my <= y1 then
                alpha = math.min(alpha, 0x38)
                sc = math.max(sc, 92)
                blur = 0
            end
            alpha = clamp(alpha, 0, 0xE0)
            out[#out + 1] =
                string.format(
                "{\\an4\\pos(%.1f,%.1f)%s\\fs%.0f\\b1\\fscx%.0f\\fscy%.0f\\alpha&H%02X&"..
                "\\1c&H%s&\\bord0\\shad0\\blur%.1f%s}%s",
                g.lx,
                y,
                font,
                layout.fs,
                sc,
                sc,
                math.floor(alpha),
                color,
                blur,
                cl,
                layout.entries[k]
            )
        end
    end
    ov.data = table.concat(out, "\n")
    ov:update()
end

-- ---------- mouse ----------
local function in_column(x)
    return geo_cache and x and x >= geo_cache.lx and x <= geo_cache.lx + geo_cache.lw
end

local function on_click()
    if not (active and lyrics) then
        return
    end
    local x, y = mouse()
    mp.msg.info(string.format("click x=%s y=%s", tostring(x), tostring(y)))
    if not in_column(x) then
        return
    end
    for _, h in ipairs(hits) do
        if y >= h.y0 and y <= h.y1 then
            mp.commandv("seek", tostring(math.max(0, lyrics[h.k].t - offset)), "absolute+exact")
            browse_until = 0
            return
        end
    end
end

local function wheel(dir)
    return function()
        local x = mouse()
        if lyrics and in_column(x) then
            local now = mp.get_time()
            if now >= browse_until then
                browse_idx = clamp(active_index((mp.get_property_number("time-pos") or 0) + offset + 0.05), 1, #lyrics)
            end
            browse_idx = clamp(browse_idx + dir, 1, #lyrics)
            browse_until = now + 3
        else
            mp.commandv("add", "volume", tostring(-dir * 2))
        end
    end
end

-- ---------- visualizer ----------
local function apply_vis()
    if active and O.visualizer then
        mp.set_property("lavfi-complex", O.vis_graph)
        apply_margins(true)
    else
        mp.set_property("lavfi-complex", saved.lavfi or "")
        apply_margins(false)
    end
end

-- ---------- mode switching ----------
local function reload_current()
    local pos = mp.get_property_number("time-pos")
    local pl = mp.get_property_number("playlist-pos")
    local path = mp.get_property("path")
    if pl and pl >= 0 and path and path:match("^%a[%w+.-]*://") then
        pending_seek = pos
        mp.commandv("playlist-play-index", tostring(pl))
        return true
    end
    return false
end

local function refresh_track()
    load_lyrics()
    load_cover()
end

local saved_fit = {}
local fit_keys = {"autofit", "autofit-larger", "autofit-smaller"}

local function fit_window(restore)
    if not O.resize_window then
        return
    end
    if restore then
        for _, k in ipairs(fit_keys) do
            if saved_fit[k] ~= nil then
                mp.set_property(k, saved_fit[k])
            end
        end
        saved_fit = {}
        return
    end
    if mp.get_property_bool("fullscreen") or mp.get_property_bool("window-maximized") then
        return
    end
    local size = O.win_w .. "x" .. O.win_h
    for _, k in ipairs(fit_keys) do
        saved_fit[k] = mp.get_property(k)
        mp.set_property(k, size)
    end
    local dw = mp.get_property_number("video-out-params/dw") or 640
    local dh = mp.get_property_number("video-out-params/dh") or 360
    if dw > 0 and dh > 0 then
        mp.set_property_number("window-scale", math.min(O.win_w / dw, O.win_h / dh))
    end
end

local function set_mode(on)
    if on == active then
        return
    end
    active = on
    if on then
        ensure_dir()
        saved.fmt = mp.get_property("ytdl-format")
        saved.vid = mp.get_property("vid")
        saved.fw = mp.get_property("force-window")
        saved.lavfi = mp.get_property("lavfi-complex")
        mp.set_property("ytdl-format", O.audio_format)
        mp.set_property("force-window", "yes")
        mp.set_property("lavfi-complex", O.vis_graph)
        apply_margins(O.visualizer)
        mp.add_timeout(0.8, fit_window)
        saved.brightness = mp.get_property_number("brightness")
        show_vis(O.visualizer)
        timer = timer or mp.add_periodic_timer(1 / O.fps, render)
        timer:resume()
        if mp.get_property_number("playlist-pos", -1) >= 0 then
            if not reload_current() then
                refresh_track()
            end
        else
            status, lyrics = "Nothing playing", nil
        end
        mp.osd_message("Music mode: ON")
    else
        if timer then
            timer:kill()
        end
        mp.remove_key_binding("lyric-click")
        mp.remove_key_binding("lyric-wheel-up")
        mp.remove_key_binding("lyric-wheel-down")
        ov:remove()
        cover_clear()
        lyrics, layout = nil, nil
        apply_vis()
        mp.set_property("ytdl-format", saved.fmt or "")
        mp.set_property("vid", (saved.vid and saved.vid ~= "no") and saved.vid or "auto")
        mp.set_property("force-window", saved.fw or "auto")
        reload_current()
        mp.osd_message("Music mode: OFF")
    end
    mp.commandv("script-message", "music-mode-changed", on and "yes" or "no")
    mp.set_property_native("user-data/music_mode/active", on)
end

mp.register_event(
    "file-loaded",
    function()
        if active then
            apply_margins(true)
            show_vis(O.visualizer)
        end
        if pending_seek and pending_seek > 1 then
            mp.commandv("seek", tostring(pending_seek), "absolute+exact")
        end
        pending_seek = nil
        if active then
            refresh_track()
        end
    end
)

mp.register_event(
    "end-file",
    function()
        if active then
            gen = gen + 1
        end
    end
)

mp.observe_property(
    "osd-dimensions",
    "native",
    function()
        if not active then
            return
        end
        local W, H = osd_size()
        if W == last_w and H == last_h then
            return
        end
        last_w, last_h = W, H
        if O.visualizer then
            apply_margins(true)
        end
        if resize_timer then
            resize_timer:kill()
        end
        resize_timer =
            mp.add_timeout(
            0.4,
            function()
                place_cover(gen)
            end
        )
    end
)
O.bottom_reserve = 130 -- OSC bar height; clicks below this pass through

local function in_zone(x, y)
    if not (x and y and in_column(x)) then
        return false
    end
    local _, H = osd_size()
    if y < H * 0.17 or y > H - O.bottom_reserve then
        return false
    end
    if mp.get_property_bool("user-data/cadre_menu/visible", false) then
        return false
    end
    local osc = mp.get_property_native("user-data/cadre_osc/rect")
    if type(osc) == "table" and osc.visible
        and x >= osc.x1 and x <= osc.x2 and y >= osc.y1 and y <= osc.y2 then
        return false
    end
    if mp.get_property_native("user-data/cadre_playlist/visible") then
        local x1 = mp.get_property_number("user-data/cadre_playlist/x1", 1e9)
        local y1 = mp.get_property_number("user-data/cadre_playlist/y1", 0)
        local y2 = mp.get_property_number("user-data/cadre_playlist/y2", 0)
        if x >= x1 and y >= y1 and y <= y2 then
            return false
        end
    end
    local p = mp.get_property_native("user-data/cadre_osc/popup")
    if type(p) == "table" and p.visible and x >= p.x1 and x <= p.x2 and y >= p.y1 and y <= p.y2 then
        return false
    end
    return true
end

local bound = false
local function bind_lyrics(on)
    if on == bound then
        return
    end
    bound = on
    if on then
        mp.add_forced_key_binding("MBTN_LEFT", "lyric-click", on_click)
        mp.add_forced_key_binding("WHEEL_UP", "lyric-wheel-up", wheel(-1))
        mp.add_forced_key_binding("WHEEL_DOWN", "lyric-wheel-down", wheel(1))
    else
        mp.remove_key_binding("lyric-click")
        mp.remove_key_binding("lyric-wheel-up")
        mp.remove_key_binding("lyric-wheel-down")
    end
end

mp.observe_property(
    "mouse-pos",
    "native",
    function(_, m)
        if not active then
            return
        end
        bind_lyrics(m and m.hover and in_zone(m.x, m.y) or false)
    end
)

local function refresh_lyrics_hit_zone()
    if not active then return end
    local m = mp.get_property_native("mouse-pos")
    bind_lyrics(m and m.hover and in_zone(m.x, m.y) or false)
end
for _, property in ipairs({
    "user-data/cadre_menu/visible", "user-data/cadre_osc/rect",
    "user-data/cadre_osc/popup", "user-data/cadre_playlist/visible"
}) do
    mp.observe_property(property, "native", refresh_lyrics_hit_zone)
end

local function update_cover()
    if not active then
        return
    end
    local pl = mp.get_property_native("user-data/cadre_playlist/visible") and true or false
    local hide = pl or mp.get_property_bool("user-data/cadre_menu/visible", false)
    local p = mp.get_property_native("user-data/cadre_osc/popup")
    local g = geo_cache
    if
        type(p) == "table" and p.visible and g and g.cs > 0 and
            not (p.x2 < g.cx or p.x1 > g.cx + g.cs or p.y2 < g.cy or p.y1 > g.cy + g.cs)
     then
        hide = true
    end
    if hide and cover_shown then
        mp.commandv("overlay-remove", "1")
        cover_shown = false
    elseif not hide and not cover_shown then
        cover_shown = true
        place_cover(gen)
    end
    show_vis(O.visualizer and not pl)
end

mp.observe_property("user-data/cadre_playlist/visible", "native", update_cover)
mp.observe_property("user-data/cadre_menu/visible", "bool", update_cover)
mp.observe_property("user-data/cadre_osc/popup", "native", update_cover)
local function toggle()
    set_mode(not active)
end
mp.add_key_binding(O.key, "music-mode", toggle)
mp.add_key_binding(
    O.key_vis,
    "music-visualizer",
    function()
        O.visualizer = not O.visualizer
        if active then
            show_vis(O.visualizer)
        end
        mp.osd_message("Visualizer: " .. (O.visualizer and "ON" or "OFF"))
    end
)
mp.add_key_binding(
    O.key_later,
    "lyrics-later",
    function()
        offset = offset - 0.5
        mp.osd_message(string.format("Lyrics offset: %+.1fs", -offset))
    end
)
mp.add_key_binding(
    O.key_earlier,
    "lyrics-earlier",
    function()
        offset = offset + 0.5
        mp.osd_message(string.format("Lyrics offset: %+.1fs", -offset))
    end
)
mp.register_script_message("music-mode-toggle", toggle)
