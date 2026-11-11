-- Cadre OSC defaults. The built-in default button layout is used because no osc_L/C/R slots are assigned.
M = {}

-- Cadre OSC defaults. The built-in default button layout is used because no osc_L/C/R slots are assigned.
M.font_text = "Inter"
M.font_size = 16
M.text_color = "F8FAFC"
M.accent_color = "63B8FF"
M.surface_color = "0D1117"
M.background_color = "0A0C10"

M.bar_height_osc = 70
M.bar_side_inset_osc = 0
M.bar_y_anchor_osc = "bottom"
M.bar_top_inset_osc = 0
M.bar_bottom_inset_osc = 0
M.bar_radius_osc = 0
M.color_bar_bg_osc = "0D1117"
M.alpha_bar_bg_osc = "30"

M.seek_side_inset_osc = 70
M.seek_height_normal = 20
M.seek_height_hover = 20
M.seek_hover_resize_mode_osc = "all"
M.color_track_fg_osc = "63B8FF"
M.color_track_bg_osc = "303845"
M.seek_border_width_osc = 0
M.thumb_width = 2
M.thumb_height = 12
M.thumb_radius = 0
M.seek_radius_osc = 0


M.time_label_position_osc = "inline"
M.time_label_offset_y = 16
M.osc_title_enabled_osc = true
M.osc_title_position_osc = "above_seekbar"
M.osc_title_align_osc = "center"
M.osc_title_seekbar_gap_osc = 6

M.icon_size = 24
M.icon_spacing = 36
M.alpha_icon_dim_osc = "60"
M.icon_group_bg_enabled_osc = false
M.icon_group_bg_color_osc = "0D1117"
M.icon_group_bg_alpha_osc = "40"
M.icon_group_bg_padding_osc = 8
M.icon_group_bg_height_osc = 52
M.icon_group_bg_radius_osc = 0
M.button_y_anchor_osc = "bottom"
M.button_row_offset_osc = 30
M.alpha_chapter_mark = "FF"

M.osc_C1 = "seekbar"
M.osc_L1 = "prev"
M.osc_L2 = "play"
M.osc_L3 = "next"
M.osc_L4 = "volume_slider"
M.osc_R1 = "settings"
M.osc_R2 = "subtitle"
M.osc_R3 = "fullscreen"
M.osc_R4 = "playlist"

M.volume_slider_width_osc = 60
M.volume_slider_height_osc = 2
M.volume_slider_thumb_width_osc = 6 
M.volume_slider_thumb_height_osc = 6 
M.volume_slider_radius_osc = 3 -- Slider track corner radius.
M.volume_slider_color_osc = "FFFFFF" -- Filled track/thumb color.
M.volume_slider_track_color_osc = "444444" -- Unfilled track color.
M.volume_slider_mute_osc = true -- Show the mute button beside the slider.
M.volume_slider_mute_width_osc = nil -- Mute button width; falls back to icon_size.
M.volume_slider_mute_gap_osc = 8 -- Gap between mute button and slider.
M.volume_slider_pad_left_osc = 6 -- Left padding inside the slider item.
M.volume_slider_pad_right_osc = 6 -- Right padding inside the slider item.
M.time_item_width_osc = 70

M.bottom_inset_pl = 80

return M