local M = {}

M.theme_name = "Endgame"
M.theme_author = "Lunedor"

----------------------------------------------------------
-- SHARED IDENTITY
----------------------------------------------------------

M.text_color = "E7E5DF"
M.surface_color = "302E2B"
M.accent_color = "81B64C"
M.alpha_panel_bg = "FF"
M.panel_radius = 10

----------------------------------------------------------
-- FLOATING CONTROL PANEL
----------------------------------------------------------

M.anchor_y_panel_osc = "bottom"
M.height_panel_osc = 112
M.inset_side_panel_osc = 16
M.inset_bottom_panel_osc = 16

M.osc_layout = {
    button_row = {
        anchor = "center",
        offset = 16,
    },
    seekbar = {
        anchor = "panel_top",
        panel_inset = 20,
    },
}

-- No floating OSC title.
-- Titlebar behavior remains controlled by the player.
M.enabled_title_osc = false

----------------------------------------------------------
-- CONTROL LAYOUT
----------------------------------------------------------

M.osc_L1 = "time"

M.osc_C1 = "prev"
M.osc_C2 = "seekbar_back"
M.osc_C3 = "play"
M.osc_C4 = "seekbar_forward"
M.osc_C5 = "next"

M.osc_R1 = "volume"
M.osc_R2 = "subtitle"
M.osc_R3 = "playlist"
M.osc_R4 = "fullscreen"

----------------------------------------------------------
-- SEEKBAR
----------------------------------------------------------

M.color_track_bg_osc = "494640"
M.height_normal_seekbar = 4
M.height_hover_seekbar = 6

M.width_thumb_seekbar_osc = 6
M.height_thumb_seekbar_osc = 6
M.radius_thumb_seekbar_osc = 6

-- Progress and thumb color inherit the shared green accent.

----------------------------------------------------------
-- SLOT APPEARANCE
----------------------------------------------------------

M.osc_slot_overrides = {
    osc_L1 = {
        text_color = "B9B6AE",
    },

    osc_C3 = {
        icon_color = "FFFFFF",

        button_background = true,
        button_color = "81B64C",
        button_alpha = "FF",
        button_height = 40,
        button_padding = 8,
        button_radius = 7,

        hover_icon_color = "FFFFFF",
        hover_bg_color = "95C65D",
        hover_bg_alpha = "FF",
    },
}

-- Neutral hover treatment for the remaining action buttons.
-- Time does not support hover-icon/background overrides.
for _, slot in ipairs({
    "osc_C1",
    "osc_C2",
    "osc_C4",
    "osc_C5",
    "osc_R1",
    "osc_R2",
    "osc_R3",
    "osc_R4",
}) do
    M.osc_slot_overrides[slot] = {
        hover_icon_color = "FFFFFF",
        hover_bg_color = "45423E",
        hover_bg_alpha = "FF",
    }
end

----------------------------------------------------------
-- MATCHING TOOLTIP SURFACES
----------------------------------------------------------

M.chapter_tooltip_bg_color = "262421"
M.chapter_tooltip_text_color = "E7E5DF"

-- Seekbar time-tooltip background and text inherit
-- the chapter-tooltip colors through documented fallbacks.

M.inset_bottom_pl = 140

return M