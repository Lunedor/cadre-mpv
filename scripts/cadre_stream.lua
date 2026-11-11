-- cadre_stream.lua

local mp = require("mp")
local msg = require("mp.msg")
local utils = require("mp.utils")

local script_path      = mp.command_native({"expand-path", "~~/scripts/cadre/tools/cadre_stream.py"})
local state_file_path  = mp.command_native({"expand-path", "~~/scripts/cadre/data/cadre_stream_state.json"})
local common = dofile(mp.command_native({"expand-path", "~~/scripts/cadre/scripts/cadre_common.lua"}))

local d = common.load_conf()
local conf = d and d.stream or {}
local function announce(url)
    if url then mp.commandv("script-message", "cadre-source", url) end
end
local PYTHON = conf.python_path
if type(PYTHON) ~= "string" or PYTHON == "" then PYTHON = "python" end

-- State tracking
local current_media = nil
local last_time_pos = 0
local last_duration = 0
local pending_start_time = 0

-- Auto-play & UI State
local next_fetched = false
local next_payload = nil
local show_next_ui = false
local mouse_hovering = false

-- Layout dimensions are based on mpv's current OSD size to preserve the card's aspect ratio.
local next_overlay = mp.create_osd_overlay("ass-events")
-- WebDAV uses bitmap ids 0–59, id 60 for its next-up card, and id 63 for posters.
local next_image_id = 61
local next_timer_id = 62
local base_image_w, base_image_h = 150, 84
local next_image_w, next_image_h, next_image_path
local next_image_ready = false
local next_image_key = nil
local prepare_next_image
local next_timer_rendering = false
local next_timer_request, next_timer_ready_key, next_timer_failed_key
local next_timer_shown_key

-- Button geometry is configured at 1080p and uniformly scaled to fit the OSD.
local btn_w = tonumber(conf.next_btn_w) or 460
local btn_h = tonumber(conf.next_btn_h) or 128
local margin_x = tonumber(conf.next_btn_margin_x) or 60
local margin_bottom = tonumber(conf.next_btn_margin_bottom) or 250
local align = tostring(conf.next_btn_align or "center"):lower()

local function card_layout()
    local w, h = mp.get_osd_size()
    w, h = tonumber(w) or 1920, tonumber(h) or 1080
    if w < 1 or h < 1 then w, h = 1920, 1080 end
    local scale = math.min(w / 1920, h / 1080)
    local cw, ch = btn_w * scale, btn_h * scale
    local mx, mb = margin_x * scale, margin_bottom * scale
    local x = align == "left" and mx or (align == "right" and w - mx - cw or (w - cw) / 2)
    local y = h - mb - ch
    return { x = x, y = y, w = cw, h = ch, scale = scale, osd_w = w, osd_h = h }
end

local function apply_pending_start_time()
    if pending_start_time > 0 then
        mp.commandv("seek", pending_start_time, "absolute")
        pending_start_time = 0
    end
end

-- Saves tracking data back to JSON without duplicates
local function save_progress()
    if not current_media or last_duration == 0 then return end

    local f = io.open(state_file_path, "r")
    local state = {["continue"] = {}, watchlater = {}}
    if f then
        local content = f:read("*a")
        f:close()
        if content and content ~= "" then
            state = utils.parse_json(content) or state
        end
    end

    current_media.time_pos = last_time_pos
    current_media.duration = last_duration

    local new_continue = {}
    for _, item in ipairs(state["continue"] or {}) do
        local is_match = (tostring(item.type):lower() == tostring(current_media.type):lower() and
        tostring(item.tmdb_id) == tostring(current_media.tmdb_id))
        if not is_match then
            table.insert(new_continue, item)
        end
    end

    table.insert(new_continue, 1, current_media)
    while #new_continue > 50 do table.remove(new_continue) end

    state["continue"] = new_continue

    local temp_file_path = state_file_path .. ".tmp"
    local out_f = io.open(temp_file_path, "w")
    if out_f then
        out_f:write(utils.format_json(state))
        out_f:close()
        os.remove(state_file_path)
        os.rename(temp_file_path, state_file_path)
    end

    current_media = nil
    last_time_pos = 0
    last_duration = 0
end

