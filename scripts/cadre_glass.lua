-- Coordinates the optional gpu-next backdrop shader for Cadre's three panels.
local mp = require "mp"
local msg = require "mp.msg"

-- This helper is loaded by main.lua with load-script, where mpv may not expose
-- a script directory. Resolve the same portable-config path used by main.lua.
local shader_path = mp.command_native({
    "expand-path", "~~/scripts/cadre/scripts/cadre_glass.hook"
})
local components = {"osc", "playlist", "titlebar", "track_popup", "volume_popup",
"add_popup", "settings_dialog", "playlist_add_popup", "menu"}
for depth = 1, 7 do components[#components + 1] = "menu_sub" .. depth end
local regions = {}
local previous_options = {}
local shader_added = false
local warned_missing = false

for _, name in ipairs(components) do
    regions[name] = {enabled = false}
end

local function is_shader_loaded()
    local shaders = mp.get_property_native("glsl-shaders", {})
    if type(shaders) == "string" then
        return shaders == shader_path
    end
    if type(shaders) ~= "table" then
        return false
    end
    for _, path in ipairs(shaders) do
        if path == shader_path then return true end
    end
    return false
end

local function set_shader_loaded(loaded)
    if loaded == shader_added then return end
    if loaded then
        if not is_shader_loaded() then
            local ok = pcall(mp.commandv, "change-list", "glsl-shaders", "append", shader_path)
            if not ok then
                if not warned_missing then
                    msg.warn("cadre_glass: could not load the backdrop shader")
                    warned_missing = true
                end
                return
            end
        end
        shader_added = true
        previous_options = {}
    else
        if is_shader_loaded() then
            pcall(mp.commandv, "change-list", "glsl-shaders", "remove", shader_path)
        end
        shader_added = false
        previous_options = {}
    end
end

local function set_param(name, value)
    value = tonumber(value) or 0
    value = string.format("%.6f", value)
    if previous_options[name] == value then return end
    previous_options[name] = value
    pcall(mp.commandv, "change-list", "glsl-shader-opts", "append", "cadre_glass/" .. name .. "=" .. value)
end

local function apply_regions()
    local enabled = mp.get_property("current-vo", "") == "gpu-next"
    local rotation = mp.get_property_number("video-rotate", 0) or 0
    local normalized_rotation = ((rotation % 360) + 360) % 360
    local rotate_180 = normalized_rotation > 179.5 and normalized_rotation < 180.5
    local dimensions = mp.get_property_native("osd-dimensions", {}) or {}
    local screen_w = tonumber(dimensions.w) or 0
    local screen_h = tonumber(dimensions.h) or 0
    local margin_l = math.max(0, tonumber(dimensions.ml) or 0)
    local margin_r = math.max(0, tonumber(dimensions.mr) or 0)
    local margin_t = math.max(0, tonumber(dimensions.mt) or 0)
    local margin_b = math.max(0, tonumber(dimensions.mb) or 0)
    local video_x1 = screen_w > 0 and math.min(1, margin_l / screen_w) or 0
    local video_y1 = screen_h > 0 and math.min(1, margin_t / screen_h) or 0
    local video_x2 = screen_w > 0 and math.max(0, 1 - margin_r / screen_w) or 1
    local video_y2 = screen_h > 0 and math.max(0, 1 - margin_b / screen_h) or 1

    local any = false
    for _, name in ipairs(components) do
        local region = regions[name]
        if region.enabled then
            any = true
        end
    end

    if not enabled or not any then
        set_shader_loaded(false)
        return
    end

    set_shader_loaded(true)
    set_param("rotate_180", rotate_180 and 1 or 0)
    set_param("screen_w", screen_w)
    set_param("screen_h", screen_h)
    set_param("screen_aspect", screen_h > 0 and screen_w / screen_h or 1)
    set_param("video_x1", video_x1)
    set_param("video_y1", video_y1)
    set_param("video_x2", video_x2)
    set_param("video_y2", video_y2)
    for _, name in ipairs(components) do
        local region = regions[name]
        local w = tonumber(region.screen_w) or 0
        local h = tonumber(region.screen_h) or 0
        local active = region.enabled and w > 0 and h > 0 and enabled
        set_param(name .. "_enabled", active and 1 or 0)
        set_param(name .. "_blur", active and (tonumber(region.blur_radius) or 12) or 0)
        if active then
            set_param(name .. "_x1", (tonumber(region.x1) or 0) / w)
            set_param(name .. "_y1", (tonumber(region.y1) or 0) / h)
            set_param(name .. "_x2", (tonumber(region.x2) or 0) / w)
            set_param(name .. "_y2", (tonumber(region.y2) or 0) / h)
            set_param(name .. "_corner", tonumber(region.corner) or 0)
        else
            set_param(name .. "_x1", 0)
            set_param(name .. "_y1", 0)
            set_param(name .. "_x2", 0)
            set_param(name .. "_y2", 0)
            set_param(name .. "_corner", 0)
        end
    end
end

for _, name in ipairs(components) do
    mp.observe_property("user-data/cadre_glass/" .. name, "native", function(_, value)
        if type(value) == "table" then
            regions[name] = value
        else
            regions[name] = {enabled = false}
        end
        apply_regions()
    end)
end

mp.observe_property("current-vo", "string", apply_regions)
mp.observe_property("video-rotate", "number", apply_regions)
mp.observe_property("osd-dimensions", "native", apply_regions)
mp.register_event("shutdown", function()
    set_shader_loaded(false)
end)
