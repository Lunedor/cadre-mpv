local M = {}

-- Soft Graphite — blur showcase
-- Intended minimum width: 960 OSC-coordinate pixels.
-- Calculated layout; not runtime-tested.

-- Shared identity
M.surface_color = "292E37"
M.text_color = "DCE1E8"
M.accent_color = "8C9FB8"
M.alpha_bar_bg = "08"
M.bar_radius = 18
M.font_icon = "Material Icons Round"

-- Titlebar
M.title_font_size_tb = 16
M.color_bar_bg_tb = "222730"
M.color_button_bg_tb = "3A4351"
M.color_button_pressed_bg_tb = "495568"
M.button_radius_tb = 7
M.color_close_bg_tb = "A65861"
M.close_button_radius_tb = 7

-- Floating graphite surface
M.bar_height_osc = 128
M.bar_side_inset_osc = 20
M.bar_bottom_inset_osc = 18

M.osc_layout = {
    button_row = {
        anchor = "center",
        offset = 30,
    },
    seekbar = {
        anchor = "panel_top",
        panel_inset = 44,
    },
}

M.button_left_inset_osc = 32
M.button_right_inset_osc = 32

-- Preserve SoftUI's arrangement
M.osc_L1 = "playlist"
M.osc_L2 = "subtitle"

M.osc_C1 = "prev"
M.osc_C2 = "play"
M.osc_C3 = "next"

M.osc_R1 = "volume"
M.osc_R2 = "settings"
M.osc_R3 = "fullscreen"

-- Single title placement
M.osc_C1_top_osc = "title"
M.osc_top_offset = 18
M.osc_title_item_width_osc = 500

-- Thin slate timeline
M.seek_side_inset_osc = 28
M.seek_height_normal = 4
M.seek_height_hover = 6
M.color_track_bg_osc = "414B5A"

M.thumb_width = 5
M.thumb_height = 5
M.thumb_color = "BFCDE0"

-- Time labels: sharp foreground over a soft outline and shadow
M.time_label_position_osc = "inline"
M.seek_start_label_osc = true

M.time_label_outline_osc = true
M.time_label_outline_color_osc = "8B9DB7"
M.time_label_outline_alpha_osc = "B8"
M.time_label_outline_width_osc = 1
M.time_label_outline_blur_osc = 1.5

M.time_label_shadow_osc = true
M.time_label_shadow_color_osc = "080B10"
M.time_label_shadow_alpha_osc = "38"
M.time_label_shadow_x_osc = 0
M.time_label_shadow_y_osc = 2
M.time_label_shadow_blur_osc = 3

-- Rounded button faces provide contrast for the glyph effects
M.icon_size = 22
M.icon_spacing = 48

M.icon_bg_enabled_osc = true
M.icon_bg_color_osc = "38414F"
M.icon_bg_alpha_osc = "00"
M.icon_bg_height_osc = 38
M.icon_bg_pad_x_osc = 8
M.icon_bg_radius_osc = 12

M.icon_border_enabled_osc = true
M.icon_border_color_osc = "71829A"
M.icon_border_alpha_osc = "B0"

-- Soft slate edge around crisp icons
M.icon_outline_enabled_osc = true
M.icon_outline_color_osc = "92A8C8"
M.icon_outline_alpha_osc = "A0"
M.icon_outline_width_osc = 1.2
M.icon_outline_blur_osc = 2

-- Deliberately visible blurred icon shadows
M.icon_shadow_enabled_osc = true
M.icon_shadow_color_osc = "070A10"
M.icon_shadow_alpha_osc = "28"
M.icon_shadow_x_osc = 0
M.icon_shadow_y_osc = 3
M.icon_shadow_blur_osc = 4

-- Hover brightens the face without scaling the effects
M.hover_icon_color_osc = "F0F4FA"
M.hover_bg_color_osc = "4B596D"
M.hover_bg_alpha_osc = "00"

-- Title has no button surface; its effects are configured separately
M.osc_group_overrides = {
    C_top_osc = {
        button = {
            background = false,
            border = false,
        },
    },
}

M.osc_slot_overrides = {
    osc_C2 = {
        icon_size = 28,
        icon_color = "EDF2F9",
        button_color = "4C5B70",
        button_height = 46,
        button_radius = 14,
        button_border_color = "91A5C1",
        button_border_alpha = "A0",
        hover_bg_color = "60748F",
        hover_bg_alpha = "00",
    },

    osc_C1_top_osc = {
        font_size = 15,
        text_color = "CBD5E3",
    },
}

-- Title: blurred effects beneath a sharp foreground
M.osc_title_outline_osc = true
M.osc_title_outline_color_osc = "91A5C1"
M.osc_title_outline_alpha_osc = "B0"
M.osc_title_outline_width_osc = 1
M.osc_title_outline_blur_osc = 1.8

M.osc_title_shadow_osc = true
M.osc_title_shadow_color_osc = "070A10"
M.osc_title_shadow_alpha_osc = "30"
M.osc_title_shadow_x_osc = 0
M.osc_title_shadow_y_osc = 2
M.osc_title_shadow_blur_osc = 3

-- Matching preview surfaces
M.chapter_tooltip_bg_color = "222A35"
M.chapter_tooltip_text_color = "DCE1E8"
M.chapter_tooltip_radius = 10
M.seek_time_tooltip_text_color_osc = "DCE1E8"
M.seek_time_tooltip_radius_osc = 10

-- Playlist: lighter shell around a dark inset
M.panel_width_pl = 400
M.bottom_inset_pl = 162
M.osc_bottom_exclusion_pl = 162

M.color_frame_pl = "343E4C"
M.color_list_bg_pl = "1D242E"
M.alpha_list_bg_pl = "00"

M.list_inset_left_pl = 12
M.list_inset_right_pl = 12
M.list_radius_pl = 10

-- Visible, softened shadow on the inside of the viewport edge
M.frame_shadow_pl = true
M.frame_shadow_color_pl = "070B12"
M.frame_shadow_alpha_pl = "28"
M.frame_shadow_size_pl = 7
M.frame_shadow_blur_pl = 4

-- Rows match the recessed viewport
M.row_bg_pl = "1D242E"
M.row_bg_alpha_pl = "00"
M.row_height_pl = 44
M.row_gap_pl = 3
M.row_radius_pl = 8

M.font_size_pl = 14
M.title_font_size_pl = 16
M.title_position_pl = "center"
M.color_dim_pl = "96A4B7"
M.color_icon_pl = "BFCBDD"

M.color_hover_pl = "3C4A5D"
M.alpha_hover_pl = "20"
M.alpha_selected_pl = "98"
M.alpha_current_pl = "B0"

M.color_scroll_fg_pl = "7387A2"
M.color_scroll_bg_pl = "283240"
M.color_danger_pl = "CB7C86"

return M