local function draw_next_ui()
    if not show_next_ui or not next_payload then
        next_overlay:remove()
        pcall(mp.commandv, "overlay-remove", tostring(next_image_id))
        pcall(mp.commandv, "overlay-remove", tostring(next_timer_id))
        next_timer_shown_key = nil
        return
    end

    local g = card_layout()
    local s = g.scale
    local wanted_w = math.max(1, math.floor(base_image_w * s + 0.5))
    local wanted_h = math.max(1, math.floor(base_image_h * s + 0.5))
    if prepare_next_image and (next_image_w ~= wanted_w or next_image_h ~= wanted_h) then
        prepare_next_image(next_payload, s)
    end
    next_overlay.res_x, next_overlay.res_y = g.osd_w, g.osd_h
    local progress = 0
    if last_duration > 0 then progress = last_time_pos / last_duration end
    local ratio = math.max(0, math.min(1, (progress - 0.95) / 0.05))
    local bg_color = mouse_hovering and "&H30283A&" or "&H18121F&"
    local card_w, card_h = math.floor(g.w + 0.5), math.floor(g.h + 0.5)
    local card_x, card_y = math.floor(g.x + 0.5), math.floor(g.y + 0.5)
    local radius = math.max(4, math.floor(12 * s + 0.5))
    local curve = radius * 0.5522847
    local rounded = string.format(
        "m %d %d l %d %d b %d %d %d %d %d %d l %d %d b %d %d %d %d %d %d l %d %d b %d %d %d %d %d %d l %d %d b %d %d %d %d %d %d",
        radius, 0, card_w-radius, 0, card_w-radius+curve, 0, card_w, radius-curve, card_w, radius,
        card_w, card_h-radius, card_w, card_h-radius+curve, card_w-radius+curve, card_h, card_w-radius, card_h,
        radius, card_h, radius-curve, card_h, 0, card_h-radius+curve, 0, card_h-radius,
        0, radius, 0, radius-curve, radius-curve, 0, radius, 0)
    local bg = string.format([[{\an7\pos(%d,%d)\1c%s\1a&H18&\bord1\3c&H6A526F&\3a&H30&\p1}%s{\p0}]],
        card_x, card_y, bg_color, rounded)
    local text_str = string.format("S%02d E%02d", next_payload.season, next_payload.episode)
    local tx = math.floor(g.x + (base_image_w + 30) * s + 0.5)
    local ty = math.floor(g.y + 14 * s + 0.5)
    local fs = math.max(14, math.floor(21 * s))
    local function text_line(y, tags, str)
        return string.format("{\\an7\\pos(%d,%d)\\fs18\\bord0\\shad0%s}%s", tx, math.floor(y + 0.5), tags, str)
    end
    local label = text_line(ty, string.format("\\b1\\fs%d\\c&HB88FFF&", fs + 3), "Next episode in")
    local season_line_y = ty + fs * 1.55
    local season_line = text_line(season_line_y, string.format("\\b1\\fs%d\\c&HFFFFFF&", fs), text_str)
    local episode_name = tostring(next_payload.episode_name or "")
    if #episode_name > 34 then episode_name = episode_name:sub(1, 31) .. "..." end
    local name_line = text_line(season_line_y + fs * 1.35,
        string.format("\\fs%d\\c&HB2A8C6&", math.max(14, fs - 4)), episode_name)
    local remaining = tostring(math.max(0, math.ceil(last_duration - last_time_pos)))
    local timer_fs = math.max(12, math.floor(17 * s))
    local ring_radius = math.max(10, math.floor(22 * s + 0.5))
    local timer_w = ring_radius * 2 + 8
    local timer_h = timer_w
    local filled = math.floor(ratio * 48 + 0.5)
    local timer_path = mp.command_native({"expand-path", "~~/scripts/cadre/data/cadre_stream_timer.bgra"})
    local timer_key = table.concat({timer_w, timer_h, remaining, filled, timer_fs}, ":")
    if next_timer_request ~= timer_key then
        next_timer_request = timer_key
        next_timer_ready_key = nil
        next_timer_failed_key = nil
    end
    local timer_cx = math.floor(g.x + g.w - 48 * s + 0.5)
    local timer_cy = math.floor(g.y + g.h / 2 + 0.5)
    if next_timer_ready_key == timer_key and timer_path then
        local timer_x = math.floor(timer_cx - timer_w / 2 + 0.5)
        local timer_y = math.floor(timer_cy - timer_h / 2 + 0.5)
        local shown_key = timer_key .. ":" .. timer_x .. ":" .. timer_y
        if next_timer_shown_key ~= shown_key then
            local ok, added = pcall(mp.commandv, "overlay-add", tostring(next_timer_id), tostring(timer_x), tostring(timer_y),
                timer_path, "0", "bgra", tostring(timer_w), tostring(timer_h), tostring(timer_w * 4))
            if ok and added ~= false then next_timer_shown_key = shown_key end
        end
    elseif not next_timer_rendering and next_timer_failed_key ~= timer_key and timer_path then
        local render_key = timer_key
        local render_remaining = remaining
        local render_filled = filled
        local render_fs = timer_fs
        next_timer_rendering = true
        mp.command_native_async({
            name = "subprocess",
            args = { PYTHON, script_path, "--render-next-timer", timer_path, tostring(timer_w), tostring(timer_h),
                render_remaining, tostring(render_filled), tostring(render_fs) },
            capture_stdout = true, capture_stderr = true, playback_only = false,
        }, function(success, result)
            next_timer_rendering = false
            local info = utils.file_info(timer_path)
            if success and result and result.status == 0 and info and info.size == timer_w * timer_h * 4 then
                if next_timer_request == render_key then next_timer_ready_key = render_key end
            else
                next_timer_failed_key = render_key
                local detail = result and (result.stderr or result.error_string) or "timer renderer failed"
                msg.warn("Cadre Stream: next episode timer couldn't be rendered: " .. tostring(detail))
            end
            if show_next_ui then draw_next_ui() end
        end)
    end
    next_overlay.data = bg .. "\n" .. label .. "\n" .. season_line .. "\n" .. name_line
    next_overlay:update()
    if next_image_ready and next_image_path then
        local image_x = math.floor(g.x + 14 * s + 0.5)
        local image_y = math.floor(g.y + (g.h - next_image_h) / 2 + 0.5)
        local ok, added = pcall(mp.commandv, "overlay-add", tostring(next_image_id), tostring(image_x), tostring(image_y),
            next_image_path, "0", "bgra", tostring(next_image_w), tostring(next_image_h), tostring(next_image_w * 4))
        if not ok or added == false then msg.warn("Cadre Stream: mpv couldn't display the next episode still") end
    end
