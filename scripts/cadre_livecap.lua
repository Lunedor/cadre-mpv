local mp = require "mp"
local utils = require "mp.utils"
local msg = require "mp.msg"

local base = mp.command_native({ "expand-path", "~~/scripts/cadre/" })

local conf_path = base .. "cadre.conf"
local flag_path = base .. "data/livecap.enabled"

local key = "ctrl+shift+c"
local enabled = false

-- -----------------------
-- Configuration
-- -----------------------

local function read_conf()
    local file = io.open(conf_path, "r")

    if not file then
        msg.error("Could not open config: " .. conf_path)
        return nil
    end

    local content = file:read("*a")
    file:close()

    local ok, data = pcall(utils.parse_json, content)

    if not ok then
        msg.error(
            "Could not parse cadre.conf: " .. tostring(data)
        )
        return nil
    end

    return data
end

local data = read_conf()

if data and type(data.keys) == "table"
    and type(data.keys.livecap_toggle) == "string" then
    key = data.keys.livecap_toggle
end

local livecap_conf = data and type(data.livecap) == "table"
    and data.livecap or {}
local overlay_conf = type(livecap_conf.overlay) == "table"
    and livecap_conf.overlay or {}

local function conf_number(name, fallback)
    local value = overlay_conf[name]

    if type(value) == "number" then
        return value
    end

    return fallback
end

local function conf_string(name, fallback)
    local value = overlay_conf[name]

    if type(value) == "string" then
        return value
    end

    return fallback
end

local function status_messages_enabled()
    local current = read_conf()
    local current_livecap = type(current) == "table"
        and type(current.livecap) == "table"
        and current.livecap or nil
    return current_livecap ~= nil
        and current_livecap.osd_status == true
end

-- -----------------------
-- Live caption overlay
-- -----------------------

local caption_overlay = mp.create_osd_overlay("ass-events")
local overlay_visible = false
local hide_timer = nil
local last_caption_json = nil

local function ass_escape(text)
    text = tostring(text)
    text = text:gsub("\\", "\\\\")
    text = text:gsub("{", "\\{")
    text = text:gsub("}", "\\}")

    return text
end

local function caption_char_width(char)
    if #char > 1 then
        return 1
    end

    if char:match("[ilI.,'`:;!|]") then
        return 0.3
    elseif char:match("[MW@#%%&]") then
        return 0.9
    elseif char:match("[A-Z]") then
        return 0.68
    elseif char:match("[0-9]") then
        return 0.56
    elseif char:match("%s") then
        return 0.3
    end

    return 0.55
end

local function for_each_caption_char(text, callback)
    local index = 1
    while index <= #text do
        local first = text:byte(index)
        local char_length = first >= 0xF0 and 4
            or (first >= 0xE0 and 3
                or (first >= 0xC2 and 2 or 1))

        if char_length > 1 then
            for offset = 1, char_length - 1 do
                local continuation = text:byte(index + offset)
                if not continuation or continuation < 0x80
                    or continuation > 0xBF then
                    char_length = 1
                    break
                end
            end
        end

        callback(text:sub(index, index + char_length - 1))
        index = index + char_length
    end
end

