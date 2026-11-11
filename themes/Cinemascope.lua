local M = {}

-- =========================================================
-- Cinema Console
-- =========================================================

-- Shared identity
M.surface_color = "0B0D12"
M.text_color = "E7ECF3"
M.accent_color = "5FA8FF"
M.alpha_bar_bg = "28"
M.bar_height = 96
M.bar_radius = 10
M.alpha_icon_dim = "55"

-- Titlebar
M.titlebar_show_mode_tb = "auto"
M.titlebar_button_side_tb = "left"
M.bar_height_tb = 34
M.button_width_tb = 42
M.color_bar_bg_tb = "080A0E"
M.alpha_bar_bg_tb = "10"
M.color_text_tb = "DDE5EF"
M.color_button_bg_tb = "1A2029"
M.alpha_button_bg_tb = "30"
M.color_button_pressed_bg_tb = "222A35"
M.alpha_button_pressed_bg_tb = "48"
M.button_radius_tb = 6
M.color_close_bg_tb = "E5484D"
M.alpha_close_bg_tb = "60"
M.close_button_radius_tb = 6

-- OSC panel
M.bar_height_osc = 128
M.bar_bottom_inset_osc = 12
M.bar_side_inset_osc = 18
M.bar_y_anchor_osc = "bottom"
M.bar_radius_osc = 12
M.bar_autohide_sec_osc = 0.45

-- Console layout: transport center, volume right, utilities left
M.osc_L1 = "playlist"
M.osc_L2 = "subtitle"
M.osc_L3 = "settings"
M.osc_L4 = "info"

M.osc_C1 = "prev"
M.osc_C2 = "seek_back"
M.osc_C3 = "play"
M.osc_C4 = "seek_forward"
M.osc_C5 = "next"

M.osc_R2 = "volume_slider"
M.osc_R3 = "screenshot"
M.osc_R4 = "fullscreen"

M.button_left_inset_osc = 28
M.button_right_inset_osc = 28
M.button_y_anchor_osc = "bottom"
M.button_row_offset_osc = 28
M.button_group_left_align_osc = "start"
M.button_group_center_align_osc = "center"
M.button_group_right_align_osc = "end"

-- Hardware-module button styling
M.icon_size = 22
M.icon_spacing = 50
M.color_icon_osc = "E7ECF3"
M.alpha_icon_dim_osc = "55"

M.icon_bg_enabled_osc = true
M.icon_bg_color_osc = "151A22"
M.icon_bg_alpha_osc = "55"
M.icon_bg_height_osc = 38
M.icon_bg_width_osc = 38
M.icon_bg_radius_osc = 8

M.icon_border_enabled_osc = true
M.icon_border_color_osc = "2A3340"
M.icon_border_alpha_osc = "80"
M.icon_border_width_osc = 1

M.icon_group_bg_enabled_osc = true
M.icon_group_bg_color_osc = "0E1116"
M.icon_group_bg_alpha_osc = "65"
M.icon_group_bg_padding_osc = 10
M.icon_group_bg_radius_osc = 12

M.icon_group_border_enabled_osc = true
M.icon_group_border_color_osc = "232B36"
M.icon_group_border_alpha_osc = "90"
M.icon_group_border_width_osc = 1

-- Seekbar
M.seekbar_position_osc = "top"
M.seekbar_button_gap_osc = 14
M.seek_y_offset = 12
M.seek_side_inset_osc = 28
M.seek_height_normal = 5
M.seek_height_hover = 10
M.seek_radius_osc = 3
M.color_track_fg_osc = "5FA8FF"
M.color_track_bg_osc = "262D38"
M.seek_border_color_osc = "39434F"
M.seek_border_alpha_osc = "70"
M.seek_border_width_osc = 1

M.thumb_width = 4
M.thumb_height = 11
M.thumb_radius = 3
M.thumb_color = "E7ECF3"
M.thumb_border_color_osc = "0B0D12"
M.thumb_border_alpha_osc = "90"
M.thumb_border_width_osc = 1

M.chapter_mark_width = 2
M.color_chapter_mark = "0B0D12"
M.alpha_chapter_mark = "45"

-- Time labels
M.font_size_osc = 15
M.color_text_osc = "DDE5EF"
M.time_label_position_osc = "below_seekbar"
M.time_label_offset_y = 18
M.time_label_outline_osc = false
M.time_label_shadow_osc = true
M.time_label_shadow_x_osc = 1
M.time_label_shadow_y_osc = 1
M.time_label_shadow_color_osc = "000000"
M.time_label_shadow_alpha_osc = "55"

-- Floating title
M.osc_title_enabled_osc = true
M.osc_title_position_osc = "below_seekbar"
M.osc_title_anchor_osc = "seekbar"
M.osc_title_align_osc = "left"
M.font_title_osc = "Inter"
M.osc_title_size_osc = 15
M.color_title_osc = "E7ECF3"
M.alpha_title_osc = "10"
M.osc_title_gap_osc = 22
M.osc_title_side_inset_osc = 28
M.osc_title_shadow_osc = true
M.osc_title_shadow_x_osc = 1
M.osc_title_shadow_y_osc = 1
M.osc_title_shadow_color_osc = "000000"
M.osc_title_shadow_alpha_osc = "55"

-- Volume slider
M.volume_slider_width_osc = 120
M.volume_slider_height_osc = 5
M.volume_slider_thumb_width_osc = 4
M.volume_slider_thumb_height_osc = 11
M.volume_slider_radius_osc = 3
M.volume_slider_color_osc = "5FA8FF"
M.volume_slider_track_color_osc = "2A3340"
M.volume_slider_mute_osc = true
M.volume_slider_mute_gap_osc = 8

-- Playlist
M.color_bar_bg_pl = "0B0E13"
M.alpha_bar_bg_pl = "35"
M.bar_radius_pl = 12
M.panel_width_pl = 430
M.side_inset_pl = 18
M.top_inset_pl = 52
M.bottom_inset_pl = 140

M.font_size_pl = 15
M.title_font_size_pl = 17
M.color_text_pl = "E7ECF3"
M.color_dim_pl = "7C8798"
M.color_icon_pl = "AEB8C6"

M.row_height_pl = 42
M.row_gap_pl = 3
M.row_radius_pl = 8
M.row_padding_x_pl = 16
M.title_offset_x_pl = 44
M.row_right_inset_x_pl = 16

M.color_hover_pl = "1A2029"
M.alpha_hover_pl = "55"
M.color_selected_pl = "5FA8FF"
M.alpha_selected_pl = "45"
M.color_current_pl = "5FA8FF"
M.alpha_current_pl = "75"

M.color_index_pl = "6B7686"
M.alpha_index_pl = "55"
M.color_duration_pl = "8A94A5"
M.alpha_duration_pl = "20"

M.color_danger_pl = "E5484D"
M.alpha_icon_dim_pl = "55"
M.icon_size_pl = 18
M.toolbar_icon_size_pl = 20
M.toolbar_icon_spacing_pl = 32

M.color_scroll_fg_pl = "39434F"
M.color_scroll_bg_pl = "10141A"
M.scrollbar_width_pl = 4

M.hover_strip_width_pl = 18
M.hide_delay_sec_pl = 0.4
M.osc_bottom_exclusion_pl = 135

return M