end

prepare_next_image = function(payload, scale)
    if not payload then return end
    local still = payload.still_path or payload.poster_path
    if not still or still == "" then return end
    scale = scale or card_layout().scale
    next_image_w = math.max(1, math.floor(base_image_w * scale + 0.5))
    next_image_h = math.max(1, math.floor(base_image_h * scale + 0.5))
    local key = tostring(payload.url) .. ":" .. next_image_w .. "x" .. next_image_h
    if next_image_key == key then return end
    next_image_key = key
    next_image_ready = false
    pcall(mp.commandv, "overlay-remove", tostring(next_image_id))
    next_image_path = mp.command_native({"expand-path", string.format("~~/scripts/cadre/data/cadre_stream_next_%dx%d.bgra", next_image_w, next_image_h)})
    if not next_image_path then return end
    local image_path, image_w, image_h = next_image_path, next_image_w, next_image_h
    local image_url = "https://image.tmdb.org/t/p/w500" .. still
    mp.command_native_async({
        name = "subprocess", args = { PYTHON, script_path, "--render-next-image", image_url, image_path,
            tostring(image_w), tostring(image_h) },
        capture_stdout = true, capture_stderr = true, playback_only = false,
    }, function(success, result)
        local info = utils.file_info(image_path)
        if next_payload ~= payload or next_image_key ~= key then return end
        if success and result and result.status == 0 and info and info.size == image_w * image_h * 4 then
            next_image_ready = true
            if show_next_ui then draw_next_ui() end
        else
            local detail = result and (result.stderr or result.error_string) or "image helper failed"
            msg.warn("Cadre Stream: next episode image wasn't created: " .. tostring(detail))
        end
    end)
end

-- Tracks mouse and binds click only while hovering over the next episode card.
local function check_mouse_hover()
    if not show_next_ui then
        if mouse_hovering then
            pcall(function() mp.remove_key_binding("next-ui-click") end)
            mouse_hovering = false
        end
        return
    end

    local mx = mp.get_property_number("mouse-pos/x")
    local my = mp.get_property_number("mouse-pos/y")
    local ww = mp.get_property_number("osd-width")
    local wh = mp.get_property_number("osd-height")

    if not mx or not my or not ww or not wh then return end

    local g = card_layout()
    local in_box = mx >= g.x and mx <= g.x + g.w and my >= g.y and my <= g.y + g.h

    if in_box and not mouse_hovering then
        mouse_hovering = true
        mp.add_forced_key_binding("MBTN_LEFT", "next-ui-click", function()
            last_time_pos = last_duration -- Force 100% completion on click
            save_progress()
            mp.commandv("playlist-next")
        end)
        draw_next_ui()
    elseif not in_box and mouse_hovering then
        mouse_hovering = false
        pcall(function() mp.remove_key_binding("next-ui-click") end)
        draw_next_ui()
    end
