--[[
cadre_common.lua
]]
local mp = require "mp"
local utils = require "mp.utils"
local msg = require "mp.msg"
local theme = dofile(mp.command_native({"expand-path", "~~/scripts/cadre/scripts/cadre_theme.lua"}))
local UI_FONT = theme.font_ui or theme.font_text or "Inter"

local M = {}
local conf_cache

-- Convert a Unicode codepoint to the UTF-8 byte sequence expected by mpv's ASS renderer.
local function codepoint_to_utf8(value)
  local cp
  if type(value) == "number" then
    cp = math.floor(value)
  elseif type(value) == "string" then
    local hex = value:match("^[Uu]%+([%x]+)$") or value:match("^0[xX]([%x]+)$") or value
    if not hex:match("^[%x]+$") then return nil end
    cp = tonumber(hex, 16)
  else
    return nil
  end
  if not cp or cp < 0 or cp > 0x10FFFF or (cp >= 0xD800 and cp <= 0xDFFF) then return nil end
  if cp <= 0x7F then return string.char(cp) end
  if cp <= 0x7FF then
    return string.char(0xC0 + math.floor(cp / 0x40), 0x80 + (cp % 0x40))
  end
  if cp <= 0xFFFF then
    return string.char(0xE0 + math.floor(cp / 0x1000), 0x80 + (math.floor(cp / 0x40) % 0x40), 0x80 + (cp % 0x40))
  end
  return string.char(0xF0 + math.floor(cp / 0x40000), 0x80 + (math.floor(cp / 0x1000) % 0x40),
    0x80 + (math.floor(cp / 0x40) % 0x40), 0x80 + (cp % 0x40))
end

-- Built-in non-Material sets are keyed by the font's internal family name.
-- These map the Cadre semantic icon names to the corresponding font codepoints.
local ICON_CODEPOINT_SETS = {
  ["FluentSystemIcons-Regular"] = {
    play = "F606", pause = "F5A2", prev = "F629", next = "F56A", stop = "F72B",
    volume_up = "EB43", volume_off = "EB4B", audio = "F35D",
    add = "F10A", fullscreen = "E685", seekbar_back = "EAFC", seekbar_forward = "EB01",
    playlist = "F138", add_file = "E4DC", add_folder = "F41D", add_url = "F021D",
    cc_on = "F2E3", cc_off = "E37F", subtitles = "EBCD",
    settings = "F6AA", youtube = "F850", stream = "F003A", webdav = "F4B1",
    info = "F4A4", music_mode = "E856", screenshot = "F68E", pin = "F602",
    picture_in_picture = "E97E", always_on_top = "F5FE", close = "F36A",
    frame_back = "F02DF", frame_forward = "F02DD",
    chapter_list = "F017C", chapter_prev = "F16D", chapter_next = "F16B",
    speed_down = "F675", speed_reset = "F4C8", speed_up = "F3FF",
    ab_loop = "F060F", shuffle = "EF37", repeat_all = "F172", repeat_one = "EF34", repeat_auto = "F140",
    search = "F690", save = "F680", load = "F379", remove = "F02B8", delete = "F34D", globe ="F45B",
  },
  ["FluentSystemIcons-Filled"] = {
    play = "F610", pause = "F5AC", prev = "F633", next = "F574", stop = "F743",
    volume_up = "EB4C", volume_off = "EB54", audio = "F35D",
    add = "F10A", fullscreen = "E692", seekbar_back = "EB05", seekbar_forward = "EB0A",
    playlist = "F138", add_file = "E4E8", add_folder = "F421", add_url = "F230",
    cc_on = "F2E3", cc_off = "E394", subtitles = "EBC7",
    settings = "F6B3", youtube = "F868", stream = "F003E", webdav = "F4BB",
    info = "F4AB", music_mode = "E864", screenshot = "F698", pin = "F60C",
    picture_in_picture = "E990", always_on_top = "F608", close = "F36A",
    frame_back = "F02F2", frame_forward = "F02F0",
    chapter_list = "F017C", chapter_prev = "F16D", chapter_next = "F16B",
    speed_down = "F67F", speed_reset = "F4D2", speed_up = "F3FE",
    ab_loop = "F068B", shuffle = "EF37", repeat_all = "F172", repeat_one = "EF34", repeat_auto = "F140",
    search = "F69A", save = "F68A", load = "F379", remove = "F02CB", delete = "F34D", globe ="F45F",
  },
}

