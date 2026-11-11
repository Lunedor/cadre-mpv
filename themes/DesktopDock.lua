local M = {}

M.name = "Desktop Dock"

-- Target minimum player width: 800 OSC units.
-- Shared identity.
M.text_color = "F1F3F5"
M.surface_color = "171A20"
M.accent_color = "91BFFF"

-- Floating dock.
M.bar_height_osc = 112
M.bar_side_inset_osc = 16
M.bar_bottom_inset_osc = 16
M.max_bar_width_osc = 1120
M.bar_radius_osc = 18
M.alpha_bar_bg_osc = "10"

-- Track above the controls, without automatic row movement.
M.osc_layout = {
    button_row = {anchor = "center", offset = 20},
    seekbar = {anchor = "panel_top", panel_inset = 16},
}

-- Left: media identity.
M.osc_L1 = "time"
M.osc_title_enabled_osc = true
M.osc_title_position_osc = "below_seekbar"
M.osc_title_align_osc = "center"

-- Center: transport.
M.osc_C1 = "prev"
M.osc_C2 = "play"
M.osc_C3 = "next"

-- Right: timing and utilities.
M.osc_R1 = "volume"
M.osc_R2 = "fullscreen"

-- Fine timeline and compact thumb.
M.seek_height_normal = 4
M.seek_height_hover = 6
M.color_track_bg_osc = "3A414D"
M.thumb_width = 4
M.thumb_height = 4
M.thumb_radius = 4

-- Make play the primary action without changing its layout width.
M.osc_slot_overrides = {
    osc_C2 = {
        icon_color = "171A20",
        button_background = true,
        button_color = "91BFFF",
        button_alpha = "00",
        button_height = 36,
        button_padding = 6,
        button_radius = 18,
    },
}

-- 16 px bottom gap + 112 px dock + 16 px clearance.
M.bottom_inset_pl = 144
M.osc_bottom_exclusion_pl = 144

return M