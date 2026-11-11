local M = {}

M.theme_name = "Music"
M.theme_author = "Lunedor"

-- Shared appearance
M.text_color = "DCE3EA"
M.surface_color = "0C1015"
M.alpha_panel_bg = "33"
M.accent_color = "4E9E6A"
M.alpha_icon_dim = "9F"

M.panel_height = 84
M.panel_radius = 14
M.glass_blur = true
M.radius_glass_blur = 10

M.font_size = 15
M.title_font_size = 16
M.icon_size = 24

-- OSC panel
M.height_panel_osc = 84
M.side_inset_panel_osc = 20
M.panel_bottom_inset_osc = 14
M.panel_radius_osc = 14
M.surface_color_osc = "0C1015"
M.alpha_panel_bg_osc = "33"
M.glass_blur_osc = true
M.radius_glass_blur_osc = 10

M.text_color_osc = "DCE3EA"
M.color_icon_osc = "DCE3EA"
M.color_track_fg_osc = "4E9E6A"
M.color_track_bg_osc = "272E37"

-- Music-focused control layout
M.osc_L1_top = "title"
M.osc_R1_top = "time"

M.osc_L1 = "shuffle"
M.osc_L2 = "repeat"

M.osc_C1 = "prev"
M.osc_C2 = "play"
M.osc_C3 = "next"

M.osc_R1 = "playlist"
M.osc_R2 = "music_mode"
M.osc_R3 = "volume_slider"

-- Seekbar
M.position_seekbar_osc = "below_buttons"
M.gap_button_seekbar_osc = 8
M.side_inset_seekbar_osc = 20
M.height_normal_seekbar = 5
M.height_hover_seekbar = 9
M.seekbar_edge_labels_osc = true
M.width_seekbar_border_osc = 0

-- Title
M.osc_title_enabled_osc = false
M.osc_title_size_osc = 16
M.color_title_osc = "DCE3EA"

-- Controls: clean icon-only appearance
M.icon_size_osc = 24
M.icon_bg_enabled_osc = false
M.icon_group_bg_enabled_osc = false
M.hover_bg_color_osc = "4E9E6A"
M.hover_bg_alpha_osc = "DD"
M.hover_scale_osc = 1.04
M.hover_border_osc = false

-- Volume slider
M.width_volume_slider_osc = 100
M.height_volume_slider_osc = 5
M.radius_volume_slider_osc = 3
M.color_volume_slider_osc = "4E9E6A"
M.color_volume_slider_track_osc = "272E37"
M.color_volume_slider_thumb_osc = "DCE3EA"
M.volume_slider_mute_osc = true
M.gap_volume_slider_mute_osc = 8

-- Playlist
M.panel_height_pl = 420
M.panel_radius_pl = 14
M.surface_color_pl = "0C1015"
M.alpha_panel_bg_pl = "26"
M.glass_blur_pl = true
M.radius_glass_blur_pl = 10

M.text_color_pl = "DCE3EA"
M.color_icon_pl = "DCE3EA"
M.color_selected_pl = "4E9E6A"
M.color_current_pl = "4E9E6A"
M.alpha_icon_dim_pl = "9F"

-- Titlebar
M.titlebar_show_mode_tb = "auto"
M.panel_height_tb = 36
M.surface_color_tb = "0C1015"
M.alpha_panel_bg_tb = "33"
M.text_color_tb = "DCE3EA"
M.glass_blur_tb = true
M.radius_glass_blur_tb = 10

return M
