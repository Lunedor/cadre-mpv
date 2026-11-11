local M = {}

M.theme_name = "BlueprintWireframe"
M.theme_author = "Lunedor"

----------------------------------------------------------
-- CORE PALETTE
----------------------------------------------------------

M.accent_color = "38BDF8"
M.background_color = "06111C"
M.surface_color = "081827"
M.text_color = "D7F3FF"

M.font_text = "Inter"
M.font_size = 14

----------------------------------------------------------
-- INVISIBLE OSC CONTAINER
----------------------------------------------------------

M.anchor_y_panel_osc = "bottom"
M.height_panel_osc = 92
M.inset_side_panel_osc = 32

M.surface_color_osc = "06111C"
M.alpha_panel_bg_osc = "00"

-- Panel radius retains the documented zero default.

M.inset_left_button_osc = 56
M.inset_right_button_osc = 56

M.osc_layout = {
    button_row = {
        anchor = "center",
        offset = 12,
    },
    seekbar = {
        anchor = "panel_top",
        panel_inset = 16,
    },
}

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
M.osc_R2 = "settings"
M.osc_R3 = "fullscreen"
M.osc_R4 = "playlist"

----------------------------------------------------------
-- OUTLINED TIMELINE
----------------------------------------------------------

-- 32 px container inset + 18 px internal clearance.
M.inset_side_seekbar_osc = 50

M.height_normal_seekbar = 2
M.height_hover_seekbar = 5
M.color_track_bg_osc = "164E63"

-- Progress inherits the cyan accent.
M.width_border_seekbar_osc = 1
M.color_border_seekbar_osc = "38BDF8"
M.alpha_border_seekbar_osc = "CF"

----------------------------------------------------------
-- RECTANGULAR PLAYHEAD
----------------------------------------------------------

M.width_thumb = 8
M.height_thumb = 14
M.radius_thumb = 0

-- Thumb color inherits the cyan progress color.
-- Border width retains the documented 1 px default.
M.color_border_thumb_osc = "D7F3FF"
M.alpha_border_thumb_osc = "DF"

----------------------------------------------------------
-- TIME DISPLAY
----------------------------------------------------------

M.width_time_item_osc = 140
M.enabled_shadow_time_label_osc = false

-- OSC font size and text color inherit shared settings.
-- The time slot replaces standalone elapsed/duration labels.

----------------------------------------------------------
-- ICONS
----------------------------------------------------------

M.icon_size = 20
M.icon_spacing = 42
M.color_icon_osc = "B9E9FF"

----------------------------------------------------------
-- SQUARE BUTTON SURFACES
----------------------------------------------------------

M.enabled_icon_bg_osc = true
M.color_bg_icon_osc = "06111C"
M.alpha_bg_icon_osc = "FF"

-- Button radius retains the documented zero default.
M.enabled_border_icon_osc = true
M.color_border_icon_osc = "38BDF8"
M.alpha_border_icon_osc = "BF"

-- Button border width retains the documented 1 px default.
-- Use the documented row-decoration height field.
M.osc_group_overrides = {
    L = {
        button = {
            height = 36,
        },
    },

    C = {
        button = {
            height = 36,
        },
    },

    R = {
        button = {
            height = 36,
        },
    },
}

----------------------------------------------------------
-- CHAPTERS AND PREVIEW CARDS
----------------------------------------------------------

M.color_chapter_mark = "38BDF8"
M.alpha_chapter_mark = "9F"
M.chapter_mark_width = 1

M.chapter_tooltip_bg_color = "081827"
M.chapter_tooltip_bg_alpha = "DF"
M.chapter_tooltip_radius = 0

return M