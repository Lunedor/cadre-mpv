local M = {}

M.theme_name = "Mpvlike"
M.theme_author = "Lunedor"

----------------------------------------------------------
-- PANEL AND PLACEMENT
----------------------------------------------------------

M.font_icon = "Material Icons"
M.height_panel_osc = 64
M.surface_color_osc = "000000"

-- Bottom inset retains the documented zero default.

M.osc_layout = {
    button_row = {
        anchor = "top",
        offset = 20,
    },
    seekbar = {
        anchor = "panel_bottom",
        panel_inset = 0,
    },
}

----------------------------------------------------------
-- THICK WHITE TIMELINE
----------------------------------------------------------

M.inset_side_seekbar_osc = 30
M.height_normal_seekbar = 24
M.height_hover_seekbar = 24
M.radius_seekbar_osc = 0
M.color_track_fg_osc = "FFFFFF"

-- Preserve zero-size thumb geometry.
M.width_thumb_seekbar_osc = 0
M.height_thumb_seekbar_osc = 0
M.radius_thumb_seekbar_osc = 0

----------------------------------------------------------
-- TITLE OVER TIMELINE
----------------------------------------------------------

M.enabled_title_osc = true
M.position_title_osc = "above_seekbar"
M.size_font_title_osc = 18
M.gap_title_seekbar_osc = -21

M.enabled_outline_title_osc = true
M.alpha_outline_title_osc = "DF"

-- No title slot is assigned, so the floating title is used.
-- width_title_item_osc is omitted because it sizes title slots.
-- Title-outline blur has no documented setting.

----------------------------------------------------------
-- TRANSPORT AND FRAME CONTROLS
----------------------------------------------------------

M.osc_L1 = "play_only"
M.osc_L2 = "pause"
M.osc_L3 = "stop"
M.osc_L4 = "next"

M.osc_L5 = "separator"

M.osc_L6 = "chapter_prev"
M.osc_L7 = "frame_back_step"
M.osc_L8 = "frame_step"
M.osc_L9 = "chapter_next"

-- shuffle/repeat are not documented action IDs.
-- Their preceding trailing separator is also omitted.

----------------------------------------------------------
-- UTILITIES
----------------------------------------------------------

M.osc_R1 = "volume"
M.osc_R2 = "settings"
M.osc_R3 = "fullscreen"
M.osc_R4 = "playlist"

----------------------------------------------------------
-- TIME AND DECORATION
----------------------------------------------------------

M.position_time_label_osc = "inline"

M.osc_slot_overrides = {
    osc_L5 = {
        separator_height = 26,
        separator_width = 1,
    },
}

-- Button tooltips retain the documented disabled default.

return M