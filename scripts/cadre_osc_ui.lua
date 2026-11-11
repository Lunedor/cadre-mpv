--[[
cadre_osc_ui.lua (flyouts, rendering, and interaction)
]]
--------------------------------------------------------------------------------
-- VOLUME FLYOUT
--------------------------------------------------------------------------------
msg.info("cadre_osc_ui: LIVECAP UI VERSION 3 LOADED")

function popup_card_position(button, card_w, card_h, gap)
    gap = gap or 10
    local above_space = button.y - button.height / 2 - gap
    local below_space = screen_h - button.y - button.height / 2 - gap
    local card_y1
    if above_space >= card_h then
        card_y1 = button.y - button.height / 2 - gap - card_h
    elseif below_space >= card_h then
        card_y1 = button.y + button.height / 2 + gap
    elseif above_space >= below_space then
        card_y1 = button.y - button.height / 2 - gap - card_h
    else
        card_y1 = button.y + button.height / 2 + gap
    end
    card_y1 = math.max(0, math.min(math.max(0, screen_h - card_h), card_y1))

    local card_x1 = math.max(0, math.min(math.max(0, screen_w - card_w), button.x - card_w / 2))
    return card_x1, card_y1
end

function osc_panel_top_y()
    if cfg.BAR_Y_ANCHOR == "top" then
        return cfg.BAR_TOP_INSET
    elseif cfg.BAR_Y_ANCHOR == "center" then
        return (screen_h - cfg.BAR_HEIGHT) / 2
    end
    return screen_h - cfg.BAR_BOTTOM_INSET - cfg.BAR_HEIGHT
end

local function send_livecap_command(action)
    if not mp.get_property_native(
        "user-data/cadre_livecap/loaded",
        false
    ) then
        mp.osd_message(
            "Live Captions script is not loaded",
            2
        )
        return
    end

    mp.set_property(
        "user-data/livecap/command",
        utils.format_json({
            action = action,
        })
    )
end

function compute_popup_geo(button)
    local card_w, card_h = 44, 158
    local card_x1 = math.max(0, math.min(screen_w - card_w, button.x - card_w / 2))
    local card_y1
    if button.anchor_space ~= "window" and cfg.BAR_Y_ANCHOR == "bottom" then
        card_y1 = osc_panel_top_y() - card_h - 10
    else
        local _, anchored_y = popup_card_position(button, card_w, card_h, 10)
        card_y1 = anchored_y
    end

    -- Negative moves up; positive moves down.
    card_y1 = card_y1 + (cfg.VOLUME_POPUP_OFFSET_Y or 0)
    card_y1 = math.max(0, math.min(math.max(0, screen_h - card_h), card_y1))

    local cx = button.x
    local card_x2, card_y2 = card_x1 + card_w, card_y1 + card_h
    local track_y1, track_y2 = card_y1 + 18, card_y2 - 54
    local mute_y = card_y2 - 18

    return {
        cx = cx,
        card_x1 = card_x1,
        card_x2 = card_x2,
        card_y1 = card_y1,
        card_y2 = card_y2,
        track_y1 = track_y1,
        track_y2 = track_y2,
        mute_y = mute_y
    }
end

local function get_livecap_status_info()
    local raw = mp.get_property("user-data/livecap/status", "")

    if not raw or raw == "" then
        return "disabled", cfg.ICON_DIM_A
    end

    local status = utils.parse_json(raw)

    if type(status) ~= "table" or not status.message then
        return "disabled", cfg.ICON_DIM_A
    end

    local message = string.lower(status.message)

    if
        message:find("loading")
        or message:find("preparing")
        or message:find("transcribing")
        or message:find("translating")
        or message:find("creating")
    then
        return "busy", common.bgr("FFD54A")
    end

    if message:find("ready") then
        return "ready", cfg.TRACK_FG
    end

    if
        message:find("paused")
        or message:find("disabled")
    then
        return "paused", cfg.ICON_DIM_A
    end

    return "idle", cfg.ICON_DIM_A
end

local function livecap_ui_state()
    local loaded = mp.get_property_native(
        "user-data/cadre_livecap/loaded",
        false
    )
    local enabled = mp.get_property_native(
        "user-data/cadre_livecap/enabled",
        false
    )
    local path = mp.get_property_native("path", nil)
    local has_media = path ~= nil and path ~= ""
    local job = mp.get_property_native("user-data/livecap/job", nil)
    if type(job) ~= "table" then
        job = utils.parse_json(
            mp.get_property("user-data/livecap/job", "")
        )
    end
    local job_running = type(job) == "table" and job.running == true

    local status_raw = mp.get_property("user-data/livecap/status", "")
    local status = utils.parse_json(status_raw)
    local status_message = type(status) == "table"
        and status.message or ""
    if type(status) == "table" and status.job_running ~= nil then
        job_running = status.job_running == true
    end
    local job_progress = type(status) == "table"
        and tonumber(status.progress) or nil
    local active_model = type(status) == "table"
        and status.active_model or nil
    active_model = active_model
        or mp.get_property("user-data/livecap/active-model", nil)

    return {
        loaded = loaded,
        enabled = enabled,
        has_media = has_media,
        job = type(job) == "table" and job or nil,
        status_message = status_message,
        job_running = job_running,
        job_progress = job_progress,
        active_model = active_model,
        busy = job_running,
        show_header = loaded,
        show_actions = loaded and (enabled or job_running),
        show_settings_tab = loaded and enabled,
    }
end

local function livecap_action_area_height()
    local ui = livecap_ui_state()

    if not ui.show_actions then
        return 0
    end

    return 28 + 30 + 30 + 14
end

local function has_text_subtitle_track()
    local text_codecs = {
        ass = true,
        mov_text = true,
        ssa = true,
        srt = true,
        subrip = true,
        text = true,
        vtt = true,
        webvtt = true,
    }

    for _, track in ipairs(mp.get_property_native("track-list", {}) or {}) do
        if track.type == "sub"
            and text_codecs[string.lower(track.codec or "")] then
            return true
        end
    end

    return false
end


function compute_track_popup_geo(button, rowcount)
    local row_h = 34
    local visible_rows = math.max(1, math.min(7, rowcount))

    local livecap_loaded = mp.get_property_native(
        "user-data/cadre_livecap/loaded",
        false
    )

    local card_w = livecap_loaded and 320 or 250
        local card_h = 42 + livecap_action_area_height() + visible_rows * row_h + 8

    local card_x1, card_y1 = popup_card_position(
        button,
        card_w,
        card_h,
        16
    )

    if
        button.anchor_space ~= "window"
        and cfg.BAR_Y_ANCHOR == "bottom"
    then
        card_y1 = osc_panel_top_y() - card_h - 10
    end

    local edge_gap = 8

    card_x1 = math.max(
        edge_gap,
        math.min(screen_w - card_w - edge_gap, card_x1)
    )

    card_y1 = card_y1 + (cfg.TRACK_POPUP_OFFSET_Y or 0)
    card_y1 = math.max(0, math.min(screen_h - card_h, card_y1))

    local card_x2 = card_x1 + card_w
    local card_y2 = card_y1 + card_h

    return {
        card_x1 = card_x1,
        card_x2 = card_x2,
        card_y1 = card_y1,
        card_y2 = card_y2,
        row_y1 = card_y1 + 38,
        row_h = row_h,
        visible_rows = visible_rows,
    }
end

function publish_popup_glass(name, enabled, geo, radius, blur_radius)
    local bounds = geo and {
        x1 = geo.card_x1, y1 = geo.card_y1,
        x2 = geo.card_x2, y2 = geo.card_y2,
    } or nil
    common.publish_glass_region(name, enabled, bounds, screen_w, screen_h, radius, blur_radius)
end

local function render_livecap_actions(ass, geo, ui)
    if not ui.show_actions then
        return geo.row_y1
    end

    local x1 = geo.card_x1 + 14
    local x2 = geo.card_x2 - 14
    local y = geo.row_y1

    common.draw_text(
        ass,
        "Live Captions",
        x1,
        y + 12,
        cfg.FONT_SIZE,
        cfg.TRACK_POPUP_TEXT,
        "00",
        4,
        false
    )

    local status_text
    local status_color

    if ui.busy then
        status_text = ui.job and ui.job.message
            or (ui.status_message ~= "" and ui.status_message)
            or "Working…"
        if ui.job_progress then
            status_text = status_text
                .. string.format(" (%.0f%%)", ui.job_progress)
        end
        status_color = common.bgr("FFD54A")
    elseif ui.enabled then
        status_text = ui.status_message ~= ""
            and ui.status_message
            or "Ready"
        status_color = cfg.TRACK_FG
    else
        status_text = "Off"
        status_color = cfg.ICON_DIM_A
    end

    common.draw_text(
        ass,
        status_text,
        x2,
        y + 12,
        cfg.FONT_SIZE - 1,
        status_color,
        "00",
        6,
        false
    )

    y = y + 28

    local create_enabled = ui.has_media and not ui.busy

    common.draw_text(
        ass,
        "Create subtitles from audio…",
        x1,
        y + 14,
        cfg.FONT_SIZE - 1,
        cfg.TRACK_POPUP_TEXT,
        create_enabled and "00" or "60",
        4,
        false
    )

    if create_enabled then
        add_hitbox(
            "track_popup_livecap_create_audio",
            x1,
            y,
            x2,
            y + 28,
            function()
                send_livecap_command("create_srt")
            end
        )
    end

    y = y + 30

    local translate_enabled = ui.has_media
        and has_text_subtitle_track()
        and not ui.busy
    common.draw_text(
        ass,
        "Translate existing subtitles…",
        x1,
        y + 14,
        cfg.FONT_SIZE - 1,
        cfg.TRACK_POPUP_TEXT,
        translate_enabled and "00" or "60",
        4,
        false
    )

    if translate_enabled then
        add_hitbox(
            "track_popup_livecap_translate",
            x1,
            y,
            x2,
            y + 28,
            function()
                send_livecap_command("translate_subs")
            end
        )
    end

    y = y + 30

    common.draw_rrect(
        ass,
        x1,
        y + 4,
        x2,
        y + 5,
        0,
        cfg.TRACK_BG,
        "50"
    )

    return y + 14
end

