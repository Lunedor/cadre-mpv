-- Optional content-aware theme selection. The configured main.theme remains the fallback.
local mp = require "mp"
local utils = require "mp.utils"

local function config()
    local path = mp.command_native({"expand-path", "~~/scripts/cadre/cadre.conf"})
    local f = io.open(path, "r")
    if not f then return {} end
    local data = utils.parse_json(f:read("*a")); f:close()
    local opts = type(data) == "table" and type(data.auto_theme) == "table" and data.auto_theme or {}
    for _, key in ipairs({"image_theme", "music_theme"}) do
        local name = opts[key]
        if type(name) == "string" then
            name = name:gsub("^%s+", ""):gsub("%s+$", "")
            while #name >= 2 and name:sub(1, 1) == '"' and name:sub(-1) == '"' do
                name = name:sub(2, -2)
            end
            opts[key] = name
        end
    end
    return opts
end

local current
local restore_timer
local RESTORE_DELAY = 1.5
local file_ready = mp.get_property_bool("file-loaded", false)

local function cancel_restore()
    if restore_timer then
        restore_timer:kill()
        restore_timer = nil
    end
end

local function publish(selected)
    if selected == current then return end
    current = selected
    mp.set_property("user-data/cadre/runtime-theme", selected or "")
    for _, script in ipairs({"cadre_osc", "cadre_titlebar", "cadre_playlist", "cadre_menu"}) do
        mp.commandv("script-message-to", script, "cadre-theme-reload")
    end
end

local function classify()
    local opts = config()
    if opts.enabled ~= true then return nil end

    local tracks = mp.get_property_native("track-list", {}) or {}
    local has_audio, has_video, is_image = false, false, false
    for _, track in ipairs(tracks) do
        if track.type == "audio" and not track.albumart then has_audio = true end
        if track.type == "video" then
            has_video = true
            if track.image == true or track.albumart == true then is_image = true end
        end
    end

    if is_image and not has_audio then return opts.image_theme end
    local music_mode = mp.get_property_bool("user-data/music_mode/active", false)
    if has_audio and (not has_video or (opts.music_mode_counts_as_music == true and music_mode)) then
        return opts.music_theme
    end
    return nil
end

local function update()
    if not file_ready then return end
    cancel_restore()
    local selected = classify()
    publish(selected)
end

-- start-file fires for the next playlist item before it is loaded. Keep the
-- current theme during the transition; file-loaded selects the next theme.
mp.register_event("start-file", function()
    file_ready = false
    cancel_restore()
end)
mp.register_event("file-loaded", function()
    file_ready = true
    update()
end)
mp.register_event("end-file", function()
    file_ready = false
    cancel_restore()
    restore_timer = mp.add_timeout(RESTORE_DELAY, function()
        restore_timer = nil
        -- Only restore after a genuine stop/playlist end. If another file has
        -- started loading, its file-loaded event will choose the right theme.
        if mp.get_property("path", "") == "" or mp.get_property_bool("idle-active", false) then
            publish(nil)
        end
    end)
end)
mp.observe_property("track-list", "native", update)
mp.observe_property("user-data/music_mode/active", "bool", update)
mp.register_script_message("cadre-auto-theme-refresh", update)
mp.register_script_message("cadre-theme-reload", update)
update()
