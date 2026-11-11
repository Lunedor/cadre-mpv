local M = {}

M.theme_name = "WinXP"
M.theme_author = "Lunedor"

-- Shared identity
M.font_ui = "Tahoma"
M.font_size = 14
M.text_color = "17335C"
M.surface_color = "D6E2F3"
M.alpha_panel_bg = "FF"
M.accent_color = "397BD5"
M.panel_radius = 3

-- Titlebar: all original settings restored
M.titlebar_show_mode_tb = "always"
M.panel_height_tb = 30
M.button_width_tb = 32

M.surface_color_tb = "245BB5"
M.text_color_tb = "FFFFFF"

M.color_button_bg_tb = "467CCD"
M.alpha_button_bg_tb = "FF"
M.color_bg_hover_tb = "FFFFFF"
M.alpha_bg_hover_tb = "DF"
M.color_button_pressed_bg_tb = "17458E"
M.alpha_button_pressed_bg_tb = "FF"
M.button_radius_tb = 2

M.color_close_bg_tb = "C95440"
M.alpha_close_bg_tb = "FF"
M.close_button_radius_tb = 2

-- OSC geometry
-- Timeline target: y=12.
-- Main row target: y=48-2=46.
-- Play surface: 28..64.
-- Secondary row target: y=48+34=82.
M.height_panel_osc = 96
M.inset_left_button_osc = 16
M.inset_right_button_osc = 16

M.osc_layout = {
    button_row = {
        anchor = "center",
        offset = -2,
    },
    seekbar = {
        anchor = "panel_top",
        panel_inset = 12,
    },
}

M.offset_center_osc = 34

-- Main transport
M.osc_L1 = "play"
M.osc_L2 = "stop"
M.osc_L3 = "prev"
M.osc_L4 = "next"

M.osc_C1 = "time"
M.osc_R1 = "volume_slider"

-- Secondary row
M.osc_L1_center_osc = "playlist"
M.osc_L2_center_osc = "subtitle"
M.osc_L3_center_osc = "settings"
M.osc_R1_center_osc = "fullscreen"

M.icon_size = 22
M.icon_spacing = 32
M.width_time_item_osc = 140

-- Timeline
M.inset_side_seekbar_osc = 16
M.height_normal_seekbar = 4
M.height_hover_seekbar = 4
M.radius_seekbar_osc = 1

M.color_track_bg_osc = "A7B8CF"
M.color_border_seekbar_osc = "657D9D"
M.alpha_border_seekbar_osc = "FF"
M.width_border_seekbar_osc = 1

M.height_thumb = 6
M.radius_thumb = 1
M.thumb_color = "F1F4FA"
M.color_border_thumb_osc = "526E95"
M.alpha_border_thumb_osc = "FF"

-- Integrated mute/volume slider
M.enabled_mute_volume_slider_osc = true
M.enabled_thumb_volume_slider_osc = true
M.width_volume_slider_osc = 90
M.height_volume_slider_osc = 4
M.radius_volume_slider_osc = 1
M.width_thumb_volume_slider_osc = 3
M.height_thumb_volume_slider_osc = 8

M.color_volume_slider_osc = "397BD5"
M.color_track_volume_slider_osc = "A7B8CF"
M.color_thumb_volume_slider_osc = "526E95"

-- Silver transport surfaces
M.osc_group_overrides = {
    L = {
        button = {
            background = true,
            color = "F8FAFD",
            gradient_color = "B6C9E2",
            gradient_type = "top_to_bottom",
            alpha = "FF",
            padding = 3,
            height = 28,
            radius = 3,
            border = true,
            border_color = "7189AD",
            border_alpha = "FF",
            border_width = 1,
        },
    },
}

-- Larger blue Play button
M.osc_slot_overrides = {
    osc_L1 = {
        icon_size = 30,
        icon_color = "FFFFFF",
        spacing = 36,

        button_background = true,
        button_color = "75A9EE",
        button_gradient_color = "245BB5",
        button_gradient_type = "top_to_bottom",
        button_alpha = "FF",
        button_height = 36,
        button_padding = 3,
        button_radius = 18,

        button_border = true,
        button_border_color = "214E92",
        button_border_alpha = "FF",
        button_border_width = 1,

        hover_icon_color = "FFFFFF",
        hover_bg_color = "4B8FE3",
        hover_bg_alpha = "FF",
        hover_radius = 18,
        hover_scale = 1,
    },

    osc_R1 = {
        hover_bg_color = "EAF3FF",
        hover_bg_alpha = "FF",
    },
}

for _, slot in ipairs({
    "osc_L2", "osc_L3", "osc_L4",
    "osc_L1_center_osc",
    "osc_L2_center_osc",
    "osc_L3_center_osc",
    "osc_R1_center_osc",
}) do
    M.osc_slot_overrides[slot] = {
        hover_icon_color = "123F81",
        hover_bg_color = "EAF3FF",
        hover_bg_alpha = "FF",
        hover_scale = 1,
    }
end

-- Playlist: all original settings restored
M.panel_width_pl = 300
M.side_inset_pl = 8
M.top_inset_pl = 38
M.bottom_inset_pl = 104
M.osc_bottom_exclusion_pl = 104

M.header_height_pl = 32
M.search_height_pl = 30
M.toolbar_height_pl = 34

M.color_frame_pl = "C2D3EB"
M.color_list_bg_pl = "F2F6FC"
M.list_radius_pl = 1
M.list_inset_left_pl = 5
M.list_inset_right_pl = 5

M.frame_shadow_pl = true
M.frame_shadow_color_pl = "667F9F"
M.frame_shadow_alpha_pl = "7F"
M.frame_shadow_size_pl = 2

M.row_bg_pl = "F2F6FC"
M.row_bg_alpha_pl = "FF"
M.row_height_pl = 30
M.row_gap_pl = 1
M.row_radius_pl = 1

M.row_padding_x_pl = 10
M.title_offset_x_pl = 34
M.row_right_inset_x_pl = 10

M.color_dim_pl = "607693"
M.color_hover_pl = "DCE9FA"
M.alpha_hover_pl = "FF"

M.color_selected_pl = "B6D2F5"
M.alpha_selected_pl = "FF"
M.color_current_pl = "9EC2EF"
M.alpha_current_pl = "FF"

M.color_scroll_fg_pl = "8BA7CC"
M.color_scroll_bg_pl = "DFE8F5"
M.scrollbar_width_pl = 8

return M