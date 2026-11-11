-- cadre_theme.lua
local M = {}

--------------------------------------------------------------------------------
-- Typography
--------------------------------------------------------------------------------

M.font_text = "Inter"

--------------------------------------------------------------------------------
-- OSC
--------------------------------------------------------------------------------

M.bar_height = 108

M.bar_side_inset = 20
M.bar_bottom_inset = 24

M.bar_radius = 22

M.bar_autohide_sec = 0.55

M.thumb_width = 5
M.thumb_height = 12
M.thumb_radius = 3
M.thumb_color = "66D9FF"

M.seek_y_offset = 20
M.icon_row_offset = 66

M.icon_spacing = 42

M.seek_height_normal = 8
M.seek_height_hover = 13

M.time_label_offset_y = 18
M.side_margin = 30

M.icon_size = 28

--------------------------------------------------------------------------------
-- Playlist
--------------------------------------------------------------------------------

M.panel_width = 460

M.row_height = 52
M.header_height = 48
M.toolbar_height = 48
M.search_height = 44

M.side_inset = 20
M.top_inset = 60
M.bottom_inset = 130

M.bar_radius_pl = 24

M.scrollbar_width = 8
M.hover_strip_width = 22

--------------------------------------------------------------------------------
-- Titlebar
--------------------------------------------------------------------------------

M.bar_height_tb = 40
M.button_width_tb = 46
M.title_font_size_tb = 15
M.hover_strip_height_tb = 10

--------------------------------------------------------------------------------
-- Base Palette
--------------------------------------------------------------------------------

M.color_text = "F4F7FA"
M.color_dim = "7F8B98"

M.color_bar_bg = "11161D"
M.alpha_bar_bg = "24"

M.color_icon = "FFFFFF"
M.color_icon_dim = "66717D"

M.color_hover_bg = "27313C"

--------------------------------------------------------------------------------
-- Playlist
--------------------------------------------------------------------------------

M.color_selected_pl = "273F52"
M.color_current_pl = "4FD1FF"

--------------------------------------------------------------------------------
-- Controls
--------------------------------------------------------------------------------

M.color_track_fg = "4FD1FF"
M.color_track_bg = "343D48"

M.color_slider_rail = "252D36"

M.thumb_color = "FFFFFF"

M.color_scroll_fg = "728394"
M.color_scroll_bg = "182029"

M.color_danger = "FF5C5C"

--------------------------------------------------------------------------------
-- Component Overrides
--------------------------------------------------------------------------------

M.color_bar_bg_tb = "121820"
M.alpha_bar_bg_tb = "30"

M.color_bar_bg_osc = "121922"
M.alpha_bar_bg_osc = "28"

M.color_bar_bg_pl = "141B24"
M.alpha_bar_bg_pl = "2A"

--------------------------------------------------------------------------------
-- Chapter Tooltip
--------------------------------------------------------------------------------

M.color_chapter_mark = "141B24"
M.alpha_chapter_mark = "28"

M.chapter_tooltip_bg_color = "18212B"
M.chapter_tooltip_bg_alpha = "20"
M.chapter_tooltip_radius = 12

return M