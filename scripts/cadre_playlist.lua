--[[
cadre_playlist.lua
]]
local mp = require "mp"
local assdraw = require "mp.assdraw"
local common = dofile(mp.command_native({"expand-path", "~~/scripts/cadre/scripts/cadre_common.lua"}))
common.register_script("cadre_playlist")

--------------------------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------------------------

local theme = common.theme

local ICON_FONT, ICON_COLOR, TEXT, FONT_SIZE, TITLE_FONT_SIZE, DIM, BARBG, FRAME_BG, LIST_BG, ALPHA_BAR_BG, FRAME_ALPHA, LIST_ALPHA, DANGER
local SCROLL_FG, SCROLL_BG, SELECTED_COLOR, NOW_PLAYING_COLOR, HOVER_COLOR, INDEX_COLOR, DURATION_COLOR, ICON_DIM_A
local ROW_BG, ROW_BG_ALPHA, ROW_HEIGHT, ROW_PADDING_X, ROW_GAP, ROW_RADIUS, TITLE_OFFSET_X, ROW_RIGHT_INSET_X
local HOVER_ALPHA, SELECTED_ALPHA, CURRENT_ALPHA, INDEX_ALPHA, DURATION_ALPHA, RADIUS, LIST_RADIUS
local TOOLBAR_HEIGHT, HEADER_HEIGHT, SEARCH_HEIGHT, PANEL_WIDTH, SIDE_INSET, TOP_INSET, BOTTOM_INSET
local SCROLLBAR_WIDTH, HOVER_STRIP_WIDTH, HIDE_DELAY_SEC, OSC_BOTTOM_EXCLUSION
local ICON_SIZE, TOOLBAR_ICON_SIZE, TOOLBAR_ICON_SPACING, TITLE_POSITION
local FRAME_SHADOW, FRAME_SHADOW_COLOR, FRAME_SHADOW_ALPHA, FRAME_SHADOW_SIZE
local FRAME_SHADOW_BLUR
local POPUP_HOVER_COLOR, POPUP_HOVER_ALPHA
local LIST_INSET_LEFT, LIST_INSET_RIGHT
local GLASS_BLUR, GLASS_BLUR_RADIUS, ADD_POPUP_GLASS, ADD_POPUP_GLASS_RADIUS
local ICON_DEFAULTS = {
    search = "E8B6",
    shuffle = "E043",
    save = "E161",
    load = "E166",
    remove = "E15B",
    delete = "E872",
    repeat_all = "E040",
    repeat_one = "E041",
    repeat_auto = "F053",
    play = "E037",
    pause = "E034",
    add = "E145",
    add_file = "E24D",
    add_folder = "E2CC",
    add_url = "E157",
}
local ICON

local function apply_theme_colors()
    ICON_FONT = theme.font_icon_pl or theme.font_icon or "Material Icons Outlined"
    ICON = common.resolve_icon_map(ICON_DEFAULTS, theme.icon_codepoints, ICON_FONT)

    ICON_COLOR = common.bgr(theme.color_icon_pl or theme.text_color or "CBD5E1")
    TEXT = common.bgr(theme.color_text_pl or theme.text_color or "F8FAFC")
    FONT_SIZE = theme.size_font_pl or theme.font_size or 16
    TITLE_FONT_SIZE = theme.size_font_title_pl
        or theme.size_font_title
        or theme.font_size
        or 18

    DIM = common.bgr(theme.color_dim_pl or theme.dim_color or "64748B")
    BARBG = common.bgr(theme.surface_color_pl or theme.surface_color or "0B0E14")

    FRAME_BG = common.bgr(
        theme.color_bg_frame_pl
        or theme.surface_color_pl
        or theme.surface_color
        or "0B0E14"
    )
    LIST_BG = common.bgr(
        theme.color_bg_list_pl
        or theme.surface_color_pl
        or theme.surface_color
        or "0B0E14"
    )

    ALPHA_BAR_BG = common.ass_alpha(theme.alpha_panel_bg_pl or theme.alpha_panel_bg or "E7")

    PANEL_BORDER_COLOR = common.bgr(
        theme.color_border_panel_pl
        or theme.border_all_color
        or "FFFFFF"
    )
    PANEL_BORDER_ALPHA = common.ass_alpha(theme.alpha_border_panel_pl or theme.border_all_alpha or "00")
    PANEL_BORDER_WIDTH = theme.width_border_panel_pl or theme.border_all_width or 0

    FRAME_ALPHA = common.ass_alpha(theme.alpha_bg_frame_pl or theme.alpha_panel_bg_pl or theme.alpha_panel_bg or "E7")
    LIST_ALPHA = common.ass_alpha(theme.alpha_bg_list_pl or theme.alpha_panel_bg_pl or theme.alpha_panel_bg or "E7")

    DROP_LINE = common.bgr(
        theme.color_drop_line_pl
        or theme.color_text_pl
        or theme.text_color
        or "F8FAFC"
    )

    FRAME_SHADOW = theme.enabled_shadow_frame_pl == true
    FRAME_SHADOW_COLOR = common.bgr(theme.color_shadow_frame_pl or "000000")
    FRAME_SHADOW_ALPHA = common.ass_alpha(theme.alpha_shadow_frame_pl or "8F")
    FRAME_SHADOW_SIZE = theme.size_shadow_frame_pl or 5
    FRAME_SHADOW_BLUR = math.max(0, theme.blur_shadow_frame_pl or 0)

    DANGER = common.bgr(theme.color_danger_pl or theme.danger_color or "EF4444")

    SCROLL_FG = common.bgr(theme.color_scroll_fg_pl or "475569")
    SCROLL_BG = common.bgr(theme.color_scroll_bg_pl or "0F172A")

    SELECTED_COLOR = common.bgr(
        theme.color_row_selected_pl
        or theme.accent_color
        or "63B8FF"
    )
    NOW_PLAYING_COLOR = common.bgr(
        theme.color_row_current_pl
        or theme.accent_color
        or "63B8FF"
    )
    HOVER_COLOR = common.bgr(theme.color_hover_pl or "252A31")

    INDEX_COLOR = common.bgr(
        theme.color_index_pl
        or theme.color_dim_pl
        or theme.dim_color
        or "CBD5E1"
    )
    DURATION_COLOR = common.bgr(
        theme.color_duration_pl
        or theme.color_dim_pl
        or theme.dim_color
        or "CBD5E1"
    )

    ICON_DIM_A = common.ass_alpha(theme.alpha_icon_dim_pl or theme.alpha_icon_dim or "9F")
end

local function apply_theme_rows()
    ROW_BG = common.bgr(
        theme.color_bg_row_pl
        or LIST_BG
        or BARBG
        or "0B0E14"
    )
    ROW_BG_ALPHA = common.ass_alpha(theme.alpha_bg_row_pl or theme.alpha_bg_list_pl or theme.alpha_panel_bg_pl or theme.alpha_panel_bg or "E7")
    ROW_HEIGHT = theme.height_row_pl or theme.row_height or 42
    ROW_PADDING_X = theme.pad_x_row_pl or 16
    ROW_GAP = theme.gap_row_pl or 2
    ROW_RADIUS = theme.radius_row_pl or 6

    TITLE_OFFSET_X = theme.offset_x_title_pl or 42
    ROW_RIGHT_INSET_X = theme.inset_x_right_row_pl or 16

    HOVER_ALPHA = common.ass_alpha(theme.alpha_hover_pl or "BF")
    SELECTED_ALPHA = common.ass_alpha(theme.alpha_row_selected_pl or "9F")
    CURRENT_ALPHA = common.ass_alpha(theme.alpha_row_current_pl or "77")
    INDEX_ALPHA = common.ass_alpha(theme.alpha_index_pl or "CF")
    DURATION_ALPHA = common.ass_alpha(theme.alpha_duration_pl or "FF")

    RADIUS = theme.radius_panel_pl or theme.panel_radius or 20
    LIST_RADIUS = theme.radius_list_pl or 6

    TOOLBAR_HEIGHT = theme.height_toolbar_pl or theme.toolbar_height or 42
    HEADER_HEIGHT = theme.height_header_pl or theme.header_height or 42
    SEARCH_HEIGHT = theme.height_search_pl or theme.search_height or 40
    PANEL_WIDTH = theme.width_panel_pl or theme.panel_width or 420

    SIDE_INSET = theme.inset_side_pl or theme.side_inset or 16
    TOP_INSET = theme.inset_top_pl or theme.top_inset or 48
    BOTTOM_INSET = theme.inset_bottom_pl or theme.bottom_inset or 115

    SCROLLBAR_WIDTH = theme.width_scrollbar_pl or theme.scrollbar_width or 4
    HOVER_STRIP_WIDTH = theme.width_hover_strip_pl or theme.hover_strip_width or 16

    HIDE_DELAY_SEC = theme.hide_delay_sec_pl or theme.hide_delay_sec or 0.35
    OSC_BOTTOM_EXCLUSION = theme.exclusion_bottom_osc_pl
        or theme.exclusion_bottom_osc
        or 125

    ICON_SIZE = theme.size_icon_pl or 18
    TOOLBAR_ICON_SIZE = theme.size_icon_toolbar_pl or 20
    TOOLBAR_ICON_SPACING = theme.spacing_icon_toolbar_pl or 34

    TITLE_POSITION = theme.position_title_pl or "left"

    LIST_INSET_LEFT = theme.inset_left_list_pl or 8
    LIST_INSET_RIGHT = theme.inset_right_list_pl or 8
