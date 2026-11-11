local M = {}

M.name = "Center Strip"

-- Intended minimum width: 960 OSC units.
M.text_color = "F3EEE6"
M.surface_color = "24211E"
M.accent_color = "E5B980"

-- One continuous horizontal control surface at window center.
M.bar_y_anchor_osc = "center"
M.bar_height_osc = 64
M.bar_side_inset_osc = 24
M.max_bar_width_osc = 1040
M.bar_radius_osc = 8
M.alpha_bar_bg_osc = "18"

M.osc_layout = {
    button_row = {anchor = "center", offset = 0},
}

M.osc_L1 = "prev"
M.osc_L2 = "play"
M.osc_L3 = "next"

-- The only seekbar is an inline flexible slot, not a standalone track.
M.osc_C1 = "seekbar"
M.button_group_center_width_osc = "44%"

M.osc_R1 = "time"
M.osc_R2 = "volume"
M.osc_R3 = "fullscreen"

M.seek_height_normal = 3
M.seek_height_hover = 5
M.seek_side_inset_osc = 12
M.color_track_bg_osc = "665B4E"
M.thumb_width = 4
M.thumb_height = 4
M.thumb_radius = 4

M.osc_slot_overrides = {
    osc_L2 = {icon_color = "E5B980"},
}

return M
