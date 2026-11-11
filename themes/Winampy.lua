local M = {}

M.theme_name = "Winampy"
M.theme_author = "Lunedor"

-- Shared identity
M.font_ui = "Consolas"
M.font_size = 14
M.text_color = "B5EF74"
M.surface_color = "292A38"
M.alpha_panel_bg = "FF"
M.accent_color = "87C953"
M.panel_radius = 1

-- Titlebar: all original settings restored
M.titlebar_show_mode_tb = "always"
M.panel_height_tb = 28
M.button_width_tb = 30

M.surface_color_tb = "222330"
M.text_color_tb = "C6C8D4"

M.color_button_bg_tb = "454858"
M.alpha_button_bg_tb = "FF"
M.color_button_pressed_bg_tb = "15161F"
M.alpha_button_pressed_bg_tb = "FF"
M.button_radius_tb = 1

M.color_close_bg_tb = "874C49"
M.alpha_close_bg_tb = "FF"
M.close_button_radius_tb = 1

-- OSC geometry
-- Display row target: y=55-32=23; surfaces 9..37.
-- Timeline target: y=49.
-- Transport target: y=55+27=82; surfaces 68..96.
M.height_panel_osc = 110
M.inset_left_button_osc = 16
M.inset_right_button_osc = 16

M.icon_size = 22
M.icon_spacing = 32
M.color_icon_osc = "D3D5DF"

M.osc_layout = {
    button_row = {
        anchor = "center",
        offset = 27,
    },
    seekbar = {
        anchor = "panel_top",
        panel_inset = 49,
    },
}

M.offset_center_osc = -32
M.osc_L1_center_osc = "time"
M.osc_R1_center_osc = "title"
M.width_time_item_osc = 120
M.width_title_item_osc = 600

-- Transport
M.osc_L1 = "prev"
M.osc_L2 = "play"
M.osc_L3 = "stop"
M.osc_L4 = "next"

-- Supported secondary actions
M.osc_C1 = "playlist"
M.osc_C2 = "subtitle"
M.osc_C3 = "settings"

-- shuffle/repeat are not listed in the supplied OSC action reference.

M.osc_R1 = "pin"
M.osc_R2 = "volume_slider"

-- Timeline
M.inset_side_seekbar_osc = 16
M.height_normal_seekbar = 4
M.height_hover_seekbar = 4
M.radius_seekbar_osc = 0

M.color_track_bg_osc = "101218"
M.color_border_seekbar_osc = "626675"
M.alpha_border_seekbar_osc = "FF"
M.width_border_seekbar_osc = 1

M.height_thumb = 6
M.radius_thumb = 0
M.thumb_color = "D5AA55"
M.color_border_thumb_osc = "7D622F"
M.alpha_border_thumb_osc = "FF"

-- Volume
M.enabled_mute_volume_slider_osc = true
M.enabled_thumb_volume_slider_osc = true
M.width_volume_slider_osc = 90
M.height_volume_slider_osc = 5
M.radius_volume_slider_osc = 0

M.width_thumb_volume_slider_osc = 3
M.height_thumb_volume_slider_osc = 8
M.color_thumb_volume_slider_osc = "D5AA55"
M.color_volume_slider_osc = "78C64A"
M.color_end_volume_slider_osc = "D6C85B"
M.color_track_volume_slider_osc = "101218"

-- Row decoration
M.osc_group_overrides = {
    L = {
        button = {
            background = true,
            color = "C7CBD6",
            gradient_color = "777E91",
            gradient_type = "top_to_bottom",
            alpha = "FF",
            padding = 3,
            height = 28,
            radius = 1,
            border = true,
            border_color = "12141D",
            border_alpha = "FF",
            border_width = 1,
        },
    },

    L_center_osc = {
        group = {
            background = true,
            color = "080D09",
            alpha = "FF",
            padding = 6,
            height = 28,
            radius = 0,
            border = true,
            border_color = "626675",
            border_alpha = "FF",
            border_width = 1,
        },
    },

    R_center_osc = {
        group = {
            background = true,
            color = "080D09",
            alpha = "FF",
            padding = 6,
            height = 28,
            radius = 0,
            border = true,
            border_color = "626675",
            border_alpha = "FF",
            border_width = 1,
        },
    },
}

M.osc_slot_overrides = {
    osc_R2 = {
        hover_bg_color = "444858",
        hover_bg_alpha = "FF",
    },
}

for _, slot in ipairs({
    "osc_L1", "osc_L2", "osc_L3", "osc_L4",
}) do
    M.osc_slot_overrides[slot] = {
        icon_color = "202431",
        hover_icon_color = "101721",
        hover_bg_color = "DEE2EC",
        hover_bg_alpha = "FF",
        hover_radius = 1,
        hover_scale = 1,
    }
end

for _, slot in ipairs({
    "osc_C1", "osc_C2", "osc_C3", "osc_R1",
}) do
    M.osc_slot_overrides[slot] = {
        hover_icon_color = "E6F8CF",
        hover_bg_color = "444858",
        hover_bg_alpha = "FF",
        hover_scale = 1,
    }
end

-- Playlist: all original settings restored
M.panel_width_pl = 320
M.side_inset_pl = 8
M.top_inset_pl = 36
M.bottom_inset_pl = 118
M.osc_bottom_exclusion_pl = 118

M.header_height_pl = 35
M.search_height_pl = 30
M.toolbar_height_pl = 34

M.color_icon_pl = "C6C8D4"
M.color_dim_pl = "82966D"

M.color_frame_pl = "292A38"
M.color_list_bg_pl = "080D09"
M.list_radius_pl = 0
M.list_inset_left_pl = 6
M.list_inset_right_pl = 6

M.frame_shadow_pl = true
M.frame_shadow_color_pl = "000000"
M.frame_shadow_alpha_pl = "CF"
M.frame_shadow_size_pl = 3

M.row_bg_pl = "080D09"
M.row_bg_alpha_pl = "FF"
M.row_height_pl = 28
M.row_gap_pl = 0
M.row_radius_pl = 0

M.row_padding_x_pl = 10
M.title_offset_x_pl = 36
M.row_right_inset_x_pl = 10

M.color_hover_pl = "1B2B1A"
M.alpha_hover_pl = "FF"
M.color_selected_pl = "293B62"
M.alpha_selected_pl = "FF"
M.color_current_pl = "243822"
M.alpha_current_pl = "FF"

M.color_scroll_fg_pl = "7B8192"
M.color_scroll_bg_pl = "161821"
M.scrollbar_width_pl = 8

return M