end

local function apply_theme_popup()
    ADD_POPUP_BG = common.bgr(
        theme.color_bg_add_popup_osc
        or theme.surface_color_osc
        or theme.surface_color
        or "0D1117"
    )
    ADD_POPUP_BG_ALPHA = common.ass_alpha(theme.alpha_bg_add_popup_osc or theme.alpha_panel_bg or "E3")
    ADD_POPUP_RADIUS = theme.radius_add_popup_osc or 10

    ADD_POPUP_BORDER_COLOR = common.bgr(
        theme.color_border_add_popup_osc
        or theme.border_all_color
        or "FFFFFF"
    )
    ADD_POPUP_BORDER_ALPHA = common.ass_alpha(theme.alpha_border_add_popup_osc
        or theme.border_all_alpha
        or "00")
    ADD_POPUP_BORDER_WIDTH = theme.width_border_add_popup_osc
        or theme.border_all_width
        or 0

    POPUP_HOVER_COLOR = common.bgr(
        theme.popup_hover_color
        or theme.color_bg_hover_osc
        or theme.color_hover_pl
        or theme.accent_color
        or "63B8FF"
    )
    POPUP_HOVER_ALPHA = common.ass_alpha(theme.alpha_popup_hover or "1F")

    GLASS_BLUR = theme.enabled_glass_blur_pl == true
        or (theme.enabled_glass_blur_pl == nil and theme.glass_blur == true)
    GLASS_BLUR_RADIUS = theme.radius_glass_blur_pl or theme.radius_glass_blur or 12

    ADD_POPUP_GLASS = theme.enabled_glass_blur_add_popup == nil
        and GLASS_BLUR
        or theme.enabled_glass_blur_add_popup == true
    ADD_POPUP_GLASS_RADIUS = theme.radius_glass_blur_add_popup_osc or GLASS_BLUR_RADIUS
end

local function apply_theme(updated)
    theme = updated
    apply_theme_colors()
    apply_theme_rows()
    apply_theme_popup()
end

apply_theme(theme)

math.randomseed(os.time())
--------------------------------------------------------------------------------
-- STATE
--------------------------------------------------------------------------------

local osd = mp.create_osd_overlay("ass-events")
local render_ctrl = common.render_controller(osd)
local screen_w, screen_h = 1280, 720
local mouse_x, mouse_y = -1, -1
local active_ass = nil

local pinned = false
local hover_open = false
local panel_visible = false
local hide_timer = nil

local items = {}
local filtered_items = {}
local current_index = -1
local selected_index = -1
local selected_indices = {}
local selection_anchor = -1
local scroll_offset = 0

local search_active = false
local search_query = ""
local render

local shuffle_on = false
local shuffle_order = {}

local drag = {active = false, from_index = -1, current_target = -1, indices = {}}
local scrollbar_drag = false

local hitboxes = {}
local last_click_time = 0
local last_click_index = -1
local DOUBLE_CLICK_SEC = 0.35

local load_append_mode = false
local duration_cache = {}
local add_menu_open = false
local add_menu_geo = nil

local click_state = {
    down_time = 0,
    down_x = -1,
    down_y = -1,
    down_index = -1,
    is_dragging = false
}
local selection_last_added = -1

--------------------------------------------------------------------------------
-- LAYOUT
--------------------------------------------------------------------------------

local function get_layout()
    local x2 = screen_w - SIDE_INSET
    local x1 = x2 - PANEL_WIDTH
    local y1 = TOP_INSET
    local y2 = screen_h - BOTTOM_INSET

    local header_y2 = y1 + HEADER_HEIGHT
    local search_y2 = header_y2 + (search_active and SEARCH_HEIGHT or 0)
    local toolbar_y1 = y2 - TOOLBAR_HEIGHT
    local list_y1 = search_y2 + 4
    local list_y2 = toolbar_y1 - 4

    return {
        x1 = x1,
        x2 = x2,
        y1 = y1,
        y2 = y2,
        header_y2 = header_y2,
        search_y1 = header_y2,
        search_y2 = search_y2,
        list_y1 = list_y1,
        list_y2 = list_y2,
        toolbar_y1 = toolbar_y1,
        list_h = list_y2 - list_y1,
        visible_rows = math.floor((list_y2 - list_y1) / ROW_HEIGHT)
    }
end

