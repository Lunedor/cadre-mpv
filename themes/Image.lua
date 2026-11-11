local M = {}

M.theme_name = "Image"
M.theme_author = "Lunedor"

-- Shared appearance
M.surface_color = "101318"
M.accent_color = "8CC8FF"

-- Compact controller
M.height_panel_osc = 58
M.radius_panel_osc = 10
M.max_width_panel_osc = 760
M.alpha_panel_bg_osc = "CF"

-- Disable the seekbar, its hitbox, and seek labels.
M.enabled_seekbar_osc = false

-- Explicit single-row placement
M.osc_layout = {
    button_row = {
        anchor = "center",
        offset = 0,
    },
}

-- Image navigation
M.osc_L1 = "prev"
M.osc_L3 = "next"

-- Image title
M.osc_C1 = "title"

-- Utilities
M.osc_R1 = "settings"
M.osc_R2 = "playlist"
M.osc_R3 = "fullscreen"

return M