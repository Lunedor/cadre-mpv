local M = {}

-- Shared identity
M.text_color = "E8EEE5"
M.surface_color = "101710"
M.accent_color = "B5EF64"

-- Playlist frame and panel
M.panel_width_pl = 380
M.bottom_inset_pl = 120
M.bar_radius_pl = 12
M.alpha_bar_bg_pl = "00"
M.title_position_pl = "center"

M.color_frame_pl = "172117"
M.color_list_bg_pl = "050805"

-- Recessed list surface
M.frame_shadow_pl = true
M.frame_shadow_alpha_pl = "90"
M.list_radius_pl = 4

-- Rows: explicitly match the viewport rather than the panel
M.row_bg_pl = "050805"
M.row_height_pl = 38
M.row_radius_pl = 4

-- Muted supporting text and icons
M.color_dim_pl = "82917C"
M.color_icon_pl = "B8C8AE"

-- Hover, selected, and currently playing states
M.color_hover_pl = "203520"
M.alpha_hover_pl = "18"
M.alpha_selected_pl = "90"
M.alpha_current_pl = "C0"

-- Scrollbar
M.color_scroll_fg_pl = "526C42"
M.color_scroll_bg_pl = "0C120B"

-- Complementary OSC details
M.color_track_bg_osc = "293624"
M.thumb_color = "D9F7B8"

return M