-- Cadre theme: Neumorphic Dark
-- Minimum intended player width: 900 px

local M = {}

-- Shared identity
M.text_color = "D7DEE8"
M.surface_color = "111418"
M.alpha_bar_bg = "0A"
M.accent_color = "5AC8FA"
M.bar_radius = 24

-- OSC panel
M.bar_height_osc = 120
M.bar_bottom_inset_osc = 16
M.bar_radius_osc = 24
M.color_bar_bg_osc = "111418"
M.alpha_bar_bg_osc = "0A"

-- OSC layout: controls at the bottom, seekbar above them
M.osc_layout = {
    button_row = { anchor = "bottom", offset = 18 },
    seekbar = { anchor = "above_buttons", gap = 10 },
}

M.osc_L1 = "time"
M.osc_C1 = "prev"
M.osc_C2 = "play"
M.osc_C3 = "next"
M.osc_R1 = "volume_slider"
M.osc_R2 = "playlist"

-- Soft raised icon surfaces
M.icon_size = 24
M.icon_spacing = 36
M.color_icon_osc = "D7DEE8"
M.icon_bg_enabled_osc = true
M.icon_bg_color_osc = "171B21"
M.icon_bg_alpha_osc = "00"
M.icon_bg_height_osc = 40
M.icon_bg_width_osc = 40
M.icon_bg_radius_osc = 14
M.icon_border_enabled_osc = true
M.icon_border_color_osc = "2A313A"
M.icon_border_alpha_osc = "FF"
M.icon_border_width_osc = 1
M.icon_shadow_enabled_osc = true
M.icon_shadow_color_osc = "000000"
M.icon_shadow_alpha_osc = "38"
M.icon_shadow_x_osc = 0
M.icon_shadow_y_osc = 2
M.icon_shadow_blur_osc = 6

-- Gentle hover: slightly lighter raised surface
M.hover_bg_color_osc = "1E242C"
M.hover_bg_alpha_osc = "00"
M.hover_border_osc = true
M.hover_border_color_osc = "39424E"
M.hover_border_alpha_osc = "40"
M.hover_border_width_osc = 1

-- Center transport capsule
M.osc_group_overrides = {
    C = {
        button = { background = false, border = false },
        group = {
            background = true,
            color = "14181D",
            alpha = "00",
            padding = 14,
            height = 56,
            radius = 24,
            border = true,
            border_color = "2A313A",
            border_alpha = "FF",
            border_width = 1,
        },
    },
}

-- Slightly emphasize play
M.osc_slot_overrides = {
    osc_C2 = {
        icon_size = 30,
        icon_color = "E6EDF5",
    },
}

-- Recessed seekbar
M.seek_side_inset_osc = 28
M.seek_height_normal = 8
M.seek_height_hover = 10
M.color_track_bg_osc = "232A33"
M.color_track_fg_osc = "5AC8FA"
M.seek_border_width_osc = 0
M.thumb_color = "E6EDF5"
M.thumb_border_color_osc = "000000"
M.thumb_border_alpha_osc = "60"
M.thumb_border_width_osc = 1

-- Inline elapsed / duration labels
M.time_label_position_osc = "inline"

-- Floating media title
M.osc_title_enabled_osc = true
M.osc_title_position_osc = "above_seekbar"
M.osc_title_align_osc = "center"
M.color_title_osc = "D7DEE8"
M.osc_title_gap_osc = 6

-- Playlist: dark clay panel with inset list
M.color_bar_bg_pl = "111418"
M.alpha_bar_bg_pl = "0A"
M.bar_radius_pl = 24
M.color_text_pl = "D7DEE8"
M.color_icon_pl = "D7DEE8"
M.color_dim_pl = "7C8794"
M.row_height_pl = 40
M.row_radius_pl = 10
M.color_hover_pl = "1B2129"
M.alpha_hover_pl = "00"
M.color_selected_pl = "5AC8FA"
M.alpha_selected_pl = "28"
M.color_current_pl = "5AC8FA"
M.alpha_current_pl = "38"

M.color_frame_pl = "0D1014"
M.alpha_frame_pl = "00"
M.color_list_bg_pl = "0F1318"
M.alpha_list_bg_pl = "00"
M.list_radius_pl = 14
M.frame_shadow_pl = true
M.frame_shadow_color_pl = "000000"
M.frame_shadow_alpha_pl = "55"
M.frame_shadow_size_pl = 6
M.frame_shadow_blur_pl = 8

M.color_scroll_fg_pl = "39424E"
M.color_scroll_bg_pl = "171B21"

-- Titlebar
M.color_bar_bg_tb = "0E1116"
M.alpha_bar_bg_tb = "28"
M.color_text_tb = "D7DEE8"
M.color_button_bg_tb = "1B2129"
M.alpha_button_bg_tb = "00"
M.button_radius_tb = 8

return M