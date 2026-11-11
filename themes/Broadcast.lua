-- cadre_theme.lua
local M = {}

--------------------------------------------------------------------------------
-- Typography
--------------------------------------------------------------------------------

M.font_text = "Inter"

--------------------------------------------------------------------------------
-- OSC
--------------------------------------------------------------------------------

M.bar_height = 92

M.bar_side_inset = 0
M.bar_bottom_inset = 0

M.bar_radius = 4

M.bar_autohide_sec = 0.35

M.thumb_width = 4
M.thumb_height = 10
M.thumb_radius = 2
M.thumb_color = "FFB000"

M.seek_y_offset = 13
M.icon_row_offset = 58

M.icon_spacing = 36

M.seek_height_normal = 5
M.seek_height_hover = 9

M.time_label_offset_y = 15
M.side_margin = 24

M.icon_size = 24

--------------------------------------------------------------------------------
-- Playlist
--------------------------------------------------------------------------------

M.panel_width = 410

M.row_height = 40
M.header_height = 40
M.toolbar_height = 40
M.search_height = 38

M.side_inset = 12
M.top_inset = 46
M.bottom_inset = 110

M.bar_radius_pl = 5

M.scrollbar_width = 5
M.hover_strip_width = 16

--------------------------------------------------------------------------------
-- Titlebar
--------------------------------------------------------------------------------

M.bar_height_tb = 34
M.button_width_tb = 42
M.title_font_size_tb = 14
M.hover_strip_height_tb = 8

--------------------------------------------------------------------------------
-- Base Palette
--------------------------------------------------------------------------------

M.color_text = "E6E1D8"
M.color_dim = "8A8070"

M.color_bar_bg = "171614"
M.alpha_bar_bg = "18"

M.color_icon = "E8DDCC"
M.color_icon_dim = "62594D"

M.color_hover_bg = "302A21"

--------------------------------------------------------------------------------
-- Playlist
--------------------------------------------------------------------------------

M.color_selected_pl = "493719"
M.color_current_pl = "FFB000"

--------------------------------------------------------------------------------
-- Controls
--------------------------------------------------------------------------------

M.color_track_fg = "FFB000"
M.color_track_bg = "3A352D"

M.color_slider_rail = "25211C"

M.thumb_color = "FFE2A0"

M.color_scroll_fg = "8C7A5E"
M.color_scroll_bg = "211E19"

M.color_danger = "FF5544"

--------------------------------------------------------------------------------
-- Component Overrides
--------------------------------------------------------------------------------

M.color_bar_bg_tb = "151310"
M.alpha_bar_bg_tb = "22"

M.color_bar_bg_osc = "181613"
M.alpha_bar_bg_osc = "20"

M.color_bar_bg_pl = "191713"
M.alpha_bar_bg_pl = "1C"

--------------------------------------------------------------------------------
-- Chapter Tooltip
--------------------------------------------------------------------------------

M.color_chapter_mark = "191713"
M.alpha_chapter_mark = "25"

M.chapter_tooltip_bg_color = "211D17"
M.chapter_tooltip_bg_alpha = "24"
M.chapter_tooltip_radius = 5

return M