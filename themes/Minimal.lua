local M = {}

M.name = "Minimal"

-- Minimalist overlay theme (target min width: 640)

-- Shared identity
M.text_color    = "FFFFFF"
M.surface_color = "000000"
M.alpha_bar_bg  = "99"
M.accent_color  = "FFFFFF"

-- Panel
M.bar_height_osc = 46
M.bar_radius_osc = 0

-- Top-right menu (window-anchored): add, volume, settings, fullscreen
M.osc_R1_top = "add"
M.osc_R2_top = "volume"
M.osc_R3_top = "settings"
M.osc_R4_top = "fullscreen"

-- Top-left
M.osc_L1_top = "quit"
M.osc_L2_top = "title"

-- Join the top groups into a full-width header background.
M.osc_group_overrides = {
    L_top = {
        group = {
            background = true,
            color = "000000",
            alpha = "40",
            width = "50%",
            padding = 0,
            height = 80,
            radius = 0,
            border = false,
        },
    },
    R_top = {
        group = {
            background = true,
            color = "000000",
            alpha = "40",
            width = "50%",
            padding = 0,
            height = 80,
            radius = 0,
            border = false,
        },
    },
}

-- Center row
M.osc_C1_center = "play"

M.osc_slot_overrides = {
    osc_C1_center = {
        icon_size = 46,
        button_background = true,
        button_color = "FFFFFF", button_height = 70,
        button_alpha = "A0",
        button_padding = 12, button_radius = 35,        
    }
}

-- Bottom row: time + seekbar
M.osc_L1 = "time"
M.osc_C1 = "seekbar"
M.button_group_gap_osc = 8
M.button_y_anchor_osc = "center"

-- Thin seekbar with round-ish white thumb
M.seek_height_normal = 3
M.seek_height_hover  = 5
M.color_track_bg_osc = "6B6B6B"
M.seek_side_inset_osc = 8
M.thumb_width  = 6
M.thumb_height = 6
M.osc_title_align_osc = "left"

M.bottom_inset_pl = 55
M.top_inset_pl = 90

return M
