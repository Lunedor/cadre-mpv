local M = {}

-- Shared palette for controls, dialogs, playlist, and menus.
M.surface_color = "151515"
M.text_color = "F5F5F5"
M.dim_color = "AAAAAA"
M.accent_color = "777777"

-- Bottom OSC panel.
M.height_panel_osc = 110
M.alpha_panel_bg_osc = "FF"
M.inset_bottom_panel_osc = 0
M.inset_left_button_osc = 20
M.inset_right_button_osc = 20

-- Explicitly separate the seekbar and controls.
M.osc_layout = {
    seekbar = {
        anchor = "panel_top",
        panel_inset = 30,
    },
    button_row = {
        anchor = "top",
        offset = 75,
    },
}

-- Title anchored to the OSC panel, NOT the window.
-- A title slot replaces the floating title automatically.
M.osc_C1_top_osc = "title"

M.osc_group_overrides = {
    C_top_osc = {
        button = {
            background = false,
            border = false,
        },
        group = {
            background = true,
            color = "000000",
            alpha = "FF",
            width = "100%",
            height = 36,
            padding = 0,
            radius = 0,
        },
    },
}

M.osc_slot_overrides = {
    osc_C1_top_osc = {
        font_size = 18,
        text_color = "FFFFFF",
    },
}

-- Thick seekbar, separate from the black title header.
M.enabled_seekbar_osc = true
M.inset_side_seekbar_osc = 0

M.height_normal_seekbar = 30
M.height_hover_seekbar = 30
M.radius_seekbar_osc = 0

M.color_track_bg_osc = "888888"
M.color_track_fg_osc = "FFFFFF"
M.color_thumb_seekbar_osc = "FFFFFF"

M.height_thumb_seekbar_osc = 15
M.width_thumb_seekbar_osc = 1
M.radius_thumb_seekbar_osc = 0

M.enabled_time_tooltip_seekbar_osc = true

-- Shared button styling.
M.size_icon_osc = 22
M.spacing_icon_osc = 46

M.enabled_icon_bg_osc = true
M.color_bg_icon_osc = "202020"
M.alpha_bg_icon_osc = "FF"
M.height_icon_bg_osc = 36
M.radius_bg_icon_osc = 8

-- Left: elapsed time and duration.
M.osc_L1 = "time"

-- Center: playback controls.
M.osc_C1 = "prev"
M.osc_C2 = "play"
M.osc_C3 = "next"

-- Right: tracks, volume, and utilities.
M.osc_R1 = "subtitle_list"
M.osc_R2 = "audio_list"
M.osc_R3 = "volume"
M.osc_R4 = "settings"
M.osc_R5 = "playlist"
M.osc_R6 = "fullscreen"

return M