function render_track_popup(ass, geo)
    local all_tracks = mp.get_property_native("track-list", {})
    local tracks = {}
    for _, track in ipairs(all_tracks) do
        if track.type == track_popup_type then
            tracks[#tracks + 1] = track
        end
    end
    local is_chapters = track_popup_type == "chapters"
    if is_chapters then
        tracks = mp.get_property_native("chapter-list", {}) or {}
    end
    local has_disable = track_popup_type == "sub"
    local item_count = #tracks + (has_disable and 1 or 0)
    track_popup_max_scroll = math.max(0, item_count - geo.visible_rows)
    track_popup_scroll = math.max(0, math.min(track_popup_scroll, track_popup_max_scroll))

    common.draw_rrect(ass, geo.card_x1, geo.card_y1, geo.card_x2, geo.card_y2, cfg.TRACK_POPUP_RADIUS, cfg.TRACK_POPUP_BG, cfg.TRACK_POPUP_BG_ALPHA)
    if cfg.TRACK_POPUP_BORDER_WIDTH > 0 then draw_rrect_outline(ass, geo.card_x1, geo.card_y1, geo.card_x2, geo.card_y2, cfg.TRACK_POPUP_RADIUS, cfg.TRACK_POPUP_BORDER_COLOR, cfg.TRACK_POPUP_BORDER_ALPHA, cfg.TRACK_POPUP_BORDER_WIDTH) end
    local popup_title = track_popup_type == "audio" and "Audio tracks"
        or track_popup_type == "sub" and "Subtitles" or "Chapters"
    common.draw_text(ass, popup_title,
        geo.card_x1 + 14, geo.card_y1 + 20, cfg.FONT_SIZE, cfg.TRACK_POPUP_TEXT, "00", 4, false)
        if track_popup_type == "sub" then
        local livecap_loaded = mp.get_property_native(
            "user-data/cadre_livecap/loaded",
            false
        )

        if livecap_loaded then
            local livecap_enabled = mp.get_property_native(
                "user-data/cadre_livecap/enabled",
                false
            )

            -- Live captions toggle
            local icon = livecap_enabled
                and ICON.cc_on
                or ICON.cc_off

            local icon_alpha = livecap_enabled
                and "00"
                or cfg.ICON_DIM_A

            draw_icon(
                ass,
                icon,
                geo.card_x2 - 60,
                geo.card_y1 + 20,
                cfg.FONT_SIZE + 2,
                cfg.ICON_COLOR,
                icon_alpha
            )

            add_hitbox(
                "track_popup_livecap_toggle",
                geo.card_x2 - 78,
                geo.card_y1 + 4,
                geo.card_x2 - 42,
                geo.card_y1 + 36,
                function()
                    mp.commandv(
                        "script-message-to",
                        "cadre_livecap",
                        "cadre-livecap-toggle"
                    )
                end
            )
        end
    end
    if track_popup_type == "sub"
        and mp.get_property_native("user-data/cadre_subs/available", false) then
        draw_icon(ass, ICON.globe, geo.card_x2 - 20, geo.card_y1 + 20,
            cfg.FONT_SIZE + 2, cfg.ICON_COLOR, cfg.ICON_DIM_A)
        add_hitbox("track_popup_subs_search",
            geo.card_x2 - 38, geo.card_y1 + 4, geo.card_x2 - 4, geo.card_y1 + 36,
            function()
                track_popup_open = false
                mp.commandv("script-message-to", "cadre_subs", "cadre-subs-search")
            end)
    end
    common.draw_rrect(ass, geo.card_x1 + 8, geo.card_y1 + 36,
        geo.card_x2 - 8, geo.card_y1 + 37, 0, cfg.TRACK_BG, "50")

    local subtitle_rows_y = geo.row_y1
    if track_popup_type == "sub" then
        subtitle_rows_y = render_livecap_actions(
            ass,
            geo,
            livecap_ui_state()
        )
    end

    local function draw_row(index, label, selected, callback)
        local y1 = subtitle_rows_y + (index - 1 - track_popup_scroll) * geo.row_h
        if y1 < subtitle_rows_y or y1 + geo.row_h > geo.card_y2 - 4 then 
            return end
        if selected then
            common.draw_rrect(ass, geo.card_x1 + 6, y1 + 2, geo.card_x2 - 6, y1 + geo.row_h - 2,
            6, cfg.TRACK_BG, "20")
        end
        common.draw_text(ass, selected and "●" or "○", geo.card_x1 + 18,
            y1 + geo.row_h / 2, cfg.FONT_SIZE - 2, selected and cfg.TRACK_POPUP_ACCENT or cfg.ICON_COLOR,
            selected and "00" or cfg.ICON_DIM_A, 5, false)
        local label_width = geo.card_x2 - geo.card_x1 - 54
        if item_count > geo.visible_rows then label_width = label_width - 10 end
        label = fit_title_to_width(escape_ass_text(label), label_width, cfg.FONT_SIZE - 1)
        common.draw_text(ass, label, geo.card_x1 + 34, y1 + geo.row_h / 2,
            cfg.FONT_SIZE - 1, cfg.TRACK_POPUP_TEXT, "00", 4, false)
        add_hitbox("track_popup_row_" .. index, geo.card_x1 + 4, y1,
            geo.card_x2 - 4, y1 + geo.row_h, callback)
    end

    local current = mp.get_property(track_popup_type == "audio" and "aid" or "sid", "no")
    local index = 1
    if has_disable then
        draw_row(index, "No subtitles", current == "no", function()
            mp.set_property("sid", "no")
            track_popup_open = false
        end)
        index = index + 1
    end
    for i, track in ipairs(tracks) do
        if is_chapters then
            local chapter_title = track.title
            if not chapter_title or chapter_title == "" then chapter_title = "Chapter " .. tostring(i) end
            local chapter_index = i - 1
            local selected_chapter = mp.get_property_number("chapter", -1) == chapter_index
            draw_row(index, string.format("%02d:%02d  %s", math.floor((track.time or 0) / 60),
                math.floor((track.time or 0) % 60), chapter_title), selected_chapter, function()
                    mp.commandv("seek", track.time or 0, "absolute", "exact")
                    track_popup_open = false
                end)
            index = index + 1
        else
        local title, language = subtitle_track_text(track, i)
        if language and language ~= "" and title ~= language then
            title = title .. "  ·  " .. language
        end
        local selected = tostring(track.id) == tostring(current)
        local id = track.id
        draw_row(index, title, selected, function()
            mp.set_property_number(track_popup_type == "audio" and "aid" or "sid", id)
            if track_popup_type == "sub" then last_subtitle_sid = id end
            track_popup_open = false
        end)
        index = index + 1
        end
    end

    if item_count == 0 then
        common.draw_text(ass, is_chapters and "No chapters available" or "No tracks available", geo.card_x1 + 14,
            subtitle_rows_y + geo.row_h / 2, cfg.FONT_SIZE - 1, cfg.TEXT, "40", 4, false)
    end
    if track_popup_max_scroll > 0 then
        local bar_x1, bar_x2 = geo.card_x2 - 9, geo.card_x2 - 6
        local bar_y1, bar_y2 = subtitle_rows_y + 2, geo.card_y2 - 5
        local bar_h = bar_y2 - bar_y1
        local thumb_h = math.max(18, bar_h * geo.visible_rows / item_count)
        local thumb_y = bar_y1 + (bar_h - thumb_h) * track_popup_scroll / track_popup_max_scroll
        common.draw_rrect(ass, bar_x1, bar_y1, bar_x2, bar_y2, 2, cfg.TRACK_BG, "30")
        common.draw_rrect(ass, bar_x1 - 1, thumb_y, bar_x2 + 1, thumb_y + thumb_h,
            3, cfg.TRACK_FG, "00")
    end
    add_hitbox("track_popup_bg", geo.card_x1, geo.card_y1, geo.card_x2, geo.card_y2, function() end)
end

last_popup_key = ""
function publish_popup()
  local pb = settings_menu_geo or track_popup_geo or speed_popup_geo or popup_geo or add_menu_geo
  local x1, y1, x2, y2
  if pb then
    x1 = pb.cardx1 or pb.card_x1
    y1 = pb.cardy1 or pb.card_y1
    x2 = pb.cardx2 or pb.card_x2
    y2 = pb.cardy2 or pb.card_y2
  end
  local ok = x1 and y1 and x2 and y2
  local key = ok and string.format("%.0f,%.0f,%.0f,%.0f", x1, y1, x2, y2) or "none"
  if key == last_popup_key then return end
  last_popup_key = key
  mp.set_property_native("user-data/cadre_osc/popup", ok
    and {visible = true, x1 = x1, y1 = y1, x2 = x2, y2 = y2}
    or {visible = false})
end

function render_volume_popup(ass, geo)
    common.draw_rrect(ass, geo.card_x1, geo.card_y1, geo.card_x2, geo.card_y2, cfg.VOLUME_POPUP_RADIUS, cfg.VOLUME_POPUP_BG, cfg.VOLUME_POPUP_BG_ALPHA)
    if cfg.VOLUME_POPUP_BORDER_WIDTH > 0 then draw_rrect_outline(ass, geo.card_x1, geo.card_y1, geo.card_x2, geo.card_y2, cfg.VOLUME_POPUP_RADIUS, cfg.VOLUME_POPUP_BORDER_COLOR, cfg.VOLUME_POPUP_BORDER_ALPHA, cfg.VOLUME_POPUP_BORDER_WIDTH) end

    ass:new_event()
    ass:append(string.format("{\\pos(0,0)\\an7\\1c&H%s&\\1a&H00&\\bord0\\shad0}", cfg.SLIDER_RAIL))
    ass:draw_start()
    ass:round_rect_cw(geo.cx - 2, geo.track_y1, geo.cx + 2, geo.track_y2, 2)
    ass:draw_stop()

    local vol_ratio = math.min(1, math.max(0, volume / 100))
    local fill_y1 = geo.track_y2 - (geo.track_y2 - geo.track_y1) * vol_ratio

    common.draw_rrect(ass, geo.cx - 2, fill_y1, geo.cx + 2, geo.track_y2, 2, cfg.TRACK_FG, "00")

    ass:new_event()
    ass:append("{\\pos(0,0)\\an7\\1c&HFFFFFF&\\1a&H00&\\bord0\\shad0}")
    ass:draw_start()
    ass:round_rect_cw(geo.cx - 6, fill_y1 - 6, geo.cx + 6, fill_y1 + 6, 6)
    ass:draw_stop()

    common.draw_text(ass, math.floor(volume) .. "%", geo.cx, geo.card_y2 - 38, cfg.FONT_SIZE, cfg.TEXT, "10", 2, false)

    draw_icon(
        ass,
        muted and ICON.volume_off or ICON.volume_up,
        geo.cx,
        geo.mute_y,
        18,
        cfg.ICON_COLOR,
        muted and "00" or "40"
    )

    add_hitbox(
        "volume_mute",
        geo.cx - 16,
        geo.mute_y - 14,
        geo.cx + 16,
        geo.mute_y + 14,
        function()
            mp.commandv("cycle", "mute")
        end
    )

    add_hitbox(
        "volume_track",
        geo.cx - 14,
        geo.track_y1 - 12,
        geo.cx + 14,
        geo.track_y2 + 12,
        function(_, py)
            volume_dragging = true
            set_volume_from_y(py, geo)
        end
    )
    add_hitbox(
        "volume_card_bg",
        geo.card_x1,
        geo.card_y1,
        geo.card_x2,
        geo.card_y2,
        function()
        end
    )
end

function compute_speed_popup_geo(button)
    local card_w = math.min(360, math.max(280, screen_w - 16))
    local card_h = 106
    local x, y = popup_card_position(button, card_w, card_h, 10)
    if button.anchor_space ~= "window" and cfg.BAR_Y_ANCHOR == "bottom" then
        y = osc_panel_top_y() - card_h - 10
    end
    x = math.max(8, math.min(screen_w - card_w - 8, x))
    y = math.max(8, math.min(screen_h - card_h - 8, y))
    return {card_x1=x, card_x2=x+card_w, card_y1=y, card_y2=y+card_h,
        ruler_spacing=math.min(40, (card_w-32)/8)}
end

SPEED_PRESETS = {0, 0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2}
function speed_preset_index(speed)
    if speed_zero_selected then return 1 end
    local best, best_diff = 1, math.huge
    for i = 2, #SPEED_PRESETS do
        local rate = SPEED_PRESETS[i]
        local diff = math.abs(speed-rate)
        if diff < best_diff then best, best_diff = i, diff end
    end
    return best
end

function apply_speed_preset(index)
    local rate = SPEED_PRESETS[index]
    if rate == 0 then
        speed_zero_selected = true
        mp.set_property_bool("pause", true)
    else
        speed_zero_selected = false
        mp.set_property_number("speed", rate)
    end
end

function speed_wheel_geometry(button)
    local x1 = button.x - button.width/2
    local x2 = button.x + button.width/2
    local spacing = button.width / 8
    return {x1=x1, x2=x2, y1=button.y-button.height/2, y2=button.y+button.height/2,
        cx=button.x, cy=button.y, spacing=spacing}
end

function draw_speed_control_wheel(ass, button)
    local geo = speed_wheel_geometry(button)
    local selected = speed_preset_index(mp.get_property_number("speed", 1) or 1)
    local sizes = {7,8,9,10,12,10,9,8,7}
    local heights = {3,4,5,7,11,7,5,4,3}
    common.draw_rrect(ass, geo.x1+2, geo.cy+8, geo.x2-2, geo.cy+10, 1, cfg.TRACK_BG, "25")
    for slot=-4,4 do
        local index = selected + slot
        local value = SPEED_PRESETS[index]
        if value ~= nil then
            local x = button.x + slot*geo.spacing
            local font_size = math.max(7, (button.style.font_size or cfg.FONT_SIZE) - math.abs(slot)*2)
            local label = value == 0 and "0" or tostring(value)
            common.draw_text(ass, label, x, geo.cy-5, font_size,
                slot == 0 and cfg.TRACK_POPUP_ACCENT or cfg.TRACK_POPUP_TEXT,
                slot == 0 and "00" or (math.abs(slot) == 1 and "20" or "45"), 5, slot == 0)
            local h = heights[slot+5]
            common.draw_rrect(ass, x-1, geo.cy+7, x+1, geo.cy+7+h, 1,
                slot == 0 and cfg.TRACK_POPUP_ACCENT or cfg.TRACK_POPUP_TEXT,
                slot == 0 and "00" or "45")
        end
    end
    return geo
end

function speed_wheel_button_at(px, py, layout)
    layout = layout or get_layout()
    for _, group in ipairs({"left", "center", "right"}) do
        for _, button in ipairs(layout.buttons[group]) do
            if button.id == "speed_control_wheel" then
                local geo = speed_wheel_geometry(button)
                if px >= geo.x1 and px <= geo.x2 and py >= geo.y1 and py <= geo.y2 then
                    return button, geo
                end
            end
        end
    end
end

function publish_speed_wheel_bounds(layout)
    local button
    for _, group in ipairs({"left", "center", "right"}) do
        for _, item in ipairs(layout.buttons[group]) do
            if item.id == "speed_control_wheel" then button = item; break end
        end
        if button then break end
    end
    if button then
        local geo = speed_wheel_geometry(button)
        local key = string.format("%.0f,%.0f,%.0f,%.0f", geo.x1, geo.y1, geo.x2, geo.y2)
        if key ~= last_speed_wheel_bounds_key then
            last_speed_wheel_bounds_key = key
            mp.set_property_native("user-data/cadre_osc/speed-wheel", {
                visible=true, x1=geo.x1, y1=geo.y1, x2=geo.x2, y2=geo.y2
            })
        end
    else
        if last_speed_wheel_bounds_key ~= "none" then
            last_speed_wheel_bounds_key = "none"
            mp.set_property_native("user-data/cadre_osc/speed-wheel", {visible=false})
        end
    end
end

function begin_speed_wheel_drag(px, py, button)
    local geo = speed_wheel_geometry(button)
    speed_inline_dragging = true
    speed_inline_start_x = px
    speed_inline_spacing = geo.spacing
    speed_inline_start_index = speed_preset_index(mp.get_property_number("speed", 1) or 1)
    speed_inline_last_index = speed_inline_start_index
    local slot = math.floor((px-button.x)/geo.spacing + 0.5)
    speed_inline_click_index = math.max(1, math.min(#SPEED_PRESETS, speed_inline_start_index + slot))
end

function render_speed_popup(ass, geo)
    local speed = mp.get_property_number("speed", 1) or 1
    local x1, x2, y1, y2 = geo.card_x1, geo.card_x2, geo.card_y1, geo.card_y2
    common.draw_rrect(ass, x1+2, y1+4, x2+2, y2+4, cfg.TRACK_POPUP_RADIUS, "000000", "70")
    common.draw_rrect(ass, x1, y1, x2, y2, cfg.TRACK_POPUP_RADIUS, cfg.TRACK_POPUP_BG, cfg.TRACK_POPUP_BG_ALPHA)
    if cfg.TRACK_POPUP_BORDER_WIDTH > 0 then draw_rrect_outline(ass, x1, y1, x2, y2, cfg.TRACK_POPUP_RADIUS, cfg.TRACK_POPUP_BORDER_COLOR, cfg.TRACK_POPUP_BORDER_ALPHA, cfg.TRACK_POPUP_BORDER_WIDTH) end
    local cx = (x1+x2)/2
    common.draw_text(ass, "PLAYBACK SPEED", cx, y1+17, cfg.FONT_SIZE-3, cfg.TRACK_POPUP_TEXT, "40", 5, false)
    local y = y1+40
    local tick_heights = {6,8,11,16,24,16,11,8,6}
    local spacing = geo.ruler_spacing or 43
    local selected_index = speed_preset_index(speed)
    for slot = -4, 4 do
        local value_index = selected_index + slot
        local value = SPEED_PRESETS[value_index]
        local x = cx + slot*spacing
        local selected = slot == 0
        if value then
        local alpha = selected and "00" or (math.abs(slot) == 1) and "20" or "45"
        local label = value == 0 and "0x" or tostring(value).."x"
        local label_size = math.max(12, cfg.FONT_SIZE + 1 - math.abs(slot)*3)
        common.draw_text(ass, label, x, y, label_size,
            selected and cfg.TRACK_POPUP_ACCENT or cfg.TRACK_POPUP_TEXT, alpha, 5, false)
        common.draw_rrect(ass, x-1, y+15, x+1, y+15+tick_heights[slot+5], 1,
            selected and cfg.TRACK_POPUP_ACCENT or cfg.TRACK_POPUP_TEXT, selected and "00" or "45")
        add_hitbox("speed_preset_"..value_index, x-spacing/2+2, y1+37, x+spacing/2-2, y1+104,
            function() apply_speed_preset(value_index) end)
        end
    end
    draw_icon(ass, ICON.speed_reset, cx, y2-13, cfg.FONT_SIZE-2, cfg.ICON_COLOR, "00")
    add_hitbox("speed_reset", cx-18, y2-26, cx+18, y2-1, function()
        mp.set_property_number("speed", 1)
        speed_zero_selected = false
    end)
    add_hitbox("speed_popup_bg", x1, y1, x2, y2, function() end)
end

--------------------------------------------------------------------------------
-- ADD-FILE FLYOUT MENU
--------------------------------------------------------------------------------

function compute_add_menu_geo(button)
    local card_w, card_h = 190, 3 * 36 + 12
    local card_x1 = math.max(8, math.min(screen_w - card_w - 8, button.x - card_w / 2))
    local card_y1
    if button.anchor_space ~= "window" and cfg.BAR_Y_ANCHOR == "bottom" then
        card_y1 = osc_panel_top_y() - card_h - 10
    else
        local _
        _, card_y1 = popup_card_position(button, card_w, card_h, 10)
    end
    card_y1 = card_y1 + (cfg.ADD_POPUP_OFFSET_Y or 0)
    card_y1 = math.max(0, math.min(math.max(0, screen_h - card_h), card_y1))

    local cx = button.x
    local card_x2, card_y2 = card_x1 + card_w, card_y1 + card_h

    return {
        cx = cx,
        card_x1 = card_x1,
        card_x2 = card_x2,
        card_y1 = card_y1,
        card_y2 = card_y2,
        row_h = 36
    }
end

function render_add_menu(ass, geo)
    common.draw_rrect(ass, geo.card_x1, geo.card_y1, geo.card_x2, geo.card_y2, cfg.ADD_POPUP_RADIUS, cfg.ADD_POPUP_BG, cfg.ADD_POPUP_BG_ALPHA)
    if cfg.ADD_POPUP_BORDER_WIDTH > 0 then draw_rrect_outline(ass, geo.card_x1, geo.card_y1, geo.card_x2, geo.card_y2, cfg.ADD_POPUP_RADIUS, cfg.ADD_POPUP_BORDER_COLOR, cfg.ADD_POPUP_BORDER_ALPHA, cfg.ADD_POPUP_BORDER_WIDTH) end

    local entries = {
        {label = "Add file", icon = ICON.add_file, cb = common.do_add_file},
        {label = "Add folder", icon = ICON.add_folder, cb = common.do_add_folder},
        {label = "Add URL", icon = ICON.add_url, cb = common.do_add_url}
    }

    for i, e in ipairs(entries) do
        local row_y1 = geo.card_y1 + 6 + (i - 1) * geo.row_h
        local row_y2 = row_y1 + geo.row_h
        local mid_y = (row_y1 + row_y2) / 2
        draw_icon(ass, e.icon, geo.card_x1 + 24, mid_y, 16, cfg.ICON_COLOR, cfg.ICON_DIM_A)
        common.draw_text(ass, e.label, geo.card_x1 + 42, mid_y, 16, cfg.TEXT, "00", 4, false)
        add_hitbox(
            "add_menu_" .. i,
            geo.card_x1,
            row_y1,
            geo.card_x2,
            row_y2,
            function()
                add_menu_open = false
                e.cb()
            end
        )
    end
end

--------------------------------------------------------------------------------
-- UNIFIED SETTINGS DIALOG
--------------------------------------------------------------------------------

SET_MENU_WIDTH   = 380
SET_MENU_HEIGHT  = 500
SET_MENU_PAD     = 18
SET_MENU_RADIUS  = 14
SET_MENU_ROW_H   = 38
SET_MENU_HEADER_H = 52
SET_MENU_TAB_H   = 40
SET_MENU_FOOTER_H = 46
SET_MENU_SECTION_TITLE_H = 30

-- Compute the geometry for the unified settings panel.
function compute_settings_menu_geo()
    local margin = 20
    local card_w = math.min(SET_MENU_WIDTH, screen_w - margin * 2)
    local card_h = math.min(SET_MENU_HEIGHT, screen_h - margin * 2)
    local card_x1 = math.floor((screen_w - card_w) / 2)
    local card_y1 = math.floor((screen_h - card_h) / 2)
    local card_x2 = card_x1 + card_w
    local card_y2 = card_y1 + card_h

    local cx1 = card_x1 + SET_MENU_PAD
    local cx2 = card_x2 - SET_MENU_PAD

    local header_y1 = card_y1
    local header_y2 = header_y1 + SET_MENU_HEADER_H
    local tab_y1    = header_y2
    local tab_y2    = tab_y1 + SET_MENU_TAB_H
    local footer_y1 = card_y2 - SET_MENU_FOOTER_H
    local footer_y2 = card_y2
    local body_y1   = tab_y2 + 4
    local body_y2   = footer_y1 - 4

    return {
        card_x1 = card_x1, card_x2 = card_x2,
        card_y1 = card_y1, card_y2 = card_y2,
        cx1 = cx1, cx2 = cx2,
        header_y1 = header_y1, header_y2 = header_y2,
        tab_y1 = tab_y1, tab_y2 = tab_y2,
        body_y1 = body_y1, body_y2 = body_y2,
        footer_y1 = footer_y1, footer_y2 = footer_y2,
    }
end

-- Thin separator line.
function draw_sep(ass, geo, y)
    common.draw_rrect(ass, geo.cx1, y, geo.cx2, y + 1, 0, cfg.TRACK_BG, "50")
end

-- Small +/- stepper button.
function draw_step_btn(ass, x, y, symbol)
    common.draw_rrect(ass, x - 14, y - 14, x + 14, y + 14, 7, cfg.TRACK_BG, "20")
    common.draw_text(ass, symbol, x, y, cfg.FONT_SIZE + 1, cfg.TEXT, "00", 5, false)
end

-- A full label | [−] value [+] row. Returns the row bottom y.
function draw_step_row(ass, geo, row_y, label, value_str,
                              minus_name, minus_cb, plus_name, plus_cb)
    local cy        = row_y + SET_MENU_ROW_H / 2
    local RPAD      = 16
    local minus_x   = geo.cx2 - RPAD - 84
    local val_x     = geo.cx2 - RPAD - 42
    local plus_x    = geo.cx2 - RPAD - 2

    common.draw_text(ass, label,     geo.cx1, cy, cfg.FONT_SIZE - 1, cfg.TEXT, "00", 4, false)
    draw_step_btn(ass, minus_x, cy, "−")
    draw_step_btn(ass, plus_x,  cy, "+")
    common.draw_text(ass, value_str, val_x,    cy, cfg.FONT_SIZE - 1, cfg.TEXT, "00", 5, false)

    add_hitbox(minus_name, minus_x - 18, row_y, minus_x + 18, row_y + SET_MENU_ROW_H, minus_cb)
    add_hitbox(plus_name,  plus_x  - 18, row_y, plus_x  + 18, row_y + SET_MENU_ROW_H, plus_cb)
end


measure_osd = mp.create_osd_overlay("ass-events")
    measure_osd.hidden = true
    measure_osd.compute_bounds = true

measure_text_width = function(text, font_size, font)
    local f = font or cfg.UI_FONT
    local osd_w, osd_h = mp.get_osd_size()

    measure_osd.res_x = osd_w
    measure_osd.res_y = osd_h

    measure_osd.data =
        string.format(
        "{\\pos(1000,1000)\\an5\\fn%s\\fs%d" .. "\\1c&HFFFFFF&\\1a&H00&\\bord0\\shad0\\b0}%s",
        f,
        font_size,
        text
    )

    local res = measure_osd:update()

    if res and res.x0 and res.x1 then
        return res.x1 - res.x0
    end

    -- Fallback only if libass does not return bounds.
    return utf8_char_count(text) * font_size * 0.5
end

title_fit_cache_key = nil
title_fit_cache_value = nil

escape_ass_text = function(text)
    return text:gsub("[\r\n]", " "):gsub("\\", "\\\\"):gsub("{", "\\{"):gsub("}", "\\}")
end

fit_title_to_width = function(text, max_width, font_size, font)
    font_size = font_size or cfg.TITLE_SIZE
    font = font or cfg.TITLE_FONT
    local key = text .. "\0" .. tostring(max_width) .. "\0" .. tostring(font_size) .. "\0" .. font
    if key == title_fit_cache_key then
        return title_fit_cache_value
    end

    if measure_text_width(text, font_size, font) <= max_width then
        title_fit_cache_key, title_fit_cache_value = key, text
        return text
    end

    local chars = {}
    for char in text:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        chars[#chars + 1] = char
    end
    while #chars > 0 do
        table.remove(chars)
        local candidate = table.concat(chars) .. "..."
        if measure_text_width(candidate, font_size, font) <= max_width then
            title_fit_cache_key, title_fit_cache_value = key, candidate
            return candidate
        end
    end

    title_fit_cache_key, title_fit_cache_value = key, ""
    return ""
end

-- Scrollable subtitle track list row.
function draw_subtitle_track_row(ass, geo, row_y, title, language, selected, hbname, cb)
    local vy1 = math.max(row_y, geo.body_y1)
    local vy2 = math.min(row_y + SET_MENU_ROW_H, geo.body_y2)

    if vy2 - vy1 < SET_MENU_ROW_H then
        return
    end
    local center = row_y + SET_MENU_ROW_H / 2

    -- Measure how much space language will take
    local lang_w = 0
    if language and language ~= "" then
        lang_w = measure_text_width(language, cfg.FONT_SIZE - 2, cfg.UI_FONT)
    end

    local text_start = geo.cx1 + 40
    local right_margin = 12
    local max_title_w = math.max(20, geo.cx2 - right_margin - text_start - lang_w)

    -- Width-safe truncation
    local safe_title = title
    if measure_text_width(title, cfg.FONT_SIZE - 1, cfg.UI_FONT) > max_title_w then
        local lo, hi = 0, utf8_char_count(title)
        while lo < hi do
            local mid = math.ceil((lo + hi) / 2)
            local cand = title:sub(1, mid) .. "…"
            if measure_text_width(cand, cfg.FONT_SIZE - 1, cfg.UI_FONT) <= max_title_w then
                lo = mid
            else
                hi = mid - 1
            end
        end
        safe_title = title:sub(1, lo) .. "…"
    end

    if selected then
        common.draw_rrect(ass, geo.cx1, vy1 + 2, geo.cx2 - 8, vy2 - 2, 6, cfg.TRACK_FG, "D0")
    end

    common.draw_text(ass, selected and "●" or "○", geo.cx1 + 14, center,
        cfg.FONT_SIZE, selected and cfg.TRACK_FG or cfg.ICON_COLOR,
        selected and "00" or cfg.ICON_DIM_A, 5, false)

    common.draw_text(ass, safe_title, text_start, center,
        cfg.FONT_SIZE - 1, cfg.TEXT, "00", 4, false)

    if language and language ~= "" then
        common.draw_text(ass, language, geo.cx2 - 12, center,
            cfg.FONT_SIZE - 2, cfg.TEXT, "35", 6, false)
    end

    add_hitbox(hbname, geo.cx1, vy1, geo.cx2, vy2, cb)
end

-- Section heading inside a tab body.
function draw_section_title(ass, geo, y, text)
    common.draw_text(
        ass, text, geo.cx1, y + SET_MENU_SECTION_TITLE_H / 2,
        cfg.FONT_SIZE - 2, cfg.TEXT, "40", 4, false
    )
end

-- Subtitles tab
function render_subtitles_tab(ass, geo)
    local sub_delay   = mp.get_property_number("sub-delay",        0)    or 0
    local sub_scale   = mp.get_property_number("sub-scale",        1.0)  or 1.0
    local sub_pos     = mp.get_property_number("sub-pos",          100)  or 100
    local sub_outline = mp.get_property_number("sub-outline-size", 1.65) or 0
    local sub_shadow  = mp.get_property_number("sub-shadow-offset",0)    or 0

    local y = geo.body_y1 + 2

    draw_step_row(ass, geo, y,
        "Delay",   string.format("%.1f s", sub_delay),
        "set_sub_delay_minus",  function() mp.commandv("add", "sub-delay", -0.1) end,
        "set_sub_delay_plus",   function() mp.commandv("add", "sub-delay",  0.1) end)
    y = y + SET_MENU_ROW_H

    draw_step_row(ass, geo, y,
        "Scale",   string.format("%d%%", math.floor(sub_scale * 100 + 0.5)),
        "set_sub_scale_minus",  function() mp.set_property_number("sub-scale", math.max(0.5, sub_scale - 0.1)) end,
        "set_sub_scale_plus",   function() mp.set_property_number("sub-scale", math.min(3.0, sub_scale + 0.1)) end)
    y = y + SET_MENU_ROW_H

    draw_step_row(ass, geo, y,
        "Position", string.format("%d%%", math.floor(sub_pos + 0.5)),
        "set_sub_pos_minus",
        function() mp.set_property_number("sub-pos", math.max(0,   sub_pos - 1)) end,
        "set_sub_pos_plus",
        function() mp.set_property_number("sub-pos", math.min(150, sub_pos + 1)) end)
    y = y + SET_MENU_ROW_H

    draw_step_row(ass, geo, y,
        "Outline",  string.format("%.2f", sub_outline),
        "set_sub_outline_minus",
        function() mp.set_property_number("sub-outline-size", math.max(0,  sub_outline - 0.15)) end,
        "set_sub_outline_plus",
        function() mp.set_property_number("sub-outline-size", math.min(10, sub_outline + 0.15)) end)
    y = y + SET_MENU_ROW_H

    draw_step_row(ass, geo, y,
        "Shadow",   string.format("%.1f", sub_shadow),
        "set_sub_shadow_minus",
        function() mp.set_property_number("sub-shadow-offset", math.max(0,  sub_shadow - 0.5)) end,
        "set_sub_shadow_plus",
        function() mp.set_property_number("sub-shadow-offset", math.min(10, sub_shadow + 0.5)) end)
    y = y + SET_MENU_ROW_H

    draw_sep(ass, geo, y + 2)
    y = y + 10

    -- Tracks section heading
    draw_section_title(ass, geo, y, "Tracks")
    y = y + SET_MENU_SECTION_TITLE_H
    draw_sep(ass, geo, y)
    y = y + 2

    -- Scrollable track list
    local sub_tracks = get_subtitle_tracks()
    local current_sid_native = mp.get_property_native("sid")
    local current_sid = mp.get_property("sid")

    local track_area_y1 = y

    local track_area_y2 = geo.footer_y1 - 10

    if track_area_y2 < track_area_y1 + SET_MENU_ROW_H then
        track_area_y2 = track_area_y1 + SET_MENU_ROW_H
    end

    local list_h = track_area_y2 - track_area_y1
    local visible_rows = math.max(
        1,
        math.floor(list_h / SET_MENU_ROW_H)
    )

    local total_rows = #sub_tracks + 1

    settings_menu_max_scroll = math.max(
        0,
        total_rows - visible_rows
    )

    settings_menu_scroll = math.max(
        0,
        math.min(settings_menu_scroll, settings_menu_max_scroll)
    )

    local first_y = track_area_y1 - settings_menu_scroll * SET_MENU_ROW_H

    local sub_geo = {
        cx1 = geo.cx1,
        cx2 = geo.cx2,
        body_y1 = track_area_y1,
        body_y2 = track_area_y2,
    }

    local disabled = (current_sid == "no")

    draw_subtitle_track_row(
        ass,
        sub_geo,
        first_y,
        "Disable subtitles",
        nil,
        disabled,
        "set_sub_disable",
        function()
            mp.set_property("sid", "no")
        end
    )

    for i, track in ipairs(sub_tracks) do
        local row_y = first_y + i * SET_MENU_ROW_H
        local title, language = subtitle_track_text(track, i)

        draw_subtitle_track_row(
            ass,
            sub_geo,
            row_y,
            title,
            language,
            current_sid_native == track.id,
            "set_sub_track_" .. i,
            function()
                last_subtitle_sid = track.id
                mp.set_property_number("sid", track.id)
                mp.set_property_bool("sub-visibility", true)
            end
        )
    end

    if settings_menu_max_scroll > 0 then
        local sb_x1 = geo.cx2 - 5
        local sb_x2 = geo.cx2 - 2

        common.draw_rrect(
            ass,
            sb_x1,
            track_area_y1 + 2,
            sb_x2,
            track_area_y2 - 2,
            2,
            cfg.TRACK_BG,
            "30"
        )

        local thumb_h = math.max(
            20,
            list_h * visible_rows / total_rows
        )

        local thumb_y =
            track_area_y1 +
            (list_h - thumb_h) *
            settings_menu_scroll / settings_menu_max_scroll

        common.draw_rrect(
            ass,
            sb_x1 - 1,
            thumb_y,
            sb_x2 + 1,
            thumb_y + thumb_h,
            3,
            cfg.TRACK_FG,
            "00"
        )
    end
end

function render_theme_tab(ass, geo)
    local themes = common.list_themes()
    local conf = common.load_conf()
    local selected_name = type(conf.main) == "table" and conf.main.theme or ""
    if selected_name == "" then selected_name = "Default" end

    local list_y1 = geo.body_y1 + 4
    local list_y2 = geo.body_y2 - 4
    local list_geo = {cx1 = geo.cx1, cx2 = geo.cx2, body_y1 = list_y1, body_y2 = list_y2}
    local viewport_h = list_y2 - list_y1
    local visible_rows = math.max(1, math.floor((viewport_h + 2) / SET_MENU_ROW_H))
    settings_menu_max_scroll = math.max(0, #themes - visible_rows)
    settings_menu_scroll = math.max(0, math.min(settings_menu_scroll, settings_menu_max_scroll))
    local first_y = list_y1 - settings_menu_scroll * SET_MENU_ROW_H

    for i, name in ipairs(themes) do
        local theme_name = name
        draw_subtitle_track_row(
            ass, list_geo, first_y + (i - 1) * SET_MENU_ROW_H,
            theme_name, nil, theme_name == selected_name,
            "set_theme_" .. tostring(i),
            function() common.save_theme(theme_name) end
        )
    end

    if settings_menu_max_scroll > 0 then
        local sb_x1, sb_x2 = geo.cx2 - 5, geo.cx2 - 2
        common.draw_rrect(ass, sb_x1, list_y1 + 2, sb_x2, list_y2 - 2,
            2, cfg.TRACK_BG, "30")
        local thumb_h = math.max(20, viewport_h * visible_rows / #themes)
        local thumb_y = list_y1 + (viewport_h - thumb_h)
            * settings_menu_scroll / settings_menu_max_scroll
        common.draw_rrect(ass, sb_x1 - 1, thumb_y, sb_x2 + 1, thumb_y + thumb_h,
            3, cfg.TRACK_FG, "00")
    end
end

-- Video tab
function render_video_tab(ass, geo)
    if not settings_track_list_mode then
        settings_track_list_mode = "audio"
    end

    local speed = mp.get_property_number("speed", 1.0) or 1.0
    local keepasp = mp.get_property_bool("keepaspect", true)
    local unscaled = mp.get_property("video-unscaled") or "no"
    local aspect = mp.get_property_number("video-aspect-override", -1) or -1

    local y = geo.body_y1 + 4

    -- Speed
    draw_step_row(
        ass,
        geo,
        y,
        "Speed",
        string.format("%.2fx", speed),
        "set_speed_minus",
        function()
            mp.set_property_number("speed", math.max(0.25, speed - 0.25))
        end,
        "set_speed_plus",
        function()
            mp.set_property_number("speed", math.min(4.0, speed + 0.25))
        end
    )

    y = y + SET_MENU_ROW_H
    draw_sep(ass, geo, y + 2)
    y = y + 6

    -- Aspect Ratio
    draw_section_title(ass, geo, y, "Aspect Ratio")
    y = y + SET_MENU_SECTION_TITLE_H

    local asp_choices = {
        {label = "Auto", value = -1, current = aspect < 0},
        {label = "4:3", value = 4 / 3, current = math.abs(aspect - 4 / 3) < 0.02},
        {label = "16:9", value = 16 / 9, current = math.abs(aspect - 16 / 9) < 0.02},
        {label = "2.39:1", value = 2.39, current = math.abs(aspect - 2.39) < 0.02},
    }

    local chip_w = 62
    local chip_h = 26
    local chip_gap = 6
    local chip_cy = y + SET_MENU_ROW_H / 2
    local total_w = #asp_choices * chip_w + (#asp_choices - 1) * chip_gap
    local start_x = geo.cx2 - total_w - 14

    for i, choice in ipairs(asp_choices) do
        local cx = start_x + (i - 1) * (chip_w + chip_gap) + chip_w / 2
        local x1 = cx - chip_w / 2
        local x2 = cx + chip_w / 2
        local y1 = chip_cy - chip_h / 2
        local y2 = chip_cy + chip_h / 2

        if choice.current then
            common.draw_rrect(ass, x1, y1, x2, y2, 6, cfg.TRACK_FG, "D0")
            common.draw_text(ass, choice.label, cx, chip_cy,
                cfg.FONT_SIZE - 3, cfg.TEXT, "00", 5, false)
        else
            common.draw_rrect(ass, x1, y1, x2, y2, 6, cfg.TRACK_BG, "20")
            common.draw_text(ass, choice.label, cx, chip_cy,
                cfg.FONT_SIZE - 3, cfg.TEXT, "30", 5, false)
        end

        local value = choice.value

        add_hitbox(
            "set_asp_" .. i,
            x1,
            y,
            x2,
            y + SET_MENU_ROW_H,
            function()
                if value < 0 then
                    mp.set_property("video-aspect-override", "-1")
                else
                    mp.set_property_number("video-aspect-override", value)
                end
            end
        )
    end

    y = y + SET_MENU_ROW_H
    draw_sep(ass, geo, y + 2)
    y = y + 12

    -- Display Mode
    draw_section_title(ass, geo, y, "Display Mode")
    y = y + SET_MENU_SECTION_TITLE_H

    local is_unscaled = unscaled ~= "no" and unscaled ~= "" and unscaled ~= false
    local is_fill = not is_unscaled and not keepasp
    local is_normal = not is_unscaled and keepasp

    local display_choices = {
        {label = "Normal", current = is_normal},
        {label = "Fill", current = is_fill},
        {label = "Unscaled", current = is_unscaled},
    }

    local display_chip_w = 74
    local display_chip_h = 26
    local display_chip_gap = 6
    local display_cy = y + SET_MENU_ROW_H / 2
    local display_total_w =
        #display_choices * display_chip_w +
        (#display_choices - 1) * display_chip_gap
    local display_start_x = geo.cx2 - display_total_w - 14

    for i, choice in ipairs(display_choices) do
        local cx =
            display_start_x +
            (i - 1) * (display_chip_w + display_chip_gap) +
            display_chip_w / 2

        local x1 = cx - display_chip_w / 2
        local x2 = cx + display_chip_w / 2
        local y1 = display_cy - display_chip_h / 2
        local y2 = display_cy + display_chip_h / 2

        if choice.current then
            common.draw_rrect(ass, x1, y1, x2, y2, 6, cfg.TRACK_FG, "D0")
            common.draw_text(ass, choice.label, cx, display_cy,
                cfg.FONT_SIZE - 3, cfg.TEXT, "00", 5, false)
        else
            common.draw_rrect(ass, x1, y1, x2, y2, 6, cfg.TRACK_BG, "20")
            common.draw_text(ass, choice.label, cx, display_cy,
                cfg.FONT_SIZE - 3, cfg.TEXT, "30", 5, false)
        end

        local index = i

        add_hitbox(
            "set_display_" .. i,
            x1,
            y,
            x2,
            y + SET_MENU_ROW_H,
            function()
                if index == 1 then
                    mp.set_property_bool("keepaspect", true)
                    mp.set_property("video-unscaled", "no")
                elseif index == 2 then
                    mp.set_property_bool("keepaspect", false)
                    mp.set_property("video-unscaled", "no")
                else
                    mp.set_property_bool("keepaspect", true)
                    mp.set_property("video-unscaled", "yes")
                end
            end
        )
    end

    y = y + SET_MENU_ROW_H
    draw_sep(ass, geo, y + 2)
    y = y + 2

    local audio_tracks = {}

    for _, track in ipairs(mp.get_property_native("track-list", {})) do
        if track.type == "audio" then
            audio_tracks[#audio_tracks + 1] = track
        end
    end

    local editions = mp.get_property_native("edition-list", {}) or {}
    local chapter_list = mp.get_property_native("chapter-list", {}) or {}

    -- Audio / Editions / Chapters tabs
    local tab_y1 = y
    local tab_y2 = y + SET_MENU_TAB_H
    local tab_w = (geo.cx2 - geo.cx1) / 3
    local tab_cy = (tab_y1 + tab_y2) / 2

    local audio_tab_x1 = geo.cx1
    local audio_tab_x2 = audio_tab_x1 + tab_w

    local edition_tab_x1 = audio_tab_x2
    local edition_tab_x2 = edition_tab_x1 + tab_w
    local chapter_tab_x1 = edition_tab_x2
    local chapter_tab_x2 = geo.cx2

    local audio_active = settings_track_list_mode == "audio"
    local edition_active = settings_track_list_mode == "edition"
    local chapter_active = settings_track_list_mode == "chapter"

    -- Audio tab text
    common.draw_text(
        ass,
        "Audio (" .. tostring(#audio_tracks) .. ")",
        (audio_tab_x1 + audio_tab_x2) / 2,
        tab_cy,
        cfg.FONT_SIZE - 1,
        audio_active and cfg.TRACK_FG or cfg.TEXT,
        audio_active and "00" or "40",
        5,
        false
    )

    -- Editions tab text
    common.draw_text(
        ass,
        "Editions (" .. tostring(#editions) .. ")",
        (edition_tab_x1 + edition_tab_x2) / 2,
        tab_cy,
        cfg.FONT_SIZE - 1,
        edition_active and cfg.TRACK_FG or cfg.TEXT,
        edition_active and "00" or "40",
        5,
        false
    )

    -- Chapters tab text
    common.draw_text(
        ass,
        "Chapters (" .. tostring(#chapter_list) .. ")",
        (chapter_tab_x1 + chapter_tab_x2) / 2,
        tab_cy,
        cfg.FONT_SIZE - 1,
        chapter_active and cfg.TRACK_FG or cfg.TEXT,
        chapter_active and "00" or "40",
        5,
        false
    )

    -- Accent underline for active tab
    if audio_active then
        common.draw_rrect(
            ass,
            audio_tab_x1 + 8,
            tab_y2 - 3,
            audio_tab_x2 - 8,
            tab_y2,
            1,
            cfg.TRACK_FG,
            "00"
        )
    elseif edition_active then
        common.draw_rrect(
            ass,
            edition_tab_x1 + 8,
            tab_y2 - 3,
            edition_tab_x2 - 8,
            tab_y2,
            1,
            cfg.TRACK_FG,
            "00"
        )
    else
        common.draw_rrect(
            ass,
            chapter_tab_x1 + 8,
            tab_y2 - 3,
            chapter_tab_x2 - 8,
            tab_y2,
            1,
            cfg.TRACK_FG,
            "00"
        )
    end

    draw_sep(ass, geo, tab_y2)

    add_hitbox(
        "set_selector_audio",
        audio_tab_x1,
        tab_y1,
        audio_tab_x2,
        tab_y2,
        function()
            settings_track_list_mode = "audio"
            settings_menu_scroll = 0
        end
    )

    add_hitbox(
        "set_selector_chapter",
        chapter_tab_x1,
        tab_y1,
        chapter_tab_x2,
        tab_y2,
        function()
            settings_track_list_mode = "chapter"
            settings_menu_scroll = 0
        end
    )

    add_hitbox(
        "set_selector_edition",
        edition_tab_x1,
        tab_y1,
        edition_tab_x2,
        tab_y2,
        function()
            settings_track_list_mode = "edition"
            settings_menu_scroll = 0
        end
    )

    y = tab_y2 + 1

    local list_y1 = y
    local list_y2 = geo.body_y2
    local list_geo = {
        cx1 = geo.cx1,
        cx2 = geo.cx2,
        body_y1 = list_y1,
        body_y2 = list_y2,
    }

    local rows = {}
    local current_id
    local current_aid
    local disabled
    local disable_name
    local disable_cb
    local show_disable_row
    local item_prefix

    if settings_track_list_mode == "audio" then
        current_id = mp.get_property_native("aid")
        current_aid = mp.get_property("aid")
        show_disable_row = true
        disabled = (current_aid == "no")
        disable_name = "set_audio_disable"
        item_prefix = "set_audio_track_"

        disable_cb = function()
            mp.set_property("aid", "no")
        end

        for i, track in ipairs(audio_tracks) do
            local title = track.title
            local language = track.lang

            if not title or title == "" then
                if language and language ~= "" then
                    title = language
                    language = nil
                else
                    title = "Audio track " .. tostring(i)
                end
            end

            rows[#rows + 1] = {
                id = track.id,
                title = title,
                language = language,
                callback = function()
                    mp.set_property_number("aid", track.id)
                end
            }
        end
    elseif settings_track_list_mode == "edition" then
        current_id = mp.get_property_number("current-edition", -1)
        show_disable_row = false
        item_prefix = "set_edition_"

        for i, edition in ipairs(editions) do
            local edition_id = edition.id
            if edition_id == nil then
                edition_id = i - 1
            end

            local title = edition.title
            if not title or title == "" then
                title = "Edition " .. tostring(edition_id + 1)
            end

            if edition.default then
                title = title .. " (default)"
            end

            rows[#rows + 1] = {
                id = edition_id,
                title = title,
                language = nil,
                callback = function()
                    mp.set_property_number("edition", edition_id)
                end
            }
        end
    else
        current_id = mp.get_property_number("chapter", -1)
        item_prefix = "set_chapter_"

        for i, chapter in ipairs(chapter_list) do
            local title = chapter.title
            if not title or title == "" then
                title = "Chapter " .. tostring(i)
            end

            rows[#rows + 1] = {
                id = i - 1,
                title = title,
                language = nil,
                callback = function()
                    mp.set_property_number("chapter", i - 1)
                end
            }
        end
    end

    local total_rows = #rows + (show_disable_row and 1 or 0)
    local viewport_h = list_y2 - list_y1
    local visible_rows = math.max(
        1,
        math.floor((viewport_h + 2) / SET_MENU_ROW_H)
    )
    settings_menu_max_scroll = math.max(0, total_rows - visible_rows)
    settings_menu_scroll = math.max(
        0,
        math.min(settings_menu_scroll, settings_menu_max_scroll)
    )

    local first_y = list_y1 - settings_menu_scroll * SET_MENU_ROW_H
    local offset = 0

    if show_disable_row then
        draw_subtitle_track_row(
            ass,
            list_geo,
            first_y,
            "Disable audio",
            nil,
            disabled,
            disable_name,
            disable_cb
        )

        offset = 1
    end

    for i, row in ipairs(rows) do
        local row_y = first_y + (offset + i - 1) * SET_MENU_ROW_H

        draw_subtitle_track_row(
            ass,
            list_geo,
            row_y,
            row.title,
            row.language,
            current_id == row.id,
            item_prefix .. i,
            row.callback
        )
    end

    -- Scrollbar only for this fixed list area
    if settings_menu_max_scroll > 0 and total_rows > 0 then
        local sb_x1 = geo.cx2 - 5
        local sb_x2 = geo.cx2 - 2

        common.draw_rrect(
            ass,
            sb_x1,
            list_y1 + 2,
            sb_x2,
            list_y2 - 2,
            2,
            cfg.TRACK_BG,
            "30"
        )

        local thumb_h = math.max(
            20,
            viewport_h * visible_rows / total_rows
        )

        local thumb_y =
            list_y1 +
            (viewport_h - thumb_h) *
            settings_menu_scroll / settings_menu_max_scroll

        common.draw_rrect(
            ass,
            sb_x1 - 1,
            thumb_y,
            sb_x2 + 1,
            thumb_y + thumb_h,
            3,
            cfg.TRACK_FG,
            "00"
        )
    end
end

local livecap_editor = nil
local livecap_draft_settings = {}
local livecap_pending_request = nil
local livecap_setting_request_sequence = 0
local livecap_advanced_open = false
local livecap_dropdown = nil

local LIVECAP_SPEECH_MODELS = {
    "tiny",
    "base",
    "small",
    "medium",
    "large-v3-turbo",
    "large-v3",
}

local LIVECAP_TRANSLATION_MODELS = {
    "Hy-MT2-1.8B-Q4_K_M",
    "Hy-MT2-1.8B-Q6_K",
    "Hy-MT2-1.8B-Q8_0",
}

local LIVECAP_DEFAULTS = {
    source_language = "",
    target_language = "en",
    whisper_model = "",
    hy_mt2_model = "",
    caption_block_length = 45,
    context_window = 0,
    prime_seconds = 30,
    auto_resume_after_preroll = true,
    save_srt = false,
    osd_status = false,
    subtitle_save_mode = "cache",
    subs_dir = "",
    auto_start = false,
    ["overlay.align"] = 2,
    ["overlay.margin_x"] = 40,
    ["overlay.margin_y"] = 90,
    ["overlay.font"] = "Segoe UI",
    ["overlay.font_size"] = 40,
    ["overlay.color"] = "&H00FFFFFF&",
    ["overlay.border_color"] = "&H00000000&",
    ["overlay.border_width"] = 3,
    ["overlay.shadow"] = 1,
    ["overlay.max_duration"] = 8,
}

local function stage_livecap_setting(key, value)
    if livecap_pending_request then
        return
    end
    livecap_draft_settings[key] = value
    render()
end

local function discard_livecap_draft()
    livecap_draft_settings = {}
end

local function reset_livecap_draft()
    livecap_draft_settings = {}
    for key, value in pairs(LIVECAP_DEFAULTS) do
        livecap_draft_settings[key] = value
    end
    render()
end

local function apply_livecap_draft()
    if not mp.get_property_native(
        "user-data/cadre_livecap/loaded",
        false
    ) then
        mp.osd_message("Live Captions script is not loaded", 2)
        return
    end

    if next(livecap_draft_settings) == nil then
        settings_menu_open = false
        settings_menu_scroll = 0
        render()
        return
    end

    if livecap_ui_state().job_running then
        mp.osd_message("Settings are locked while a subtitle job runs", 3)
        return
    end

    if livecap_pending_request then
        return
    end

    livecap_setting_request_sequence = livecap_setting_request_sequence + 1
    local request_id = string.format(
        "%.6f-%d",
        mp.get_time(),
        livecap_setting_request_sequence
    )
    local timeout = mp.add_timeout(15, function()
        if livecap_pending_request
            and livecap_pending_request.request_id == request_id then
            livecap_pending_request = nil
            msg.warn("Timed out waiting for Live Captions settings confirmation")
            mp.osd_message("Settings were not confirmed; draft was kept", 4)
            render()
        end
    end)
    livecap_pending_request = {
        request_id = request_id,
        timeout = timeout,
    }

    local ok, err = mp.set_property(
        "user-data/livecap/command",
        utils.format_json({
            action = "apply_settings",
            settings = livecap_draft_settings,
            request_id = request_id,
        })
    )
    if not ok then
        timeout:kill()
        livecap_pending_request = nil
        msg.error("Could not apply Live Captions settings: " .. tostring(err))
        mp.osd_message("Could not save Live Captions settings", 3)
        return
    end
    render()
end

local function finish_livecap_settings_request(success, message)
    local pending = livecap_pending_request
    if not pending then
        return false
    end

    pending.timeout:kill()
    livecap_pending_request = nil

    if success then
        if livecap_editor then
            finish_livecap_edit(false)
        end
        livecap_draft_settings = {}
        common.reload_conf()
        settings_menu_open = false
        settings_menu_geo = nil
        settings_menu_scroll = 0
    else
        local error_message = message
            or "Could not save Live Captions settings"
        mp.osd_message(error_message, 4)
        msg.error(error_message)
    end

    render()
    return true
end

local function livecap_setting(name, fallback)
    if livecap_draft_settings[name] ~= nil then
        return livecap_draft_settings[name]
    end

    local conf = common.load_conf()
    local livecap = conf and conf.livecap or {}
    local value
    if name:sub(1, 8) == "overlay." then
        local overlay = livecap.overlay
        value = type(overlay) == "table"
            and overlay[name:sub(9)] or nil
    else
        value = livecap[name]
    end

    if value == nil then
        return fallback
    end

    return value
end

local function livecap_text_value(value, fallback)
    if value == nil or value == "" then
        return fallback
    end

    return tostring(value)
end

local function remove_livecap_editor_bindings()
    for _, name in ipairs({
        "cadre_livecap_editor_unicode",
        "cadre_livecap_editor_backspace",
        "cadre_livecap_editor_space",
        "cadre_livecap_editor_enter",
        "cadre_livecap_editor_escape",
        "cadre_livecap_editor_clear",
    }) do
        mp.remove_key_binding(name)
    end
end

local function finish_livecap_edit(save)
    if not livecap_editor then
        return
    end

    local editor = livecap_editor
    livecap_editor = nil
    remove_livecap_editor_bindings()

    if save then
        local value = editor.value:gsub("^%s+", ""):gsub("%s+$", "")
        if value == "" and not editor.allow_empty then
            mp.osd_message(editor.label .. " cannot be empty", 3)
        else
            stage_livecap_setting(editor.key, value)
        end
    end

    render()
end

local function start_livecap_edit(label, key, current, allow_empty)
    if livecap_editor then
        finish_livecap_edit(false)
    end

    livecap_editor = {
        label = label,
        key = key,
        value = "",
        allow_empty = allow_empty,
    }

    mp.add_forced_key_binding(
        "ANY_UNICODE",
        "cadre_livecap_editor_unicode",
        function(event)
            if event.event ~= "down" or not livecap_editor then
                return
            end

            local character = event.key_text
            if not character or character == "" then
                character = event.key_name or ""
            end
            if character ~= " " and character ~= "SPACE"
                and #character > 0 and #livecap_editor.value < 256 then
                livecap_editor.value = livecap_editor.value .. character
                render()
            end
        end,
        {complex = true}
    )
    mp.add_forced_key_binding(
        "BS",
        "cadre_livecap_editor_backspace",
        function()
            if livecap_editor then
                livecap_editor.value = livecap_editor.value:gsub(
                    "[%z\1-\127\194-\244][\128-\191]*$",
                    ""
                )
                render()
            end
        end,
        {repeatable = true}
    )
    mp.add_forced_key_binding(
        "SPACE",
        "cadre_livecap_editor_space",
        function()
            if livecap_editor and #livecap_editor.value < 256 then
                livecap_editor.value = livecap_editor.value .. " "
                render()
            end
        end,
        {repeatable = true}
    )
    mp.add_forced_key_binding(
        "ENTER",
        "cadre_livecap_editor_enter",
        function()
            finish_livecap_edit(true)
        end
    )
    mp.add_forced_key_binding(
        "ESC",
        "cadre_livecap_editor_escape",
        function()
            finish_livecap_edit(false)
        end
    )
    mp.add_forced_key_binding(
        "Ctrl+a",
        "cadre_livecap_editor_clear",
        function()
            if livecap_editor then
                livecap_editor.value = ""
                render()
            end
        end
    )

    render()
end

local function draw_livecap_text_row(
    ass, geo, y, label, value, name, on_click, enabled, setting_key
)
    local cy = y + SET_MENU_ROW_H / 2
    local value_x1 = geo.cx2 - 190
    local value_x2 = geo.cx2 - 30

    local hovered = enabled
        and settings_control_hovered(
            value_x1,
            y,
            value_x2,
            y + SET_MENU_ROW_H
        )

    if hovered then
        common.draw_rrect(
            ass,
            value_x1,
            y,
            value_x2,
            y + SET_MENU_ROW_H,
            6,
            cfg.POPUP_HOVER_COLOR,
            cfg.POPUP_HOVER_ALPHA
        )
    end

    common.draw_text(
        ass,
        fit_title_to_width(
            escape_ass_text(label),
            value_x1 - geo.cx1 - 12,
            cfg.FONT_SIZE - 1,
            cfg.UI_FONT
        ),
        geo.cx1,
        cy,
        cfg.FONT_SIZE - 1,
        cfg.TEXT,
        enabled and "00" or "60",
        4,
        false
    )

    local shown_value = value
    if livecap_editor and livecap_editor.key == setting_key then
        shown_value = livecap_editor.value == ""
            and "Type a replacement..." or livecap_editor.value .. "|"
    end
    shown_value = fit_title_to_width(
        escape_ass_text(shown_value),
        value_x2 - value_x1 - 16,
        cfg.FONT_SIZE - 1,
        cfg.UI_FONT
    )

    common.draw_text(
        ass,
        shown_value,
        value_x1 + 10,
        cy,
        cfg.FONT_SIZE - 1,
        cfg.TRACK_FG,
        enabled and "00" or "60",
        4,
        false
    )

    if enabled then
        add_hitbox(
            name,
            value_x1,
            y,
            value_x2,
            y + SET_MENU_ROW_H,
            on_click
        )
    end
end

local function draw_livecap_toggle_row(
    ass, geo, y, label, value, name, on_toggle, enabled
)
    local cy = y + SET_MENU_ROW_H / 2
    local button_x = geo.cx2 - 90

    common.draw_text(
        ass,
        fit_title_to_width(
            escape_ass_text(label),
            button_x - 46 - geo.cx1,
            cfg.FONT_SIZE - 1,
            cfg.UI_FONT
        ),
        geo.cx1,
        cy,
        cfg.FONT_SIZE - 1,
        cfg.TEXT,
        enabled and "00" or "60",
        4,
        false
    )

    common.draw_rrect(
        ass,
        button_x - 34,
        cy - 13,
        button_x + 34,
        cy + 13,
        8,
        cfg.TRACK_BG,
        "30"
    )

    common.draw_text(
        ass,
        value and "On" or "Off",
        button_x,
        cy,
        cfg.FONT_SIZE - 1,
        value and cfg.TRACK_FG or cfg.TEXT,
        enabled and "00" or "60",
        5,
        false
    )

    if enabled then
        add_hitbox(
            name,
            button_x - 38,
            y,
            button_x + 38,
            y + SET_MENU_ROW_H,
            on_toggle
        )
    end
end

local function draw_caption_step_row(
    ass, geo, y, label, value, name, on_minus, on_plus, enabled
)
    local cy = y + SET_MENU_ROW_H / 2
    local minus_x = geo.cx2 - 165
    local value_x = geo.cx2 - 103
    local plus_x = geo.cx2 - 41
    local alpha = enabled and "00" or "60"

    common.draw_text(
        ass,
        fit_title_to_width(
            escape_ass_text(label),
            minus_x - geo.cx1 - 20,
            cfg.FONT_SIZE - 1,
            cfg.UI_FONT
        ),
        geo.cx1,
        cy,
        cfg.FONT_SIZE - 1,
        cfg.TEXT,
        alpha,
        4,
        false
    )
    common.draw_rrect(
        ass, minus_x - 14, cy - 14, minus_x + 14, cy + 14, 7,
        cfg.TRACK_BG, enabled and "20" or "60"
    )
    common.draw_text(
        ass, "−", minus_x, cy, cfg.FONT_SIZE + 1, cfg.TEXT, alpha, 5, false
    )
    common.draw_text(
        ass,
        fit_title_to_width(
            escape_ass_text(value), 96, cfg.FONT_SIZE - 3, cfg.UI_FONT
        ),
        value_x, cy, cfg.FONT_SIZE - 3, cfg.TRACK_FG, alpha, 5, false
    )
    common.draw_rrect(
        ass, plus_x - 14, cy - 14, plus_x + 14, cy + 14, 7,
        cfg.TRACK_BG, enabled and "20" or "60"
    )
    common.draw_text(
        ass, "+", plus_x, cy, cfg.FONT_SIZE + 1, cfg.TEXT, alpha, 5, false
    )

    if enabled then
        add_hitbox(name .. "_minus", minus_x - 18, y, minus_x + 18,
            y + SET_MENU_ROW_H, on_minus)
        add_hitbox(name .. "_plus", plus_x - 18, y, plus_x + 18,
            y + SET_MENU_ROW_H, on_plus)
    end
end

local function draw_caption_action_row(
    ass, geo, y, label, button_label, name, callback, enabled
)
    local cy = y + SET_MENU_ROW_H / 2
    local button_x = geo.cx2 - 90

    common.draw_text(
        ass,
        fit_title_to_width(
            escape_ass_text(label),
            button_x - 46 - geo.cx1,
            cfg.FONT_SIZE - 1,
            cfg.UI_FONT
        ),
        geo.cx1,
        cy,
        cfg.FONT_SIZE - 1,
        cfg.TEXT,
        enabled and "00" or "60", 4, false
    )
    common.draw_rrect(
        ass, button_x - 36, cy - 13, button_x + 36, cy + 13, 7,
        cfg.TRACK_BG, enabled and "20" or "60"
    )
    common.draw_text(
        ass, button_label, button_x, cy, cfg.FONT_SIZE - 2, cfg.TRACK_FG,
        enabled and "00" or "60", 5, false
    )

    if enabled then
        add_hitbox(name, button_x - 40, y, button_x + 40,
            y + SET_MENU_ROW_H, callback)
    end
end

local function render_captions_tab_legacy(ass, geo)
    local ui = livecap_ui_state()
    local settings_pending = livecap_pending_request ~= nil
    local can_edit = not ui.job_running and not settings_pending
    local source_language = livecap_setting("source_language", "")
    local target_language = livecap_setting("target_language", "en")
    local whisper_model = livecap_setting("whisper_model", "")
    local hy_mt2_model = livecap_setting("hy_mt2_model", "")
    local block_length = tonumber(
        livecap_setting("caption_block_length", 45)
    ) or 45
    local context_window = tonumber(
        livecap_setting("context_window", 0)
    ) or 0
    local prime_seconds = tonumber(
        livecap_setting("prime_seconds", 30)
    ) or 30
    local save_srt = livecap_setting("save_srt", false)
    local osd_status = livecap_setting("osd_status", false)
    local save_mode = livecap_setting("subtitle_save_mode", "cache")
    local subs_dir = livecap_setting("subs_dir", "")
    local auto_start = livecap_setting("auto_start", false)
    local model = livecap_text_value(whisper_model, "large-v3-turbo")
    local hy_model = livecap_text_value(hy_mt2_model, "Hy-MT2-1.8B-Q6_K")
    local active_model = ui.active_model
    local model_pending = active_model ~= nil
        and string.lower(tostring(active_model))
            ~= string.lower(whisper_model)

    local row_count = 13
    local list_y1 = geo.body_y1 + 4
    local list_y2 = geo.body_y2 - 30
    local viewport_h = list_y2 - list_y1
    local visible_rows = math.max(
        1,
        math.floor((viewport_h + 2) / SET_MENU_ROW_H)
    )
    settings_menu_max_scroll = math.max(0, row_count - visible_rows)
    settings_menu_scroll = math.max(
        0,
        math.min(settings_menu_scroll, settings_menu_max_scroll)
    )

    local row_help = {
        [1] = "Leave empty to let speech recognition detect the spoken language.",
        [2] = "Language the generated or translated subtitles should use.",
        [3] = "Speech-recognition model. Changes take effect after Restart worker.",
        [4] = "Shows which recognition model is loaded and whether a change is pending.",
        [5] = "Reloads the worker to use the selected recognition model.",
        [6] = "Start live captions automatically when mpv launches.",
        [7] = "Seconds of audio transcribed together. Larger batches can increase delay.",
        [8] = "Previous subtitle translations sent as context. Set to 0 to turn this off.",
        [9] = "Buffers opening audio while models load, then captions that audio. Set to 0 to disable.",
        [10] = "Also write live captions to a .live.srt file; full subtitle creation always saves.",
        [11] = "Show temporary Live Captions progress and status messages on screen.",
        [12] = "For local videos, choose the cache folder or the video folder. Remote media uses cache.",
        [13] = "Folder used for cached or remote subtitles. Empty uses the default cache folder.",
    }
    local hovered_help

    local function draw_row(index, draw)
        local y = list_y1 + (index - 1 - settings_menu_scroll)
            * SET_MENU_ROW_H
        if y >= list_y1 and y + SET_MENU_ROW_H <= list_y2 then
            if mouse_x >= geo.cx1 and mouse_x <= geo.cx2
                and mouse_y >= y and mouse_y < y + SET_MENU_ROW_H then
                hovered_help = row_help[index]
            end
            draw(y)
        end
    end

    draw_row(1, function(y)
        draw_livecap_text_row(
            ass, geo, y, "Source language",
            livecap_text_value(source_language, "Auto"),
            "set_livecap_source_language",
            function()
                start_livecap_edit(
                    "Source language (empty = Auto)",
                    "source_language",
                    source_language,
                    true
                )
            end,
            can_edit,
            "source_language"
        )
    end)
    draw_row(2, function(y)
        draw_livecap_text_row(
            ass, geo, y, "Target language",
            livecap_text_value(target_language, "en"),
            "set_livecap_target_language",
            function()
                start_livecap_edit(
                    "Target language code",
                    "target_language",
                    target_language,
                    false
                )
            end,
            can_edit,
            "target_language"
        )
    end)
    draw_row(3, function(y)
        draw_livecap_text_row(
            ass, geo, y, "Whisper model", model,
            "set_livecap_whisper_model",
            function()
                start_livecap_edit(
                    "Whisper model name",
                    "whisper_model",
                    model,
                    false
                )
            end,
            can_edit,
            "whisper_model"
        )
    end)
    draw_row(3, function(y)
        draw_livecap_text_row(
            ass, geo, y, "Hy-MT2 model", hy_model,
            "set_livecap_hy_mt2_model",
            function()
                start_livecap_edit(
                    "Hy-MT2 model name",
                    "hy_mt2_model",
                    hy_mt2_model,
                    false
                )
            end,
            can_edit,
            "hy_mt2_model"
        )
    end)
    draw_row(4, function(y)
        local state = settings_pending
            and "Saving setting…"
            or (model_pending
                and "Pending model change"
                or (active_model and ("Loaded: " .. tostring(active_model))
                    or "Loads when the worker starts"))
        draw_livecap_text_row(
            ass, geo, y, "Worker model", state, "set_livecap_model_state",
            function() end, false, "model_state"
        )
    end)
    draw_row(5, function(y)
        draw_caption_action_row(
            ass, geo, y, "Restart worker", "Restart",
            "set_livecap_restart_worker",
            function()
                send_livecap_command("restart_worker")
            end,
            can_edit
        )
    end)
    draw_row(6, function(y)
        draw_livecap_toggle_row(
            ass, geo, y, "Start captions automatically", auto_start,
            "set_livecap_auto_start",
            function()
                stage_livecap_setting("auto_start", not auto_start)
            end,
            can_edit
        )
    end)
    draw_row(7, function(y)
        draw_caption_step_row(
            ass, geo, y, "Audio batch length (seconds)",
            string.format("%.0f s", block_length),
            "set_livecap_block",
            function()
                stage_livecap_setting(
                    "caption_block_length", math.max(1, block_length - 5)
                )
            end,
            function()
                stage_livecap_setting(
                    "caption_block_length", block_length + 5
                )
            end,
            can_edit
        )
    end)
    draw_row(8, function(y)
        draw_caption_step_row(
            ass, geo, y, "Translation history (lines)", tostring(context_window),
            "set_livecap_context",
            function()
                stage_livecap_setting(
                    "context_window", math.max(0, context_window - 1)
                )
            end,
            function()
                stage_livecap_setting(
                    "context_window", context_window + 1
                )
            end,
            can_edit
        )
    end)
    draw_row(9, function(y)
        draw_caption_step_row(
            ass, geo, y, "Prepare captions after start or seek (seconds)",
            string.format("%.0f s", prime_seconds),
            "set_livecap_prime",
            function()
                stage_livecap_setting(
                    "prime_seconds", math.max(0, prime_seconds - 5)
                )
            end,
            function()
                stage_livecap_setting(
                    "prime_seconds", prime_seconds + 5
                )
            end,
            can_edit
        )
    end)
    draw_row(10, function(y)
        draw_livecap_toggle_row(
            ass, geo, y, "Save live transcript (.live.srt)", save_srt,
            "set_livecap_save_srt",
            function()
                stage_livecap_setting("save_srt", not save_srt)
            end,
            can_edit
        )
    end)
    draw_row(11, function(y)
        draw_livecap_toggle_row(
            ass, geo, y, "Show status messages", osd_status,
            "set_livecap_osd_status",
            function()
                stage_livecap_setting("osd_status", not osd_status)
            end,
            can_edit
        )
    end)
    draw_row(12, function(y)
        local use_cache = save_mode == "cache"
        draw_livecap_toggle_row(
            ass, geo, y,
            "Use cache folder for output",
            use_cache,
            "set_livecap_subtitle_location",
            function()
                stage_livecap_setting(
                    "subtitle_save_mode",
                    use_cache and "auto" or "cache"
                )
            end,
            can_edit
        )
    end)
    draw_row(13, function(y)
        draw_livecap_text_row(
            ass, geo, y, "Output/cache folder",
            livecap_text_value(subs_dir, "Default cache"),
            "set_livecap_cache_directory",
            function()
                start_livecap_edit(
                    "Cache directory (empty = default)",
                    "subs_dir",
                    subs_dir,
                    true
                )
            end,
            can_edit,
            "subs_dir"
        )
    end)

    if settings_menu_max_scroll > 0 then
        local thumb_h = math.max(
            20,
            viewport_h * visible_rows / row_count
        )
        local thumb_y = list_y1 + (viewport_h - thumb_h)
            * settings_menu_scroll / settings_menu_max_scroll
        common.draw_rrect(
            ass, geo.cx2 - 5, list_y1 + 2, geo.cx2 - 2,
            list_y2 - 2, 2, cfg.TRACK_BG, "30"
        )
        common.draw_rrect(
            ass, geo.cx2 - 6, thumb_y, geo.cx2 - 1,
            thumb_y + thumb_h, 3, cfg.TRACK_FG, "00"
        )
    end

    local help_text
    if ui.job_running then
        help_text = "A subtitle job is running; settings are locked."
    elseif livecap_editor then
        help_text = livecap_editor.label
            .. ": type a replacement; Enter stages it, Done saves, Esc cancels."
    else
        help_text = hovered_help or "Hover over a setting for details."
    end
    help_text = fit_title_to_width(
        escape_ass_text(help_text),
        geo.cx2 - geo.cx1,
        math.max(10, cfg.FONT_SIZE - 5),
        cfg.UI_FONT
    )
    common.draw_text(
        ass,
        help_text,
        geo.cx1,
        geo.body_y2 - 12,
        math.max(10, cfg.FONT_SIZE - 5),
        cfg.TEXT,
        "35",
        4,
        false
    )
end

function render_captions_tab(ass, geo)
    local ui = livecap_ui_state()
    local can_edit = not ui.job_running and livecap_pending_request == nil
    if not can_edit then
        livecap_dropdown = nil
    end
    local rows = {}
    local hovered_help
    local dropdown_anchor_y

    local function add_row(help, draw)
        rows[#rows + 1] = {help = help, draw = draw}
    end

    local function setting_number(key, fallback)
        return tonumber(livecap_setting(key, fallback)) or fallback
    end

    local function add_step_row(label, key, step, minimum, maximum, format_value, help)
        add_row(help, function(y)
            local value = setting_number(key, minimum)
            draw_caption_step_row(
                ass, geo, y, label, format_value(value), "set_caption_" .. key,
                function()
                    stage_livecap_setting(key, math.max(minimum, value - step))
                end,
                function()
                    stage_livecap_setting(key, math.min(maximum, value + step))
                end,
                can_edit
            )
        end)
    end

    local function add_model_select_row(label, key, fallback, options, help)
        add_row(help, function(y)
            local value = livecap_text_value(
                livecap_setting(key, fallback),
                fallback
            )
            local value_x1 = geo.cx2 - 190
            local value_x2 = geo.cx2 - 30
            local cy = y + SET_MENU_ROW_H / 2
            local opened = livecap_dropdown
                and livecap_dropdown.key == key
            local hovered = can_edit and settings_control_hovered(
                value_x1,
                y,
                value_x2,
                y + SET_MENU_ROW_H
            )

            if hovered or opened then
                common.draw_rrect(
                    ass,
                    value_x1,
                    y,
                    value_x2,
                    y + SET_MENU_ROW_H,
                    6,
                    cfg.POPUP_HOVER_COLOR,
                    cfg.POPUP_HOVER_ALPHA
                )
            end

            common.draw_text(
                ass,
                fit_title_to_width(
                    escape_ass_text(label),
                    value_x1 - geo.cx1 - 12,
                    cfg.FONT_SIZE - 1,
                    cfg.UI_FONT
                ),
                geo.cx1,
                cy,
                cfg.FONT_SIZE - 1,
                cfg.TEXT,
                can_edit and "00" or "60",
                4,
                false
            )
            common.draw_text(
                ass,
                fit_title_to_width(
                    escape_ass_text(value),
                    value_x2 - value_x1 - 34,
                    cfg.FONT_SIZE - 1,
                    cfg.UI_FONT
                ),
                value_x1 + 10,
                cy,
                cfg.FONT_SIZE - 1,
                cfg.TRACK_FG,
                can_edit and "00" or "60",
                4,
                false
            )
            common.draw_text(
                ass,
                "v",
                value_x2 - 13,
                cy,
                cfg.FONT_SIZE - 1,
                cfg.TRACK_FG,
                can_edit and "00" or "60",
                5,
                false
            )

            if can_edit then
                add_hitbox(
                    "set_livecap_model_dropdown_" .. key,
                    value_x1,
                    y,
                    value_x2,
                    y + SET_MENU_ROW_H,
                    function()
                        if livecap_dropdown
                            and livecap_dropdown.key == key then
                            livecap_dropdown = nil
                        else
                            livecap_dropdown = {
                                key = key,
                                options = options,
                            }
                        end
                    end
                )
            end

            if opened then
                dropdown_anchor_y = y
            end
        end)
    end

    local positions = {
        "Bottom left", "Bottom center", "Bottom right",
        "Middle left", "Middle center", "Middle right",
        "Top left", "Top center", "Top right",
    }
    local alignment = math.max(1, math.min(9, setting_number("overlay.align", 2)))
    add_row("Choose where captions appear on the video.", function(y)
        draw_caption_step_row(
            ass, geo, y, "Caption position", positions[alignment],
            "set_caption_position",
            function()
                stage_livecap_setting(
                    "overlay.align", alignment == 1 and 9 or alignment - 1
                )
            end,
            function()
                stage_livecap_setting(
                    "overlay.align", alignment == 9 and 1 or alignment + 1
                )
            end,
            can_edit
        )
    end)

    local font = livecap_setting("overlay.font", "Segoe UI")
    add_row("Font used for the captions.", function(y)
        draw_livecap_text_row(
            ass, geo, y, "Font", livecap_text_value(font, "Segoe UI"),
            "set_caption_font",
            function()
                start_livecap_edit("Caption font", "overlay.font", font, false)
            end,
            can_edit,
            "overlay.font"
        )
    end)
    add_step_row("Text size", "overlay.font_size", 2, 8, 200,
        function(value) return tostring(value) .. " px" end,
        "Change the size of the caption text.")
    add_step_row("Side margin", "overlay.margin_x", 10, 0, 1000,
        function(value) return tostring(value) .. " px" end,
        "Keep captions this far from both sides; long lines wrap within the safe area.")
    add_step_row("Top/bottom margin", "overlay.margin_y", 10, 0, 1000,
        function(value) return tostring(value) .. " px" end,
        "Distance from the top or bottom edge of the video.")

    local colors = {
        {name = "White", value = "&H00FFFFFF&"},
        {name = "Black", value = "&H00000000&"},
        {name = "Yellow", value = "&H0000FFFF&"},
        {name = "Cyan", value = "&H00FFFF00&"},
        {name = "Green", value = "&H0000FF00&"},
        {name = "Red", value = "&H000000FF&"},
    }
    local function add_color_row(label, key, fallback, help)
        add_row(help, function(y)
            local current = livecap_setting(key, fallback)
            local selected = 1
            for index, color in ipairs(colors) do
                if color.value == current then
                    selected = index
                    break
                end
            end
            draw_caption_step_row(
                ass, geo, y, label, colors[selected].name,
                "set_caption_" .. key,
                function()
                    local index = selected == 1 and #colors or selected - 1
                    stage_livecap_setting(key, colors[index].value)
                end,
                function()
                    local index = selected == #colors and 1 or selected + 1
                    stage_livecap_setting(key, colors[index].value)
                end,
                can_edit
            )
        end)
    end
    add_color_row(
        "Text color", "overlay.color", "&H00FFFFFF&",
        "Color of the caption text."
    )
    add_color_row(
        "Outline color", "overlay.border_color", "&H00000000&",
        "Color of the border around caption letters."
    )
    add_step_row("Outline thickness", "overlay.border_width", 1, 0, 20,
        function(value)
            return value == 0 and "Off" or tostring(value) .. " px"
        end,
        "Set to Off for no outline.")
    add_step_row("Shadow", "overlay.shadow", 1, 0, 10,
        function(value)
            if value == 0 then
                return "Off"
            end
            if value <= 2 then
                return "Soft"
            end
            if value <= 5 then
                return "Medium"
            end
            return "Strong"
        end,
        "0 turns the shadow off; higher values make it stronger.")
    add_step_row("Display time", "overlay.max_duration", 1, 1, 60,
        function(value) return string.format("%.0f s", value) end,
        "Maximum time a live caption stays visible.")

    local source_language = livecap_setting("source_language", "")
    add_row(
        "Language spoken in the audio. Leave empty to detect it automatically.",
        function(y)
            draw_livecap_text_row(
                ass, geo, y, "Spoken language",
                livecap_text_value(source_language, "Auto"),
                "set_caption_source_language",
                function()
                    start_livecap_edit(
                        "Spoken language (empty = Auto)",
                        "source_language",
                        source_language,
                        true
                    )
                end,
                can_edit,
                "source_language"
            )
        end
    )
    local target_language = livecap_setting("target_language", "en")
    add_row("Language used for generated or translated captions.", function(y)
        draw_livecap_text_row(
            ass, geo, y, "Caption language", target_language,
            "set_caption_target_language",
            function()
                start_livecap_edit(
                    "Caption language code",
                    "target_language",
                    target_language,
                    false
                )
            end,
            can_edit,
            "target_language"
        )
    end)

    local whisper_model = livecap_text_value(
        livecap_setting("whisper_model", ""),
        "large-v3-turbo"
    )
    local active_model = ui.active_model
    local model_pending = active_model ~= nil
        and string.lower(tostring(active_model))
            ~= string.lower(whisper_model)
    add_model_select_row(
        "Speech model",
        "whisper_model",
        "large-v3-turbo",
        LIVECAP_SPEECH_MODELS,
        "Speech recognition model. Changes wait until the worker restarts."
    )
    add_model_select_row(
        "Translation model",
        "hy_mt2_model",
        "Hy-MT2-1.8B-Q6_K",
        LIVECAP_TRANSLATION_MODELS,
        "Translation model quantization. Changes wait until the worker restarts."
    )
    add_row("Shows the loaded model and whether a change is waiting to apply.",
        function(y)
            local state = livecap_pending_request and "Saving…"
                or (model_pending and "Change pending"
                    or (active_model and ("Loaded: " .. tostring(active_model))
                        or "Loads when captions start"))
            draw_livecap_text_row(
                ass, geo, y, "Worker status", state,
                "set_caption_model_state", function() end, false, "model_state"
            )
        end)
    add_row("Restart captions with the selected speech model.", function(y)
        draw_caption_action_row(
            ass, geo, y, "Apply model change", "Restart",
            "set_caption_restart_worker",
            function() send_livecap_command("restart_worker") end,
            can_edit
        )
    end)

    local auto_start = livecap_setting("auto_start", false)
    add_row("Turn Live Captions on automatically when mpv starts.", function(y)
        draw_livecap_toggle_row(
            ass, geo, y, "Start captions automatically", auto_start,
            "set_caption_auto_start",
            function() stage_livecap_setting("auto_start", not auto_start) end,
            can_edit
        )
    end)
    local auto_resume = livecap_setting(
        "auto_resume_after_preroll",
        true
    )
    add_row(
        "Resume playback automatically after captions are prepared.",
        function(y)
            draw_livecap_toggle_row(
                ass, geo, y, "Auto-resume when ready", auto_resume,
                "set_caption_auto_resume",
                function()
                    stage_livecap_setting(
                        "auto_resume_after_preroll",
                        not auto_resume
                    )
                end,
                can_edit
            )
        end
    )
    local save_srt = livecap_setting("save_srt", false)
    add_row("Also save a growing .live.srt file while live captions run.",
        function(y)
            draw_livecap_toggle_row(
                ass, geo, y, "Save live transcript", save_srt,
                "set_caption_save_srt",
                function() stage_livecap_setting("save_srt", not save_srt) end,
                can_edit
            )
        end)
    local save_mode = livecap_setting("subtitle_save_mode", "cache")
    add_row(
        "Choose whether subtitles are saved beside local videos or in the cache.",
        function(y)
            local use_cache = save_mode == "cache"
            draw_livecap_toggle_row(
                ass, geo, y, "Save to cache folder", use_cache,
                "set_caption_save_location",
                function()
                    stage_livecap_setting(
                        "subtitle_save_mode", use_cache and "auto" or "cache"
                    )
                end,
                can_edit
            )
        end
    )
    local subs_dir = livecap_setting("subs_dir", "")
    add_row("Folder used for cached subtitles. Empty uses the default cache.",
        function(y)
            draw_livecap_text_row(
                ass, geo, y, "Cache folder",
                livecap_text_value(subs_dir, "Default"),
                "set_caption_cache_folder",
                function()
                    start_livecap_edit(
                        "Cache folder (empty = default)", "subs_dir", subs_dir, true
                    )
                end,
                can_edit,
                "subs_dir"
            )
        end)

    add_row("Less commonly changed processing and status options.", function(y)
        draw_caption_action_row(
            ass, geo, y, "Advanced processing options",
            livecap_advanced_open and "Hide" or "Show",
            "set_caption_advanced",
            function()
                livecap_advanced_open = not livecap_advanced_open
                render()
            end,
            livecap_pending_request == nil
        )
    end)
    if livecap_advanced_open then
        add_step_row("Audio batch length", "caption_block_length", 5, 1, 300,
            function(value) return string.format("%.0f s", value) end,
            "How much audio is transcribed together; larger batches may add delay.")
        add_step_row("Translation history", "context_window", 1, 0, 20,
            function(value) return tostring(value) end,
            "Previous subtitle lines used as translation context; 0 disables it.")
        add_step_row("Caption preparation buffer", "prime_seconds", 5, 0, 300,
            function(value) return string.format("%.0f s", value) end,
            "Audio translated before playback resumes after a start or seek.")
        local osd_status = livecap_setting("osd_status", false)
        add_row("Show temporary Live Captions progress and status messages.",
            function(y)
                draw_livecap_toggle_row(
                    ass, geo, y, "Show status messages", osd_status,
                    "set_caption_osd_status",
                    function()
                        stage_livecap_setting("osd_status", not osd_status)
                    end,
                    can_edit
                )
            end)
    end

    local row_count = #rows
    local list_y1 = geo.body_y1 + 4
    local list_y2 = geo.body_y2 - 30
    local viewport_h = list_y2 - list_y1
    local visible_rows = math.max(
        1,
        math.floor((viewport_h + 2) / SET_MENU_ROW_H)
    )
    settings_menu_max_scroll = math.max(0, row_count - visible_rows)
    settings_menu_scroll = math.max(
        0,
        math.min(settings_menu_scroll, settings_menu_max_scroll)
    )

    for index, row in ipairs(rows) do
        local y = list_y1 + (index - 1 - settings_menu_scroll)
            * SET_MENU_ROW_H
        if y >= list_y1 and y + SET_MENU_ROW_H <= list_y2 then
            if mouse_x >= geo.cx1 and mouse_x <= geo.cx2
                and mouse_y >= y and mouse_y < y + SET_MENU_ROW_H then
                hovered_help = row.help
            end
            row.draw(y)
        end
    end

    if livecap_dropdown and dropdown_anchor_y then
        local options = livecap_dropdown.options
        local option_h = math.min(
            SET_MENU_ROW_H,
            math.max(1, math.floor(viewport_h / #options))
        )
        local menu_h = option_h * #options
        local menu_y = dropdown_anchor_y + SET_MENU_ROW_H
        if menu_y + menu_h > list_y2 then
            menu_y = dropdown_anchor_y - menu_h
        end
        menu_y = math.max(list_y1, math.min(menu_y, list_y2 - menu_h))
        local menu_x2 = geo.cx2 - 20
        local menu_x1 = math.max(geo.cx1 + 4, menu_x2 - 270)

        common.draw_rrect(
            ass,
            menu_x1,
            menu_y,
            menu_x2,
            menu_y + menu_h,
            cfg.TRACK_POPUP_RADIUS,
            cfg.TRACK_POPUP_BG,
            cfg.TRACK_POPUP_BG_ALPHA
        )
        add_hitbox(
            "set_livecap_model_dropdown_bg",
            menu_x1,
            menu_y,
            menu_x2,
            menu_y + menu_h,
            function()
                livecap_dropdown = nil
            end
        )

        for index, option in ipairs(options) do
            local selected_option = option
            local option_y = menu_y + (index - 1) * option_h
            local selected = livecap_setting(livecap_dropdown.key, "")
                == selected_option
                or (livecap_setting(livecap_dropdown.key, "") == ""
                    and (
                        (livecap_dropdown.key == "whisper_model"
                            and selected_option == "large-v3-turbo")
                        or (livecap_dropdown.key == "hy_mt2_model"
                            and selected_option == "Hy-MT2-1.8B-Q6_K")
                    ))
            local hovered = mouse_x >= menu_x1 and mouse_x <= menu_x2
                and mouse_y >= option_y and mouse_y < option_y + option_h

            if selected or hovered then
                common.draw_rrect(
                    ass,
                    menu_x1 + 3,
                    option_y + 1,
                    menu_x2 - 3,
                    option_y + option_h - 1,
                    5,
                    selected and cfg.TRACK_BG or cfg.POPUP_HOVER_COLOR,
                    selected and "20" or cfg.POPUP_HOVER_ALPHA
                )
            end
            common.draw_text(
                ass,
                fit_title_to_width(
                    escape_ass_text(option),
                    menu_x2 - menu_x1 - 20,
                    cfg.FONT_SIZE - 1,
                    cfg.UI_FONT
                ),
                menu_x1 + 10,
                option_y + option_h / 2,
                cfg.FONT_SIZE - 1,
                cfg.TRACK_POPUP_TEXT,
                "00",
                4,
                false
            )
            add_hitbox(
                "set_livecap_model_dropdown_option_" .. index,
                menu_x1,
                option_y,
                menu_x2,
                option_y + option_h,
                function()
                    local key = livecap_dropdown.key
                    local current = livecap_setting(key, "")
                    livecap_dropdown = nil
                    if current ~= selected_option then
                        stage_livecap_setting(key, selected_option)
                    end
                end
            )
        end
    end

    if settings_menu_max_scroll > 0 then
        local thumb_h = math.max(
            20,
            viewport_h * visible_rows / row_count
        )
        local thumb_y = list_y1 + (viewport_h - thumb_h)
            * settings_menu_scroll / settings_menu_max_scroll
        common.draw_rrect(
            ass, geo.cx2 - 5, list_y1 + 2, geo.cx2 - 2,
            list_y2 - 2, 2, cfg.TRACK_BG, "30"
        )
        common.draw_rrect(
            ass, geo.cx2 - 6, thumb_y, geo.cx2 - 1,
            thumb_y + thumb_h, 3, cfg.TRACK_FG, "00"
        )
    end

    local help_text
    if ui.job_running then
        help_text = "A subtitle job is running; settings are locked."
    elseif livecap_editor then
        help_text = livecap_editor.label
            .. ": type a replacement; Enter stages it, Done saves, Esc cancels."
    else
        help_text = hovered_help or "Hover over a setting for details."
    end
    help_text = fit_title_to_width(
        escape_ass_text(help_text),
        geo.cx2 - geo.cx1,
        math.max(10, cfg.FONT_SIZE - 5),
        cfg.UI_FONT
    )
    common.draw_text(
        ass,
        help_text,
        geo.cx1,
        geo.body_y2 - 12,
        math.max(10, cfg.FONT_SIZE - 5),
        cfg.TEXT,
        "35",
        4,
        false
    )
end

-- Main unified render
function render_settings_menu(ass, geo)
    local livecap_ui = livecap_ui_state()

    if settings_active_tab ~= "subtitles" and settings_active_tab ~= "video"
        and settings_active_tab ~= "theme"
        and not (livecap_ui.show_settings_tab and settings_active_tab == "captions") then
        settings_active_tab = "video"
    end
    -- Background card
    common.draw_rrect(ass, geo.card_x1, geo.card_y1, geo.card_x2, geo.card_y2,
        cfg.SETTINGS_RADIUS, cfg.SETTINGS_BG, cfg.SETTINGS_BG_ALPHA)
    if cfg.SETTINGS_BORDER_WIDTH > 0 then
        draw_rrect_outline(ass, geo.card_x1, geo.card_y1, geo.card_x2, geo.card_y2,
            cfg.SETTINGS_RADIUS, cfg.SETTINGS_BORDER_COLOR, cfg.SETTINGS_BORDER_ALPHA, cfg.SETTINGS_BORDER_WIDTH)
    end

    -- Header
    common.draw_text(ass, settings_active_tab == "captions"
        and "Live Captions" or "Settings",
        geo.cx1, geo.header_y1 + SET_MENU_HEADER_H / 2,
        cfg.FONT_SIZE + 2, cfg.TEXT, "00", 4, false)
    local close_x1, close_y1 = geo.cx2 - 42, geo.header_y1 + 6
    local close_x2, close_y2 = geo.cx2 + 4, geo.header_y2 - 6
    local close_hovered = settings_control_hovered(close_x1, close_y1, close_x2, close_y2)
    common.draw_text(ass, "×",
        (close_x1 + close_x2) / 2, geo.header_y1 + SET_MENU_HEADER_H / 2,
        21, close_hovered and cfg.TRACK_FG or cfg.ICON_COLOR, "00", 5, false)
    add_hitbox("set_close",
        geo.cx2 - 42, geo.header_y1 + 6,
        geo.cx2 + 4,  geo.header_y2 - 6,
        function()
            if livecap_editor then
                finish_livecap_edit(false)
            end
            if not livecap_pending_request then
                discard_livecap_draft()
            end
            livecap_dropdown = nil
            settings_menu_open  = false
            settings_menu_scroll = 0
        end)
    draw_sep(ass, geo, geo.header_y2)

    -- Tab bar
    -- Tab bar
    local tabs = {
        {id = "subtitles", label = "Subtitles"},
        {id = "video", label = "Video"},
    }

    if livecap_ui.show_settings_tab then
        tabs[#tabs + 1] = {
            id = "captions",
            label = "Captions",
        }
    end

    tabs[#tabs + 1] = {
        id = "theme",
        label = "Theme",
    }
    local tab_w = (geo.cx2 - geo.cx1) / #tabs
    for i, tab in ipairs(tabs) do
        local tx1   = geo.cx1 + (i - 1) * tab_w
        local tx2   = tx1 + tab_w
        local tab_cy = geo.tab_y1 + SET_MENU_TAB_H / 2
        local active = (settings_active_tab == tab.id)
        if active then
            -- Accent underline
            common.draw_rrect(ass, tx1 + 6, geo.tab_y2 - 3, tx2 - 6, geo.tab_y2, 1,
                cfg.TRACK_FG, "00")
        end
        common.draw_text(
            ass,
            fit_title_to_width(
                escape_ass_text(tab.label),
                tab_w - 14,
                cfg.FONT_SIZE - 1,
                cfg.UI_FONT
            ),
            (tx1 + tx2) / 2,
            tab_cy,
            cfg.FONT_SIZE - 1,
            active and cfg.TRACK_FG or cfg.TEXT,
            active and "00" or "40",
            5, false)
        local tid = tab.id
        if not livecap_pending_request then
            add_hitbox("set_tab_" .. i, tx1, geo.tab_y1, tx2, geo.tab_y2,
                function()
                    if livecap_editor then
                        finish_livecap_edit(false)
                    end
                    livecap_dropdown = nil
                    settings_active_tab  = tid
                    settings_menu_scroll = 0
                end)
        end
    end
    draw_sep(ass, geo, geo.tab_y2)

    -- Tab body
    if settings_active_tab == "subtitles" then
        render_subtitles_tab(ass, geo)
    elseif settings_active_tab == "video" then
        render_video_tab(ass, geo)
    elseif settings_active_tab == "captions" then
        render_captions_tab(ass, geo)
    else
        render_theme_tab(ass, geo)
    end

    -- Footer
    draw_sep(ass, geo, geo.footer_y1)

    if settings_active_tab == "captions" then
        local ui = livecap_ui_state()
        local controls_enabled = not ui.job_running
            and livecap_pending_request == nil
        local reset_x1 = geo.cx1
        local reset_x2 = geo.cx1 + 92
        local reset_hovered = controls_enabled
            and settings_control_hovered(
                reset_x1,
                geo.footer_y1,
                reset_x2,
                geo.footer_y2
            )
        common.draw_text(
            ass,
            "Reset",
            (reset_x1 + reset_x2) / 2,
            geo.footer_y1 + SET_MENU_FOOTER_H / 2,
            cfg.FONT_SIZE - 1,
            reset_hovered and cfg.HOVER_ICON_COLOR or cfg.TEXT,
            controls_enabled and "00" or "60",
            5,
            false
        )
        if controls_enabled then
            add_hitbox(
                "set_livecap_reset",
                reset_x1,
                geo.footer_y1,
                reset_x2,
                geo.footer_y2,
                reset_livecap_draft
            )
        end
    elseif settings_active_tab == "theme" then
        local apply_hovered = settings_control_hovered(geo.cx1, geo.footer_y1, geo.cx1 + 120, geo.footer_y2)
        common.draw_text(ass, "Apply",
            geo.cx1 + 60, geo.footer_y1 + SET_MENU_FOOTER_H / 2,
            cfg.FONT_SIZE, (apply_hovered and cfg.HOVER_ICON_COLOR) or cfg.TRACK_FG, "00", 5, false)
        add_hitbox("set_theme_apply", geo.cx1, geo.footer_y1, geo.cx1 + 120, geo.footer_y2,
            function()
                common.reload_theme()
                mp.commandv("script-message-to", "cadre_titlebar", "cadre-theme-reload")
                mp.commandv("script-message-to", "cadre_playlist", "cadre-theme-reload")
                mp.commandv("script-message-to", "cadre_menu", "cadre-theme-reload")
            end)
    elseif settings_active_tab == "subtitles" then
        local reset_hovered = settings_control_hovered(geo.cx1, geo.footer_y1, geo.cx1 + 110, geo.footer_y2)
        common.draw_text(ass, "Reset",
            geo.cx1 + 55, geo.footer_y1 + SET_MENU_FOOTER_H / 2,
            cfg.FONT_SIZE, (reset_hovered and cfg.HOVER_ICON_COLOR) or cfg.TEXT, "35", 5, false)
        add_hitbox("set_sub_reset", geo.cx1, geo.footer_y1, geo.cx1 + 110, geo.footer_y2,
            function()
                mp.set_property_number("sub-delay",        0)
                mp.set_property_number("sub-scale",        1.0)
                mp.set_property_number("sub-pos",          100)
                mp.set_property_number("sub-outline-size", 1.65)
                mp.set_property_number("sub-shadow-offset",0)
            end)
    else
        local reset_hovered = settings_control_hovered(geo.cx1, geo.footer_y1, geo.cx1 + 120, geo.footer_y2)
        common.draw_text(ass, "Reset",
            geo.cx1 + 60, geo.footer_y1 + SET_MENU_FOOTER_H / 2,
            cfg.FONT_SIZE, (reset_hovered and cfg.HOVER_ICON_COLOR) or cfg.TEXT, "35", 5, false)
        add_hitbox("set_vid_reset", geo.cx1, geo.footer_y1, geo.cx1 + 120, geo.footer_y2,
            function()
                mp.set_property_number("speed", 1.0)
                mp.set_property_bool("keepaspect", true)
                mp.set_property("video-unscaled", "no")
                mp.set_property("video-aspect-override", "-1")
            end)
    end

    local done_hovered = settings_control_hovered(
        geo.cx2 - 110,
        geo.footer_y1,
        geo.cx2,
        geo.footer_y2
    )
    local has_caption_draft = next(livecap_draft_settings) ~= nil
    local done_enabled = livecap_pending_request == nil
        and (not has_caption_draft or not livecap_ui_state().job_running)
    common.draw_text(
        ass,
        settings_active_tab == "captions" and livecap_pending_request
            and "Saving…" or "Done",
        geo.cx2 - 55,
        geo.footer_y1 + SET_MENU_FOOTER_H / 2,
        cfg.FONT_SIZE - 1,
        done_hovered and done_enabled and cfg.HOVER_ICON_COLOR
            or cfg.TRACK_FG,
        done_enabled and "00" or "60",
        5,
        false
    )
    if done_enabled then
        add_hitbox(
            "set_done",
            geo.cx2 - 110,
            geo.footer_y1,
            geo.cx2,
            geo.footer_y2,
            function()
                if has_caption_draft then
                    apply_livecap_draft()
                else
                    settings_menu_open  = false
                    settings_menu_scroll = 0
                    discard_livecap_draft()
                end
            end
        )
    end
end

--------------------------------------------------------------------------------
-- MAIN RENDER
--------------------------------------------------------------------------------

function draw_title_text(ass, text, x, y, align, max_width, font_size, color)
    font_size = font_size or cfg.TITLE_SIZE
    color = color or cfg.TITLE_COLOR
    text = fit_title_to_width(escape_ass_text(text), max_width, font_size)
    if text ~= "" then
        draw_effect_text(ass, text, x, y, align, cfg.TITLE_FONT, font_size, color, cfg.TITLE_ALPHA,
            cfg.TITLE_OUTLINE_COLOR, cfg.TITLE_OUTLINE_ALPHA, cfg.TITLE_OUTLINE_WIDTH,
            cfg.TITLE_OUTLINE_BLUR, cfg.TITLE_SHADOW > 0, cfg.TITLE_SHADOW_X, cfg.TITLE_SHADOW_Y,
            cfg.TITLE_SHADOW_COLOR, cfg.TITLE_SHADOW_ALPHA, cfg.TITLE_SHADOW_BLUR)
    end
end

function draw_button_title(ass, button, row_y)
    local title = display_media_title()
    local x, align
    if cfg.TITLE_ALIGN == "left" then
        x = button.x - button.width / 2 + cfg.TITLE_SIDE_INSET
        align = 4
    elseif cfg.TITLE_ALIGN == "right" then
        x = button.x + button.width / 2 - cfg.TITLE_SIDE_INSET
        align = 6
    else
        x = button.x
        align = 5
    end
    draw_title_text(
        ass,
        title,
        x,
        row_y,
        align,
        math.max(0, button.width - cfg.TITLE_SIDE_INSET * 2),
        button.style.font_size,
        button.style.text_color and common.bgr(button.style.text_color) or nil
    )
end

function draw_media_title(ass, L)
    if not cfg.TITLE_ENABLED or L.buttons.by_id.title then
        return
    end
    local title = display_media_title()

    local x, x1, x2, y, align
    local above = cfg.TITLE_POSITION == "above_seekbar" or cfg.TITLE_POSITION == "above_osc"
    if cfg.TITLE_POSITION == "above_seekbar" or cfg.TITLE_POSITION == "below_seekbar" then
        x1, x2 = L.seekbar_x1, L.seekbar_x2
        local gap = above and cfg.TITLE_SEEKBAR_GAP or cfg.TITLE_GAP
        local track_extent = math.max(cfg.THUMB_WH, cfg.SEEKBAR_HEIGHT_HOVER / 2)
        y = L.seekbar_y + (above and -1 or 1) * (track_extent + gap + cfg.TITLE_SIZE / 2)
    else
        x1, x2 = L.pill_x1 + cfg.TITLE_SIDE_INSET, L.pill_x2 - cfg.TITLE_SIDE_INSET
        y = above
            and L.pill_y1 + cfg.TITLE_GAP + cfg.TITLE_SIZE / 2
            or L.pill_y2 - cfg.TITLE_GAP - cfg.TITLE_SIZE / 2
    end

    if cfg.TITLE_ALIGN == "left" then
        x = x1
        align = 4
    elseif cfg.TITLE_ALIGN == "right" then
        x = x2
        align = 6
    else
        x = (x1 + x2) / 2
        align = 5
    end

    draw_title_text(ass, title, x, y, align, x2 - x1)
end

local current_layout = nil

function render()
    hitboxes = common.new_hitboxes()
    local ass = assdraw.ass_new()
    active_ass = ass
    local chapter_tooltip_ass = assdraw.ass_new()
    local w, h = mp.get_osd_size()

    if not bar_visible then
        mp.set_property_native("user-data/cadre_osc/rect", {visible = false})
        common.publish_glass_region("osc", false, nil, w, h, cfg.BAR_RADIUS, GLASS_BLUR_RADIUS)
        publish_popup_glass("track_popup", false, nil, cfg.TRACK_POPUP_RADIUS, cfg.TRACK_POPUP_GLASS_RADIUS)
        publish_popup_glass("volume_popup", false, nil, cfg.VOLUME_POPUP_RADIUS, cfg.VOLUME_POPUP_GLASS_RADIUS)
        publish_popup_glass("add_popup", false, nil, cfg.ADD_POPUP_RADIUS, cfg.ADD_POPUP_GLASS_RADIUS)
        publish_popup_glass("settings_dialog", false, nil, cfg.SETTINGS_RADIUS, cfg.SETTINGS_GLASS_RADIUS)
        render_ctrl:update("", w, h)
        chapter_tooltip_render_ctrl:update("", w, h)
        popup_geo = nil
        add_menu_geo = nil
        last_speed_wheel_bounds_key = "none"
        mp.set_property_native("user-data/cadre_osc/speed-wheel", {visible=false})
		publish_popup()
        return
    end

    position = position or 0
    duration = duration or 0
    volume = volume or 100

    local L = get_layout()
    current_layout = L
    publish_speed_wheel_bounds(L)
    mp.set_property_native("user-data/cadre_osc/rect", {
        visible = true, x1 = L.pill_x1, y1 = L.pill_y1, x2 = L.pill_x2, y2 = L.pill_y2
    })
    common.publish_glass_region(
        "osc", GLASS_BLUR,
        {x1 = L.pill_x1, y1 = L.pill_y1, x2 = L.pill_x2, y2 = L.pill_y2},
        w, h, cfg.BAR_RADIUS, GLASS_BLUR_RADIUS
    )

    ass:new_event()
    ass:append(string.format("{\\pos(0,0)\\an7\\1c&H%s&\\1a&H%s&\\bord0\\shad0}", cfg.BARBG, cfg.ALPHA_BAR_BG))
    ass:draw_start()
    ass:round_rect_cw(L.pill_x1, L.pill_y1, L.pill_x2, L.pill_y2, cfg.BAR_RADIUS)
    ass:draw_stop()

    if cfg.BAR_BORDER_WIDTH > 0 and cfg.BAR_BORDER_ALPHA ~= "FF" then
        ass:new_event()
        ass:append(string.format(
            "{\\pos(0,0)\\an7\\1a&HFF&\\3c&H%s&\\3a&H%s&\\bord%g\\shad0}",
            cfg.BAR_BORDER_COLOR, cfg.BAR_BORDER_ALPHA, cfg.BAR_BORDER_WIDTH
        ))
        ass:draw_start()
        ass:round_rect_cw(L.pill_x1, L.pill_y1, L.pill_x2, L.pill_y2, cfg.BAR_RADIUS)
        ass:draw_stop()
    end

    for _, group in ipairs({"left", "center", "right"}) do
        for _, row in ipairs(group_buttons_by_y(L.buttons[group], L.row_y)) do
            draw_icon_group_background(
                ass,
                row.buttons,
                row.y,
                not row.buttons[1].anchor and
                    (row.buttons[1].row_bounds or L.button_group_bounds[group]) or nil,
                group,
                row.buttons[1].group_style.group
            )
        end
    end

    if cfg.SEEKBAR_ENABLED then
    local hovering_seek =
    (L.track_x2 > L.track_x1
    and mouse_y >= L.seekbar_y - 10
    and mouse_y <= L.seekbar_y + 10
    and mouse_x >= L.track_x1
    and mouse_x <= L.track_x2)
    local bar_x1, bar_x2 = L.track_x1, L.track_x2
    local bar_w = bar_x2 - bar_x1

    local segs = chapter_segments(bar_x1, bar_x2, bar_w, duration)
    local hovered_segment = hovering_seek and cfg.SEEKBAR_HOVER_RESIZE_MODE == "segment"
        and nearest_seekbar_segment(segs, mouse_x) or nil
    local track_heights = {}
    local max_track_h = cfg.SEEKBAR_HEIGHT_NORMAL
    for index = 1, #segs do
        local track_h = hovering_seek and (
            cfg.SEEKBAR_HOVER_RESIZE_MODE == "all" or index == hovered_segment
        ) and cfg.SEEKBAR_HEIGHT_HOVER or cfg.SEEKBAR_HEIGHT_NORMAL
        track_heights[index] = track_h
        max_track_h = math.max(max_track_h, track_h)
    end

    draw_segmented(ass, segs, L.seekbar_y, track_heights, cfg.TRACK_BG, "00")

    local ratio = (duration and duration > 0) and math.min(1, math.max(0, position / duration)) or 0
    local filled_x = bar_x1 + bar_w * ratio
    if filled_x > bar_x1 then
        draw_segmented(ass, segs, L.seekbar_y, track_heights, cfg.TRACK_FG, "00", filled_x)
    end

    draw_chapter_marks(ass, bar_x1, bar_x2, bar_w, L.seekbar_y, max_track_h, duration)

    draw_segmented_outline(
        ass,
        segs,
        L.seekbar_y,
        track_heights,
        cfg.SEEKBAR_BORDER_COLOR,
        cfg.SEEKBAR_BORDER_ALPHA,
        cfg.SEEKBAR_BORDER_WIDTH
    )

    common.draw_rrect(
        ass,
        filled_x - cfg.THUMB_WW,
        L.seekbar_y - cfg.THUMB_WH,
        filled_x + cfg.THUMB_WW,
        L.seekbar_y + cfg.THUMB_WH,
        cfg.THUMB_WRADIUS,
        cfg.THUMB_WCOLOR,
        "00"
    )
    draw_rrect_outline(
        ass,
        filled_x - cfg.THUMB_WW,
        L.seekbar_y - cfg.THUMB_WH,
        filled_x + cfg.THUMB_WW,
        L.seekbar_y + cfg.THUMB_WH,
        cfg.THUMB_WRADIUS,
        cfg.THUMB_WBORDER_COLOR,
        cfg.THUMB_WBORDER_ALPHA,
        cfg.THUMB_WBORDER_WIDTH
    )

    if hovering_seek and cfg.CHAPTER_TOOLTIP and hovered_chapter and hovered_chapter.title then
        local chapter_label = hovered_chapter.title
        if cfg.SEEKBAR_TIME_TOOLTIP and duration > 0 then
            local hover_time = math.min(duration, math.max(0, (mouse_x - bar_x1) / bar_w * duration))
            chapter_label = chapter_label .. "  |  " .. fmt_time(hover_time)
        end
        local text_w = measure_text_width(
            chapter_label,
            cfg.CHAPTER_TOOLTIP_FONT_SIZE,
            cfg.CHAPTER_TOOLTIP_FONT
        )

        text_w = text_w + 2

        local pad_x = cfg.CHAPTER_TOOLTIP_PAD_X or 0
        local pad_y = cfg.CHAPTER_TOOLTIP_PAD_Y or 3

        local pill_w = text_w + pad_x * 2
        local pill_h = cfg.CHAPTER_TOOLTIP_FONT_SIZE + pad_y * 2

        local edge_gap = math.min(6, screen_w / 2)
        local max_pill_w = math.max(0, screen_w - edge_gap * 2)
        pill_w = math.min(pill_w, max_pill_w)

        local half_w = pill_w / 2
        local target_x = math.min(
            screen_w - half_w - edge_gap,
            math.max(edge_gap + half_w, mouse_x)
        )

        local tooltip_y1
        local tooltip_gap = 10
        local below_space = screen_h - L.seekbar_y - tooltip_gap
        local above_space = L.seekbar_y - tooltip_gap
        local place_below = below_space >= pill_h and above_space < pill_h

        if L.seekbar_anchor_space ~= "window" and cfg.BAR_Y_ANCHOR == "bottom" then
            tooltip_y1 = osc_panel_top_y() - pill_h - tooltip_gap + cfg.TRACK_POPUP_OFFSET_Y
        elseif place_below then
            tooltip_y1 = L.seekbar_y
                + math.max(cfg.THUMB_WH, cfg.SEEKBAR_HEIGHT_HOVER / 2)
                + tooltip_gap
        else
            tooltip_y1 = L.seekbar_y - math.max(cfg.THUMB_WH, cfg.SEEKBAR_HEIGHT_HOVER / 2)
                - pill_h - tooltip_gap
        end
        tooltip_y1 = tooltip_y1 + cfg.SEEKBAR_TIME_TOOLTIP_OFFSET_Y
        local center_y = tooltip_y1 + pill_h / 2

        local box_x1 = target_x - half_w
        local box_x2 = target_x + half_w
        local box_y1 = center_y - pill_h / 2
        local box_y2 = center_y + pill_h / 2

        common.draw_rrect(
            chapter_tooltip_ass,
            box_x1,
            box_y1,
            box_x2,
            box_y2,
            cfg.CHAPTER_TOOLTIP_RADIUS,
            cfg.CHAPTER_TOOLTIP_BG_COLOR,
            cfg.CHAPTER_TOOLTIP_BG_ALPHA
        )
        common.draw_text(
            chapter_tooltip_ass,
            chapter_label,
            target_x,
            center_y,
            cfg.CHAPTER_TOOLTIP_FONT_SIZE,
            cfg.CHAPTER_TOOLTIP_FONT_COLOR,
            cfg.CHAPTER_TOOLTIP_FONT_ALPHA,
            5,
            false,
            cfg.CHAPTER_TOOLTIP_FONT
        )
    end
    if hovering_seek and cfg.SEEKBAR_TIME_TOOLTIP and duration > 0
        and not (cfg.CHAPTER_TOOLTIP and hovered_chapter and hovered_chapter.title) then
        local seekbar_time = math.min(duration, math.max(0, (mouse_x - bar_x1) / bar_w * duration))
        local label = fmt_time(seekbar_time)
        local text_w = measure_text_width(label, cfg.SEEKBAR_TIME_TOOLTIP_SIZE, cfg.SEEKBAR_TIME_TOOLTIP_FONT) + 2
        local pill_w = text_w + cfg.SEEKBAR_TIME_TOOLTIP_PAD_X * 2
        local pill_h = cfg.SEEKBAR_TIME_TOOLTIP_SIZE + cfg.SEEKBAR_TIME_TOOLTIP_PAD_Y * 2
        local half_w = pill_w / 2
        local target_x = math.min(bar_x2 - half_w - 6, math.max(bar_x1 + half_w + 6, mouse_x))
        local tooltip_y1
        local tooltip_gap = 10
        local below_space = screen_h - L.seekbar_y - tooltip_gap
        local above_space = L.seekbar_y - tooltip_gap
        local place_below = below_space >= pill_h and above_space < pill_h

        if L.seekbar_anchor_space ~= "window" and cfg.BAR_Y_ANCHOR == "bottom" then
            tooltip_y1 = osc_panel_top_y() - pill_h - tooltip_gap + cfg.TRACK_POPUP_OFFSET_Y
        elseif place_below then
            tooltip_y1 = L.seekbar_y
                + math.max(cfg.THUMB_WH, cfg.SEEKBAR_HEIGHT_HOVER / 2)
                + tooltip_gap
        else
            tooltip_y1 = L.seekbar_y - math.max(cfg.THUMB_WH, cfg.SEEKBAR_HEIGHT_HOVER / 2)
                - pill_h - tooltip_gap
        end
        tooltip_y1 = tooltip_y1 + cfg.SEEKBAR_TIME_TOOLTIP_OFFSET_Y
        local center_y = tooltip_y1 + pill_h / 2
        common.draw_rrect(
            chapter_tooltip_ass,
            target_x - half_w, center_y - pill_h / 2,
            target_x + half_w, center_y + pill_h / 2,
            cfg.SEEKBAR_TIME_TOOLTIP_RADIUS,
            cfg.SEEKBAR_TIME_TOOLTIP_BG_COLOR,
            cfg.SEEKBAR_TIME_TOOLTIP_BG_ALPHA
        )
        common.draw_text(
            chapter_tooltip_ass, label, target_x, center_y,
            cfg.SEEKBAR_TIME_TOOLTIP_SIZE, cfg.SEEKBAR_TIME_TOOLTIP_COLOR,
            cfg.SEEKBAR_TIME_TOOLTIP_ALPHA, 5, false, cfg.SEEKBAR_TIME_TOOLTIP_FONT
        )
    end
    if bar_w > 0 then
        add_hitbox(
            "seekbar",
            bar_x1,
            L.seekbar_y - 10,
            bar_x2,
            L.seekbar_y + 10,
            function(px)
                seekbar_dragging = true
                if duration and duration > 0 then
                    local r = (px - bar_x1) / bar_w
                    mp.commandv("seek", math.min(1, math.max(0, r)) * duration, "absolute")
                end
            end
        )
    end
    end

    local hovered_button_tooltip = nil
    local hovered_button_tooltip_x, hovered_button_tooltip_y
    for _, group in ipairs({"left", "center", "right"}) do
        for _, button in ipairs(L.buttons[group]) do
            local definition = BUTTONS[button.id]
            local button_y = button.y or L.row_y
            local button_style = button.style or {}
            if definition.kind ~= "seekbar" and definition.kind ~= "separator" then
                local button_decoration_style = button.group_style.button
                local visual_button_width = button.width
                local icon_hoverable = definition.kind == nil
                    local is_volume_slider = definition.kind == "volume_slider"
                    local has_slider_hover_override = button.style.hover_icon_color ~= nil
                        or button.style.hover_bg_color ~= nil
                        or button.style.hover_bg_alpha ~= nil
                        or button.style.hover_scale ~= nil
                        or button.style.hover_border ~= nil
                        or button.style.hover_border_color ~= nil
                        or button.style.hover_border_alpha ~= nil
                        or button.style.hover_border_width ~= nil
                        or button.style.hover_radius ~= nil
                local button_hoverable = definition.kind ~= "title" and definition.kind ~= "time"
                        and definition.kind ~= "separator"
                        and (not is_volume_slider or has_slider_hover_override)
                local decoration = item_decoration_bounds(
                    button.x,
                    button_y,
                    button.width,
                    button_decoration_style
                )
                local hover_half_w = math.max(16, button.width / 2)
                local hover_half_h = math.max(16, button.height / 2)
                if decoration.background or decoration.border then
                    hover_half_w = math.max(
                        hover_half_w,
                        button.x - decoration.visual_x1,
                        decoration.visual_x2 - button.x
                    )
                    hover_half_h = math.max(
                        hover_half_h,
                        button_y - decoration.visual_y1,
                        decoration.visual_y2 - button_y
                    )
                end
                local is_button_hovered = button_hoverable
                    and mouse_x >= button.x - hover_half_w and mouse_x <= button.x + hover_half_w
                    and mouse_y >= button_y - hover_half_h and mouse_y <= button_y + hover_half_h
                if is_button_hovered then
                    if definition.tooltip then
                        hovered_button_tooltip = definition.tooltip
                        hovered_button_tooltip_x = button.x
                        hovered_button_tooltip_y = button_y
                    end
                    local hover_icon_color = is_volume_slider
                        and button.style.hover_icon_color
                        or (not is_volume_slider and (button.style.hover_icon_color or cfg.HOVER_ICON_COLOR))
                    local hover_bg_color = is_volume_slider
                        and button.style.hover_bg_color
                        or (not is_volume_slider and (button.style.hover_bg_color or cfg.HOVER_BG_COLOR))
                    local hover_bg_alpha = is_volume_slider
                        and button.style.hover_bg_alpha
                        or (not is_volume_slider and (button.style.hover_bg_alpha or cfg.HOVER_BG_ALPHA))
                    local hover_scale = icon_hoverable
                        and (button.style.hover_scale or cfg.HOVER_SCALE) or 1
                    local hover_border = button.style.hover_border
                    if hover_border == nil and not is_volume_slider then
                        hover_border = cfg.HOVER_BORDER
                    end
                    local hover_border_color = is_volume_slider
                        and button.style.hover_border_color
                        or (not is_volume_slider and (button.style.hover_border_color or cfg.HOVER_BORDER_COLOR))
                    local hover_border_alpha = is_volume_slider
                        and button.style.hover_border_alpha
                        or (not is_volume_slider and (button.style.hover_border_alpha or cfg.HOVER_BORDER_ALPHA))
                    local hover_border_width = is_volume_slider
                        and button.style.hover_border_width
                        or (not is_volume_slider and (button.style.hover_border_width or cfg.HOVER_BORDER_WIDTH))
                    local hover_radius = button.style.hover_radius

                    if hover_icon_color or hover_bg_color or hover_border
                        or hover_scale ~= 1 or hover_radius ~= nil then
                        local hover_button_style = {}
                        for key, value in pairs(button_style) do
                            hover_button_style[key] = value
                        end
                        if hover_bg_color then
                            button_decoration_style = {}
                            for key, value in pairs(button.group_style.button) do
                                button_decoration_style[key] = value
                            end
                            button_decoration_style.background = true
                            button_decoration_style.color = common.bgr(hover_bg_color)
                            button_decoration_style.alpha = hover_bg_alpha
                        else
                            button_decoration_style = {}
                            for key, value in pairs(button.group_style.button) do
                                button_decoration_style[key] = value
                            end
                        end
                        if hover_scale ~= 1 then
                            visual_button_width = button.width * hover_scale
                            button_decoration_style.padding = button_decoration_style.padding * hover_scale
                            button_decoration_style.height = button_decoration_style.height * hover_scale
                            if hover_radius == nil then
                                button_decoration_style.radius = button_decoration_style.radius * hover_scale
                            end
                            hover_button_style.icon_size = (button.style.icon_size or cfg.ICON_SIZE) * hover_scale
                        end
                        if hover_radius ~= nil then
                            button_decoration_style.radius = hover_radius
                        end
                        if hover_border then
                            button_decoration_style.border = true
                            button_decoration_style.border_color = common.bgr(hover_border_color)
                            button_decoration_style.border_alpha = hover_border_alpha
                            button_decoration_style.border_width = hover_border_width
                        end
                        if hover_icon_color then
                            hover_button_style.icon_color = hover_icon_color
                        end
                        button_style = hover_button_style
                    end
                end
                draw_item_background(
                    ass,
                    button.x,
                    button_y,
                    visual_button_width,
                    button_decoration_style
                )
                draw_item_border(
                    ass,
                    button.x,
                    button_y,
                    visual_button_width,
                    button_decoration_style
                )
            end

            if definition.kind == "separator" then
                local separator_style = button.group_style and button.group_style.button or {}
                local sw = button.style.width or separator_style.separator_width or cfg.SEPARATOR_WIDTH
                local sh = button.style.height or separator_style.separator_height or cfg.SEPARATOR_HEIGHT
                local separator_radius = math.min(
                    button.style.radius or separator_style.separator_radius or cfg.SEPARATOR_RADIUS,
                    sw / 2,
                    sh / 2
                )
                common.draw_rrect(ass, button.x - sw / 2, button_y - sh / 2,
                    button.x + sw / 2, button_y + sh / 2, separator_radius,
                    button.style.color or cfg.ICON_COLOR, button.style.alpha or "60")
            elseif definition.kind == "title" then
                draw_button_title(ass, button, button_y)
            elseif definition.kind ~= "seekbar" then
                if definition.kind == "time" then
                    draw_time_label(
                        ass,
                        fmt_time(position) .. " / " .. fmt_time(duration),
                        button.x,
                        button_y,
                        5,
                        button_style.font_size,
                        button_style.text_color and common.bgr(button_style.text_color) or nil
                    )
                elseif definition.kind == "volume_slider" then
                    draw_volume_slider(ass, button.x, button_y, button_style, button.icon_style)
                elseif definition.kind == "speed_control_wheel" then
                    draw_speed_control_wheel(ass, button)
                else
                    local glyph = type(definition.icon) == "function" and definition.icon() or definition.icon
                    local alpha = definition.alpha and definition.alpha() or cfg.ICON_DIM_A
                    draw_icon(
                        ass,
                        glyph,
                        button.x,
                        button_y,
                        button_style.icon_size or cfg.ICON_SIZE,
                        button_style.icon_color and common.bgr(button_style.icon_color) or cfg.ICON_COLOR,
                        alpha,
                        button.icon_style
                    )
                end
            end

            local hitbox_half_w = math.max(16, button.width / 2)
            local hitbox_half_h = math.max(16, button.height / 2)
            if definition.kind ~= "seekbar" then
                local decoration = item_decoration_bounds(
                    button.x,
                    button_y,
                    button.width,
                    button.group_style.button
                )
                if decoration.background or decoration.border then
                    hitbox_half_w = math.max(
                        hitbox_half_w,
                        button.x - decoration.visual_x1,
                        decoration.visual_x2 - button.x
                    )
                    hitbox_half_h = math.max(
                        hitbox_half_h,
                        button_y - decoration.visual_y1,
                        decoration.visual_y2 - button_y
                    )
                end
            end

            if definition.kind ~= "seekbar" and definition.kind ~= "title"
                and definition.kind ~= "separator" then
                if definition.kind == "speed_control_wheel" then
                    local geo = speed_wheel_geometry(button)
                    add_hitbox("button_speed_control_wheel", geo.x1, geo.y1, geo.x2, geo.y2,
                        function(px, py) begin_speed_wheel_drag(px, py, button) end)
                elseif definition.kind == "volume_slider" and cfg.VOLUME_SLIDER_MUTE then
                    local mute_width = math.max(cfg.VOLUME_SLIDER_MUTE_WIDTH, button.style.icon_size or 0)
                    local total_item_width = button.width
                    local mute_x = button.x - total_item_width / 2 + mute_width / 2 + cfg.VOLUME_SLIDER_PAD_LEFT

                    add_hitbox(
                        "button_volume_slider_mute",
                        mute_x - mute_width / 2,
                        button_y - hitbox_half_h,
                        mute_x + mute_width / 2,
                        button_y + hitbox_half_h,
                        function()
                            mp.commandv("cycle", "mute")
                        end
                    )

                    local geo = get_volume_slider_geometry(button)

                    add_hitbox(
                        "button_volume_slider_track",
                        geo.slider_x1 - cfg.VOLUME_SLIDER_THUMB_WIDTH - 4,
                        button_y - hitbox_half_h,
                        geo.slider_x2 + cfg.VOLUME_SLIDER_THUMB_WIDTH + 4,
                        button_y + hitbox_half_h,
                        function(px, py)
                            definition.click(px, py, button)
                        end
                    )
                else
                    add_hitbox(
                        "button_" .. button.id,
                        button.x - hitbox_half_w,
                        button_y - hitbox_half_h,
                        button.x + hitbox_half_w,
                        button_y + hitbox_half_h,
                        function(px, py)
                            definition.click(px, py, button)
                        end
                    )
                end
            end
        end
    end

    if cfg.BUTTON_TOOLTIP and hovered_button_tooltip then
    local tooltip_size = cfg.CHAPTER_TOOLTIP_FONT_SIZE
    local tooltip_height =
        tooltip_size + cfg.CHAPTER_TOOLTIP_PAD_Y * 2

    local tooltip_width =
        #hovered_button_tooltip * tooltip_size * 0.58
        + cfg.CHAPTER_TOOLTIP_PAD_X * 2

    local half_width = tooltip_width / 2
    local half_height = tooltip_height / 2

    local screen_margin = 6
    local button_half_height = 30
    local tooltip_gap = 10

    -- Keep the tooltip horizontally inside the window where it fits.
    local tooltip_x = w / 2
    if tooltip_width <= w - screen_margin * 2 then
            tooltip_x = math.min(
                w - half_width - screen_margin,
                math.max(
                    half_width + screen_margin,
                    hovered_button_tooltip_x
                )
            )
        end

        -- Positive configured offset increases separation.
        -- Clamp the gap so a negative offset cannot cause overlap.
        local separation = math.max(
            tooltip_gap,
            tooltip_gap + (cfg.CHAPTER_TOOLTIP_OFFSET_Y or 0)
        )

        local button_top =
            hovered_button_tooltip_y - button_half_height
        local button_bottom =
            hovered_button_tooltip_y + button_half_height

        -- Tooltip bottom edge sits above the button.
        local tooltip_y =
            button_top - separation - half_height

        -- Near the top of the window, place it below instead.
        if tooltip_y - half_height < screen_margin then
            tooltip_y =
                button_bottom + separation + half_height
        end

        common.draw_rrect(
            ass,
            tooltip_x - half_width,
            tooltip_y - half_height,
            tooltip_x + half_width,
            tooltip_y + half_height,
            cfg.CHAPTER_TOOLTIP_RADIUS,
            cfg.CHAPTER_TOOLTIP_BG_COLOR,
            cfg.CHAPTER_TOOLTIP_BG_ALPHA
        )

        common.draw_text(
            ass,
            hovered_button_tooltip,
            tooltip_x,
            tooltip_y,
            tooltip_size,
            cfg.CHAPTER_TOOLTIP_FONT_COLOR,
            cfg.CHAPTER_TOOLTIP_FONT_ALPHA,
            5,
            false,
            cfg.CHAPTER_TOOLTIP_FONT
        )
    end

    local title_below_seekbar = cfg.TITLE_ENABLED and
        cfg.TITLE_POSITION == "below_seekbar" and
        not L.buttons.by_id.title
    local time_label_above = cfg.TIME_LABEL_POSITION == "above_seekbar" or
        (cfg.TIME_LABEL_POSITION == "auto" and title_below_seekbar)
    local time_label_y = cfg.TIME_LABEL_POSITION == "inline" and L.seekbar_y or
        L.seekbar_y + (time_label_above and -(cfg.TIME_LABEL_OFFSET_Y + 3) or (cfg.TIME_LABEL_OFFSET_Y + 3))
    if cfg.SEEKBAR_ENABLED and (cfg.SEEKBAR_START_LABEL or cfg.SEEKBAR_END_LABEL) and not L.buttons.by_id.time then
        local label_x1, label_x2 = L.track_x1, L.track_x2
        if cfg.TIME_LABEL_POSITION == "inline" then
            label_x1, label_x2 = L.seekbar_x1, L.seekbar_x2
        end
        if cfg.SEEKBAR_START_LABEL then
            draw_time_label(ass, fmt_time(position), label_x1, time_label_y, 4)
        end
        if cfg.SEEKBAR_END_LABEL then
            draw_time_label(ass, fmt_time(duration), label_x2, time_label_y, 6)
        end
    end
    draw_media_title(ass, L)

    local volume_button = volume_popup_slot and L.buttons.by_slot[volume_popup_slot]
    if volume_popup_open and volume_button and volume_button.id == "volume" then
        popup_geo = compute_popup_geo(volume_button)
        publish_popup_glass("volume_popup", cfg.VOLUME_POPUP_GLASS, popup_geo, cfg.VOLUME_POPUP_RADIUS, cfg.VOLUME_POPUP_GLASS_RADIUS)
        render_volume_popup(ass, popup_geo)
    else
        volume_popup_open = false
        volume_popup_slot = nil
        popup_geo = nil
        publish_popup_glass("volume_popup", false, nil, cfg.VOLUME_POPUP_RADIUS, cfg.VOLUME_POPUP_GLASS_RADIUS)
    end

    local speed_button = speed_popup_slot and L.buttons.by_slot[speed_popup_slot]
    if speed_popup_open and speed_button and speed_button.id == "speed_control" then
        speed_popup_geo = compute_speed_popup_geo(speed_button)
        publish_popup_glass("speed_popup", cfg.TRACK_POPUP_GLASS, speed_popup_geo, cfg.TRACK_POPUP_RADIUS, cfg.TRACK_POPUP_GLASS_RADIUS)
        render_speed_popup(ass, speed_popup_geo)
    else
        speed_popup_open = false
        speed_popup_slot = nil
        speed_popup_geo = nil
        publish_popup_glass("speed_popup", false, nil, cfg.TRACK_POPUP_RADIUS, cfg.TRACK_POPUP_GLASS_RADIUS)
    end

    local add_button = add_menu_slot and L.buttons.by_slot[add_menu_slot]
    if add_menu_open and add_button and add_button.id == "add" then
        add_menu_geo = compute_add_menu_geo(add_button)
        publish_popup_glass("add_popup", cfg.ADD_POPUP_GLASS, add_menu_geo, cfg.ADD_POPUP_RADIUS, cfg.ADD_POPUP_GLASS_RADIUS)
        render_add_menu(ass, add_menu_geo)
    else
        add_menu_open = false
        add_menu_slot = nil
        add_menu_geo = nil
        publish_popup_glass("add_popup", false, nil, cfg.ADD_POPUP_RADIUS, cfg.ADD_POPUP_GLASS_RADIUS)
    end

    if settings_menu_open then
        settings_menu_geo = compute_settings_menu_geo()
        publish_popup_glass("settings_dialog", cfg.SETTINGS_GLASS, settings_menu_geo, cfg.SETTINGS_RADIUS, cfg.SETTINGS_GLASS_RADIUS)
        render_settings_menu(ass, settings_menu_geo)
    else
        settings_menu_open = false
        settings_menu_geo = nil
        publish_popup_glass("settings_dialog", false, nil, cfg.SETTINGS_RADIUS, cfg.SETTINGS_GLASS_RADIUS)
    end

    local track_button = track_popup_slot and L.buttons.by_slot[track_popup_slot]
    if track_popup_open and track_button and track_button.id == (track_popup_type == "audio" and "audio_list" or track_popup_type == "chapters" and "chapter_list" or "subtitle_list") then
        local all_tracks = track_popup_type == "chapters" and (mp.get_property_native("chapter-list", {}) or {}) or mp.get_property_native("track-list", {})
        local count = track_popup_type == "sub" and 1 or 0
        if track_popup_type == "chapters" then count = #all_tracks else
            for _, track in ipairs(all_tracks) do
                if track.type == track_popup_type then count = count + 1 end
            end
        end
        track_popup_geo = compute_track_popup_geo(track_button, count)
        publish_popup_glass("track_popup", cfg.TRACK_POPUP_GLASS, track_popup_geo, cfg.TRACK_POPUP_RADIUS, cfg.TRACK_POPUP_GLASS_RADIUS)
        render_track_popup(ass, track_popup_geo)
    else
        track_popup_open = false
        track_popup_slot = nil
        track_popup_geo = nil
        publish_popup_glass("track_popup", false, nil, cfg.TRACK_POPUP_RADIUS, cfg.TRACK_POPUP_GLASS_RADIUS)
    end

	publish_popup()
    render_ctrl:update(ass.text, w, h)
    chapter_tooltip_render_ctrl:update(chapter_tooltip_ass.text, w, h)
end

common.on_theme_reload(function(updated)
    apply_theme(updated)
    normalize_group_widths()
    render_ctrl:invalidate_ass_cache()
    chapter_tooltip_render_ctrl:invalidate_ass_cache()
    invalidate_layout()
    render()
end)
mp.register_script_message("cadre-theme-reload", function() common.reload_theme() end)

mp.observe_property("user-data/cadre_subs/available", "native", function()
    if track_popup_open and track_popup_type == "sub" then
        render()
    end
end)

mp.observe_property("track-list", "native", function()
    if track_popup_open and track_popup_type == "sub" then
        render()
    end
end)

local function handle_livecap_setting_result(value)
    local result = type(value) == "table" and value
        or utils.parse_json(value or "")
    local pending = livecap_pending_request
    if type(result) ~= "table" or not pending
        or result.request_id ~= pending.request_id then
        return
    end
    finish_livecap_settings_request(
        result.success == true,
        result.error
    )
end

mp.register_script_message(
    "cadre-livecap-settings-result",
    handle_livecap_setting_result
)

mp.observe_property(
    "user-data/livecap/setting-result",
    "string",
    function(_, value)
        handle_livecap_setting_result(value)
    end
)

mp.observe_property(
    "user-data/livecap/status",
    "string",
    function(_, value)
        local status = utils.parse_json(value or "")
        local pending = livecap_pending_request
        local matched_result = type(status) == "table"
            and pending ~= nil
            and status.request_id == pending.request_id
            and (status.setting_saved ~= nil
                or status.setting_error ~= nil)
        if matched_result then
            finish_livecap_settings_request(
                status.setting_saved ~= nil,
                status.message
            )
        elseif type(status) == "table" and status.setting_saved then
            common.reload_conf()
        elseif type(status) == "table" and status.setting_error then
            mp.osd_message(
                status.message or "Could not save Live Captions setting",
                4
            )
        end
        if (track_popup_open and track_popup_type == "sub")
            or settings_menu_open then
            render()
        end
    end
)

mp.observe_property(
    "user-data/cadre_livecap/enabled",
    "native",
    function()
        if (track_popup_open and track_popup_type == "sub")
            or settings_menu_open then
            render()
        end
    end
)

mp.observe_property(
    "user-data/cadre_livecap/loaded",
    "native",
    function(_, loaded)
        if not loaded and livecap_editor then
            finish_livecap_edit(false)
        end
        if (track_popup_open and track_popup_type == "sub")
            or settings_menu_open then
            render()
        end
    end
)

function schedule_render()
    if render_timer then
        return -- Already scheduled
    end
    render_timer = mp.add_timeout(
        0.016, -- ~60fps frame time
        function()
            render_timer = nil
            render()
        end
    )
end


--------------------------------------------------------------------------------
-- VISIBILITY
--------------------------------------------------------------------------------

function point_in_layout_controls(L, px, py, padding)
    padding = padding or 0
    for _, group in ipairs({"left", "center", "right"}) do
        for _, button in ipairs(L.buttons[group]) do
            if px >= button.x - button.width / 2 - padding
                and px <= button.x + button.width / 2 + padding
                and py >= button.y - button.height / 2 - padding
                and py <= button.y + button.height / 2 + padding then
                return true
            end
        end
    end
    return L.track_x2 > L.track_x1
        and px >= L.track_x1 - padding and px <= L.track_x2 + padding
        and py >= L.seekbar_y - 10 - padding and py <= L.seekbar_y + 10 + padding
end

function mouse_in_active_zone()
    if volume_dragging or volume_slider_dragging then
        return true
    end

    local L = current_layout
    if not L then
        L = get_layout()
        current_layout = L
    end
    if point_in_layout_controls(L, mouse_x, mouse_y, 20) then
        return true
    end
    if mouse_y >= L.pill_y1 - 20
        and mouse_y <= L.pill_y2 + 20
        and mouse_x >= L.pill_x1 - 20
        and mouse_x <= L.pill_x2 + 20 then
        return true
    end

    if popup_geo
        and mouse_x >= popup_geo.card_x1 - 14
        and mouse_x <= popup_geo.card_x2 + 14
        and mouse_y >= popup_geo.card_y1 - 14
        and mouse_y <= popup_geo.card_y2 + 14 then
        return true
    end

    if track_popup_geo
        and mouse_x >= track_popup_geo.card_x1 - 14
        and mouse_x <= track_popup_geo.card_x2 + 14
        and mouse_y >= track_popup_geo.card_y1 - 14
        and mouse_y <= track_popup_geo.card_y2 + 14 then
        return true
    end

    if speed_popup_geo and mouse_x >= speed_popup_geo.card_x1 - 14 and mouse_x <= speed_popup_geo.card_x2 + 14
        and mouse_y >= speed_popup_geo.card_y1 - 14 and mouse_y <= speed_popup_geo.card_y2 + 14 then
        return true
    end

    if add_menu_geo
        and mouse_x >= add_menu_geo.card_x1 - 14
        and mouse_x <= add_menu_geo.card_x2 + 14
        and mouse_y >= add_menu_geo.card_y1 - 14
        and mouse_y <= add_menu_geo.card_y2 + 14 then
        return true
    end

    if settings_menu_geo
        and mouse_x >= settings_menu_geo.card_x1 - 10
        and mouse_x <= settings_menu_geo.card_x2 + 10
        and mouse_y >= settings_menu_geo.card_y1 - 10
        and mouse_y <= settings_menu_geo.card_y2 + 10 then
        return true
    end

    return false
end

function restart_hide_timer()
    if hide_timer then
        hide_timer:kill()
        hide_timer = nil
    end
    if bar_pinned or not bar_visible or idle_active or (cfg.SHOW_PANEL_ON_PAUSE == true and paused) then
        return
    end
    hide_timer =
        mp.add_timeout(
        cfg.AUTOHIDE_SEC,
        function()
            hide_timer = nil
            if bar_pinned then
                return
            end
            if volume_dragging or volume_slider_dragging or speed_dragging or speed_inline_dragging
                or mouse_in_active_zone() then
                restart_hide_timer()
            else
                bar_visible = false
                volume_popup_open = false
                speed_popup_open = false
                add_menu_open = false
                render()
            end
        end
    )
end

function show_bar()
    if not bar_visible then
        bar_visible = true
        render()
    end
    restart_hide_timer()
end

toggle_osc_pin = function()
    bar_pinned = not bar_pinned
    if bar_pinned then
        show_bar()
    elseif bar_visible then
        restart_hide_timer()
    end
    render()
end

function set_pip_property(name, value)
    local ok, err
    if type(value) == "number" then
        ok, err = mp.set_property_number(name, value)
    elseif type(value) == "boolean" then
        ok, err = mp.set_property_bool(name, value)
    else
        ok, err = mp.set_property(name, value)
    end
    if not ok then
        msg.warn("cadre_osc: could not set " .. name .. " for picture-in-picture: " .. tostring(err))
        return false
    end
    return true
end

function restore_picture_in_picture()
    if not pip_state then
        return
    end

    local state = pip_state
    pip_state = nil
    set_pip_property("window-scale", state.window_scale)
    set_pip_property("geometry", state.geometry)
    set_pip_property("ontop", state.ontop)
    if state.maximized then
        set_pip_property("window-maximized", true)
    end
    render()
end

toggle_picture_in_picture = function()
    if pip_state then
        restore_picture_in_picture()
        return
    end

    if mp.get_property_bool("fullscreen", false) then
        msg.warn("cadre_osc: exit fullscreen before entering picture-in-picture")
        return
    end

    local window_scale = mp.get_property_number("window-scale")
    if not window_scale or window_scale <= 0 then
        msg.warn("cadre_osc: cannot enter picture-in-picture without a valid window-scale")
        return
    end

    local state = {
        window_scale = window_scale,
        geometry = mp.get_property("geometry") or "",
        ontop = mp.get_property_bool("ontop", false),
        maximized = mp.get_property_bool("window-maximized", false),
    }
    pip_state = state

    if state.maximized and not set_pip_property("window-maximized", false) then
        pip_state = nil
        return
    end
    if not set_pip_property("window-scale", window_scale * cfg.PIP_SCALE)
        or not set_pip_property("geometry", string.format("-%d-%d", cfg.PIP_MARGIN, cfg.PIP_MARGIN))
        or not set_pip_property("ontop", true) then
        restore_picture_in_picture()
        return
    end
    render()
end

function toggle_bar()
    if bar_visible then
        if livecap_editor then
            finish_livecap_edit(false)
        end
        if hide_timer then
            hide_timer:kill()
        end
        bar_visible = false
        volume_popup_open = false
        speed_popup_open = false
        add_menu_open = false
        settings_menu_open = false
        settings_menu_geo = nil
        settings_menu_scroll = 0
        render()
    else
        show_bar()
    end
end

toggle_settings_menu = function()
    if not bar_visible and not settings_menu_open then
        show_bar()
    end
    local opening = not settings_menu_open
    if opening and livecap_editor then
        finish_livecap_edit(false)
    end
    settings_menu_open = opening
    if settings_menu_open then
        common.reload_conf()
    elseif not livecap_pending_request then
        discard_livecap_draft()
    end
    volume_popup_open = false
    speed_popup_open = false
    add_menu_open = false
    track_popup_open = false
    if settings_menu_open then
        settings_active_tab = "video"
        settings_menu_scroll = 0
    else
        settings_menu_geo = nil
    end
    render()
end

open_track_picker = function(track_type, button)
    if not bar_visible then
        show_bar()
    end
    track_popup_open = not track_popup_open or track_popup_type ~= track_type
    track_popup_type = track_type
    track_popup_slot = track_popup_open and button and button.slot or nil
    track_popup_scroll = 0
    settings_menu_open = false
    volume_popup_open = false
    volume_popup_slot = nil
    add_menu_open = false
    add_menu_slot = nil
    add_menu_geo = nil
    render()
end

mp.register_script_message("cadre-osc-toggle", toggle_bar)
mp.register_script_message("cadre-toggle-osc-pin", toggle_osc_pin)
mp.register_script_message("cadre-settings-open", toggle_settings_menu)
mp.register_script_message("cadre-osc-pin-toggle", function()
    toggle_osc_pin()
end)
mp.register_script_message("cadre-osc-pip-toggle", function()
    toggle_picture_in_picture()
end)
mp.register_script_message("open-file-dialog", common.do_add_file)
mp.register_script_message("open-folder-dialog", common.do_add_folder)
mp.register_script_message("open-url-dialog", common.do_add_url)
mp.add_key_binding(nil, "cadre_osc_toggle", toggle_bar)
mp.add_key_binding(nil, "open-file-dialog", common.do_add_file)
mp.add_key_binding(nil, "open-folder-dialog", common.do_add_folder)
mp.add_key_binding(nil, "open-url-dialog", common.do_add_url)

local THUMBNAIL_REQUEST_INTERVAL = 0.05 -- Limit Thumbfast requests to 20 per second.
local thumbnail_preview_active = false
local last_thumbnail_request_time = nil

function update_thumbnail_preview()
    local L = get_layout()
    local bar_x1, bar_x2 = L.track_x1, L.track_x2
    local hovering_seek =
        (bar_x2 > bar_x1 and mouse_y >= L.seekbar_y - 10 and mouse_y <= L.seekbar_y + 10
            and mouse_x >= bar_x1 and mouse_x <= bar_x2)

    if hovering_seek and duration and duration > 0 and not thumbfast.disabled then
        local now = mp.get_time()
        if last_thumbnail_request_time
            and now - last_thumbnail_request_time < THUMBNAIL_REQUEST_INTERVAL then
            return
        end

        local ratio = (mouse_x - bar_x1) / (bar_x2 - bar_x1)
        local hovered_seconds = duration * math.min(1, math.max(0, ratio))
        local display_width = mp.get_property_number("osd-width", screen_w)
        local chapter_tooltip_visible = cfg.CHAPTER_TOOLTIP and hovered_chapter and hovered_chapter.title
        local tooltip_height, tooltip_offset
        if chapter_tooltip_visible then
            tooltip_height = cfg.CHAPTER_TOOLTIP_FONT_SIZE + 2 * (cfg.CHAPTER_TOOLTIP_PAD_Y or 0)
            tooltip_offset = cfg.CHAPTER_TOOLTIP_OFFSET_Y
        elseif cfg.SEEKBAR_TIME_TOOLTIP then
            tooltip_height = cfg.SEEKBAR_TIME_TOOLTIP_SIZE + 2 * (cfg.SEEKBAR_TIME_TOOLTIP_PAD_Y or 0)
            tooltip_offset = cfg.SEEKBAR_TIME_TOOLTIP_OFFSET_Y
        end
                local thumbnail_y
        local preview_gap = 10
        local tooltip_gap = 8
        local below_label_clearance = 0

        if cfg.TIME_LABEL_POSITION == "below_seekbar" then
            below_label_clearance = cfg.TIME_LABEL_OFFSET_Y + cfg.FONT_SIZE + 6
        end

        local place_below = false
        if L.seekbar_anchor_space ~= "window" and cfg.BAR_Y_ANCHOR ~= "bottom" then
            local required_height
            if tooltip_height then
                required_height = math.max(cfg.THUMB_WH, cfg.SEEKBAR_HEIGHT_HOVER / 2)
                    + preview_gap
                    + thumbfast.height
                    + tooltip_gap
                    + tooltip_height
                    + below_label_clearance
            else
                required_height = math.max(cfg.THUMB_WH, cfg.SEEKBAR_HEIGHT_HOVER / 2)
                    + preview_gap
                    + thumbfast.height
                    + below_label_clearance
            end

            place_below = (screen_h - L.seekbar_y) >= required_height
        end
        if L.seekbar_anchor_space ~= "window" and cfg.BAR_Y_ANCHOR == "bottom" then
            if tooltip_height then
                local tooltip_y1 = osc_panel_top_y()
                    - tooltip_height
                    - preview_gap
                    + cfg.TRACK_POPUP_OFFSET_Y

                tooltip_y1 = tooltip_y1 + tooltip_offset
                thumbnail_y = tooltip_y1 - tooltip_gap - thumbfast.height
            else
                thumbnail_y = osc_panel_top_y()
                    - thumbfast.height
                    - preview_gap
                    + cfg.TRACK_POPUP_OFFSET_Y
            end
        elseif place_below then
            local preview_top = L.seekbar_y
                + math.max(cfg.THUMB_WH, cfg.SEEKBAR_HEIGHT_HOVER / 2)
                + preview_gap
                + below_label_clearance

            if tooltip_height then
                local tooltip_y1 = preview_top + tooltip_offset
                thumbnail_y = tooltip_y1 + tooltip_height + tooltip_gap
            else
                thumbnail_y = preview_top
            end
        else
            if tooltip_height then
                local tooltip_y1 = L.seekbar_y
                    - math.max(cfg.THUMB_WH, cfg.SEEKBAR_HEIGHT_HOVER / 2)
                    - tooltip_height
                    - preview_gap

                tooltip_y1 = tooltip_y1 + tooltip_offset
                thumbnail_y = tooltip_y1 - tooltip_gap - thumbfast.height
            else
                thumbnail_y = L.seekbar_y
                    - math.max(cfg.THUMB_WH, cfg.SEEKBAR_HEIGHT_HOVER / 2)
                    - thumbfast.height
                    - preview_gap
            end
        end
        mp.commandv(
            "script-message-to",
            "thumbfast",
            "thumb",
            hovered_seconds,
            math.min(display_width - thumbfast.width - 10, math.max(10, mouse_x - thumbfast.width / 2)),
            thumbnail_y
        )
        thumbnail_preview_active = true
        last_thumbnail_request_time = now
    elseif thumbnail_preview_active and thumbfast.available then
        mp.commandv("script-message-to", "thumbfast", "clear")
        thumbnail_preview_active = false
        last_thumbnail_request_time = nil
    elseif not hovering_seek then
        thumbnail_preview_active = false
        last_thumbnail_request_time = nil
    end
end

--------------------------------------------------------------------------------
-- INPUT
--------------------------------------------------------------------------------

function point_in_own_ui(px, py)
    local L = current_layout
    if not L then
        L = get_layout()
        current_layout = L
    end
    if point_in_layout_controls(L, px, py) then
        return true
    end

    -- Main OSC control-bar region.
    if px >= L.pill_x1 and px <= L.pill_x2 and py >= L.pill_y1 and py <= L.pill_y2 then
        return true
    end

    -- Volume flyout.
    if
        popup_geo and px >= popup_geo.card_x1 and px <= popup_geo.card_x2 and py >= popup_geo.card_y1 and
            py <= popup_geo.card_y2
     then
        return true
    end

    if track_popup_geo and px >= track_popup_geo.card_x1 and px <= track_popup_geo.card_x2
        and py >= track_popup_geo.card_y1 and py <= track_popup_geo.card_y2 then
        return true
    end

    if speed_popup_geo and px >= speed_popup_geo.card_x1 and px <= speed_popup_geo.card_x2
        and py >= speed_popup_geo.card_y1 and py <= speed_popup_geo.card_y2 then return true end

    -- Add-file flyout.
    if
        add_menu_geo and px >= add_menu_geo.card_x1 and px <= add_menu_geo.card_x2 and py >= add_menu_geo.card_y1 and
            py <= add_menu_geo.card_y2
     then
        return true
    end

    -- Subtitle settings dialog.
    if
        settings_menu_geo and px >= settings_menu_geo.card_x1 and px <= settings_menu_geo.card_x2 and
            py >= settings_menu_geo.card_y1 and
            py <= settings_menu_geo.card_y2
     then
        return true
    end

    return false
end

function point_in_osc_dialog(px, py)
    local function inside(geo)
        if not geo then return false end
        local x1, x2 = geo.card_x1 or geo.cardx1, geo.card_x2 or geo.cardx2
        local y1, y2 = geo.card_y1 or geo.cardy1, geo.card_y2 or geo.cardy2
        return x1 and x2 and y1 and y2 and px >= x1 and px <= x2 and py >= y1 and py <= y2
    end
    return inside(settings_menu_geo) or inside(track_popup_geo) or inside(speed_popup_geo)
        or inside(popup_geo) or inside(add_menu_geo) or speed_wheel_button_at(px, py) ~= nil
end

function point_in_published_bounds(prefix, px, py)
    local visible = mp.get_property_native("user-data/" .. prefix .. "/visible", false)
    if not visible then
        return false
    end
    local x1 = mp.get_property_native("user-data/" .. prefix .. "/x1", -1)
    local y1 = mp.get_property_native("user-data/" .. prefix .. "/y1", -1)
    local x2 = mp.get_property_native("user-data/" .. prefix .. "/x2", -1)
    local y2 = mp.get_property_native("user-data/" .. prefix .. "/y2", -1)
    return px >= x1 and px <= x2 and py >= y1 and py <= y2
end

function point_in_playlist_ui(px, py)
    return point_in_published_bounds("cadre_playlist", px, py)
end

function point_in_titlebar_ui(px, py)
    return point_in_published_bounds("cadre_titlebar", px, py)
end

local last_hover_target = nil

local function get_hover_target(L)
    for _, group in ipairs({ "left", "center", "right" }) do
        for _, button in ipairs(L.buttons[group]) do
            if mouse_x >= button.x - button.width / 2
                and mouse_x <= button.x + button.width / 2
                and mouse_y >= button.y - button.height / 2
                and mouse_y <= button.y + button.height / 2 then
                return button.id
            end
        end
    end

    if L.track_x2 > L.track_x1
        and mouse_x >= L.track_x1
        and mouse_x <= L.track_x2
        and mouse_y >= L.seekbar_y - 10
        and mouse_y <= L.seekbar_y + 10 then
        return "seekbar"
    end

    return nil
end

function on_mouse_move()
    local in_playlist_area = point_in_playlist_ui(mouse_x, mouse_y)
    local in_titlebar_area = point_in_titlebar_ui(mouse_x, mouse_y)

    local L = current_layout or get_layout()
    current_layout = L

    local in_osc_area = point_in_own_ui(mouse_x, mouse_y)
        or in_playlist_area
        or in_titlebar_area

    if not in_titlebar_area then
        mp.set_property_bool("window-dragging", not in_osc_area)
    end

    if volume_dragging and popup_geo then
        local clamped_y = math.min(popup_geo.track_y2, math.max(popup_geo.track_y1, mouse_y))
        set_volume_from_y(clamped_y, popup_geo)
        render()
        return
    end

    if speed_dragging then
        local steps = math.floor((mouse_x - speed_drag_start_x) / (speed_drag_spacing or 43) + 0.5)
        local next_index = math.max(1, math.min(#SPEED_PRESETS, speed_drag_start_index - steps))
        if next_index ~= speed_drag_last_index then
            speed_drag_last_index = next_index
            apply_speed_preset(next_index)
            render()
        end
        return
    end

    if speed_inline_dragging then
        local steps = math.floor((mouse_x-speed_inline_start_x)/speed_inline_spacing + 0.5)
        local index = math.max(1, math.min(#SPEED_PRESETS, speed_inline_start_index-steps))
        if index ~= speed_inline_last_index then
            speed_inline_last_index = index
            apply_speed_preset(index)
            render()
        end
        return
    end

    if volume_slider_dragging then
        local slider_button = nil
        local current_layout = get_layout()
        for _, group in ipairs({"left", "center", "right"}) do
            for _, button in ipairs(current_layout.buttons[group]) do
                if button.id == "volume_slider" then
                    slider_button = button
                    break
                end
            end

            if slider_button then
                break
            end
        end

        if slider_button then
            set_volume_from_x(mouse_x, slider_button)
            render()
            return
        end
    end

    if seekbar_dragging then
        local L = get_layout()
        local bar_x1, bar_x2 = L.track_x1, L.track_x2
        local bar_w = bar_x2 - bar_x1
        if duration and duration > 0 and bar_w > 0 then
            local r = (mouse_x - bar_x1) / bar_w
            mp.commandv("seek", math.min(1, math.max(0, r)) * duration, "absolute")
        end
        render()
        return
    end

    if not file_loaded then
        local L = current_layout or get_layout()
        current_layout = L

        local hover_target = get_hover_target(L)

        if not bar_visible or hover_target ~= last_hover_target then
            bar_visible = true
            last_hover_target = hover_target
            render()
        end

        return
    end

    update_thumbnail_preview()

    local function update_hovered_chapter()
        local L = get_layout()
        local bar_x1, bar_x2 = L.track_x1, L.track_x2
        local hovering_seek =
            (bar_x2 > bar_x1 and mouse_y >= L.seekbar_y - 10 and mouse_y <= L.seekbar_y + 10
                and mouse_x >= bar_x1 and mouse_x <= bar_x2)

        local new_hovered = nil
        if hovering_seek then
            new_hovered = find_hovered_chapter(bar_x1, bar_x2 - bar_x1, duration, mouse_x)
        end

        if new_hovered ~= hovered_chapter then
            hovered_chapter = new_hovered
            if bar_visible then
                render()
            end
        end
    end

    update_hovered_chapter()
    local hovering_hitbox = false
    for _, b in ipairs(hitboxes) do
        if point_in(mouse_x, mouse_y, b) then
            hovering_hitbox = true
            break
        end
    end
    local hover_state = hovering_hitbox

    if hover_state ~= last_osc_hover then
        last_osc_hover = hover_state

        mp.commandv(
            "script-message",
            "python-bridge",
            "osc-hover",
            tostring(hover_state)
        )
    end

    local hover_target = get_hover_target(L)

    if mouse_in_active_zone() then
        if not bar_visible then
            show_bar()
        else
            restart_hide_timer()

            if hover_target ~= last_hover_target then
                last_hover_target = hover_target
                render()
            end
        end
    elseif bar_visible then
        if hover_target ~= last_hover_target then
            last_hover_target = hover_target
            render()
        end
    end
end

function on_mbtn_left(event)
    if event.event == "down" or event.event == "press" then
        playlist_mouse_relayed = false
        local in_osc_dialog = point_in_osc_dialog(mouse_x, mouse_y)
        local in_playlist_area = point_in_playlist_ui(mouse_x, mouse_y) and not in_osc_dialog
        local in_titlebar_area = point_in_titlebar_ui(mouse_x, mouse_y) and not in_osc_dialog
        local in_osd_area = point_in_own_ui(mouse_x, mouse_y) or in_playlist_area or in_titlebar_area

        mp.commandv("script-message", "python-bridge", "osd-hit", tostring(in_osd_area))

        if in_titlebar_area then
            mp.commandv("script-message-to", "cadre_titlebar", "titlebar-mbtn-left-down")
            return
        end

        if in_playlist_area then
            playlist_mouse_relayed = true
            mp.commandv("script-message-to", "cadre_playlist", "playlist-mbtn-left-down", event.key_name or "")
            return
        end

        if not in_osd_area then
            if not bar_visible then
                show_bar()
            end
            return
        end

        if not bar_visible then
            show_bar()
            return
        end

        if track_popup_open and track_popup_geo then
            local in_popup = mouse_x >= track_popup_geo.card_x1 and mouse_x <= track_popup_geo.card_x2
                and mouse_y >= track_popup_geo.card_y1 and mouse_y <= track_popup_geo.card_y2
            if in_popup then
                for _, b in ipairs(hitboxes) do
                    if (b.name:match("^track_popup_row")
                        or b.name == "track_popup_bg"
                        or b.name == "track_popup_subs_search"
                        or b.name == "track_popup_livecap_toggle"
                        or b.name == "track_popup_livecap_create_audio"
                        or b.name == "track_popup_livecap_translate")
                        and point_in(mouse_x, mouse_y, b) then
                        b.cb(mouse_x, mouse_y)
                        render()
                        return
                    end
                end
                return
            else
                track_popup_open = false
                track_popup_geo = nil
                render()
            end
        end

        if speed_popup_open and speed_popup_geo then
            local in_popup = mouse_x >= speed_popup_geo.card_x1 and mouse_x <= speed_popup_geo.card_x2
                and mouse_y >= speed_popup_geo.card_y1 and mouse_y <= speed_popup_geo.card_y2
            if in_popup then
                for _, b in ipairs(hitboxes) do
                    if b.name == "speed_reset" and point_in(mouse_x, mouse_y, b) then
                        b.cb()
                        render()
                        return
                    end
                end
                speed_dragging = true
                speed_drag_start_x = mouse_x
                speed_drag_spacing = speed_popup_geo.ruler_spacing or 43
                speed_drag_start_value = mp.get_property_number("speed", 1) or 1
                local center_x = (speed_popup_geo.card_x1 + speed_popup_geo.card_x2) / 2
                speed_drag_start_index = speed_preset_index(speed_drag_start_value)
                speed_drag_last_index = speed_drag_start_index
                local slot = math.max(-4, math.min(4, math.floor((mouse_x-center_x)/speed_drag_spacing + 0.5)))
                speed_click_index = math.max(1, math.min(#SPEED_PRESETS, speed_drag_start_index + slot))
                return
            else
                speed_popup_open = false
                speed_popup_slot = nil
                speed_popup_geo = nil
                render()
                return
            end
        end

        if volume_popup_open and popup_geo then
            local in_popup =
                mouse_x >= popup_geo.card_x1 and mouse_x <= popup_geo.card_x2 and mouse_y >= popup_geo.card_y1 and
                mouse_y <= popup_geo.card_y2
            if in_popup then
                for _, b in ipairs(hitboxes) do
                    if
                        (b.name == "volume_track" or b.name == "volume_mute" or b.name == "volume_card_bg") and
                            point_in(mouse_x, mouse_y, b)
                     then
                        b.cb(mouse_x, mouse_y)
                        render()
                        return
                    end
                end
                return
            else
                volume_popup_open = false
                render()
            end
        end

        if add_menu_open and add_menu_geo then
          local in_menu = mouse_x >= add_menu_geo.card_x1
              and mouse_x <= add_menu_geo.card_x2
              and mouse_y >= add_menu_geo.card_y1
              and mouse_y <= add_menu_geo.card_y2

          if in_menu then
                for _, b in ipairs(hitboxes) do
                    if b.name:match("^add_menu_") and point_in(mouse_x, mouse_y, b) then
                        b.cb()
                        render()
                        return
                    end
                end
                return
            else
                add_menu_open = false
                render()
            end
        end
        if settings_menu_open and settings_menu_geo then
            local in_settings_menu =
                mouse_x >= settings_menu_geo.card_x1 and mouse_x <= settings_menu_geo.card_x2 and
                mouse_y >= settings_menu_geo.card_y1 and
                mouse_y <= settings_menu_geo.card_y2

            if in_settings_menu then
                -- Settings hitboxes are appended last; search backward for top priority.
                for i = #hitboxes, 1, -1 do
                    local b = hitboxes[i]

                    if b.name:match("^set_") and point_in(mouse_x, mouse_y, b) then
                        if livecap_dropdown
                            and not b.name:match("^set_livecap_model_dropdown") then
                            livecap_dropdown = nil
                        end
                        b.cb(mouse_x, mouse_y)
                        render()
                        return
                    end
                end

                if livecap_dropdown then
                    livecap_dropdown = nil
                    render()
                end

                -- Blank area inside the modal is consumed, not passed through.
                return
            else
                -- Clicking outside the settings dialog closes it.
                if livecap_editor then
                    finish_livecap_edit(false)
                end
                settings_menu_open = false
                settings_menu_geo = nil
                settings_menu_scroll = 0
                livecap_dropdown = nil
                render()
                return
            end
        end

        for _, b in ipairs(hitboxes) do
            if point_in(mouse_x, mouse_y, b) then
                if b.name == "seekbar" or b.name == "volume_track" or b.name == "button_volume_slider_track"
                    or b.name == "button_speed_control_wheel" then
                    b.cb(mouse_x, mouse_y)
                else
                    b.cb()
                end
                render()
                return
            end
        end
    elseif event.event == "up" or event.event == "release" then
        if playlist_mouse_relayed then
            mp.commandv("script-message-to", "cadre_playlist", "playlist-mbtn-left-up", event.key_name or "")
            playlist_mouse_relayed = false
        end
        mp.commandv("script-message-to", "cadre_titlebar", "titlebar-mbtn-left-up")
        volume_dragging = false
        volume_slider_dragging = false
        seekbar_dragging = false
        if speed_dragging and math.abs(mouse_x-speed_drag_start_x) < 5 and speed_click_index then
            apply_speed_preset(speed_click_index)
            render()
        end
        speed_dragging = false
        speed_click_value = nil
        speed_click_index = nil
        if speed_inline_dragging and math.abs(mouse_x-speed_inline_start_x) < 5 and speed_inline_click_index then
            apply_speed_preset(speed_inline_click_index)
            render()
        end
        speed_inline_dragging = false
        speed_inline_click_index = nil
    end
end

mp.observe_property("mouse-pos", "native", function(_, pos)
    if not pos then
        return
    end

    mouse_x = pos.x or -1
    mouse_y = pos.y or -1

    on_mouse_move()
    
    if bar_visible then
        schedule_render()
    end
end)
mp.add_forced_key_binding("MBTN_LEFT", "cadre_mbtn_left", on_mbtn_left, {complex = true})
mp.add_forced_key_binding("Ctrl+MBTN_LEFT", "cadre_ctrl_mbtn_left", on_mbtn_left, {complex = true})
mp.add_forced_key_binding("Shift+MBTN_LEFT", "cadre_shift_mbtn_left", on_mbtn_left, {complex = true})
mp.add_forced_key_binding("Ctrl+Shift+MBTN_LEFT", "cadre_ctrl_shift_mbtn_left", on_mbtn_left, {complex = true})
mp.register_event(
    "client-message",
    function()
    end
)
mp.add_key_binding(
    "MBTN_LEFT_DBL",
    "cadre_mbtn_left_dbl",
    function()
        local in_playlist_area = point_in_playlist_ui(mouse_x, mouse_y)
        local in_titlebar_area = point_in_titlebar_ui(mouse_x, mouse_y)
        if in_playlist_area or in_titlebar_area then
            return
        end
        if point_in_own_ui(mouse_x, mouse_y) then
            return
        end
        mp.commandv("cycle", "fullscreen")
    end
)
--------------------------------------------------------------------------------
-- MOUSE WHEEL
--------------------------------------------------------------------------------

function handle_osc_dialog_wheel(direction)
    local inline_wheel = speed_wheel_button_at(mouse_x, mouse_y)
    local delta = direction == "up" and -1 or 1
    local function inside(geo)
        return geo and mouse_x >= geo.card_x1 and mouse_x <= geo.card_x2
            and mouse_y >= geo.card_y1 and mouse_y <= geo.card_y2
    end
    if settings_menu_open and inside(settings_menu_geo) then
        settings_menu_scroll = math.max(0, math.min(settings_menu_max_scroll, settings_menu_scroll + delta))
    elseif track_popup_open and inside(track_popup_geo) then
        track_popup_scroll = math.max(0, math.min(track_popup_max_scroll, track_popup_scroll + delta))
    elseif speed_popup_open and inside(speed_popup_geo) then
        local index = speed_preset_index(mp.get_property_number("speed", 1) or 1)
        apply_speed_preset(math.max(1, math.min(#SPEED_PRESETS, index - delta)))
    elseif volume_popup_open and inside(popup_geo) then
        mp.commandv("add", "volume", direction == "up" and 2 or -2)
    elseif inline_wheel then
        local index = speed_preset_index(mp.get_property_number("speed", 1) or 1)
        apply_speed_preset(math.max(1, math.min(#SPEED_PRESETS, index-delta)))
    elseif point_in_osc_dialog(mouse_x, mouse_y) then
        -- Consume wheel input inside non-scrollable OSC dialogs.
    else
        return false
    end
    render()
    return true
end

mp.register_script_message("cadre-osc-dialog-wheel", function(direction)
    handle_osc_dialog_wheel(direction)
end)

mp.observe_property("pause", "bool", function(_, paused_now)
    if paused_now == false and speed_zero_selected then
        speed_zero_selected = false
        if bar_visible then render() end
    end
end)

mp.add_key_binding(
    "WHEEL_UP",
    "cadre_wheel_up",
    function()
        local L = get_layout()
        -- Subtitle dialog owns the wheel only while it is open.
        if settings_menu_open then
            settings_menu_scroll = math.max(0, settings_menu_scroll - 1)
            render()
            return
        end

        if track_popup_open and track_popup_geo and mouse_x >= track_popup_geo.card_x1
            and mouse_x <= track_popup_geo.card_x2 and mouse_y >= track_popup_geo.card_y1
            and mouse_y <= track_popup_geo.card_y2 then
            track_popup_scroll = math.max(0, track_popup_scroll - 1)
            render()
            return
        end

        if speed_wheel_button_at(mouse_x, mouse_y, L) then
            local index = speed_preset_index(mp.get_property_number("speed", 1) or 1)
            apply_speed_preset(math.min(#SPEED_PRESETS, index+1))
            render()
            return
        end

        if speed_popup_open and speed_popup_geo and mouse_x >= speed_popup_geo.card_x1
            and mouse_x <= speed_popup_geo.card_x2 and mouse_y >= speed_popup_geo.card_y1
            and mouse_y <= speed_popup_geo.card_y2 then
            local index = speed_preset_index(mp.get_property_number("speed", 1) or 1)
            apply_speed_preset(math.min(#SPEED_PRESETS, index+1))
            render()
            return
        end

        -- Vertical volume popup.
        if
            volume_popup_open and popup_geo and mouse_x >= popup_geo.card_x1 and mouse_x <= popup_geo.card_x2 and
                mouse_y >= popup_geo.card_y1 and
                mouse_y <= popup_geo.card_y2
         then
            mp.commandv("add", "volume", 2)
            return
        end

        -- Seekbar.
        if L.track_x2 > L.track_x1 and mouse_x >= L.track_x1 and mouse_x <= L.track_x2
            and mouse_y >= L.seekbar_y - 12 and mouse_y <= L.seekbar_y + 12 then
            mp.commandv("seek", 5, "relative")
            return
        end

        -- Inline horizontal volume slider, if "volume_slider" is in the layout.
        for _, group in ipairs({"left", "center", "right"}) do
            for _, button in ipairs(L.buttons[group]) do
                if button.id == "volume_slider" then
                    local geo = get_volume_slider_geometry(button)

                    if
                        mouse_x >= geo.slider_x1 - 8 and mouse_x <= geo.slider_x2 + 8 and mouse_y >= button.y - 18 and
                            mouse_y <= button.y + 18
                     then
                        mp.commandv("add", "volume", 2)
                        return
                    end
                end
            end
        end
    end,
    {repeatable = true}
)

mp.add_key_binding(
    "WHEEL_DOWN",
    "cadre_wheel_down",
    function()
        local L = get_layout()

        -- Subtitle dialog owns the wheel only while it is open.
        if settings_menu_open then
            settings_menu_scroll = math.min(settings_menu_max_scroll, settings_menu_scroll + 1)
            render()
            return
        end

        if track_popup_open and track_popup_geo and mouse_x >= track_popup_geo.card_x1
            and mouse_x <= track_popup_geo.card_x2 and mouse_y >= track_popup_geo.card_y1
            and mouse_y <= track_popup_geo.card_y2 then
            track_popup_scroll = math.min(track_popup_max_scroll, track_popup_scroll + 1)
            render()
            return
        end

        if speed_wheel_button_at(mouse_x, mouse_y, L) then
            local index = speed_preset_index(mp.get_property_number("speed", 1) or 1)
            apply_speed_preset(math.max(1, index-1))
            render()
            return
        end

        if speed_popup_open and speed_popup_geo and mouse_x >= speed_popup_geo.card_x1
            and mouse_x <= speed_popup_geo.card_x2 and mouse_y >= speed_popup_geo.card_y1
            and mouse_y <= speed_popup_geo.card_y2 then
            local index = speed_preset_index(mp.get_property_number("speed", 1) or 1)
            apply_speed_preset(math.max(1, index-1))
            render()
            return
        end

        -- Vertical volume popup.
        if
            volume_popup_open and popup_geo and mouse_x >= popup_geo.card_x1 and mouse_x <= popup_geo.card_x2 and
                mouse_y >= popup_geo.card_y1 and
                mouse_y <= popup_geo.card_y2
         then
            mp.commandv("add", "volume", -2)
            return
        end

        -- Seekbar.
        if L.track_x2 > L.track_x1 and mouse_x >= L.track_x1 and mouse_x <= L.track_x2
            and mouse_y >= L.seekbar_y - 12 and mouse_y <= L.seekbar_y + 12 then
            mp.commandv("seek", -5, "relative")
            return
        end

        -- Inline horizontal volume slider, if "volume_slider" is in the layout.
        for _, group in ipairs({"left", "center", "right"}) do
            for _, button in ipairs(L.buttons[group]) do
                if button.id == "volume_slider" then
                    local geo = get_volume_slider_geometry(button)

                    if
                        mouse_x >= geo.slider_x1 - 8 and mouse_x <= geo.slider_x2 + 8 and mouse_y >= button.y - 18 and
                            mouse_y <= button.y + 18
                     then
                        mp.commandv("add", "volume", -2)
                        return
                    end
                end
            end
        end
    end,
    {repeatable = true}
)

--------------------------------------------------------------------------------
-- PROPERTY OBSERVERS
--------------------------------------------------------------------------------

mp.observe_property("osd-dimensions", "native", function(_, val)
    if not val or not val.w or not val.h or val.w == 0 or val.h == 0 then return end
    if screen_w ~= val.w or screen_h ~= val.h then
        screen_w, screen_h = val.w, val.h
        osd.res_x, osd.res_y = screen_w, screen_h
        if bar_pinned then
            bar_visible = true
        end
        invalidate_layout()
        render()
        if bar_visible then
            restart_hide_timer()
        end
    end
end)

mp.observe_property(
    "duration",
    "number",
    function(_, v)
        duration = v or 0
        schedule_render()
    end
)
mp.observe_property(
    "time-pos",
    "number",
    function(_, v)
        position = v or 0
        if bar_visible then
            schedule_render()
        end
    end
)
mp.observe_property(
    "pause",
    "bool",
    function(_, v)
        paused = v
        if cfg.SHOW_PANEL_ON_PAUSE == true then show_bar() end
        schedule_render()
    end
)
mp.observe_property(
    "idle-active",
    "bool",
    function(_, v)
        local new_idle = v == true

        if new_idle ~= idle_active then
            idle_active = new_idle
            last_hover_target = nil
            show_bar()
            schedule_render()
        end
    end
)
mp.observe_property(
    "mute",
    "bool",
    function(_, v)
        muted = v
        schedule_render()
    end
)
mp.observe_property(
    "volume",
    "number",
    function(_, v)
        volume = v or 100
        schedule_render()
    end
)
mp.observe_property(
    "media-title",
    "string",
    function(_, value)
        media_title = (value and value ~= "" and value) or mp.get_property("filename/no-ext") or ""
        schedule_render()
    end
)
mp.observe_property(
    "filename",
    "string",
    function(_, value)
        local current_title = mp.get_property("media-title")
        media_title = (current_title and current_title ~= "" and current_title)
            or mp.get_property("filename/no-ext") or value or ""
        schedule_render()
    end
)
mp.observe_property(
    "ontop",
    "bool",
    function()
        schedule_render()
    end
)

mp.observe_property(
    "chapter-list",
    "native",
    function(_, raw)
        chapters = normalize_chapters(raw)
        hovered_chapter = nil
        render()
    end
)

mp.register_event(
    "playback-restart",
    function()
        local raw = mp.get_property_native("chapter-list", {})
        local normalized = normalize_chapters(raw)
        if #normalized ~= #chapters then
            chapters = normalized
            render()
        end
    end
)

file_init_timer = nil

function on_file_initialized()
    if not file_loaded then
        file_loaded = true
        last_subtitle_sid = nil
        last_osc_hover = nil
        bar_visible = true
    end
    render()
end

mp.register_event(
    "file-loaded",
    function()
        -- Use a micro-timer to batch rapid-fire events
        if file_init_timer then
            file_init_timer:kill()
        end
        file_init_timer = mp.add_timeout(
            0.05,
            function()
                on_file_initialized()

                -- NEW: auto-load chapters if none exist
                local existing = mp.get_property_native("chapter-list", {})
                if #existing == 0 then
                    load_youtube_chapters()
                end

                file_init_timer = nil
            end
        )
    end
)

mp.observe_property(
    "path",
    "string",
    function(_, v)
        if v ~= nil and v ~= "" and not file_loaded then
            -- Path changed but file-loaded hasn't fired yet (edge case)
            if file_init_timer then
                file_init_timer:kill()
            end
            file_init_timer = mp.add_timeout(
                0.05,
                function()
                    on_file_initialized()
                    file_init_timer = nil
                end
            )
        end
    end
)
common.bind("osc", "o", "cadre_toggle_osc_pin", function()
  mp.commandv("script-message", "cadre-toggle-osc-pin")
end)
common.bind("settings", "alt+s", "cadre_settings_toggle", toggle_settings_menu)
render()