function M.resolve_icon_map(defaults, overrides, font_family)
  local resolved = {}
  local function merge_codepoints(values)
    if type(values) ~= "table" then return end
    for name, value in pairs(values) do
      local glyph = codepoint_to_utf8(value)
      if glyph then resolved[name] = glyph
      elseif type(value) == "string" then resolved[name] = value end
    end
  end
  merge_codepoints(defaults)
  merge_codepoints(ICON_CODEPOINT_SETS[font_family])
  merge_codepoints(overrides)
  return resolved
end

M.theme = theme
local theme_reload_handlers = {}

function M.on_theme_reload(handler)
  if type(handler) == "function" then
    theme_reload_handlers[#theme_reload_handlers + 1] = handler
  end
end

function M.publish_glass_region(name, enabled, bounds, width, height, corner_radius, blur_radius)
  if type(name) ~= "string" then return end
  local region = {
    enabled = enabled == true and type(bounds) == "table",
    screen_w = tonumber(width) or 0,
    screen_h = tonumber(height) or 0,
    x1 = bounds and tonumber(bounds.x1) or 0,
    y1 = bounds and tonumber(bounds.y1) or 0,
    x2 = bounds and tonumber(bounds.x2) or 0,
    y2 = bounds and tonumber(bounds.y2) or 0,
    corner = math.max(0, tonumber(corner_radius) or 0),
    blur_radius = math.max(0, tonumber(blur_radius) or 12)
  }
  mp.set_property_native("user-data/cadre_glass/" .. name, region)
end

function M.reload_theme()
  local path = mp.command_native({"expand-path", "~~/scripts/cadre/scripts/cadre_theme.lua"})
  local ok, updated = pcall(dofile, path)
  if not ok or type(updated) ~= "table" then
    msg.error("cadre: could not reload theme: " .. tostring(updated))
    return false
  end
  M.theme = updated
  UI_FONT = updated.font_ui or updated.font_text or "Inter"
  for _, handler in ipairs(theme_reload_handlers) do
    local handler_ok, err = pcall(handler, updated)
    if not handler_ok then msg.error("cadre: theme refresh failed: " .. tostring(err)) end
  end
  return true
end

function M.list_themes()
  local dir = mp.command_native({"expand-path", "~~/scripts/cadre/themes"})
  local entries = utils.readdir(dir, "files") or {}
  local names = {"Default"}
  for _, entry in ipairs(entries) do
    local name = entry:match("^(.*)%.lua$")
    if name and name ~= "Default" then names[#names + 1] = name end
  end
  table.sort(names, function(a, b)
    if a == "Default" then return true end
    if b == "Default" then return false end
    return a:lower() < b:lower()
  end)
  return names
end

function M.save_theme(name)
  if type(name) ~= "string" or not name:match("^[%w _%.%-]+$") or name:find("..", 1, true) then return false end
  local path = mp.command_native({"expand-path", "~~/scripts/cadre/cadre.conf"})
  local f = io.open(path, "r")
  if not f then return false end
  local contents = f:read("*a")
  f:close()
  local quoted = name == "Default" and "\"\"" or string.format("%q", name)
  local updated, count = contents:gsub(
    '("theme"%s*:%s*)"[^"]*"',
    function(prefix) return prefix .. quoted end,
    1
  )
  if count == 0 then return false end
  f = io.open(path, "w")
  if not f then return false end
  local ok = f:write(updated)
  f:close()
  if not ok then return false end
  conf_cache = nil
  return true
end

mp.register_script_message("cadre-theme-reload", function()
  M.reload_theme()
end)

function M.load_conf()
  if conf_cache then return conf_cache end
  conf_cache = {}
  local f = io.open(mp.command_native({"expand-path", "~~/scripts/cadre/cadre.conf"}), "r")
  if f then
    local d = utils.parse_json(f:read("*a")); f:close()
    if type(d) == "table" then conf_cache = d end
  end
  return conf_cache
end

function M.reload_conf()
  conf_cache = nil
  return M.load_conf()
end

-- merge section values into defaults table (type-checked)
function M.section(name, defaults)
  local s = M.load_conf()[name]
  if type(s) == "table" then
    for k, v in pairs(s) do
      if defaults[k] ~= nil and type(defaults[k]) == type(v) then defaults[k] = v end
    end
  end
  return defaults
end

local DEFAULT_MEDIA_EXTENSIONS = {
  "mp4", "mkv", "avi", "mov", "webm", "wmv", "flv", "m4v", "mpeg", "mpg", "3gp",
  "mp3", "flac", "wav", "m4a", "ogg", "wma", "aac",
}

function M.media_extensions()
  local configured = M.section("playlist", {media_extensions = DEFAULT_MEDIA_EXTENSIONS}).media_extensions
  local extensions, seen = {}, {}
  for _, value in ipairs(configured) do
    if type(value) == "string" then
      local ext = value:lower():gsub("^%.", "")
      if ext:match("^[%w]+$") and not seen[ext] then
        extensions[#extensions + 1] = ext
        seen[ext] = true
      end
    end
  end
  return extensions
end

function M.media_extension_set()
  local result = {}
  for _, ext in ipairs(M.media_extensions()) do result[ext] = true end
  return result
end

function M.media_file_filter()
  local patterns = {}
  for _, ext in ipairs(M.media_extensions()) do patterns[#patterns + 1] = "*." .. ext end
  if #patterns == 0 then return "All files|*.*" end
  return "Media files|" .. table.concat(patterns, ";") .. "|All files|*.*"
end

function M.key(name, default)
  local k = M.load_conf().keys
  local v = type(k) == "table" and k[name]
  if type(v) == "string" then return v end
  return default
end

-- bind with configurable key; "" or "none" = no default key
function M.bind(name, default, binding_name, fn, flags)
  local key = M.key(name, default)
  if key == "" or key == "none" then key = nil end
  mp.add_key_binding(key, binding_name, fn, flags)
end

local property_cache = {}

function M.register_script(name)
    local property = "user-data/cadre_scripts/" .. name .. "/loaded"
    mp.set_property_bool(property, true)
    mp.register_event(
        "shutdown",
        function()
            mp.set_property_bool(property, false)
        end
    )
end

function M.is_script_loaded(name)
    return mp.get_property_bool("user-data/cadre_scripts/" .. name .. "/loaded", false)
end

function M.set_property_cached(name, value)
    if property_cache[name] == value then
        return
    end

    property_cache[name] = value

    if type(value) == "boolean" then
        mp.set_property_bool(name, value)
    elseif type(value) == "number" then
        mp.set_property_number(name, value)
    else
        mp.set_property(name, value)
    end
end

function M.render_controller(osd, name)
    local controller = {
        name = name or "unnamed",
        last_data = nil,
        last_width = nil,
        last_height = nil,

        calls = 0,
        updates = 0,
        skipped = 0,
        total_time = 0,
        max_time = 0,
        window_start = mp.get_time()
    }

    function controller:update(data, width, height, force)
        local start = mp.get_time()

        self.calls = self.calls + 1

        if not force
            and data == self.last_data
            and width == self.last_width
            and height == self.last_height then
            self.skipped = self.skipped + 1
            return false
        end

        self.last_data = data
        self.last_width = width
        self.last_height = height

        osd.data = data
        osd.res_x = width
        osd.res_y = height
        osd:update()

        self.updates = self.updates + 1

        local elapsed = mp.get_time() - start
        self.total_time = self.total_time + elapsed
        self.max_time = math.max(self.max_time, elapsed)

        return true
    end

    -- Theme changes can switch ASS font families while reusing the same overlay.
    -- A PlayRes change makes libass invalidate its cached glyph/render data.
    function controller:invalidate_ass_cache()
        local width, height = self.last_width, self.last_height
        self.last_data = nil
        if type(width) ~= "number" or width <= 0 or type(height) ~= "number" or height <= 0 then
            return false
        end
        osd.data = ""
        osd.res_x = width + 1
        osd.res_y = height
        osd:update()
        return true
    end

    function controller:report()
        local elapsed = mp.get_time() - self.window_start

        if elapsed <= 0 then
            return
        end

        mp.msg.info(string.format(
            "[cadre:%s] calls=%d updates=%d skipped=%d avg_update=%.3f ms max_update=%.3f ms update_rate=%.1f/s",
            self.name,
            self.calls,
            self.updates,
            self.skipped,
            self.updates > 0 and (self.total_time / self.updates) * 1000 or 0,
            self.max_time * 1000,
            self.updates / elapsed
        ))

        self.calls = 0
        self.updates = 0
        self.skipped = 0
        self.total_time = 0
        self.max_time = 0
        self.window_start = mp.get_time()
    end

    return controller
end

--------------------------------------------------------------------------------
-- COLOR
--------------------------------------------------------------------------------

function M.bgr(hex)
    if type(hex) ~= "string" or #hex < 6 then
        mp.msg.warn("cadre_common: invalid color value '" .. tostring(hex) .. "', using fallback gray")
        hex = "808080"
    end
    return hex:sub(5, 6) .. hex:sub(3, 4) .. hex:sub(1, 2)
end

function M.ass_alpha(hex)
    if type(hex) ~= "string" or not hex:match("^%x%x$") then
        return "00" -- fully opaque fallback
    end
    return string.format("%02X", 0xFF - tonumber(hex, 16))
end
--------------------------------------------------------------------------------
-- HIT TESTING
--------------------------------------------------------------------------------

function M.new_hitboxes()
    return {}
end

function M.add_hitbox(hitboxes, name, x1, y1, x2, y2, cb)
    hitboxes[#hitboxes + 1] = {name = name, x1 = x1, y1 = y1, x2 = x2, y2 = y2, cb = cb}
end

function M.point_in(px, py, b)
    return px >= b.x1 and px <= b.x2 and py >= b.y1 and py <= b.y2
end

function M.dispatch_click(hitboxes, px, py, ...)
    for _, b in ipairs(hitboxes) do
        if M.point_in(px, py, b) then
            b.cb(...)
            return true, b.name
        end
    end
    return false, nil
end

--------------------------------------------------------------------------------
-- ASS DRAWING
--------------------------------------------------------------------------------

function M.draw_icon(ass, icon_font, glyph, cx, cy, size, color, alpha, effects)
    effects = effects or {}
    local outline_width = effects.outline and effects.outline_width or 0
    local outline_color = effects.outline_color or "000000"
    local outline_alpha = effects.outline_alpha or "FF"
    if outline_alpha == "FF" then
        outline_width = 0
    end

    local shadow_x, shadow_y = 0, 0
    local shadow_color = "000000"
    local shadow_alpha = "FF"
    if effects.shadow then
        shadow_x = effects.shadow_x or 0
        shadow_y = effects.shadow_y or 0
        shadow_color = effects.shadow_color or "000000"
        shadow_alpha = effects.shadow_alpha or "FF"
    end
    if shadow_alpha == "FF" then
        shadow_x, shadow_y = 0, 0
    end

    local outline_blur = math.max(0, effects.outline_blur or 0)
    local shadow_blur = math.max(0, effects.shadow_blur or 0)

    -- ASS blur applies to the whole event. When requested, draw the outline and
    -- shadow as transparent-fill passes so the foreground glyph stays crisp.
    if outline_blur > 0 or shadow_blur > 0 then
        if shadow_alpha ~= "FF" and (shadow_x ~= 0 or shadow_y ~= 0 or shadow_blur > 0) then
            ass:new_event()
            ass:append(string.format(
                "{\\pos(%d,%d)\\an5\\fn%s\\fs%d\\1a&HFF&\\3a&HFF&" ..
                "\\4c&H%s&\\4a&H%s&\\bord0\\shad1\\xshad%g\\yshad%g\\blur%g}%s",
                cx, cy, icon_font, size, shadow_color, shadow_alpha, shadow_x, shadow_y, shadow_blur, glyph
            ))
        end
        if outline_width > 0 and outline_alpha ~= "FF" then
            ass:new_event()
            ass:append(string.format(
                "{\\pos(%d,%d)\\an5\\fn%s\\fs%d\\1a&HFF&\\3c&H%s&\\3a&H%s&\\bord%g\\shad0\\blur%g}%s",
                cx, cy, icon_font, size, outline_color, outline_alpha, outline_width, outline_blur, glyph
            ))
        end
        ass:new_event()
        ass:append(string.format(
            "{\\pos(%d,%d)\\an5\\fn%s\\fs%d\\1c&H%s&\\1a&H%s&\\bord0\\shad0}%s",
            cx, cy, icon_font, size, color, alpha or "00", glyph
        ))
        return
    end

    ass:new_event()
    ass:append(
        string.format(
            "{\\pos(%d,%d)\\an5\\fn%s\\fs%d\\1c&H%s&\\1a&H%s&" ..
                "\\3c&H%s&\\3a&H%s&\\bord%g\\4c&H%s&\\4a&H%s&\\shad0\\xshad%g\\yshad%g}%s",
            cx,
            cy,
            icon_font,
            size,
            color,
            alpha or "00",
            outline_color,
            outline_alpha,
            outline_width,
            shadow_color,
            shadow_alpha,
            shadow_x,
            shadow_y,
            glyph
        )
    )
end

function M.draw_text(ass, str, x, y, size, color, alpha, align, bold, font)
    ass:new_event()
    local b = bold and "\\b1" or "\\b0"
    local f = font or UI_FONT
    ass:append(
        string.format(
            "{\\pos(%d,%d)\\an%d\\fn%s\\fs%d\\1c&H%s&\\1a&H%s&\\bord0\\shad0%s}%s",
            x,
            y,
            align or 4,
            f,
            size,
            color,
            alpha or "00",
            b,
            str
        )
    )
end

function M.draw_rrect(ass, x1, y1, x2, y2, r, color, alpha)
    ass:new_event()
    ass:append(string.format("{\\pos(0,0)\\an7\\1c&H%s&\\1a&H%s&\\bord0\\shad0}", color, alpha or "00"))
    ass:draw_start()
    ass:round_rect_cw(x1, y1, x2, y2, r)
    ass:draw_stop()
end

function M.draw_rrect_outline(ass, x1, y1, x2, y2, r, color, alpha, width)
    if not width or width <= 0 or alpha == "FF" then return end
    ass:new_event()
    ass:append(string.format("{\\pos(0,0)\\an7\\1a&HFF&\\3c&H%s&\\3a&H%s&\\bord%g\\shad0}", color, alpha, width))
    ass:draw_start()
    ass:round_rect_cw(x1, y1, x2, y2, r)
    ass:draw_stop()
end

function M.draw_hover_rrect(ass, x1, y1, x2, y2, r, color, alpha, hovered)
    if hovered then M.draw_rrect(ass, x1, y1, x2, y2, r, color, alpha or "E0") end
end

--------------------------------------------------------------------------------
-- AUTO-HIDE / HOVER-REVEAL STATE MACHINE
--------------------------------------------------------------------------------

function M.new_visibility(opts)
    opts = opts or {}
    local hide_delay = opts.hide_delay or 0.4
    local in_zone = opts.in_zone or function()
            return false
        end
    local on_show = opts.on_show or function()
        end
    local on_hide = opts.on_hide or function()
        end

    local state = {
        pinned = false,
        hover_open = false,
        hide_timer = nil
    }

    local function is_visible()
        return state.pinned or state.hover_open
    end

    local function apply(prev_visible)
        local now_visible = is_visible()
        if now_visible and not prev_visible then
            on_show()
        end
        if not now_visible and prev_visible then
            on_hide()
        end
        return now_visible
    end

    local function set_pinned(v)
        local prev = is_visible()
        state.pinned = v
        state.hover_open = false
        if state.hide_timer then
            state.hide_timer:kill()
            state.hide_timer = nil
        end
        apply(prev)
    end

    local function poll()
        if state.pinned then
            return
        end
        local prev = is_visible()
        if in_zone() then
            if state.hide_timer then
                state.hide_timer:kill()
                state.hide_timer = nil
            end
            if not state.hover_open then
                state.hover_open = true
                apply(prev)
            end
        else
            if state.hover_open and not state.hide_timer then
                state.hide_timer =
                    mp.add_timeout(
                    hide_delay,
                    function()
                        local prev2 = is_visible()
                        state.hover_open = false
                        state.hide_timer = nil
                        apply(prev2)
                    end
                )
            end
        end
    end

    return {
        set_pinned = set_pinned,
        toggle_pinned = function()
            set_pinned(not state.pinned)
        end,
        poll = poll,
        is_visible = is_visible,
        is_pinned = function()
            return state.pinned
        end
    }
end

--------------------------------------------------------------------------------
-- NATIVE FILE DIALOGS & WINDOWS API CALLS (PowerShell)
--------------------------------------------------------------------------------

local UTF8_PREAMBLE = "[Console]::OutputEncoding = [Text.Encoding]::UTF8; "
local PLATFORM = mp.get_property("platform") or ""
local IS_WINDOWS = PLATFORM == "windows"

local function run_command(args)
    local res = utils.subprocess({args = args, cancellable = false})
    if res.status == 0 then
        return res.stdout or "", nil
    end
    return nil, res.error
end

local function linux_filter_args(filter)
    local args = {}
    for label, patterns in filter:gmatch("([^|]+)|([^|]+)") do
        patterns = patterns:gsub(";", " "):gsub("%*%.%*", "*")
        args[#args + 1] = label .. " | " .. patterns
    end
    return args
end

local function linux_dialog(args, kdialog_args)
    local out, error = run_command(args)
    if out ~= nil then
        return out
    end
    if not error then
        return nil
    end
    return run_command(kdialog_args)
end

local function run_ps(script)
    local res =
        utils.subprocess(
        {
            args = {"powershell", "-NoProfile", "-NonInteractive", "-Command", UTF8_PREAMBLE .. script},
            cancellable = false
        }
    )
    if res.status ~= 0 then
        msg.error("powershell failed: " .. (res.error or res.stderr or "unknown error"))
        return nil
    end
    return res.stdout
end

function M.pick_files_dialog(opts)
    opts = opts or {}
    local title = opts.title or "Open File"
    local filter = opts.filter or "All files|*.*"
    local multi = opts.multiselect ~= false

    if not IS_WINDOWS then
        local zenity_args = {"zenity", "--file-selection", "--title", title}
        for _, value in ipairs(linux_filter_args(filter)) do
            zenity_args[#zenity_args + 1] = "--file-filter=" .. value
        end
        if multi then
            zenity_args[#zenity_args + 1] = "--multiple"
            zenity_args[#zenity_args + 1] = "--separator=\n"
        end

        local kdialog_args = {"kdialog", "--title", title, "--getopenfilename", "."}
        if multi then
            kdialog_args[#kdialog_args + 1] = "--multiple"
            kdialog_args[#kdialog_args + 1] = "--separate-output"
        end
        kdialog_args[#kdialog_args + 1] = filter:gsub("|", " "):gsub(";", " ")

        local out = linux_dialog(zenity_args, kdialog_args)
        local paths = {}
        if out then
            for line in out:gmatch("[^\r\n]+") do
                paths[#paths + 1] = line
            end
        end
        return paths
    end

    local script =
        string.format(
        [[
Add-Type -AssemblyName System.Windows.Forms
$f = New-Object System.Windows.Forms.OpenFileDialog
$f.Title = '%s'
$f.Filter = '%s'
$f.Multiselect = $%s
if ($f.ShowDialog() -eq 'OK') { $f.FileNames -join "`n" }
]],
        title:gsub("'", "''"),
        filter:gsub("'", "''"),
        multi and "true" or "false"
    )

    local out = run_ps(script)
    local paths = {}
    if out then
        for line in out:gmatch("[^\r\n]+") do
            paths[#paths + 1] = line
        end
    end
    return paths
end

function M.pick_folder_dialog(opts)
    opts = opts or {}
    local desc = opts.description or "Select Folder"

    if not IS_WINDOWS then
        local out =
            linux_dialog(
            {"zenity", "--file-selection", "--directory", "--title", desc},
            {"kdialog", "--title", desc, "--getexistingdirectory", "."}
        )
        if out then
            out = out:gsub("[\r\n]+$", "")
            if out ~= "" then
                return out
            end
        end
        return nil
    end

    local script =
        string.format(
        [[
Add-Type -AssemblyName System.Windows.Forms
$f = New-Object System.Windows.Forms.FolderBrowserDialog
$f.Description = '%s'
if ($f.ShowDialog() -eq 'OK') { $f.SelectedPath }
]],
        desc:gsub("'", "''")
    )

    local out = run_ps(script)
    if out then
        out = out:gsub("[\r\n]+$", "")
        if out ~= "" then
            return out
        end
    end
    return nil
end

function M.prompt_text_dialog(opts)
    opts = opts or {}
    local title = opts.title or "Enter URL"
    local label = opts.label or "URL:"

    if not IS_WINDOWS then
        local out =
            linux_dialog(
            {"zenity", "--entry", "--title", title, "--text", label},
            {"kdialog", "--title", title, "--inputbox", label}
        )
        if out then
            out = out:gsub("[\r\n]+$", "")
            if out ~= "" then
                return out
            end
        end
        return nil
    end

    local script =
        string.format(
        [[
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$form = New-Object System.Windows.Forms.Form
$form.Text = '%s'
$form.Width = 480
$form.Height = 150
$form.StartPosition = 'CenterScreen'
$form.Topmost = $true
$lbl = New-Object System.Windows.Forms.Label
$lbl.Text = '%s'
$lbl.Left = 10
$lbl.Top = 15
$lbl.Width = 440
$form.Controls.Add($lbl)
$box = New-Object System.Windows.Forms.TextBox
$box.Left = 10
$box.Top = 40
$box.Width = 440
$form.Controls.Add($box)
$ok = New-Object System.Windows.Forms.Button
$ok.Text = 'OK'
$ok.Left = 290
$ok.Top = 70
$ok.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.Controls.Add($ok)
$cancel = New-Object System.Windows.Forms.Button
$cancel.Text = 'Cancel'
$cancel.Left = 375
$cancel.Top = 70
$cancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.Controls.Add($cancel)
$form.AcceptButton = $ok
$form.CancelButton = $cancel
if ($form.ShowDialog() -eq 'OK') { $box.Text }
]],
        title:gsub("'", "''"),
        label:gsub("'", "''")
    )

    local out = run_ps(script)
    if out then
        out = out:gsub("[\r\n]+$", "")
        if out ~= "" then
            return out
        end
    end
    return nil
end

function M.save_file_dialog(opts)
    opts = opts or {}
    local title = opts.title or "Save File"
    local filter = opts.filter or "Playlist files (*.m3u8)|*.m3u8|All files|*.*"
    local default_name = opts.default_name or ""

    if not IS_WINDOWS then
        local zenity_args = {"zenity", "--file-selection", "--save", "--confirm-overwrite", "--title", title}
        if default_name ~= "" then
            zenity_args[#zenity_args + 1] = "--filename=" .. default_name
        end
        for _, value in ipairs(linux_filter_args(filter)) do
            zenity_args[#zenity_args + 1] = "--file-filter=" .. value
        end

        local kdialog_args = {
            "kdialog",
            "--title",
            title,
            "--getsavefilename",
            default_name,
            filter:gsub("|", " "):gsub(";", " ")
        }
        local out = linux_dialog(zenity_args, kdialog_args)
        if out then
            out = out:gsub("[\r\n]+$", "")
            if out ~= "" then
                return out
            end
        end
        return nil
    end

    local script =
        string.format(
        [[
    Add-Type -AssemblyName System.Windows.Forms
    $f = New-Object System.Windows.Forms.SaveFileDialog
    $f.Title = '%s'
    $f.Filter = '%s'
    $f.FileName = '%s'
    if ($f.ShowDialog() -eq 'OK') { $f.FileName }
    ]],
        title:gsub("'", "''"),
        filter:gsub("'", "''"),
        default_name:gsub("'", "''")
    )

    local out = run_ps(script)
    if out then
        out = out:gsub("[\r\n]+$", "")
        if out ~= "" then
            return out
        end
    end
    return nil
end

function M.get_workarea()
    local script =
        [[
    Add-Type -AssemblyName System.Windows.Forms
    $wa = [System.Windows.Forms.Screen]::FromPoint([System.Windows.Forms.Cursor]::Position).WorkingArea
    "$($wa.Width)x$($wa.Height)+$($wa.Left)+$($wa.Top)"
    ]]
    local out = run_ps(script)
    if out then
        out = out:gsub("[\r\n]+$", "")
        if out ~= "" then
            return out
        end
    end
    return nil
end

function M.send_to_trash(path)
    if not path or path == "" then
        return false
    end

    if IS_WINDOWS then
        local res =
            utils.subprocess(
            {
                args = {
                    "powershell",
                    "-NoProfile",
                    "-Command",
                    string.format(
                        "Add-Type -AssemblyName Microsoft.VisualBasic; "
                            .. "[Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile("
                            .. "'%s', 'OnlyErrorDialogs', 'SendToRecycleBin')",
                        path:gsub("'", "''")
                    )
                },
                cancellable = false
            }
        )
        if res.status ~= 0 then
            msg.error("recycle bin move failed: " .. (res.error or res.stderr or "unknown error"))
            return false
        end
        return true
    end

    if run_command({"gio", "trash", path}) then
        return true
    end
    if run_command({"trash-put", path}) then
        return true
    end
    msg.error("could not move file to trash: no gio or trash-put command succeeded")
    return false
end

--------------------------------------------------------------------------------
-- PLAYLIST / QUEUE COMMON ACTIONS
--------------------------------------------------------------------------------

function M.playlist_is_empty()
    local pl = mp.get_property_native("playlist", {})
    return #pl == 0
end

function M.add_files_to_playlist(paths)
    local was_empty = M.playlist_is_empty()
    for i, p in ipairs(paths) do
        if i == 1 and was_empty then
            mp.commandv("loadfile", p, "replace")
        else
            mp.commandv("loadfile", p, "append-play")
        end
    end
    if not was_empty and #paths > 0 then
        local pl = mp.get_property_native("playlist", {})
        mp.commandv("playlist-play-index", #pl - #paths)
    end
end

function M.do_add_file()
    local paths =
        M.pick_files_dialog(
        {
            title = "Add File(s) to Playlist",
            filter = M.media_file_filter(),
            multiselect = true
        }
    )
    if #paths > 0 then
        M.add_files_to_playlist(paths)
        mp.osd_message(#paths == 1 and "Added 1 file" or ("Added " .. #paths .. " files"), 1.5)
    end
end

function M.do_add_folder()
    local folder = M.pick_folder_dialog({description = "Add Folder to Playlist"})
    if folder then
        local was_empty = M.playlist_is_empty()
        mp.commandv("loadfile", folder, was_empty and "replace" or "append-play")
        if not was_empty then
            local pl = mp.get_property_native("playlist", {})
            mp.commandv("playlist-play-index", #pl - 1)
        end
        mp.osd_message("Added folder: " .. folder, 1.5)
    end
end

function M.do_add_url()
    local url = M.prompt_text_dialog({title = "Add URL to Playlist", label = "Enter a media URL:"})
    if url and url ~= "" then
        local was_empty = M.playlist_is_empty()
        mp.commandv("loadfile", url, was_empty and "replace" or "append-play")
        mp.osd_message("Added URL", 1.5)
    end
end

--------------------------------------------------------------------------------
-- SHARED MOUSE DISPATCH (single owner of MBTN_LEFT / MBTN_LEFT_DBL)
--------------------------------------------------------------------------------

function M.setup_shared_mbtn_left(name, handler)
    mp.register_script_message(
        "cadre_mbtn_left_down",
        function()
            handler({event = "down"})
        end
    )
    mp.register_script_message(
        "cadre_mbtn_left_up",
        function()
            handler({event = "up"})
        end
    )

    local claimed = mp.get_property_native("user-data/cadre_common/mbtn_owner", "")
    if claimed == "" then
        mp.set_property_native("user-data/cadre_common/mbtn_owner", name)
        mp.add_forced_key_binding(
            "MBTN_LEFT",
            "cadre_mbtn_left_owner",
            function(event)
                mp.commandv(
                    "script-message",
                    "cadre_mbtn_left_" .. ((event.event == "up" or event.event == "release") and "up" or "down")
                )
            end,
            {complex = true}
        )
    end
end

return M
