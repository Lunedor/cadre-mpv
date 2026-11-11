local M = {}

M.theme_name = "Dashboard"
M.theme_author = "Lunedor"
M.theme_variant = "Dashboard"

----------------------------------------------------------
-- CORE PALETTE
----------------------------------------------------------

M.accent_color     = "4DA3FF"
M.background_color = "070A0F"
M.surface_color    = "111827"
M.text_color       = "F1F5F9"
M.dim_color        = "64748B"
M.danger_color     = "EF4444"

M.font_text  = "Inter"
M.font_size  = 15
M.alpha_bar_bg = "18"

----------------------------------------------------------
-- TITLE BAR
----------------------------------------------------------

M.titlebar_show_mode = "always"
M.titlebar_button_side = "right"

M.bar_height_tb = 36
M.button_width_tb = 42

M.color_bar_bg_tb = "070A0F"
M.alpha_bar_bg_tb = "18"
M.color_text_tb = "CBD5E1"
M.color_hover_bg_tb = "1E293B"

----------------------------------------------------------
-- OSC PANEL
----------------------------------------------------------

M.bar_y_anchor_osc = "bottom"

M.bar_height_osc = 90
M.bar_side_inset_osc = 26
M.bar_bottom_inset_osc = 24
M.bar_radius_osc = 6

M.color_bar_bg_osc = "111827"
M.alpha_bar_bg_osc = "10"

----------------------------------------------------------
-- BUTTON LAYOUT
----------------------------------------------------------

-- Left: information
M.osc_L1 = "time"
M.osc_L2 = false
M.osc_L3 = false

-- Center: transport
M.osc_C1 = "prev"
M.osc_C2 = "seek_back"
M.osc_C3 = "play"
M.osc_C4 = "seek_forward"
M.osc_C5 = "next"
M.osc_C6 = false

-- Right: utilities
M.osc_R4 = "playlist"
M.osc_R2 = "volume"
M.osc_R3 = "fullscreen"
M.osc_R1 = "add"
M.osc_R5 = false

----------------------------------------------------------
-- SEEKBAR
----------------------------------------------------------

M.seek_y_offset = 18
M.seek_side_inset_osc = 20

M.seek_height_normal = 5
M.seek_height_hover = 10

M.color_track_fg_osc = "4DA3FF"
M.color_track_bg_osc = "334155"

M.seek_border_width_osc = 0

----------------------------------------------------------
-- THUMB
----------------------------------------------------------

M.thumb_width = 12
M.thumb_height = 12
M.thumb_radius = 6

M.thumb_color = "FFFFFF"

----------------------------------------------------------
-- TIME
----------------------------------------------------------

M.font_size_osc = 18
M.color_text_osc = "F8FAFC"

M.time_item_width_osc = 150

M.time_label_shadow_osc = true
M.time_label_shadow_alpha_osc = "50"

----------------------------------------------------------
-- ICONS
----------------------------------------------------------

M.icon_size = 22
M.icon_spacing = 46

M.color_icon_osc = "E2E8F0"

M.icon_bg_enabled_osc = false

----------------------------------------------------------
-- BUTTON GROUPS
----------------------------------------------------------

M.icon_group_bg_enabled_osc = true
M.icon_group_bg_color_osc = "0B1220"
M.icon_group_bg_alpha_osc = "20"

M.icon_group_bg_padding_osc = 18
M.icon_group_bg_height_osc = 46
M.icon_group_bg_radius_osc = 6

----------------------------------------------------------
-- CHAPTERS
----------------------------------------------------------

M.color_chapter_mark = "4DA3FF"
M.alpha_chapter_mark = "40"

M.chapter_mark_width = 2

M.chapter_tooltip_bg_color = "111827"
M.chapter_tooltip_bg_alpha = "10"

----------------------------------------------------------
-- PLAYLIST
----------------------------------------------------------

M.panel_width_pl = 420

M.row_height_pl = 44
M.row_gap_pl = 4
M.row_radius_pl = 4

M.bar_radius_pl = 6

M.color_bar_bg_pl = "111827"
M.alpha_bar_bg_pl = "10"

M.color_hover_pl = "1E293B"
M.alpha_hover_pl = "50"

M.color_selected_pl = "4DA3FF"
M.color_current_pl = "4DA3FF"

M.color_text_pl = "F8FAFC"
M.color_dim_pl = "94A3B8"

M.font_size_pl = 14
M.title_font_size_pl = 17

return M
