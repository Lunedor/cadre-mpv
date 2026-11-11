-- cadre_theme.lua
local M = {}

--------------------------------------------------------------------------------
-- TYPOGRAPHY
--------------------------------------------------------------------------------

M.font_text = "Inter"
M.font_size = 18
M.title_font_size = 20

--------------------------------------------------------------------------------
-- OSC
--------------------------------------------------------------------------------

M.bar_height = 88
M.bar_side_inset = 0
M.bar_bottom_inset = 0
M.bar_radius = 0

M.bar_autohide_sec = 0.35

M.thumb_width = 3
M.thumb_height = 8
M.thumb_radius = 2
M.thumb_color = "7CC6FF"

M.seek_y_offset = 12
M.icon_row_offset = 55
M.icon_spacing = 34
M.seek_height_normal = 5
M.seek_height_hover = 8

M.time_label_offset_y = 13
M.side_margin = 22
M.icon_size = 22

--------------------------------------------------------------------------------
-- Playlist
--------------------------------------------------------------------------------

M.panel_width = 390

M.row_height = 38
M.header_height = 38
M.toolbar_height = 38
M.search_height = 36

M.side_inset = 10
M.top_inset = 42
M.bottom_inset = 102

M.bar_radius_pl = 2

M.scrollbar_width = 4
M.hover_strip_width = 14

--------------------------------------------------------------------------------
-- Titlebar
--------------------------------------------------------------------------------

M.bar_height_tb = 32
M.button_width_tb = 42
M.title_font_size_tb = 13
M.hover_strip_height_tb = 8

--------------------------------------------------------------------------------
-- Base Colors
--------------------------------------------------------------------------------

M.color_text = "E5EDF5"
M.color_dim = "738090"

M.color_bar_bg = "14181E"
M.alpha_bar_bg = "10"

M.color_icon = "D8E1EA"
M.color_icon_dim = "556170"

M.color_hover_bg = "232B35"

--------------------------------------------------------------------------------
-- Playlist
--------------------------------------------------------------------------------

M.color_selected_pl = "2B4358"
M.color_current_pl = "56B6FF"

--------------------------------------------------------------------------------
-- Controls
--------------------------------------------------------------------------------

M.color_track_fg = "63B8FF"
M.color_track_bg = "2A313B"
M.color_slider_rail = "20262F"

M.thumb_color = "9BD6FF"

M.color_scroll_fg = "56697E"
M.color_scroll_bg = "1B2027"

M.color_danger = "E25555"

--------------------------------------------------------------------------------
-- Component Overrides
--------------------------------------------------------------------------------

M.color_bar_bg_tb = "181C22"
M.alpha_bar_bg_tb = "18"

M.color_bar_bg_osc = "15191F"
M.alpha_bar_bg_osc = "14"

M.color_bar_bg_pl = "171B21"
M.alpha_bar_bg_pl = "12"

--------------------------------------------------------------------------------
-- Chapter Tooltip
--------------------------------------------------------------------------------

M.color_chapter_mark = "14181E"
M.alpha_chapter_mark = "25"

M.chapter_tooltip_bg_color = "15191F"
M.chapter_tooltip_bg_alpha = "28"
M.chapter_tooltip_radius = 3

return M