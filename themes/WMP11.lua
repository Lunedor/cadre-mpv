local M = {}

-- Media Classic
-- Intended minimum width: 800 OSC-coordinate pixels.

-- Shared identity
M.surface_color = "161A20"
M.text_color = "DCE5EF"
M.accent_color = "3399EE"
M.alpha_bar_bg = "00"
M.font_size = 14
M.title_font_size = 16
M.bar_radius = 3

-- Full-width bottom controller
M.bar_height_osc = 132

M.osc_layout = {
    button_row = {
        anchor = "center",
        offset = 0,
    },
    seekbar = {
        anchor = "panel_top",
        panel_inset = 16,
    },
}

M.icon_spacing = 44
M.hover_icon_color_osc = "FFFFFF"
M.hover_bg_color_osc = "30465E"
M.hover_bg_alpha_osc = "00"

-- Main playback row
M.osc_L1 = "time"

M.osc_C1 = "prev"
M.osc_C2 = "play"
M.osc_C3 = "next"

M.osc_R1 = "volume_slider"
M.osc_R2 = "fullscreen"

-- Lower source and utility row
M.osc_center_offset = 48

M.osc_L1_center_osc = "stream"
M.osc_L2_center_osc = "youtube"
M.osc_L3_center_osc = "music_mode"

M.osc_R1_center_osc = "playlist"
M.osc_R2_center_osc = "settings"

-- Playback button styling
M.osc_slot_overrides = {
    osc_C2 = {
        icon_size = 34,
        icon_color = "FFFFFF",

        button_background = true,
        button_color = "1468A8",
        button_alpha = "00",
        button_height = 54,
        button_padding = 10,
        button_radius = 27,

        button_border = true,
        button_border_color = "86CFFF",
        button_border_alpha = "00",
        button_border_width = 1,

        hover_bg_color = "218CD5",
        hover_bg_alpha = "00",
        hover_radius = 27,
    },

    osc_L1_center_osc = {
        icon_color = "AFC2D5",
    },
    osc_L2_center_osc = {
        icon_color = "AFC2D5",
    },
    osc_L3_center_osc = {
        icon_color = "AFC2D5",
    },

    osc_R1_center_osc = {
        icon_color = "AFC2D5",
    },
    osc_R2_center_osc = {
        icon_color = "AFC2D5",
    },
}

-- Thin blue timeline with silver slider
M.seek_height_normal = 4
M.seek_height_hover = 4
M.seek_radius_osc = 1
M.color_track_bg_osc = "070A0E"

M.seek_border_color_osc = "4B5664"
M.seek_border_alpha_osc = "00"
M.seek_border_width_osc = 1

M.thumb_width = 5
M.thumb_height = 7
M.thumb_radius = 2
M.thumb_color = "DCE5EF"
M.thumb_border_color_osc = "697C90"
M.thumb_border_alpha_osc = "00"

-- Compact volume control; its built-in mute button is retained
M.volume_slider_width_osc = 90
M.volume_slider_height_osc = 4
M.volume_slider_radius_osc = 1
M.volume_slider_color_osc = "3399EE"
M.volume_slider_track_color_osc = "070A0E"
M.volume_slider_thumb_color_osc = "DCE5EF"
M.volume_slider_thumb_width_osc = 3
M.volume_slider_thumb_height_osc = 7

-- Matching playlist frame and inset list
M.panel_width_pl = 340
M.side_inset_pl = 8
M.top_inset_pl = 44
M.bottom_inset_pl = 144
M.osc_bottom_exclusion_pl = 144

M.header_height_pl = 36
M.search_height_pl = 34
M.toolbar_height_pl = 36

M.color_list_bg_pl = "090C11"
M.list_radius_pl = 1
M.list_inset_left_pl = 6
M.list_inset_right_pl = 6

M.row_height_pl = 32
M.row_gap_pl = 0
M.row_radius_pl = 1
M.row_bg_pl = "090C11"
M.row_padding_x_pl = 12
M.title_offset_x_pl = 36
M.row_right_inset_x_pl = 12

M.color_dim_pl = "8D9BAA"
M.color_hover_pl = "25384A"
M.alpha_hover_pl = "00"

M.color_selected_pl = "205C8B"
M.alpha_selected_pl = "00"
M.color_current_pl = "183C59"
M.alpha_current_pl = "00"

M.color_scroll_fg_pl = "60758A"
M.color_scroll_bg_pl = "101720"

-- Matching Windows-style titlebar
M.bar_height_tb = 32
M.button_width_tb = 40
M.button_radius_tb = 2
M.close_button_radius_tb = 2

M.color_button_bg_tb = "30465E"
M.alpha_button_bg_tb = "00"
M.color_button_pressed_bg_tb = "205C8B"
M.alpha_button_pressed_bg_tb = "00"
M.color_close_bg_tb = "B94747"
M.alpha_close_bg_tb = "00"

return M