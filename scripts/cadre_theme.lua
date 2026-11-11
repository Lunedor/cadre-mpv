local mp = require "mp"
local msg = require "mp.msg"
local utils = require 'mp.utils'
local M = {}

M.theme_name = "Default Theme"
M.theme_author = "Lunedor"
M.theme_variant = "" -- Replaces this file with script-opts/cadre-themes/<name>.lua when changed



local function read_conf_theme()
    local path = mp.command_native({"expand-path", "~~/scripts/cadre/cadre.conf"})
    local f = io.open(path, "r")
    if not f then return nil end
    local data = utils.parse_json(f:read("*a"))
    f:close()
    local function normalize(name)
        if type(name) ~= "string" then return nil end
        name = name:gsub("^%s+", ""):gsub("%s+$", "")
        while #name >= 2 and name:sub(1, 1) == '"' and name:sub(-1) == '"' do
            name = name:sub(2, -2)
        end
        if name == "" or name == '""' or name == "default" then return nil end
        return name
    end
    local configured = normalize(data and data.main and data.main.theme)
    local runtime = normalize(mp.get_property("user-data/cadre/runtime-theme"))
    return configured, runtime
end

local function merge(base, over)
    for k, v in pairs(over) do
        -- A selected theme is a complete override set. Replacing tables as a
        -- whole prevents nested layout/slot settings from a prior theme leaking
        -- into the next one.
        base[k] = v
    end
    return base
end

local function load_theme_variant(base_theme, variant, sibling_theme_path)
    variant = variant or base_theme.theme_variant
    if type(variant) ~= "string" or variant:match("^%s*$") or variant == "default" then
        return base_theme, nil
    end

    local variant_path = variant:gsub("\\", "/")
    if variant_path:find("..", 1, true) then
        msg.warn("cadre_theme: invalid theme name: " .. variant)
        return base_theme
    end
    if not variant_path:lower():match("%.lua$") then
        variant_path = variant_path .. ".lua"
    end

    local relative_paths
    if variant_path:find("/", 1, true) then
        relative_paths = { variant_path }
    else
        relative_paths = {}
        if sibling_theme_path then
            local sibling_dir = sibling_theme_path:match("^(.*[/\\])")
            if sibling_dir then
                relative_paths[#relative_paths + 1] = sibling_dir .. variant_path
            end
        end
        local theme_dir = mp.command_native({"expand-path", "~~/scripts/cadre/themes"})
        if type(theme_dir) == "string" then
            relative_paths[#relative_paths + 1] = theme_dir:gsub("[/\\]+$", "") .. "/" .. variant_path
        end
        local search_paths = {
            "scripts/cadre/themes/" .. variant_path,
            "script-opts/cadre-themes/" .. variant_path,
            "script-opts/cadre/themes/" .. variant_path,
        }
        for _, candidate in ipairs(search_paths) do
            relative_paths[#relative_paths + 1] = candidate
        end
    end

    local attempted_paths = {}
    for _, relative_path in ipairs(relative_paths) do
        local path = relative_path
        if type(path) == "string" then
            local is_absolute = path:match("^%a:[/\\]") or path:sub(1, 1) == "/"
            if path:sub(1, 2) == "~~" then
                path = mp.command_native({"expand-path", path})
            elseif not is_absolute then
                path = mp.find_config_file(path)
            end
        end
        attempted_paths[#attempted_paths + 1] = path or relative_path
        local probe = path and io.open(path, "rb")
        if probe then probe:close() else path = nil end
        if path then
            local ok, selected = pcall(dofile, path)
            if not ok or type(selected) ~= "table" then
                msg.warn("cadre_theme: bad theme file " .. relative_path ..
                         (ok and "" or (": " .. tostring(selected))))
                return base_theme
            end
            local merged = merge(base_theme, selected)
            local base_osc_icon_font = base_theme.font_icon_osc or base_theme.font_icon
                or "Material Icons Outlined"
            local selected_osc_icon_font = selected.font_icon_osc or selected.font_icon or base_osc_icon_font
            local base_pl_icon_font = base_theme.font_icon_pl or base_theme.font_icon
                or "Material Icons Outlined"
            local selected_pl_icon_font = selected.font_icon_pl or selected.font_icon or base_pl_icon_font
            if selected_osc_icon_font ~= base_osc_icon_font or selected_pl_icon_font ~= base_pl_icon_font then
                -- Switching font families without a theme-specific map should select that family's built-in map
                -- or its normal defaults, never retain codepoints from the previously active theme.
                merged.icon_codepoints = selected.icon_codepoints
            end
            merged.theme_variant = variant
            return merged, path
        end
    end

    msg.warn("cadre_theme: theme variant not found: " .. variant ..
        " (searched: " .. table.concat(attempted_paths, " | ") .. ")")
    return base_theme, nil
end

local configured_theme, runtime_theme = read_conf_theme()
-- Match the settings dialog: load exactly one selected theme over Cadre defaults.
-- Runtime content selection temporarily takes precedence over the saved fallback.
local active_theme = runtime_theme or configured_theme
local active_theme_path
M, active_theme_path = load_theme_variant(M, active_theme)
if runtime_theme and not active_theme_path and configured_theme then
    M = load_theme_variant(M, configured_theme)
end

return M
