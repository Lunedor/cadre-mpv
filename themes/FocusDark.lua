--[[ Focus Dark — daily-use

Designed for a minimum player width of 960 px.
Not runtime-tested; verify slot spacing and blur behavior in Cadre.
]]

local M = {}

M.theme_name = "FocusDark"
M.theme_author = "Lunedor"

-- Shared identity
M.surface_color = "0A0D12"
M.alpha_panel_bg = "53"
M.text_color = "E8EDF4"
M.accent_color = "FFB000"
M.alpha_icon_dim = "9F"

M.glass_blur = true
M.radius_glass_blur = 16
M.panel_radius = 14
M.border_all_color = "000000"
M.border_all_alpha = "5F"
M.border_all_width = 1

-- OSC panel
M.height_panel_osc = 92
M.panel_y_anchor_osc = "bottom"
M.panel_bottom_inset_osc = 0
M.side_inset_panel_osc = 0
M.alpha_panel_bg_osc = "33"
M.autohide_sec_panel_osc = 0.4
M.panel_radius_osc = 0

-- Keep the video frame clean; titlebar provides the title.
M.osc_title_enabled_osc = false

-- Seekbar: full-width, top of the OSC panel
M.position_seekbar_osc = "top"
M.offset_y_seekbar_osc = 14
M.side_inset_seekbar_osc = 24
M.height_normal_seekbar = 6
M.height_hover_seekbar = 10
M.color_track_bg_osc = "303845"
M.width_seekbar_border_osc = 0

M.chapter_mark_width = 2
M.color_chapter_mark = "0A0D12"
M.alpha_chapter_mark = "00"
M.chapter_hover_px = 8
M.chapter_tooltip_osc = true
M.seekbar_time_tooltip_osc = true

-- Bottom control row
M.osc_L1 = "add"
M.osc_L2 = "stream"
M.osc_L3 = "youtube"
M.osc_L4 = "webdav"
M.osc_L5 = "music_mode"

M.osc_C1 = "prev"
M.osc_C2 = "seekbar_back"
M.osc_C3 = "play"
M.osc_C4 = "seekbar_forward"
M.osc_C5 = "next"

M.osc_R1 = "volume"
M.osc_R2 = "subtitle_list"
M.osc_R3 = "settings"
M.osc_R4 = "fullscreen"
M.osc_R5 = "playlist"

-- Playlist: right-edge hover panel for TorBox seasons and YouTube queues
M.panel_width_pl = 400
M.side_inset_pl = 16
M.top_inset_pl = 48
M.bottom_inset_pl = 116
M.header_height_pl = 42
M.search_height_pl = 40
M.toolbar_height_pl = 42

M.row_height_pl = 42
M.row_gap_pl = 2
M.row_radius_pl = 6
M.alpha_current_pl = "77"
M.alpha_selected_pl = "9F"

M.hover_strip_width_pl = 16
M.hide_delay_sec_pl = 0.35
M.osc_bottom_exclusion_pl = 116

-- Titlebar: appears only near the top edge
M.titlebar_show_mode_tb = "auto"
M.titlebar_button_side_tb = "right"
M.panel_height_tb = 36
M.hide_delay_sec_tb = 0.35
M.hover_strip_height_tb = 10

return M