local M = {}

-- Amazon Prime Video-inspired theme

-- Shared identity
M.text_color = "FFFFFF"
M.surface_color = "0F171E"
M.accent_color = "00A8E1"
M.font_size = 15
M.bar_height = 96
M.bar_radius = 0

-- Titlebar
M.titlebar_show_mode_tb = "auto"
M.titlebar_button_side_tb = "right"
M.bar_height_tb = 38
M.color_bar_bg_tb = "0B1218"
M.alpha_bar_bg_tb = "20"
M.color_text_tb = "FFFFFF"
M.color_button_bg_tb = "1A242F"
M.alpha_button_bg_tb = "40"
M.button_radius_tb = 4
M.color_close_bg_tb = "E50914"
M.alpha_close_bg_tb = "55"

-- OSC panel
M.bar_height_osc = 58
M.bar_side_inset_osc = 0
M.bar_y_anchor_osc = "bottom"
M.bar_bottom_inset_osc = 30
M.bar_radius_osc = 0
M.bar_autohide_sec_osc = 0.45
M.color_bar_bg_osc = "0F171E"
M.alpha_bar_bg_osc = "FF"

-- Floating media title
M.osc_title_enabled_osc = true
M.osc_title_position_osc = "above_seekbar"
M.osc_title_anchor_osc = "seekbar"
M.osc_title_align_osc = "left"
M.osc_title_size_osc = 17
M.color_title_osc = "FFFFFF"
M.alpha_title_osc = "00"
M.osc_title_side_inset_osc = 22
M.osc_title_gap_osc = 6
M.osc_title_seekbar_gap_osc = 8
M.osc_title_shadow_osc = true
M.osc_title_shadow_x_osc = 1
M.osc_title_shadow_y_osc = 1
M.osc_title_shadow_color_osc = "000000"
M.osc_title_shadow_alpha_osc = "55"

-- Prime-style control row
M.osc_L1_top = "title"

M.osc_C1 = "seekbar"
M.osc_C1_center = "seek_back"
M.osc_C2_center = "play"
M.osc_C3_center = "seek_forward"
M.osc_slot_overrides = {
    osc_C1_center = {
        icon_size = 32,
        spacing = 74,
        button_height = 44,
        button_padding = 6,
        button_radius = 22,
    },
    osc_C2_center = {
        icon_size = 52,
        spacing = 74,
        button_height = 64,
        button_padding = 6,
        button_radius = 32,
    },
    osc_C3_center = {
        icon_size = 32,
        spacing = 74,
        button_height = 44,
        button_padding = 6,
        button_radius = 22,
    },
}
M.osc_group_overrides = {
    C = {
        group = {
            background = true,
            color = "000000",
            alpha = "A0",
            padding = 8,
            height = 50,
            radius = 25,
            border = false,
        },
    },
    C_center = {
        button = {
            background = true,
            color = "000000",
            alpha = "A0",
            radius = 35,
        },
        group = {background = false, border = false},
    },
}

M.osc_R1_top = "settings"
M.osc_R2_top = "volume"
M.osc_R3_top = "fullscreen"
M.osc_R4_top = "next"

M.button_left_inset_osc = 52
M.button_right_inset_osc = 52
M.button_y_anchor_osc = "bottom"
M.button_row_offset_osc = 28
M.icon_size = 25
M.icon_spacing = 36
M.color_icon_osc = "FFFFFF"
M.alpha_icon_dim_osc = "55"

-- Clean controls
M.icon_bg_enabled_osc = false
M.icon_group_bg_enabled_osc = false

-- Cyan-blue seekbar
M.seek_height_normal = 4
M.seek_height_hover = 8
M.seek_hover_resize_mode_osc = "segment"
M.color_track_fg_osc = "FFFFFF"
M.color_track_bg_osc = "545454"
M.seek_border_width_osc = 0

M.chapter_mark_width = 2
M.color_chapter_mark = "0F171E"
M.alpha_chapter_mark = "FF"
M.chapter_hover_px = 10

M.thumb_width = 6
M.thumb_height = 6
M.thumb_radius = 6
M.thumb_color = "FFFFFF"
M.thumb_border_width_osc = 0

-- Time labels
M.font_size_osc = 16
M.color_text_osc = "FFFFFF"
M.time_item_width_osc = 136
M.time_label_position_osc = "inline"
M.time_label_inline_gap_osc = 10

-- Volume flyout trigger
M.volume_slider_mute_osc = true

-- Watchlist / episodes panel
M.panel_width_pl = 420
M.side_inset_pl = 16
M.top_inset_pl = 54
M.bottom_inset_pl = 136
M.bar_radius_pl = 10
M.color_bar_bg_pl = "0F171E"
M.alpha_bar_bg_pl = "15"

M.row_height_pl = 50
M.row_gap_pl = 3
M.row_radius_pl = 8
M.row_padding_x_pl = 16
M.title_offset_x_pl = 44
M.row_right_inset_x_pl = 16

M.color_text_pl = "FFFFFF"
M.color_dim_pl = "8FA3AD"
M.color_icon_pl = "FFFFFF"
M.color_hover_pl = "1A242F"
M.alpha_hover_pl = "55"
M.color_selected_pl = "00A8E1"
M.alpha_selected_pl = "30"
M.color_current_pl = "00A8E1"
M.alpha_current_pl = "50"

M.color_scroll_fg_pl = "4E6170"
M.color_scroll_bg_pl = "16202A"
M.scrollbar_width_pl = 4

return M