end

mp.observe_property("mouse-pos/x", "number", check_mouse_hover)
mp.observe_property("mouse-pos/y", "number", check_mouse_hover)

local function fetch_next_episode_async()
    msg.info("Fetching next episode in background...")
    mp.command_native_async({
        name = "subprocess",
        args = {
            PYTHON,
            script_path,
            "--fetch-next",
            tostring(current_media.tmdb_id),
            tostring(current_media.season),
            tostring(current_media.episode)
        },
        capture_stdout = true,
        capture_stderr = true
    }, function(success, res)
        if success and res.status == 0 then
            local out = res.stdout or ""
            local payload_str = out:match("NEXT_PLAY_DATA:(.+)")
            if payload_str and payload_str ~= "NONE" then
                next_payload = utils.parse_json(payload_str)
                if next_payload and next_payload.url then
                    prepare_next_image(next_payload)
                    -- Crucial: Appending places it natively in mpv's queue.
                    announce(next_payload.url)
					mp.commandv("loadfile", next_payload.url, "append")
                    local progress = last_duration > 0 and (last_time_pos / last_duration) or 0
                    show_next_ui = progress >= 0.95 and progress < 1
                    draw_next_ui()
                end
            end
        end
    end)
end

local function trigger_playlist_next()
    if next_payload then
        last_time_pos = last_duration
        save_progress()
    end
    mp.commandv("playlist-next")
end

mp.add_forced_key_binding("shift+n", "play-next-now", trigger_playlist_next)

mp.observe_property("time-pos", "number", function(_, val)
    if val then
        last_time_pos = val
        if current_media and current_media.type == "tv" and last_duration > 0 then
            local progress = last_time_pos / last_duration
            if progress >= 0.95 and not next_fetched then
                next_fetched = true
                fetch_next_episode_async()
            end
            if next_payload then
                local should_show = progress >= 0.95 and progress < 1
                if show_next_ui ~= should_show then
                    show_next_ui = should_show
                    draw_next_ui()
                end
            end
        end
        if show_next_ui then draw_next_ui() end
    end
end)

mp.observe_property("duration", "number", function(_, val)
    if val then last_duration = val end
end)

mp.register_event("file-loaded", function()
    apply_pending_start_time()

    local path = mp.get_property("path")
    -- If mpv naturally loaded the appended playlist item, promote it to current
    if next_payload and path == next_payload.url then
        current_media = next_payload
        next_payload = nil
        next_fetched = false -- The missing reset
        show_next_ui = false
        mouse_hovering = false
        pcall(function() mp.remove_key_binding("next-ui-click") end)
        draw_next_ui()
        pending_start_time = 0
    end
end)

mp.register_event("end-file", function(event)
    save_progress()
    -- If user manually stops playback or quits, kill the next-episode UI
    if event.reason == "stop" or event.reason == "quit" or event.reason == "error" then
        show_next_ui = false
        mouse_hovering = false
        pcall(function() mp.remove_key_binding("next-ui-click") end)
        draw_next_ui()
    end
end)

local function open_popup()
    local res = mp.command_native({
        name = "subprocess",
        args = {
            PYTHON,
            script_path
        },
        playback_only = false,
        capture_stdout = true,
        capture_stderr = true
    })

    if not res or res.status ~= 0 then return end

    local out = res.stdout or ""
    local payload_str = out:match("PLAY_DATA:(.+)")

    if payload_str then
        local payload = utils.parse_json(payload_str)
        if payload and payload.url then
            next_fetched = false
            show_next_ui = false
            next_payload = nil
            mouse_hovering = false
            pcall(function() mp.remove_key_binding("next-ui-click") end)
            draw_next_ui()

            last_time_pos = 0
            last_duration = 0
            current_media = payload
            pending_start_time = tonumber(payload.start_time) or 0

            mp.commandv("playlist-clear") -- Purge old appends
			announce(payload.url)
            mp.commandv("loadfile", payload.url, "replace")
        end
    end
end

common.bind("stream", "ctrl+s", "cadre-stream-popup", open_popup)
mp.register_script_message("cadre-stream-open", function() open_popup() end)
