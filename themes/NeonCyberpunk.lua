local M = {}

M.theme_name = "NeonCyberpunk"
M.theme_author = "Lunedor"

----------------------------------------------------------
-- CORE PALETTE
----------------------------------------------------------

M.accent_color = "00E5FF"
M.background_color = "070914"
M.surface_color = "160F2B"
M.text_color = "E8FFFF"

M.font_text = "Inter"
M.font_size = 14

----------------------------------------------------------
-- OSC PANEL
----------------------------------------------------------

M.anchor_y_panel_osc = "bottom"
M.height_panel_osc = 108
M.inset_side_panel_osc = 32
M.radius_panel_osc = 2
M.alpha_panel_bg_osc = "E7"

-- OSC surface inherits the shared purple surface.

M.inset_left_button_osc = 56
M.inset_right_button_osc = 56

M.osc_layout = {
    button_row = {
        anchor = "center",
        offset = 12,
    },
    seekbar = {
        anchor = "panel_top",
        panel_inset = 14,
    },
}

----------------------------------------------------------
-- BUTTON LAYOUT
----------------------------------------------------------

M.osc_L1 = "time"

M.osc_C1 = "prev"
M.osc_C2 = "seekbar_back"
M.osc_C3 = "play"
M.osc_C4 = "seekbar_forward"
M.osc_C5 = "next"

M.osc_R1 = "playlist"
M.osc_R2 = "volume"
M.osc_R3 = "fullscreen"

----------------------------------------------------------
-- CYAN TIMELINE
----------------------------------------------------------

-- 32 px panel inset + 14 px internal clearance.
M.inset_side_seekbar_osc = 46

M.height_normal_seekbar = 2
M.height_hover_seekbar = 6
M.color_track_bg_osc = "30204D"

-- Progress inherits the cyan accent.
M.width_border_seekbar_osc = 1
M.color_border_seekbar_osc = "00E5FF"
M.alpha_border_seekbar_osc = "9F"

----------------------------------------------------------
-- MAGENTA PLAYHEAD
----------------------------------------------------------

M.width_thumb_seekbar_osc = 10
M.radius_thumb_seekbar_osc = 2
M.color_thumb_seekbar_osc = "FF2E88"

-- Thumb height and border width retain their documented
-- defaults of 10 px and 1 px.
M.color_border_thumb_osc = "00E5FF"
M.alpha_border_thumb_osc = "DF"

----------------------------------------------------------
-- TIME DISPLAY
----------------------------------------------------------

M.size_font_osc = 15
M.width_time_item_osc = 120

M.enabled_shadow_time_label_osc = true
M.color_shadow_time_label_osc = "00E5FF"
M.alpha_shadow_time_label_osc = "8F"

-- OSC text inherits the shared pale-cyan text color.
-- The time slot replaces standalone elapsed/duration labels.

----------------------------------------------------------
-- ICONS
----------------------------------------------------------

M.icon_size = 20
M.icon_spacing = 40
M.color_icon_osc = "C7F9FF"

----------------------------------------------------------
-- BUTTON SURFACES AND CYAN BORDERS
----------------------------------------------------------

M.enabled_icon_bg_osc = true
M.color_bg_icon_osc = "160F2B"
M.radius_bg_icon_osc = 2

-- Button alpha retains the documented "20" default.
M.enabled_border_icon_osc = true
M.color_border_icon_osc = "00E5FF"
M.alpha_border_icon_osc = "9F"

-- Button border width retains the documented 1 px default.
-- Use the documented row-decoration field for surface height.
M.osc_group_overrides = {
    L = {
        button = {
            height = 38,
        },
    },

    C = {
        button = {
            height = 38,
        },
    },

    R = {
        button = {
            height = 38,
        },
    },
}

----------------------------------------------------------
-- GROUP HOUSINGS AND MAGENTA BORDERS
----------------------------------------------------------

M.enabled_bg_icon_group_osc = true
M.color_bg_icon_group_osc = "0B1022"
M.alpha_bg_icon_group_osc = "CF"

M.pad_bg_icon_group_osc = 14
M.height_bg_icon_group_osc = 44
M.radius_bg_icon_group_osc = 2

M.enabled_border_icon_group_osc = true
M.color_border_icon_group_osc = "FF2E88"
M.alpha_border_icon_group_osc = "8F"

-- Group border width retains the documented 1 px default.

----------------------------------------------------------
-- CHAPTER MARKERS AND PREVIEW CARDS
----------------------------------------------------------

M.color_chapter_mark = "FF2E88"
M.alpha_chapter_mark = "CF"

-- Chapter marker width retains the documented 2 px default.
M.chapter_tooltip_bg_color = "160F2B"
M.chapter_tooltip_bg_alpha = "DF"
M.chapter_tooltip_radius = 2

M.chapter_tooltip_pad_x = 14
M.chapter_tooltip_pad_y = 8

return M