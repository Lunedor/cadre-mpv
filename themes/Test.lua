local M = {}

-- Panel
M.bar_height_osc = 76
M.bar_radius_osc = 14
M.bar_side_inset_osc = 24
M.bar_bottom_inset_osc = 24
M.max_bar_width_osc = 900
M.color_bar_bg_osc = "141414"
M.alpha_bar_bg_osc = "40"
M.bar_autohide_sec_osc = 2.5

-- Rows: seekbar on top, buttons below
M.osc_layout = {
    button_row = {anchor = "center", offset = 12},
    seekbar = {anchor = "panel_top", panel_inset = 12},
}

-- Seekbar
M.seek_height_normal = 3
M.seek_height_hover = 8
M.thumb_height = 6
M.thumb_radius = 3
M.seek_edge_labels_osc = false   -- the time slot already shows elapsed / total

-- Left: transport, volume, time
M.osc_L1 = "prev"
M.osc_L2 = "play"
M.osc_L3 = "next"
M.osc_L4 = "volume_slider"
M.osc_L5 = "time"

-- Right: tracks, settings, fullscreen
M.osc_R1 = "subtitle"
M.osc_R2 = "audio_cycle"
M.osc_R3 = "settings"
M.osc_R4 = "fullscreen"

return M