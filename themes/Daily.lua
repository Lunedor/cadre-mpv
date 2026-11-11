local M = {}

M.theme_name = "Daily"
M.theme_author = "Lunedor"

local M = {}

-- Daily Refined
-- Intended minimum OSC-coordinate width: 960 px.
-- Not runtime-tested.

-- Shared identity
M.text_color = "ECEEF1"
M.surface_color = "111419"
M.accent_color = "78797A"
M.alpha_panel_bg = "97"

-- Titlebar: original settings restored
M.panel_height_tb = 34
M.button_width_tb = 40
M.title_font_size_tb = 16
M.surface_color_tb = "0B0D10"
M.color_button_bg_tb = "272C34"
M.color_button_pressed_bg_tb = "343B45"
M.color_close_bg_tb = "BA110C"

-- Invisible OSC container
-- Timeline target: y=40.
-- Main row target: y=66+16=82.
-- Capsule bounds: sides 60..104, center 56..108.
M.height_panel_osc = 120
M.alpha_panel_bg_osc = "B0"

M.osc_layout = {
    button_row = {
        anchor = "center",
        offset = 16,
    },
    seekbar = {
        anchor = "panel_top",
        panel_inset = 20,
    },
}

-- Supported launchers
-- webdav is not listed in the supplied OSC action reference.
M.osc_L1 = "stream"
M.osc_L2 = "youtube"
M.osc_L3 = "music_mode"
M.osc_L4 = "webdav"

M.osc_C1 = "prev"
M.osc_C2 = "play"
M.osc_C3 = "stop"
M.osc_C4 = "next"

-- chapter_list is not listed in the supplied OSC action reference.
M.osc_R1 = "volume"
M.osc_R2 = "speed_control"
M.osc_R3 = "subtitle_list"
M.osc_R4 = "settings"

-- Timeline
M.inset_side_seekbar_osc = 18
M.height_normal_seekbar = 10
M.height_hover_seekbar = 12
M.color_track_fg_osc = "E1E4E9"
M.color_track_bg_osc = "626873"
M.position_time_label_osc = "inline"
M.enabled_shadow_time_label_osc = true

M.width_thumb = 5
M.height_thumb = 7
M.thumb_color = "FFFFFF"

-- Icons
M.icon_spacing = 38
M.color_icon_osc = "C6CBD3"

-- Shared capsule decoration
M.enabled_bg_icon_group_osc = true
M.color_bg_icon_group_osc = "111419"
M.alpha_bg_icon_group_osc = "E7"
M.pad_bg_icon_group_osc = 6
M.height_bg_icon_group_osc = 44
M.radius_bg_icon_group_osc = 12

M.enabled_border_icon_group_osc = true
M.alpha_border_icon_group_osc = "19"

M.osc_group_overrides = {
    C = {
        group = {
            color = "1C2129",
            alpha = "EF",
            height = 52,
            radius = 14,
            border_alpha = "30",
        },
    },
}

M.osc_slot_overrides = {
    osc_C1 = {
        icon_size = 20,
    },
    osc_C2 = {
        icon_size = 28,
        icon_color = "F5F7FA",
        button_background = true,
        button_color = "454E5B",
        button_alpha = "FF",
        button_height = 40,
        button_padding = 8,
        button_radius = 10,
        hover_bg_color = "596575",
        hover_bg_alpha = "FF",
        hover_radius = 10,
    },
    osc_C3 = {
        icon_size = 20,
    },
}

for _, slot in ipairs({
    "osc_L1", "osc_L2", "osc_L3", "osc_L4",
    "osc_C1", "osc_C2", "osc_C3",
    "osc_R1", "osc_R2", "osc_R3",
    "osc_R4", "osc_R5", "osc_R6",
}) do
    local override = M.osc_slot_overrides[slot] or {}

    override.hover_icon_color = "FFFFFF"
    override.hover_scale = 1

    if override.hover_bg_color == nil then
        override.hover_bg_color = "343B45"
    end

    if override.hover_bg_alpha == nil then
        override.hover_bg_alpha = "FF"
    end

    M.osc_slot_overrides[slot] = override
end

-- Preview surfaces
M.chapter_tooltip_bg_color = "111419"
M.chapter_tooltip_bg_alpha = "EF"
M.chapter_tooltip_radius = 7
M.chapter_tooltip_pad_x = 12
M.chapter_tooltip_pad_y = 8

-- Playlist: all original settings restored
M.width_panel_pl = 400
M.side_inset_pl = 14
M.top_inset_pl = 44
M.bottom_inset_pl = 166
M.radius_panel_pl = 0
M.osc_bottom_exclusion_pl = 166

M.surface_color_pl = "191E25"
M.alpha_panel_bg_pl = "97"

M.color_frame_pl = "202630"
M.alpha_frame_pl = "97"

M.color_list_bg_pl = "0E1217"
M.alpha_list_bg_pl = "FF"
M.list_inset_left_pl = 10
M.list_inset_right_pl = 10
M.list_radius_pl = 8

M.frame_shadow_pl = true
M.frame_shadow_alpha_pl = "67"
M.frame_shadow_size_pl = 4

M.row_bg_pl = "0E1217"
M.row_bg_alpha_pl = "FF"
M.row_height_pl = 44
M.row_gap_pl = 3
M.row_radius_pl = 7

M.row_padding_x_pl = 18
M.title_offset_x_pl = 46
M.row_right_inset_x_pl = 18

M.text_color_pl = "E4E8EE"
M.color_icon_pl = "BCC4D0"
M.color_dim_pl = "8D98A7"

M.color_index_pl = "748090"
M.alpha_index_pl = "FF"
M.color_duration_pl = "919BA9"

M.color_hover_pl = "252D38"
M.alpha_hover_pl = "E7"

M.color_selected_pl = "414D5E"
M.alpha_selected_pl = "DF"

M.color_current_pl = "666F7B"
M.alpha_current_pl = "7F"

M.color_scroll_fg_pl = "596575"
M.color_scroll_bg_pl = "151B23"
M.color_danger_pl = "E05252"
M.toolbar_icon_size_pl = 19
M.toolbar_icon_spacing_pl = 32

-- Original menu settings also restored
M.alpha_panel_bg_mn = "FF"
M.menu_max_visible_items_mn = 16
M.alpha_bg_settings_dialog_osc = "FF"
return M