local function wrap_caption(text, max_width, font_size)
    text = tostring(text)
    local max_units = math.max(1, max_width / math.max(font_size, 1))
    local output = {}
    local function add_paragraph(paragraph)
        local line = ""
        local line_width = 0

        local function finish_line()
            output[#output + 1] = line
            line = ""
            line_width = 0
        end

        for word in paragraph:gmatch("%S+") do
            local word_width = 0
            for_each_caption_char(word, function(char)
                word_width = word_width + caption_char_width(char)
            end)

            local separator_width = line == "" and 0 or 0.3
            if line_width + separator_width + word_width <= max_units then
                if line ~= "" then
                    line = line .. " "
                    line_width = line_width + separator_width
                end
                line = line .. word
                line_width = line_width + word_width
            else
                if line ~= "" then
                    finish_line()
                end

                if word_width <= max_units then
                    line = word
                    line_width = word_width
                else
                    for_each_caption_char(word, function(char)
                        local char_width = caption_char_width(char)
                        if line_width + char_width > max_units and line ~= "" then
                            finish_line()
                        end
                        line = line .. char
                        line_width = line_width + char_width
                    end)
                end
            end
        end

        output[#output + 1] = line
    end

    for paragraph in (text .. "\n"):gmatch("(.-)\n") do
        add_paragraph(paragraph)
    end

    return table.concat(output, "\n")
end

local function remove_caption()
    if overlay_visible then
        caption_overlay:remove()
        overlay_visible = false
    end

    if hide_timer then
        hide_timer:kill()
        hide_timer = nil
    end
end

local function show_caption(json_text)
    local caption, parse_error = utils.parse_json(json_text)

    if type(caption) == "string" then
        caption, parse_error = utils.parse_json(caption)
    end

    if type(caption) ~= "table" or not caption.text then
        msg.error(
            "livecap: invalid caption JSON: "
            .. tostring(parse_error)
            .. " | input: "
            .. tostring(json_text)
        )
        return
    end

    local start_time = tonumber(caption.start) or 0
    local end_time = tonumber(caption["end"]) or (start_time + 3)

    local duration = math.max(
        0.2,
        math.min(
            end_time - start_time,
            conf_number("max_duration", 8.0)
        )
    )

    local dims = mp.get_property_native("osd-dimensions")

    local osd_width = dims and dims.w or 1280
    local osd_height = dims and dims.h or 720

    caption_overlay.res_x = osd_width
    caption_overlay.res_y = osd_height

    local margin_x = math.max(0, conf_number("margin_x", 40))
    local max_margin = math.max(0, math.floor((osd_width - 1) / 2))
    margin_x = math.min(margin_x, max_margin)
    local font_size = conf_number("font_size", 40)
    local max_text_width = math.max(1, osd_width - margin_x * 2)
    local text = ass_escape(
        wrap_caption(caption.text, max_text_width, font_size)
    ):gsub("\n", "\\N")
    local margin_y = conf_number("margin_y", 90)
    local alignment = math.max(1, math.min(9, conf_number("align", 2)))
    local horizontal = (alignment - 1) % 3
    local vertical = math.floor((alignment - 1) / 3)
    local pos_x = horizontal == 0 and margin_x
        or (horizontal == 2 and osd_width - margin_x
            or math.floor(osd_width / 2))
    local pos_y = vertical == 0 and osd_height - margin_y
        or (vertical == 2 and margin_y or math.floor(osd_height / 2))

    local ass = string.format(
        "{\\an%d\\fn%s\\fs%d\\c%s\\3c%s\\bord%d\\shad%d\\pos(%d,%d)}%s",
        alignment,
        conf_string("font", "Segoe UI"),
        font_size,
        conf_string("color", "&H00FFFFFF&"),
        conf_string("border_color", "&H00000000&"),
        conf_number("border_width", 3),
        conf_number("shadow", 1),
        pos_x,
        pos_y,
        text
    )

    caption_overlay.data = ass

    local result, error = caption_overlay:update()

    if not result then
        msg.error(
            "livecap: overlay update failed: " .. tostring(error)
        )
        return
    end

    overlay_visible = true

    if hide_timer then
        hide_timer:kill()
    end

    hide_timer = mp.add_timeout(duration, remove_caption)
end

mp.observe_property(
    "user-data/livecap/caption",
    "string",
    function(_, value)
        if not value or value == "" then
            last_caption_json = nil
            remove_caption()
        else
            last_caption_json = value
            show_caption(value)
        end
    end
)

mp.register_script_message("cadre-livecap-reload-overlay", function()
    local updated = read_conf()
    if not updated or type(updated.livecap) ~= "table"
        or type(updated.livecap.overlay) ~= "table" then
        msg.error("Could not reload Live Captions overlay settings")
        return
    end
    data = updated
    livecap_conf = updated.livecap
    overlay_conf = updated.livecap.overlay
    if last_caption_json then
        show_caption(last_caption_json)
    end
end)

-- -----------------------
-- Enable/disable flag
-- -----------------------

local function update_enabled_property()
    mp.set_property_native(
        "user-data/cadre_livecap/enabled",
        enabled
    )
end

local function write_flag(state, quiet)
    local file = io.open(flag_path, "w")

    if file then
        file:write(state and "1" or "0")
        file:close()

        enabled = state
        update_enabled_property()

        if not quiet and status_messages_enabled() then
            mp.osd_message(
                state and "Live captions: ON" or "Live captions: OFF",
                2
            )
        end

        msg.info(
            "Live captions "
            .. (state and "enabled" or "disabled")
        )
    else
        mp.osd_message("Could not write livecap flag", 4)
        msg.error("Could not write: " .. flag_path)
    end
end

if key ~= "" and key ~= "none" then
    mp.add_key_binding(
        key,
        "livecap-toggle",
        function()
            write_flag(not enabled)
        end
    )
end

local function set_enabled(state)
    write_flag(state)
end

mp.register_script_message(
    "cadre-livecap-toggle",
    function()
        set_enabled(not enabled)
    end
)

mp.register_script_message(
    "cadre-livecap-set",
    function(state)
        set_enabled(
            state == "1"
            or state == "true"
            or state == true
        )
    end
)

-- -----------------------
-- UI commands
-- -----------------------

local function send_command(action)
    mp.set_property(
        "user-data/livecap/command",
        utils.format_json({
            action = action,
        })
    )
    if status_messages_enabled() then
        local messages = {
            translate_subs = "Subtitle translation requested",
            create_srt = "Subtitle creation requested",
        }
        if messages[action] then
            mp.osd_message(messages[action], 3)
        end
    end
end

mp.add_key_binding(
    "ctrl+shift+t",
    "livecap-translate-subs",
    function()
        send_command("translate_subs")
    end
)

mp.add_key_binding(
    "ctrl+shift+s",
    "livecap-create-srt",
    function()
        send_command("create_srt")
    end
)

mp.register_script_message(
    "cadre-livecap-command",
    function(action)
        if action == "create_srt" then
            send_command("create_srt")
        elseif action == "translate_subs" then
            send_command("translate_subs")
        elseif action == "reload_config" then
            send_command("reload_config")
        end
    end
)

-- -----------------------
-- Script availability
-- -----------------------

mp.set_property_native(
    "user-data/cadre_livecap/loaded",
    true
)

mp.register_event(
    "shutdown",
    function()
        mp.set_property_native(
            "user-data/cadre_livecap/loaded",
            false
        )

        remove_caption()
    end
)

local auto_start = livecap_conf.auto_start == true
write_flag(auto_start, true)

msg.info(
    "livecap: initial enabled state: " .. tostring(enabled)
)