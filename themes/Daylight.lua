local M = {}

M.theme_name = "Daylight"
M.theme_author = "Lunedor"

----------------------------------------------------------
-- SHARED IDENTITY
----------------------------------------------------------

M.font_icon = "FluentSystemIcons-Regular"
M.text_color = "26313D"
M.surface_color = "F7F6F2"
M.alpha_panel_bg = "FF"
M.accent_color = "2563EB"
M.alpha_icon_dim = "CA"

----------------------------------------------------------
-- SHARED PANEL / POPUP BORDERS
----------------------------------------------------------

M.border_all_color = "D6D5CE"
M.border_all_alpha = "FF"
M.border_all_width = 1

----------------------------------------------------------
-- FLOATING OSC
----------------------------------------------------------

M.anchor_y_panel_osc = "bottom"
M.height_panel_osc = 80
M.inset_side_panel_osc = 12
M.inset_bottom_panel_osc = 12
M.radius_panel_osc = 12
M.autohide_sec_panel_osc = 0.8

M.osc_layout = {
    button_row = {
        anchor = "center",
        offset = 10,
    },
    seekbar = {
        anchor = "panel_top",
        panel_inset = 14,
    },
}

----------------------------------------------------------
-- CONTROL LAYOUT
----------------------------------------------------------

-- One combined time display.
M.osc_L1 = "time"

-- Episode navigation and quick seeking.
M.osc_C1 = "prev"
M.osc_C2 = "seekbar_back"
M.osc_C3 = "play"
M.osc_C4 = "seekbar_forward"
M.osc_C5 = "next"

-- Frequently used viewing controls.
M.osc_R1 = "volume"
M.osc_R2 = "audio_list"
M.osc_R3 = "subtitle_list"
M.osc_R4 = "fullscreen"
M.osc_R5 = "playlist"

-- The time slot replaces standalone elapsed/duration labels.

----------------------------------------------------------
-- BLUE PLAY / PAUSE BUTTON
----------------------------------------------------------

M.osc_slot_overrides = {
    osc_C3 = {
        icon_size = 28,
        icon_color = "FFFFFF",

        button_background = true,
        button_color = "2563EB",
        button_alpha = "FF",
        button_height = 36,
        button_padding = 4,
        button_radius = 18,

        hover_icon_color = "FFFFFF",
        hover_bg_color = "1D4ED8",
        hover_bg_alpha = "FF",
    },
}

-- Accent hover for the remaining action buttons.
-- Keep time unchanged; it does not support hover_icon_color.
for _, slot in ipairs({
    "osc_C1",
    "osc_C2",
    "osc_C4",
    "osc_C5",
    "osc_R1",
    "osc_R2",
    "osc_R3",
    "osc_R4",
    "osc_R5",
}) do
    M.osc_slot_overrides[slot] = {
        hover_icon_color = "2563EB",
    }
end

----------------------------------------------------------
-- QUIET TIMELINE AND COMPACT PLAYHEAD
----------------------------------------------------------

M.height_normal_seekbar = 4
M.height_hover_seekbar = 6
M.color_track_bg_osc = "D7DCE3"

M.width_thumb = 3
M.height_thumb = 6
M.radius_thumb = 3

-- Progress and thumb color inherit the shared blue accent.
-- Shared border settings remain available through the
-- documented seekbar/thumb border fallback chains.

return M