local function scroll_to_current()
    if current_index < 0 then
        return
    end
    local L = get_layout()
    local filtered_pos = nil
    for i, entry_wrap in ipairs(filtered_items) do
        if entry_wrap.real_index == current_index then
            filtered_pos = i
            break
        end
    end
    if not filtered_pos then
        return
    end

    local max_scroll = math.max(0, #filtered_items - L.visible_rows)
    if filtered_pos - 1 < scroll_offset then
        scroll_offset = filtered_pos - 1
    elseif filtered_pos > scroll_offset + L.visible_rows then
        scroll_offset = filtered_pos - L.visible_rows
    end
    scroll_offset = math.max(0, math.min(scroll_offset, max_scroll))
end

local function compute_add_menu_geo(L)
    local card_w, card_h = 190, 3 * 36 + 12
    local card_x2 = L.x2 - 10
    local card_x1 = card_x2 - card_w
    local card_y2 = L.toolbar_y1 - 8
    local card_y1 = card_y2 - card_h
    return {
        cx = card_x1 + card_w / 2,
        card_x1 = card_x1,
        card_x2 = card_x2,
        card_y1 = card_y1,
        card_y2 = card_y2,
        row_h = 36
    }
end

local function publish_add_popup_glass(enabled, geo)
    local bounds = geo and {x1 = geo.card_x1, y1 = geo.card_y1, x2 = geo.card_x2, y2 = geo.card_y2} or nil
    common.publish_glass_region("playlist_add_popup", enabled, bounds, screen_w, screen_h,
        ADD_POPUP_RADIUS, ADD_POPUP_GLASS_RADIUS)
end

--------------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------------

local function is_open()
    return pinned or hover_open
end

local function basename(path)
    if not path then
        return ""
    end
    local name = path:match("([^/\\]+)$") or path
    return name
end

-- Safely truncates strings containing multibyte UTF-8 characters
local function truncate_utf8(str, max_chars)
    if not str then
        return ""
    end
    local count = 0
    local res = {}
    for c in str:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        count = count + 1
        if count > max_chars then
            table.insert(res, "...")
            break
        end
        table.insert(res, c)
    end
    return table.concat(res)
end

local function fmt_time(t)
    if not t or t ~= t or t < 0 then
        return ""
    end
    t = math.floor(t)
    local h = math.floor(t / 3600)
    local m = math.floor((t % 3600) / 60)
    local s = t % 60
    if h > 0 then
        return string.format("%d:%02d:%02d", h, m, s)
    end
    return string.format("%02d:%02d", m, s)
end

local function add_hitbox(name, x1, y1, x2, y2, cb)
    if active_ass and name:match("^pl_add_menu_%d+$") then
        common.draw_hover_rrect(active_ass, x1, y1, x2, y2, 6, POPUP_HOVER_COLOR, POPUP_HOVER_ALPHA,
            mouse_x >= x1 and mouse_x <= x2 and mouse_y >= y1 and mouse_y <= y2)
    end
    common.add_hitbox(hitboxes, name, x1, y1, x2, y2, cb)
end
local function point_in(px, py, b)
    return common.point_in(px, py, b)
end
local function draw_icon(ass, glyph, cx, cy, size, color, alpha)
    common.draw_icon(ass, ICON_FONT, glyph, cx, cy, size, color, alpha)
end
local function draw_text(ass, str, x, y, size, color, alpha, align, bold)
    common.draw_text(ass, str, x, y, size, color, alpha, align, bold)
end
local function draw_rrect(ass, x1, y1, x2, y2, r, color, alpha)
    common.draw_rrect(ass, x1, y1, x2, y2, r, color, alpha)
end
local function draw_rrect_outline(ass, x1, y1, x2, y2, radius, color, alpha, width)
    if not width or width <= 0 or alpha == "FF" then return end
    ass:new_event()
    ass:append(string.format("{\\pos(0,0)\\an7\\1a&HFF&\\3c&H%s&\\3a&H%s&\\bord%g\\shad0}",
        color, alpha, width))
    ass:draw_start()
    ass:round_rect_cw(x1, y1, x2, y2, radius)
    ass:draw_stop()
end

local function draw_shadow_rect(ass, x1, y1, x2, y2, color, alpha, blur)
    ass:new_event()
    ass:append(string.format("{\\pos(0,0)\\an7\\1c&H%s&\\1a&H%s&\\bord0\\shad0\\blur%g}", color, alpha, blur or 0))
    ass:draw_start()
    ass:round_rect_cw(x1, y1, x2, y2, 0)
    ass:draw_stop()
end

local function draw_frame_shadow(ass, x1, y1, x2, y2, enabled, color, alpha, size, blur)
    if not enabled then return end
    size = math.max(1, math.floor(size or 1))
    -- Keep the edge from turning into a hard stripe, even when a theme uses
    -- fully opaque ASS alpha (00). The configured value still controls strength.
    local base_alpha = math.min(0xE0, (tonumber(alpha, 16) or 0x70) + 0x40)
    for depth = size, 1, -1 do
        local layer_alpha = math.min(255, base_alpha + (size - depth) * math.floor((255 - base_alpha) / size))
        local a = string.format("%02X", layer_alpha)
        local p = size - depth
        draw_shadow_rect(ass, x1 + p, y1 + p, x2 - p, y1 + p + 1, color, a, blur)
        draw_shadow_rect(ass, x1 + p, y2 - p - 1, x2 - p, y2 - p, color, a, blur)
        draw_shadow_rect(ass, x1 + p, y1 + p, x1 + p + 1, y2 - p, color, a, blur)
        draw_shadow_rect(ass, x2 - p - 1, y1 + p, x2 - p, y2 - p, color, a, blur)
    end
end

local function has_modifier(name, event)
    local key_name = event and (event.key_name or event.key) or ""
    return key_name:lower():find(name .. "+", 1, true) ~= nil
end

local function clear_selection()
    selected_indices = {}
    selected_index = -1
    selection_anchor = -1
    selection_last_added = -1
end

local function set_single_selection(index)
    selected_indices = {[index] = true}
    selected_index = index
    selection_anchor = index
    selection_last_added = index
end

local function select_row(index, event)
    local ctrl = has_modifier("ctrl", event)
    local shift = has_modifier("shift", event)

    if shift then
        -- Use last-added item as anchor if available, otherwise use selection_anchor
        local range_start = (selection_last_added >= 0) and selection_last_added or selection_anchor
        if range_start >= 0 then
            local first, last = math.min(range_start, index), math.max(range_start, index)
            if not ctrl then
                selected_indices = {}
            end
            for i = first, last do
                selected_indices[i] = true
            end
            selected_index = index
        end
    elseif ctrl then
        if selected_indices[index] then
            selected_indices[index] = nil
        else
            selected_indices[index] = true
            selection_last_added = index  -- Track the last added item
        end
        selected_index = index
        -- Only set anchor if this is the first item being selected
        if selection_anchor < 0 then
            selection_anchor = index
        end
    else
        set_single_selection(index)
    end
end

local function sorted_selected_indices()
    local indices = {}
    for index in pairs(selected_indices) do
        indices[#indices + 1] = index
    end
    table.sort(indices)
    return indices
end

local function filtered_position_for_index(index)
    for position, entry_wrap in ipairs(filtered_items) do
        if entry_wrap.real_index == index then
            return position
        end
    end
    return nil
end

local function render_add_menu(ass, geo)
    common.draw_rrect(ass, geo.card_x1, geo.card_y1, geo.card_x2, geo.card_y2, ADD_POPUP_RADIUS, ADD_POPUP_BG, ADD_POPUP_BG_ALPHA)
    if ADD_POPUP_BORDER_WIDTH > 0 then draw_rrect_outline(ass, geo.card_x1, geo.card_y1, geo.card_x2, geo.card_y2, ADD_POPUP_RADIUS, ADD_POPUP_BORDER_COLOR, ADD_POPUP_BORDER_ALPHA, ADD_POPUP_BORDER_WIDTH) end

    local entries = {
        {label = "Add file", icon = ICON.add_file, cb = common.do_add_file},
        {label = "Add folder", icon = ICON.add_folder, cb = common.do_add_folder},
        {label = "Add URL", icon = ICON.add_url, cb = common.do_add_url}
    }

    for i, e in ipairs(entries) do
        local row_y1 = geo.card_y1 + 6 + (i - 1) * geo.row_h
        local row_y2 = row_y1 + geo.row_h
        local mid_y = (row_y1 + row_y2) / 2
        draw_icon(ass, e.icon, geo.card_x1 + 24, mid_y, 16, ICON_COLOR, ICON_DIM_A)
        common.draw_text(ass, e.label, geo.card_x1 + 42, mid_y, 16, TEXT, "00", 4, false)
        add_hitbox(
            "pl_add_menu_" .. i,
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
-- PLAYLIST DATA
--------------------------------------------------------------------------------

local function get_repeat_mode()
    local loop_file = mp.get_property("loop-file", "no")
    local loop_playlist = mp.get_property("loop-playlist", "no")

    if loop_playlist == "inf" then
        return "all"        -- or whatever label you use
    elseif loop_file == "inf" then
        return "one"
    else
        return "off"
    end
end

local repeat_mode = get_repeat_mode()
mp.set_property_native("user-data/cadre_playlist/shuffle", shuffle_on)
mp.set_property("user-data/cadre_playlist/repeat", repeat_mode)

local function rebuild_filtered()
    filtered_items = {}
    local q = search_query:lower()
    for i, it in ipairs(items) do
        local title = (it.title or basename(it.filename or "")):lower()
        if q == "" or title:find(q, 1, true) then
            filtered_items[#filtered_items + 1] = {real_index = i - 1, item = it}
        end
    end
end

local function reconcile_shuffle_order()
    if not shuffle_on then
        shuffle_order = {}
        return
    end
    local n = #items
    local valid = {}
    local seen = {}
    for _, idx in ipairs(shuffle_order) do
        if idx < n then
            valid[#valid + 1] = idx
            seen[idx] = true
        end
    end
    local missing = {}
    for i = 0, n - 1 do
        if not seen[i] then
            missing[#missing + 1] = i
        end
    end
    for i = #missing, 2, -1 do
        local j = math.random(i)
        missing[i], missing[j] = missing[j], missing[i]
    end
    for _, idx in ipairs(missing) do
        valid[#valid + 1] = idx
    end
    shuffle_order = valid
end

local function refresh_playlist()
    items = mp.get_property_native("playlist") or {}
    current_index = mp.get_property_number("playlist-pos", -1)
    local valid_selection = {}
    for index in pairs(selected_indices) do
        if index >= 0 and index < #items then
            valid_selection[index] = true
        end
    end
    selected_indices = valid_selection
    if selected_index >= #items then
        selected_index = -1
    end
    if selection_anchor >= #items then
        selection_anchor = -1
    end
    rebuild_filtered()
    reconcile_shuffle_order()
end

--------------------------------------------------------------------------------
-- SHUFFLE (PLAY ORDER, not list order)
--------------------------------------------------------------------------------

local function rebuild_shuffle_order()
    local n = #items
    local order = {}
    for i = 0, n - 1 do
        order[#order + 1] = i
    end
    for i = #order, 2, -1 do
        local j = math.random(i)
        order[i], order[j] = order[j], order[i]
    end
    if current_index >= 0 then
        for i, v in ipairs(order) do
            if v == current_index then
                table.remove(order, i)
                table.insert(order, 1, current_index)
                break
            end
        end
    end
    shuffle_order = order
end

local function toggle_shuffle()
    shuffle_on = not shuffle_on
    mp.set_property_native("user-data/cadre_playlist/shuffle", shuffle_on)
    mp.set_property_bool("shuffle", false)
    if shuffle_on then
        rebuild_shuffle_order()
    else
        shuffle_order = {}
    end
end

local function advance_shuffled(direction)
    if #shuffle_order == 0 then
        rebuild_shuffle_order()
    end
    if #shuffle_order == 0 then
        return
    end

    local pos = nil
    for i, v in ipairs(shuffle_order) do
        if v == current_index then
            pos = i
            break
        end
    end
    if not pos then
        rebuild_shuffle_order()
        pos = 1
    end

    local next_pos = pos + direction
    if next_pos > #shuffle_order then
        if repeat_mode == "all" then
            rebuild_shuffle_order()
            next_pos = 1
        else
            return
        end
    elseif next_pos < 1 then
        if repeat_mode == "all" then
            next_pos = #shuffle_order
        else
            return
        end
    end
    mp.commandv("playlist-play-index", shuffle_order[next_pos])
end

local function cycle_repeat()
    if repeat_mode == "off" then
        repeat_mode = "all"
        common.set_property_cached("loop-playlist", "inf")
        common.set_property_cached("loop-file", "no")
    elseif repeat_mode == "all" then
        repeat_mode = "one"
        common.set_property_cached("loop-playlist", "no")
        common.set_property_cached("loop-file", "inf")
    elseif repeat_mode == "one" then
        repeat_mode = "auto"
        common.set_property_cached("loop-playlist", "no")
        common.set_property_cached("loop-file", "no")
    else
        repeat_mode = "off"
        common.set_property_cached("loop-playlist", "no")
        common.set_property_cached("loop-file", "no")
    end
    mp.set_property("user-data/cadre_playlist/repeat", repeat_mode)
end

mp.register_event(
    "end-file",
    function(event)
        if event.reason == "eof" and shuffle_on then
            if repeat_mode == "one" then
                mp.commandv("playlist-play-index", current_index)
            else
                advance_shuffled(1)
            end
        end
    end
)

--------------------------------------------------------------------------------
-- AUTO-NEXT: load next file in folder when at last playlist entry (timer-based)
--------------------------------------------------------------------------------

local EXT_SET = common.media_extension_set()

local function is_media_file(name)
    local ext = name:match("%.([^.]+)$")
    return ext and EXT_SET[ext:lower()]
end

local function get_dir_and_name(path)
    if not path then
        return nil, nil
    end
    if path:match("^https?://") then
        return nil, nil
    end
    local dir = path:match("^(.+)[/\\][^/\\]+$")
    local name = path:match("[/\\]([^/\\]+)$") or path
    if not dir then
        dir = "."
    end
    return dir, name
end

local function next_file_in_folder()
    local path = mp.get_property("path")
    local dir, name = get_dir_and_name(path)
    if not dir or not name then
        return nil
    end

    -- Use dir command to list files
    local cmd = 'dir /b "' .. dir .. '"'
    local handle = io.popen(cmd)
    if not handle then
        return nil
    end

    local files = {}
    for line in handle:lines() do
        if is_media_file(line) then
            files[#files + 1] = line
        end
    end
    handle:close()

    table.sort(files)

    local idx = nil
    for i, f in ipairs(files) do
        if f == name then
            idx = i
            break
        end
    end
    if not idx or idx >= #files then
        return nil
    end

    return dir .. "\\" .. files[idx + 1]
end

local auto_next_triggered_for = nil
local auto_next_started_at = mp.get_time()

mp.register_event("file-loaded", function()
    auto_next_triggered_for = nil
    auto_next_started_at = mp.get_time()
end)

mp.add_periodic_timer(
    0.2,
    function()
        if repeat_mode ~= "auto" then
            return
        end

        local pos = mp.get_property_number("time-pos", 0)
        local dur = mp.get_property_number("duration", 0)
        if dur <= 0 then
            -- Still images only have a useful playback duration when mpv's
            -- image-display-duration option is finite.
            dur = mp.get_property_number("image-display-duration", 0)
            if dur <= 0 then return end
            pos = mp.get_time() - auto_next_started_at
        elseif pos <= 0 then
            return
        end

        local remaining = dur - pos
        if remaining > 0.25 or remaining <= 0 then
            return
        end

        local path = mp.get_property("path")
        if auto_next_triggered_for == path then
            return
        end
        auto_next_triggered_for = path

        local pl = mp.get_property_native("playlist", {})
        local ppos = mp.get_property_number("playlist-pos", -1)
        if #pl <= 0 or ppos < 0 then
            return
        end

        -- Only act when at the last entry in the playlist.
        if ppos < #pl - 1 then
            return
        end

        local next_path = next_file_in_folder()
        if not next_path then
            return
        end

        mp.commandv("loadfile", next_path, "append-play")
        local new_pl = mp.get_property_native("playlist", {})
        mp.commandv("playlist-play-index", #new_pl - 1)
        mp.set_property_bool("pause", false)
    end
)
--------------------------------------------------------------------------------
-- REMOVE / DELETE
--------------------------------------------------------------------------------

local function remove_selected()
    local indices = sorted_selected_indices()
    for i = #indices, 1, -1 do
        mp.commandv("playlist-remove", indices[i])
    end
    clear_selection()
    refresh_playlist()
end

local function delete_selected_to_recycle_bin()
    local indices = sorted_selected_indices()
    if #indices == 0 then
        return
    end

    local paths = {}
    for _, index in ipairs(indices) do
        local path = items[index + 1].filename
        if not path or path:match("^https?://") then
            mp.osd_message("Cannot delete a URL/stream entry", 2)
            return
        end
        paths[#paths + 1] = path
    end

    for i = #indices, 1, -1 do
        mp.commandv("playlist-remove", indices[i])
    end
    local moved = 0
    for _, path in ipairs(paths) do
        if common.send_to_trash(path) then
            moved = moved + 1
        end
    end
    if moved > 0 then
        mp.osd_message("Moved " .. moved .. " file" .. (moved == 1 and "" or "s") .. " to Recycle Bin", 2)
    end
    clear_selection()
    refresh_playlist()
end

local function reorder_selected(target_index)
    local selected = sorted_selected_indices()
    -- -2 and #items are the start and end insertion boundaries.
    if #selected == 0 or target_index < -2 or target_index > #items then
        return
    end

    local selected_lookup = {}
    for _, index in ipairs(selected) do
        selected_lookup[index] = true
    end
    if target_index >= 0 and target_index < #items and selected_lookup[target_index] then
        return
    end

    local desired = {}
    local insert_at = 1
    for index = 0, #items - 1 do
        if not selected_lookup[index] then
            if index == target_index then
                insert_at = #desired + 1
            end
            desired[#desired + 1] = index
        end
    end
    if target_index == -2 then
        insert_at = 1
    elseif target_index == #items then
        insert_at = #desired + 1
    end
    for i = #selected, 1, -1 do
        table.insert(desired, insert_at, selected[i])
    end

    local current = {}
    for index = 0, #items - 1 do
        current[#current + 1] = index
    end
    for destination = 1, #desired do
        if current[destination] ~= desired[destination] then
            local source = destination
            while current[source] ~= desired[destination] do
                source = source + 1
            end
            mp.commandv("playlist-move", source - 1, destination - 1)
            local moved = table.remove(current, source)
            table.insert(current, destination, moved)
        end
    end

    local new_position_by_old = {}
    for position, old_index in ipairs(desired) do
        new_position_by_old[old_index] = position - 1
    end
    for i, index in ipairs(shuffle_order) do
        shuffle_order[i] = new_position_by_old[index] or index
    end

    selected_indices = {}
    for position, index in ipairs(desired) do
        if selected_lookup[index] then
            selected_indices[position - 1] = true
        end
    end
    local reordered_selection = sorted_selected_indices()
    selected_index = reordered_selection[1] or -1
    selection_anchor = selected_index
    selection_last_added = selected_index
end

--------------------------------------------------------------------------------
-- SAVE / LOAD PLAYLIST
--------------------------------------------------------------------------------

local function write_m3u8(path, entries)
    local f = io.open(path, "w")
    if not f then
        mp.osd_message("Could not open file for writing: " .. path, 3)
        return false
    end
    f:write("#EXTM3U\n")
    for _, it in ipairs(entries) do
        local title = it.title or basename(it.filename or "")
        f:write("#EXTINF:-1," .. title .. "\n")
        f:write((it.filename or "") .. "\n")
    end
    f:close()
    return true
end

local function do_save_playlist()
    if #items == 0 then
        mp.osd_message("Playlist is empty", 1.5)
        return
    end
    local path =
        common.save_file_dialog(
        {
            title = "Save Playlist",
            filter = "M3U8 playlist|*.m3u8|M3U playlist|*.m3u|All files|*.*",
            default_name = "playlist.m3u8"
        }
    )
    if not path then
        return
    end
    if write_m3u8(path, items) then
        mp.osd_message("Playlist saved: " .. basename(path), 2)
    end
end

local function do_load_playlist()
    local paths =
        common.pick_files_dialog(
        {
            title = "Load Playlist",
            filter = "Playlist files|*.m3u8;*.m3u;*.pls|All files|*.*",
            multiselect = false
        }
    )

    if not paths or type(paths) ~= "table" or #paths == 0 then
        return
    end

    local path = paths[1]
    if type(path) ~= "string" or path == "" then
        mp.msg.error("cadre_playlist: invalid path value: " .. tostring(path))
        return
    end

    mp.commandv("loadlist", path, load_append_mode and "append" or "replace")
    mp.osd_message("Playlist loaded: " .. basename(path), 2)
end

--------------------------------------------------------------------------------
-- SHARED STATE PUBLISHING
--------------------------------------------------------------------------------

local function publish_bounds(L)
    mp.set_property_native("user-data/cadre_playlist/visible", panel_visible)
    common.publish_glass_region(
        "playlist", GLASS_BLUR and panel_visible and L ~= nil,
        L and {x1 = L.x1, y1 = L.y1, x2 = L.x2, y2 = L.y2} or nil,
        screen_w, screen_h, RADIUS, GLASS_BLUR_RADIUS
    )
    if panel_visible and L then
        mp.set_property_native("user-data/cadre_playlist/x1", L.x1)
        mp.set_property_native("user-data/cadre_playlist/y1", L.y1)
        mp.set_property_native("user-data/cadre_playlist/x2", L.x2)
        mp.set_property_native("user-data/cadre_playlist/y2", L.y2)
    end
end

local function enable_search_bindings()
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 -_."
    for i = 1, #chars do
        local c = chars:sub(i, i)
        mp.add_forced_key_binding(
            c,
            "cadre_search_char_" .. c,
            function()
                search_query = search_query .. c
                rebuild_filtered()
                scroll_offset = 0
                render()
            end,
            {repeatable = true}
        )
    end
    mp.add_forced_key_binding(
        "BS",
        "cadre_search_backspace",
        function()
            if #search_query > 0 then
                search_query = search_query:sub(1, -2)
                rebuild_filtered()
                scroll_offset = 0
                render()
            end
        end,
        {repeatable = true}
    )
end

local function disable_search_bindings()
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 -_."
    for i = 1, #chars do
        mp.remove_key_binding("cadre_search_char_" .. chars:sub(i, i))
    end
    mp.remove_key_binding("cadre_search_backspace")
end

--------------------------------------------------------------------------------
-- RENDER
--------------------------------------------------------------------------------
local function render_header(ass, L)
    local count_str = #items == 1 and "1 item" or (#items .. " items")

    local x, align
    if TITLE_POSITION == "center" then
        x = math.floor((L.x1 + L.x2) / 2)
        align = 5
    else
        x = L.x1 + 16
        align = 4
    end

    draw_text(ass, "Playlist", x, L.y1 + 14, TITLE_FONT_SIZE, TEXT, "00", align, true)
    draw_text(ass, count_str, x, L.y1 + 30, TITLE_FONT_SIZE - 2, TEXT, "20", align, false)

    local search_icon_x = L.x2 - 24
    draw_icon(ass, ICON.search, search_icon_x, L.y1 + 20, ICON_SIZE, ICON_COLOR, search_active and "30" or "60")
    add_hitbox(
        "toggle_search",
        search_icon_x - 14,
        L.y1 + 4,
        search_icon_x + 14,
        L.y1 + 34,
        function()
            search_active = not search_active
            if search_active then
                enable_search_bindings()
            else
                disable_search_bindings()
                search_query = ""
                rebuild_filtered()
            end
        end
    )

    if search_active then
        draw_rrect(ass, L.x1 + 12, L.search_y1 + 2, L.x2 - 12, L.search_y2 - 4, 12, BARBG, ALPHA_BAR_BG)
        local display_q = search_query == "" and "Search playlist..." or search_query
        draw_text(
            ass,
            display_q,
            L.x1 + 22,
            (L.search_y1 + L.search_y2) / 2,
            TITLE_FONT_SIZE - 2,
            search_query == "" and DIM or TEXT,
            "10",
            4,
            false
        )
    end
end

local function render_empty_state(ass, L)
    draw_text(
        ass,
        "Playlist is empty",
        (L.x1 + L.x2) / 2,
        (L.list_y1 + L.list_y2) / 2 - 8,
        TITLE_FONT_SIZE,
        TEXT,
        "30",
        5,
        false
    )
    draw_text(
        ass,
        "Use + below to add files",
        (L.x1 + L.x2) / 2,
        (L.list_y1 + L.list_y2) / 2 + 12,
        TITLE_FONT_SIZE - 2,
        TEXT,
        "50",
        5,
        false
    )
end

local function render_row(ass, L, row, entry_wrap)
    local real_idx = entry_wrap.real_index
    local entry = entry_wrap.item
    local row_y1 = L.list_y1 + row * ROW_HEIGHT
    local row_y2 = row_y1 + math.max(1, ROW_HEIGHT - ROW_GAP)

    local is_current = (real_idx == current_index)
    local is_selected = selected_indices[real_idx] == true
    local is_drop_target = drag.active and drag.current_target == real_idx
    local row_x1 = L.x1 + LIST_INSET_LEFT
    local row_x2 = L.x2 - LIST_INSET_RIGHT
    local is_hovered = mouse_x >= row_x1 and mouse_x <= row_x2 and mouse_y >= row_y1 and mouse_y <= row_y2

    local row_color, row_alpha
    if is_current and is_selected then
        row_color = NOW_PLAYING_COLOR
        row_alpha = string.format("%02X", math.min(0xFF, tonumber(CURRENT_ALPHA, 16) + 0x10))
    elseif is_current then
        row_color = NOW_PLAYING_COLOR
        row_alpha = CURRENT_ALPHA
    elseif is_selected then
        row_color = SELECTED_COLOR
        row_alpha = SELECTED_ALPHA
    elseif is_hovered then
        row_color = HOVER_COLOR
        row_alpha = HOVER_ALPHA
    else
        row_color = ROW_BG
        row_alpha = ROW_BG_ALPHA
    end

    local corner_inset = row == 0 and math.max(2, LIST_RADIUS - ROW_RADIUS) or 2
    draw_rrect(
        ass,
        row_x1 + corner_inset,
        row_y1,
        row_x2 - SCROLLBAR_WIDTH - corner_inset + 2,
        row_y2,
        ROW_RADIUS,
        row_color,
        row_alpha
    )

    if is_drop_target then
        ass:new_event()
        ass:append(string.format("{\\pos(0,0)\\an7\\1c&H%s&\\1a&H00&\\bord0\\shad0}", DROP_LINE))
        ass:draw_start()
        ass:round_rect_cw(row_x1 + 2, row_y1 - 2, row_x2 - SCROLLBAR_WIDTH, row_y1, 1)
        ass:draw_stop()
    end

    local idx_str = string.format("%02d", real_idx + 1)
    draw_text(
        ass,
        idx_str,
        row_x1 + ROW_PADDING_X,
        (row_y1 + row_y2) / 2,
        FONT_SIZE - 2,
        INDEX_COLOR,
        INDEX_ALPHA,
        4,
        is_current
    )

    local cached_duration = duration_cache[entry.filename]
    local dur_str = cached_duration and fmt_time(cached_duration) or ""

    local max_chars = 35
    if is_current then
        max_chars = max_chars - 3
    end
    if dur_str ~= "" then
        max_chars = max_chars - 6
    end

    local title = entry.title or basename(entry.filename or "")
    title = truncate_utf8(title, max_chars)

    local title_color = TEXT
    draw_text(
        ass,
        title,
        row_x1 + TITLE_OFFSET_X,
        (row_y1 + row_y2) / 2,
        TITLE_FONT_SIZE,
        title_color,
        "00",
        4,
        is_current
    )

    local rx_right = row_x2 - ROW_RIGHT_INSET_X - SCROLLBAR_WIDTH
    if is_current then
        local paused = mp.get_property_bool("pause", false)
        draw_icon(
            ass,
            paused and ICON.pause or ICON.play,
            rx_right,
            (row_y1 + row_y2) / 2,
            ICON_SIZE,
            TEXT,
            ICON_DIM_A
        )
        rx_right = rx_right - ICON_SIZE - 6
    end

    if dur_str ~= "" then
        draw_text(
            ass,
            dur_str,
            rx_right,
            (row_y1 + row_y2) / 2,
            FONT_SIZE - 2,
            DURATION_COLOR,
            DURATION_ALPHA,
            6,
            false
        )
    end

    add_hitbox(
        "row_" .. real_idx,
        L.x1 + 6,
        row_y1,
        L.x2 - 6,
        row_y2,
        function()
            selected_index = real_idx
        end
    )
end

local function render_scrollbar(ass, L)
    local max_scroll = math.max(0, #filtered_items - L.visible_rows)
    if max_scroll == 0 then
        return
    end

    local track_x1 = L.x2 - SCROLLBAR_WIDTH - 4
    local track_x2 = L.x2 - 4
    draw_rrect(ass, track_x1, L.list_y1, track_x2, L.list_y2, SCROLLBAR_WIDTH / 2, SCROLL_BG, "F0")

    local ratio = L.visible_rows / #filtered_items
    local thumb_h = math.max(20, L.list_h * ratio)
    local thumb_y1 = L.list_y1 + (L.list_h - thumb_h) * (scroll_offset / max_scroll)
    draw_rrect(ass, track_x1, thumb_y1, track_x2, thumb_y1 + thumb_h, SCROLLBAR_WIDTH / 2, SCROLL_FG, "A0")

    add_hitbox(
        "scrollbar",
        track_x1 - 4,
        L.list_y1,
        track_x2 + 4,
        L.list_y2,
        function()
        end
    )
end

local function render_toolbar(ass, L)
    local tx = L.x1 + 20
    local ty = L.toolbar_y1 + TOOLBAR_HEIGHT / 2
    local spacing = TOOLBAR_ICON_SPACING

    draw_icon(ass, ICON.shuffle, tx, ty, TOOLBAR_ICON_SIZE, ICON_COLOR, shuffle_on and "00" or "60")
    add_hitbox("shuffle", tx - 14, ty - 14, tx + 14, ty + 14, toggle_shuffle)
    tx = tx + spacing

    local rep_icon = ICON.repeat_all
    local rep_alpha = repeat_mode ~= "off" and "00" or "60"

    if repeat_mode == "all" then
        rep_icon = ICON.repeat_all
    elseif repeat_mode == "one" then
        rep_icon = ICON.repeat_one
    elseif repeat_mode == "auto" then
        rep_icon = ICON.repeat_auto
    end

    draw_icon(ass, rep_icon, tx, ty, TOOLBAR_ICON_SIZE, ICON_COLOR, rep_alpha)
    add_hitbox("repeat", tx - 14, ty - 14, tx + 14, ty + 14, cycle_repeat)

    local rx = L.x2 - TOOLBAR_ICON_SIZE - SCROLLBAR_WIDTH
    draw_icon(ass, ICON.delete, rx, ty, TOOLBAR_ICON_SIZE, DANGER, "30")
    add_hitbox("delete", rx - 14, ty - 14, rx + 14, ty + 14, delete_selected_to_recycle_bin)
    rx = rx - spacing

    draw_icon(ass, ICON.remove, rx, ty, TOOLBAR_ICON_SIZE, ICON_COLOR, ICON_DIM_A)
    add_hitbox("remove", rx - 14, ty - 14, rx + 14, ty + 14, remove_selected)
    rx = rx - spacing

    draw_icon(ass, ICON.save, rx, ty, TOOLBAR_ICON_SIZE, ICON_COLOR, ICON_DIM_A)
    add_hitbox("save", rx - 14, ty - 14, rx + 14, ty + 14, do_save_playlist)
    rx = rx - spacing

    draw_icon(ass, ICON.load, rx, ty, TOOLBAR_ICON_SIZE, ICON_COLOR, ICON_DIM_A)
    add_hitbox(
        "load",
        rx - 14,
        ty - 14,
        rx + 14,
        ty + 14,
        function()
            load_append_mode = false
            do_load_playlist()
        end
    )
    rx = rx - spacing

    draw_icon(ass, ICON.add, rx, ty, TOOLBAR_ICON_SIZE, ICON_COLOR, ICON_DIM_A)
    add_hitbox(
        "pl_add",
        rx - 14,
        ty - 14,
        rx + 14,
        ty + 14,
        function()
            add_menu_open = not add_menu_open
        end
    )

    if add_menu_open then
        add_menu_geo = compute_add_menu_geo(L)
        publish_add_popup_glass(ADD_POPUP_GLASS, add_menu_geo)
        render_add_menu(ass, add_menu_geo)
    else
        add_menu_geo = nil
        publish_add_popup_glass(false, nil)
    end
end

render = function()
    hitboxes = common.new_hitboxes()
    local ass = assdraw.ass_new()
    active_ass = ass
    local w, h = mp.get_osd_size()

    if not panel_visible then
        render_ctrl:update("", w, h)
        publish_bounds(nil)
        add_menu_geo = nil
        publish_add_popup_glass(false, nil)
        return
    end

    local L = get_layout()
    publish_bounds(L)

    draw_rrect(ass, L.x1, L.y1, L.x2, L.y2, RADIUS, FRAME_BG, FRAME_ALPHA)
    if PANEL_BORDER_WIDTH > 0 and PANEL_BORDER_ALPHA ~= "FF" then
        ass:new_event()
        ass:append(string.format(
            "{\\pos(0,0)\\an7\\1a&HFF&\\3c&H%s&\\3a&H%s&\\bord%g\\shad0}",
            PANEL_BORDER_COLOR, PANEL_BORDER_ALPHA, PANEL_BORDER_WIDTH
        ))
        ass:draw_start()
        ass:round_rect_cw(L.x1, L.y1, L.x2, L.y2, RADIUS)
        ass:draw_stop()
    end
    local list_x1 = L.x1 + LIST_INSET_LEFT
    local list_x2 = L.x2 - LIST_INSET_RIGHT
    draw_rrect(ass, list_x1, L.list_y1, list_x2, L.list_y2, LIST_RADIUS, LIST_BG, LIST_ALPHA)

    render_header(ass, L)

    local max_scroll = math.max(0, #filtered_items - L.visible_rows)
    scroll_offset = math.max(0, math.min(scroll_offset, max_scroll))

    if #filtered_items == 0 then
        render_empty_state(ass, L)
    else
        for row = 0, L.visible_rows - 1 do
            local data_i = row + scroll_offset + 1
            local entry_wrap = filtered_items[data_i]
            if not entry_wrap then
                break
            end
            render_row(ass, L, row, entry_wrap)
        end

        render_scrollbar(ass, L)
    end

    render_toolbar(ass, L)

    -- Draw shadows after scrolling content so they remain fixed at the surfaces' edges.
    -- The viewport is the boundary between the frame and list, so both shadows
    -- follow it: frame shadow on the inside, list shadow on the outside.
    draw_frame_shadow(ass, list_x1, L.list_y1, list_x2, L.list_y2, FRAME_SHADOW,
        FRAME_SHADOW_COLOR, FRAME_SHADOW_ALPHA, FRAME_SHADOW_SIZE, FRAME_SHADOW_BLUR)

    render_ctrl:update(ass.text, w, h)
end

common.on_theme_reload(function(updated)
    apply_theme(updated)
    render_ctrl:invalidate_ass_cache()
    render()
end)
mp.register_script_message("cadre-theme-reload", function() common.reload_theme() end)

--------------------------------------------------------------------------------
-- INPUT
--------------------------------------------------------------------------------

local mouse_over_playlist = false

local function select_all()
    if not panel_visible then
        return
    end
    selected_indices = {}
    for _, entry_wrap in pairs(filtered_items) do
        selected_indices[entry_wrap.real_index] = true
    end
    if #filtered_items > 0 then
        selected_index = filtered_items[#filtered_items].real_index
        selection_anchor = filtered_items[1].real_index
    end
    render()
end

local function scroll_to_filtered_position(position)
    local L = get_layout()
    local max_scroll = math.max(0, #filtered_items - L.visible_rows)
    if position - 1 < scroll_offset then
        scroll_offset = position - 1
    elseif position > scroll_offset + L.visible_rows then
        scroll_offset = position - L.visible_rows
    end
    scroll_offset = math.max(0, math.min(scroll_offset, max_scroll))
end

local function move_selection_focus(direction, extend, additive)
    if #filtered_items == 0 then
        return
    end

    local focus_index = selected_index
    if focus_index < 0 then
        focus_index = current_index
    end
    local position = filtered_position_for_index(focus_index)
    if not position then
        focus_index = current_index
        position = filtered_position_for_index(focus_index)
    end
    if not position then
        position = direction > 0 and 0 or (#filtered_items + 1)
    end
    position = math.max(1, math.min(#filtered_items, position + direction))

    local target_index = filtered_items[position].real_index
    if not extend then
        set_single_selection(target_index)
    else
        local anchor_index = selection_anchor
        local anchor_position = filtered_position_for_index(anchor_index)
        if not anchor_position then
            anchor_position = filtered_position_for_index(focus_index) or position
            anchor_index = filtered_items[anchor_position].real_index
        end

        if not additive then
            selected_indices = {}
        end
        for i = math.min(anchor_position, position), math.max(anchor_position, position) do
            selected_indices[filtered_items[i].real_index] = true
        end
        selection_anchor = anchor_index
        selection_last_added = target_index
        selected_index = target_index
    end

    scroll_to_filtered_position(position)
    render()
end

local function toggle_focused_selection()
    local index = selected_index
    if index < 0 then
        index = current_index
    end
    if not filtered_position_for_index(index) then
        return
    end

    if selected_indices[index] then
        selected_indices[index] = nil
    else
        selected_indices[index] = true
        selection_anchor = index
        selection_last_added = index
    end
    selected_index = index
    render()
end

local function move_selected_by(direction)
    local indices = sorted_selected_indices()
    if #indices == 0 then
        move_selection_focus(direction, false, false)
        return
    end

    if direction < 0 then
        if indices[1] == 0 then
            return
        end
        for _, index in ipairs(indices) do
            mp.commandv("playlist-move", index, index - 1)
        end
    else
        if indices[#indices] >= #items - 1 then
            return
        end
        for i = #indices, 1, -1 do
            local index = indices[i]
            -- playlist-move inserts before its destination, so skip the next entry to move down.
            mp.commandv("playlist-move", index, index + 2)
        end
    end

    local current = {}
    for index = 0, #items - 1 do
        current[#current + 1] = index
    end
    if direction < 0 then
        for _, index in ipairs(indices) do
            local moved = table.remove(current, index + 1)
            table.insert(current, index, moved)
        end
    else
        for i = #indices, 1, -1 do
            local index = indices[i]
            local moved = table.remove(current, index + 1)
            table.insert(current, index + 2, moved)
        end
    end

    local new_position_by_old = {}
    for position, old_index in ipairs(current) do
        new_position_by_old[old_index] = position - 1
    end
    local moved_selection = {}
    for index in pairs(selected_indices) do
        moved_selection[new_position_by_old[index] or index] = true
    end
    selected_indices = moved_selection
    if new_position_by_old[selected_index] then
        selected_index = new_position_by_old[selected_index]
    end
    if new_position_by_old[selection_anchor] then
        selection_anchor = new_position_by_old[selection_anchor]
    end
    if new_position_by_old[selection_last_added] then
        selection_last_added = new_position_by_old[selection_last_added]
    end
    for i, index in ipairs(shuffle_order) do
        shuffle_order[i] = new_position_by_old[index] or index
    end
    render()
end

local keyboard_bindings_enabled = false
local playlist_keyboard_bindings = {
    {
        key = "UP",
        name = "cadre_playlist_key_up",
        repeatable = true,
        fn = function() move_selection_focus(-1, false, false) end
    },
    {
        key = "DOWN",
        name = "cadre_playlist_key_down",
        repeatable = true,
        fn = function() move_selection_focus(1, false, false) end
    },
    {
        key = "Shift+UP",
        name = "cadre_playlist_key_shift_up",
        repeatable = true,
        fn = function() move_selection_focus(-1, true, false) end
    },
    {
        key = "Shift+DOWN",
        name = "cadre_playlist_key_shift_down",
        repeatable = true,
        fn = function() move_selection_focus(1, true, false) end
    },
    {
        key = "Ctrl+UP",
        name = "cadre_playlist_key_ctrl_up",
        repeatable = true,
        fn = function() move_selected_by(-1) end
    },
    {
        key = "Ctrl+DOWN",
        name = "cadre_playlist_key_ctrl_down",
        repeatable = true,
        fn = function() move_selected_by(1) end
    },
    {
        key = "Ctrl+Shift+UP",
        name = "cadre_playlist_key_ctrl_shift_up",
        repeatable = true,
        fn = function() move_selection_focus(-1, true, true) end
    },
    {
        key = "Ctrl+Shift+DOWN",
        name = "cadre_playlist_key_ctrl_shift_down",
        repeatable = true,
        fn = function() move_selection_focus(1, true, true) end
    },
    {key = "Ctrl+SPACE", name = "cadre_playlist_key_ctrl_space", fn = toggle_focused_selection},
    {
        key = "ENTER",
        name = "cadre_playlist_key_enter",
        fn = function()
            if selected_index >= 0 and selected_index < #items then
                mp.commandv("playlist-play-index", selected_index)
            end
        end
    },
    {key = "Ctrl+a", name = "cadre_playlist_key_ctrl_a", fn = select_all}
}

local function update_keyboard_bindings(enabled)
    if enabled == keyboard_bindings_enabled then
        return
    end
    keyboard_bindings_enabled = enabled
    for _, binding in ipairs(playlist_keyboard_bindings) do
        if enabled then
            mp.add_forced_key_binding(binding.key, binding.name, binding.fn, {repeatable = binding.repeatable})
        else
            mp.remove_key_binding(binding.name)
        end
    end
end

local function osc_popup_under_mouse()
    local popup = mp.get_property_native("user-data/cadre_osc/popup", {}) or {}
    local wheel = mp.get_property_native("user-data/cadre_osc/speed-wheel", {}) or {}
    local function contains(bounds)
        return bounds.visible == true and mouse_x >= (bounds.x1 or math.huge)
            and mouse_x <= (bounds.x2 or -math.huge) and mouse_y >= (bounds.y1 or math.huge)
            and mouse_y <= (bounds.y2 or -math.huge)
    end
    return contains(popup) or contains(wheel)
end

local function update_wheel_bindings(over)
    if over == mouse_over_playlist then
        return
    end
    mouse_over_playlist = over
    if over then
        mp.add_forced_key_binding(
            "WHEEL_UP",
            "cadre_playlist_wheel_up",
            function()
                if osc_popup_under_mouse() then
                    mp.commandv("script-message-to", "cadre_osc", "cadre-osc-dialog-wheel", "up")
                    return
                end
                scroll_offset = math.max(0, scroll_offset - 3)
                render()
            end
        )
        mp.add_forced_key_binding(
            "WHEEL_DOWN",
            "cadre_playlist_wheel_down",
            function()
                if osc_popup_under_mouse() then
                    mp.commandv("script-message-to", "cadre_osc", "cadre-osc-dialog-wheel", "down")
                    return
                end
                local L = get_layout()
                local max_scroll = math.max(0, #filtered_items - L.visible_rows)
                scroll_offset = math.min(max_scroll, scroll_offset + 3)
                render()
            end
        )
    else
        mp.remove_key_binding("cadre_playlist_wheel_up")
        mp.remove_key_binding("cadre_playlist_wheel_down")
    end
end

local function row_at_xy(L, px, py)
    if px < L.x1 or px > L.x2 then
        return nil
    end
    if py < L.list_y1 or py > L.list_y2 then
        return nil
    end
    local row = math.floor((py - L.list_y1) / ROW_HEIGHT)
    local data_i = row + scroll_offset + 1
    local entry_wrap = filtered_items[data_i]

    return entry_wrap and entry_wrap.real_index or nil
end

local function drop_target_at_xy(L, px, py)
    if px < L.x1 or px > L.x2 or py < L.list_y1 or py > L.list_y2 then
        return nil
    end
    local row = math.floor((py - L.list_y1) / ROW_HEIGHT)
    local data_i = row + scroll_offset + 1
    local entry_wrap = filtered_items[data_i]
    if not entry_wrap then
        return nil
    end

    -- Each row is split into before/after insertion zones. This makes the
    -- end boundary reachable by dropping in the lower half of the last item.
    if (py - L.list_y1) % ROW_HEIGHT < ROW_HEIGHT / 2 then
        return entry_wrap.real_index == 0 and -2 or entry_wrap.real_index
    end
    return entry_wrap.real_index + 1
end

local DRAG_THRESHOLD_PX = 5
local CLICK_MAX_MS = 200

local function on_mouse_move_internal()
    local is_over = false
    local L = nil

    if panel_visible then
        L = get_layout()
        is_over = (mouse_x >= L.x1 and mouse_x <= L.x2 and mouse_y >= L.y1 and mouse_y <= L.y2)
    end

    if is_over and osc_popup_under_mouse() then is_over = false end

    update_wheel_bindings(is_over)

    if not panel_visible then
        return
    end

    if
        add_menu_geo and mouse_x >= add_menu_geo.card_x1 - 10 and mouse_x <= add_menu_geo.card_x2 + 10 and
            mouse_y >= add_menu_geo.card_y1 - 10 and
            mouse_y <= add_menu_geo.card_y2 + 10
     then
        return
    end

    if scrollbar_drag then
        local max_scroll = math.max(0, #filtered_items - L.visible_rows)
        local ratio = (mouse_y - L.list_y1) / L.list_h
        scroll_offset = math.floor(ratio * (#filtered_items))
        scroll_offset = math.max(0, math.min(scroll_offset, max_scroll))
        render()
        return
    end

    if drag.active then
        local edge = ROW_HEIGHT
        local max_scroll = math.max(0, #filtered_items - L.visible_rows)
        if mouse_y < L.list_y1 + edge then
            scroll_offset = math.max(0, scroll_offset - 1)
        elseif mouse_y > L.list_y2 - edge then
            scroll_offset = math.min(max_scroll, scroll_offset + 1)
        end
        drag.current_target = drop_target_at_xy(L, mouse_x, mouse_y) or drag.current_target
        render()
        return
    end
    if click_state.down_index >= 0 and not click_state.is_dragging then
        local dx = mouse_x - click_state.down_x
        local dy = mouse_y - click_state.down_y
        if dx*dx + dy*dy > DRAG_THRESHOLD_PX * DRAG_THRESHOLD_PX then
            click_state.is_dragging = true
            -- Start drag if there are selected items
            local idx = click_state.down_index
            if selected_indices[idx] or (selected_index == idx) then
                drag.active = true
                drag.from_index = idx
                drag.indices = sorted_selected_indices()
                if #drag.indices == 0 then
                    drag.indices = {idx}
                end
            end
        end
    end
    render()
end

local function update_window_dragging()
    local osc_present = common.is_script_loaded("cadre_osc")
    local titlebar_present = common.is_script_loaded("cadre_titlebar")
    if osc_present or titlebar_present then
        return
    end

    local should_drag = true
    if panel_visible then
        local L = get_layout()
        local over_panel = mouse_x >= L.x1 and mouse_x <= L.x2 and mouse_y >= L.y1 and mouse_y <= L.y2
        if over_panel then
            should_drag = false
        end
    end
    mp.set_property_bool("window-dragging", should_drag)
end

mp.observe_property(
    "mouse-pos",
    "native",
    function(_, pos)
        if pos then
            mouse_x = pos.x or -1
            mouse_y = pos.y or -1
        end

        if not pinned then
            local osd_dims = mp.get_property_native("osd-dimensions")
            local sw = (osd_dims and osd_dims.w) or screen_w
            local sh = (osd_dims and osd_dims.h) or screen_h
            local in_osc_band = mouse_y >= (sh - OSC_BOTTOM_EXCLUSION)
            local near_right_edge = (not in_osc_band) and (mouse_x >= sw - HOVER_STRIP_WIDTH)

            local over_panel = false

            if panel_visible then
                local L = get_layout()
                over_panel = mouse_x >= L.x1 and mouse_x <= L.x2 and mouse_y >= L.y1 and mouse_y <= L.y2
            end

            if near_right_edge or over_panel then
                if hide_timer then
                    hide_timer:kill()
                    hide_timer = nil
                end
                if not hover_open then
                    hover_open = true
                    panel_visible = true
                    update_keyboard_bindings(true)
                    refresh_playlist()
                    scroll_to_current()
                    render()
                end
            else
                if hover_open then
                    if not hide_timer then
                        hide_timer =
                            mp.add_timeout(
                            HIDE_DELAY_SEC,
                            function()
                                hover_open = false
                                panel_visible = is_open()
                                update_keyboard_bindings(panel_visible)
                                if not panel_visible then
                                    update_wheel_bindings(false)
                                end
                                render()
                                hide_timer = nil
                            end
                        )
                    end
                end
            end
        end

        on_mouse_move_internal()
        update_window_dragging()
    end
)

local function on_mbtn_left(event)
    if not panel_visible then
        return
    end
    local L = get_layout()

    if event.event == "down" or event.event == "press" then
        -- Handle add menu clicks
        if add_menu_open and add_menu_geo then
            local in_menu = mouse_x >= add_menu_geo.card_x1
                and mouse_x <= add_menu_geo.card_x2
                and mouse_y >= add_menu_geo.card_y1
                and mouse_y <= add_menu_geo.card_y2

            if in_menu then
                for _, b in ipairs(hitboxes) do
                    if b.name:match("^pl_add_menu_") and point_in(mouse_x, mouse_y, b) then
                        b.cb()
                        render()
                        return
                    end
                end
                return
            end
        end

        -- Handle scrollbar drag start
        if mouse_x >= L.x2 - SCROLLBAR_WIDTH and mouse_x <= L.x2 then
            if mouse_y >= L.list_y1 and mouse_y <= L.list_y2 then
                scrollbar_drag = true
                return
            end
        end

        -- Handle row click
        local row_idx = row_at_xy(L, mouse_x, mouse_y)
        if row_idx then
            local now = mp.get_time()
            local ctrl = has_modifier("ctrl", event)
            local shift = has_modifier("shift", event)
            local modified = ctrl or shift

            -- Check for double-click (only on unmodified clicks)
            if not modified and last_click_index == row_idx and (now - last_click_time) < DOUBLE_CLICK_SEC then
                mp.commandv("playlist-play-index", row_idx)
                last_click_index = -1
                last_click_time = 0
                render()
                return
            end

            -- Record click state for drag detection
            click_state.down_time = now * 1000
            click_state.down_x = mouse_x
            click_state.down_y = mouse_y
            click_state.down_index = row_idx
            click_state.is_dragging = false
            click_state.was_selected = selected_indices[row_idx] or (selected_index == row_idx)

            -- Update selection immediately for plain clicks
            if not modified and not selected_indices[row_idx] then
                set_single_selection(row_idx)
            end

            last_click_index = not modified and row_idx or -1
            last_click_time = not modified and now or 0
            render()
            return
        end

        -- Fallback: other hitboxes
        for _, b in ipairs(hitboxes) do
            if point_in(mouse_x, mouse_y, b) then
                b.cb()
                render()
                return
            end
        end
    elseif event.event == "up" or event.event == "release" then
        scrollbar_drag = false

        -- Handle drag end (only if we actually started dragging)
        if drag.active and click_state.is_dragging then
            if drag.current_target == -2 or drag.current_target >= 0 then
                reorder_selected(drag.current_target)
            end
            drag.active = false
            drag.from_index = -1
            drag.current_target = -1
            drag.indices = {}
            render()
            return
        end

        -- Reset drag state if we didn't actually drag
        if drag.active and not click_state.is_dragging then
            drag.active = false
            drag.from_index = -1
            drag.current_target = -1
            drag.indices = {}
        end

        -- Handle plain click selection (if not dragging and not modified)
        local row_idx = row_at_xy(L, mouse_x, mouse_y)
        local elapsed = mp.get_time() * 1000 - click_state.down_time
        local dx = mouse_x - click_state.down_x
        local dy = mouse_y - click_state.down_y
        local moved = dx * dx + dy * dy > DRAG_THRESHOLD_PX * DRAG_THRESHOLD_PX
        local is_click = not moved and elapsed < CLICK_MAX_MS and row_idx == click_state.down_index

        if is_click and row_idx then
            local ctrl = has_modifier("ctrl", event)
            local shift = has_modifier("shift", event)

            if not ctrl and not shift then
                -- Plain click: only select this item (if not already selected)
                if not selected_indices[row_idx] and not click_state.was_selected then
                    set_single_selection(row_idx)
                    render()
                elseif click_state.was_selected then
                    set_single_selection(row_idx)
                    render()
                end
            else
                -- Ctrl/Shift: use existing select_row logic
                select_row(row_idx, event)
                render()
            end
        end

        -- Reset click state
        click_state.down_time = 0
        click_state.down_x = -1
        click_state.down_y = -1
        click_state.down_index = -1
        click_state.is_dragging = false
        click_state.was_selected = false
    end
end

local function relay_down(key_name)
    on_mbtn_left({event = "down", key_name = key_name or ""})
end
local function relay_up(key_name)
    on_mbtn_left({event = "up", key_name = key_name or ""})
end

mp.register_script_message("playlist-mbtn-left-down", relay_down)
mp.register_script_message("playlist-mbtn-left-up", relay_up)
mp.add_key_binding("Shift+a", "cadre_playlist_select_all", select_all, {repeatable = false})

local function update_mbtn_binding()
    local osc_claimed = common.is_script_loaded("cadre_osc")
    local titlebar_present = common.is_script_loaded("cadre_titlebar")
    if osc_claimed or titlebar_present then
        -- OSC is active, release the bindings so the OSD/Titlebar can be clicked
        mp.remove_key_binding("cadre_playlist_mbtn_left")
        mp.remove_key_binding("cadre_playlist_ctrl_mbtn_left")
        mp.remove_key_binding("cadre_playlist_shift_mbtn_left")
        mp.remove_key_binding("cadre_playlist_ctrl_shift_mbtn_left")
        mp.remove_key_binding("cadre_playlist_mbtn_left_dbl")
    else
        -- OSC is inactive, playlist takes control of the clicks
        mp.add_forced_key_binding("MBTN_LEFT", "cadre_playlist_mbtn_left", on_mbtn_left, {complex = true})
        mp.add_forced_key_binding("Ctrl+MBTN_LEFT", "cadre_playlist_ctrl_mbtn_left", on_mbtn_left, {complex = true})
        mp.add_forced_key_binding("Shift+MBTN_LEFT", "cadre_playlist_shift_mbtn_left", on_mbtn_left, {complex = true})
        mp.add_forced_key_binding(
            "Ctrl+Shift+MBTN_LEFT",
            "cadre_playlist_ctrl_shift_mbtn_left",
            on_mbtn_left,
            {complex = true}
        )

        mp.add_key_binding(
            "MBTN_LEFT_DBL",
            "cadre_playlist_mbtn_left_dbl",
            function()
                local L = get_layout()
                local in_panel =
                    panel_visible and mouse_x >= L.x1 and mouse_x <= L.x2 and mouse_y >= L.y1 and mouse_y <= L.y2
                if in_panel then
                    return
                end
                mp.commandv("cycle", "fullscreen")
            end
        )
    end
end

-- Dynamically watching the property.
mp.observe_property("user-data/cadre_scripts/cadre_osc/loaded", "bool", update_mbtn_binding)
mp.observe_property("user-data/cadre_scripts/cadre_titlebar/loaded", "bool", update_mbtn_binding)

-- DEL bindings
mp.add_key_binding("DEL", "cadre_playlist_delete", remove_selected)
mp.add_key_binding("Shift+DEL", "cadre_playlist_shift_delete", delete_selected_to_recycle_bin)
mp.add_key_binding("DEL", "cadre_playlist_delete", remove_selected)
mp.add_key_binding("Shift+DEL", "cadre_playlist_shift_delete", delete_selected_to_recycle_bin)

--------------------------------------------------------------------------------
-- VISIBILITY / BRIDGE
--------------------------------------------------------------------------------

local function set_pinned(v)
    pinned = v
    hover_open = false
    panel_visible = is_open()
    update_keyboard_bindings(panel_visible)
    if not panel_visible then
        update_wheel_bindings(false)
    end
    if panel_visible then
        refresh_playlist()
        scroll_to_current()
    end
    render()
end

local function toggle_visible()
    set_pinned(not pinned)
end

mp.register_script_message("toggle-playlist", toggle_visible)
mp.register_script_message("toggle-shuffle", toggle_shuffle)
mp.register_script_message("cycle-repeat", cycle_repeat)

mp.register_script_message(
    "playlist-prev",
    function()
        if shuffle_on then
            advance_shuffled(-1)
        else
            mp.commandv("playlist-prev", "weak")
        end
    end
)
mp.register_script_message(
    "playlist-next",
    function()
        if shuffle_on then
            advance_shuffled(1)
            return
        end

        local pl = mp.get_property_native("playlist", {})
        local pos = mp.get_property_number("playlist-pos", -1)

        -- If there is a next entry in the playlist, always go to it.
        if pos >= 0 and pos < #pl - 1 then
            mp.commandv("playlist-next", "weak")
            return
        end

        -- At last playlist entry: mode-specific behavior.
        if repeat_mode == "off" then
            -- Do nothing.
            return
        elseif repeat_mode == "all" then
            -- Wrap to first item in playlist.
            mp.commandv("playlist-play-index", 0)
            mp.set_property_bool("pause", false)
            return
        elseif repeat_mode == "one" then
            -- Restart the current file.
            mp.command("seek 0")
            mp.set_property_bool("pause", false)
            return
        elseif repeat_mode == "auto" then
            -- Load next file in folder if it exists.
            local next_path = next_file_in_folder()
            if not next_path then
                return
            end

            mp.commandv("loadfile", next_path, "append-play")
            local new_pl = mp.get_property_native("playlist", {})
            mp.commandv("playlist-play-index", #new_pl - 1)
            mp.set_property_bool("pause", false)
            return
        end
    end
)

mp.observe_property(
    "playlist",
    "native",
    function()
        refresh_playlist()
        render()
    end
)
mp.observe_property(
    "playlist-pos",
    "number",
    function(_, v)
        current_index = v or -1
        if panel_visible then
            render()
        end
    end
)
mp.observe_property(
    "pause",
    "bool",
    function()
        if panel_visible then
            render()
        end
    end
)

mp.observe_property(
    "duration",
    "number",
    function(_, v)
        if v and v > 0 then
            local path = mp.get_property("path")
            if path then
                duration_cache[path] = v
                if panel_visible then
                    render()
                end
            end
        end
    end
)

mp.observe_property(
    "osd-dimensions",
    "native",
    function(_, val)
        if not val then
            return
        end
        screen_w = val.w
        screen_h = val.h
        render()
    end
)
common.bind("playlist", "p", "cadre_playlist_toggle", function()
  mp.commandv("script-message", "toggle-playlist")
end)
render()
