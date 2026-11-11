local M = {}

M.name = "Island"

-- Minimum intended width: 800 OSC units.
M.text_color = "F1F3F5"
M.surface_color = "171A20"
M.accent_color = "91BFFF"

-- Invisible support panel; only group capsules are painted.
M.bar_height_osc = 144
M.bar_bottom_inset_osc = 16
M.alpha_bar_bg_osc = "FF"

M.osc_layout = {
    button_row = {anchor = "center", offset = 32},
    seekbar = {anchor = "panel_top", panel_inset = 64},
}

-- Title above the timeline, anchored to the support panel.
M.osc_top_offset = 24
M.osc_L1_top_osc = "title"
M.osc_title_item_width_osc = 500
M.osc_title_align_osc = "left"

M.osc_L1 = "time"
M.osc_C1 = "prev"
M.osc_C2 = "play"
M.osc_C3 = "next"
M.osc_R1 = "volume"
M.osc_R2 = "playlist"
M.osc_R3 = "fullscreen"

M.seek_height_normal = 3
M.seek_height_hover = 5
M.color_track_bg_osc = "59616D"
M.thumb_width = 4
M.thumb_height = 4
M.thumb_radius = 4

-- Capsules belong only to the ordinary bottom row.
M.osc_group_overrides = {
    L = {
        group = {
            background = true, color = "171A20", alpha = "18",
            padding = 8, height = 40, radius = 20,
        },
    },
    C = {
        group = {
            background = true, color = "171A20", alpha = "18",
            padding = 8, height = 40, radius = 20,
        },
    },
    R = {
        group = {
            background = true, color = "171A20", alpha = "18",
            padding = 8, height = 40, radius = 20,
        },
    },
}

M.osc_slot_overrides = {
    osc_C2 = {icon_color = "91BFFF"},
}

M.bottom_inset_pl = 176
M.osc_bottom_exclusion_pl = 176

return M
