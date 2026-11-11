local M = {}

M.theme_name = "Edge-to-Edge Industrial"
M.theme_author = "Lunedor"

-- Panel Geometry
M.bar_height_osc = 72
M.bar_side_inset_osc = 0
M.bar_bottom_inset_osc = 0
M.bar_radius_osc = 0
M.color_bar_bg_osc = "0D1117"
M.alpha_bar_bg_osc = "00"

-- Seekbar positioning
M.seek_y_offset = 0
M.seek_side_inset_osc = 0

-- Button positioning
M.button_y_anchor_osc = "bottom"
M.button_row_offset_osc = 42

-- Left Group Layout (Playback & Time)
M.osc_L1 = "play"
M.osc_L2 = "seek_back"
M.osc_L3 = "seek_forward"
M.osc_L4 = "time"
M.osc_L5 = false
M.osc_L6 = false

-- Center Group Layout (Empty)
M.osc_C1 = false
M.osc_C2 = false
M.osc_C3 = false
M.osc_C4 = false
M.osc_C5 = false
M.osc_C6 = false

-- Right Group Layout (Utilities)
M.osc_R1 = "volume"
M.osc_R2 = "playlist"
M.osc_R3 = "fullscreen"
M.osc_R4 = false
M.osc_R5 = false
M.osc_R6 = false

M.bottom_inset_pl = 80

return M