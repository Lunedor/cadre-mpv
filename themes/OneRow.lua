local M = {}

M.theme_name = "One Row"
M.theme_author = "Lunedor"
M.theme_variant = "OneRow"

----------------------------------------------------------
-- Base palette
----------------------------------------------------------

M.background_color = "0B0D10"
M.surface_color = "121821"
M.accent_color = "7BB7FF"
M.text_color = "F5F7FA"
M.dim_color = "AAB7C5"

----------------------------------------------------------
-- Typography
----------------------------------------------------------

M.font_text = "Inter"
M.font_size = 14
M.title_font_size = 16
M.font_icon_osc = "Material Icons Outlined"

----------------------------------------------------------
-- OSC panel
----------------------------------------------------------

M.bar_y_anchor_osc = "bottom"
M.bar_height_osc = 100
M.bar_side_inset_osc = 0
M.bar_bottom_inset_osc = 12
M.bar_radius_osc = 10
M.color_bar_bg_osc = "121821"
M.alpha_bar_bg_osc = "60"

----------------------------------------------------------
-- Media title
----------------------------------------------------------

M.osc_title_enabled_osc = true
M.osc_title_position_osc = "above_seekbar"
M.osc_title_align_osc = "center"
M.color_title_osc = "F5F7FA"
M.alpha_title_osc = "00"

----------------------------------------------------------
-- Seekbar
----------------------------------------------------------

M.seek_y_offset = 4
M.seek_side_inset_osc = 18
M.seek_height_normal = 20
M.seek_height_hover = 20
M.color_track_fg_osc = "7BB7FF"
M.color_track_bg_osc = "4B5563"
M.seek_border_width_osc = 0

M.thumb_width = 2
M.thumb_height = 10
M.thumb_radius = 2
M.thumb_color = "FFFFFF"

----------------------------------------------------------
-- Button row
----------------------------------------------------------

M.icon_size = 22
M.icon_spacing = 36
M.button_left_inset_osc = 18
M.button_right_inset_osc = 18
M.button_y_anchor_osc = "center"
M.button_row_offset_osc = 0

M.button_group_left_width_osc = "20%"
M.button_group_left_min_width_osc = 110
M.button_group_left_align_osc = "start"

M.button_group_center_width_osc = "60%"
M.button_group_center_min_width_osc = 220
M.button_group_center_align_osc = "center"

M.button_group_right_width_osc = "20%"
M.button_group_right_min_width_osc = 110
M.button_group_right_align_osc = "end"

----------------------------------------------------------
-- Layout slots
----------------------------------------------------------

M.osc_C1 = "seekbar"
M.osc_C2 = false
M.osc_C3 = false
M.osc_C4 = false
M.osc_C5 = false
M.osc_C6 = false

M.osc_L1 = "prev"
M.osc_L2 = "seek_back"
M.osc_L3 = "play"
M.osc_L4 = "seek_forward"
M.osc_L5 = "next"
M.osc_C6 = false

M.osc_R1 = "volume"
M.osc_R2 = "subtitle"
M.osc_R3 = "fullscreen"
M.osc_R4 = "settings"
M.osc_R5 = "playlist"
M.osc_R6 = false
M.osc_R7 = false

----------------------------------------------------------
-- Style
----------------------------------------------------------

M.icon_bg_enabled_osc = false
M.icon_group_bg_enabled_osc = false
M.color_icon_osc = "F5F7FA"
M.alpha_icon_dim_osc = "60"

-- Keep the style clean and minimal, close to mpv’s default OSC.
M.color_chapter_mark = "F5F7FA"
M.alpha_chapter_mark = "30"

return M
