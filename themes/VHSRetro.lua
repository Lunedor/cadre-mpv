local M = {}

M.theme_name = "VHSRetro"
M.theme_author = "Lunedor"

----------------------------------------------------------
-- CORE PALETTE
----------------------------------------------------------

M.accent_color = "FFB000"
M.background_color = "120F08"
M.surface_color = "201A0D"
M.text_color = "FFECC7"

M.font_text = "Consolas"
M.font_size = 15

----------------------------------------------------------
-- FLOATING OSC PANEL
----------------------------------------------------------

M.anchor_y_panel_osc = "bottom"
M.height_panel_osc = 110
M.inset_side_panel_osc = 24
M.inset_bottom_panel_osc = 22
M.alpha_panel_bg_osc = "EF"

-- Panel radius retains the documented zero default.
-- OSC surface inherits the shared surface color.

M.inset_left_button_osc = 48
M.inset_right_button_osc = 48

M.osc_layout = {
    button_row = {
        anchor = "center",
        offset = 15,
    },
    seekbar = {
        anchor = "panel_top",
        panel_inset = 16,
    },
}

----------------------------------------------------------
-- HARDWARE TRANSPORT
----------------------------------------------------------

M.osc_L1 = "seekbar_back"
M.osc_L2 = "prev"
M.osc_L3 = "play"
M.osc_L4 = "next"
M.osc_L5 = "seekbar_forward"

----------------------------------------------------------
-- DISPLAY
----------------------------------------------------------

M.osc_C1 = "time"

----------------------------------------------------------
-- MACHINE CONTROLS
----------------------------------------------------------

M.osc_R1 = "add"
M.osc_R2 = "volume"
M.osc_R3 = "fullscreen"
M.osc_R4 = "playlist"

----------------------------------------------------------
-- AMBER TIMELINE
----------------------------------------------------------

-- 24 px panel inset + 18 px internal clearance.
M.inset_side_seekbar_osc = 42
M.height_normal_seekbar = 7

-- Hover height retains the documented 10 px default.
-- Progress inherits the amber accent.
M.color_track_bg_osc = "493300"

M.width_border_seekbar_osc = 1
M.color_border_seekbar_osc = "FFB000"
M.alpha_border_seekbar_osc = "BF"

----------------------------------------------------------
-- SQUARE PLAYHEAD
----------------------------------------------------------

M.width_thumb_seekbar_osc = 14
M.height_thumb_seekbar_osc = 14
M.radius_thumb_seekbar_osc = 0
M.color_thumb_seekbar_osc_seekbar_osc = "FFECC7"

----------------------------------------------------------
-- AMBER TIME DISPLAY
----------------------------------------------------------

M.size_font_osc = 20
M.color_text_osc = "FFB000"
M.width_time_item_osc = 170

M.enabled_shadow_time_label_osc = true
M.alpha_shadow_time_label_osc = "8F"

-- The time slot replaces standalone elapsed/duration labels.

----------------------------------------------------------
-- ICONS
----------------------------------------------------------

M.icon_spacing = 48

-- Icon size retains the documented 24 px default.
-- Icons inherit the shared ivory text color rather than
-- the OSC-specific amber text color.

----------------------------------------------------------
-- SQUARE BUTTON SURFACES
----------------------------------------------------------

M.enabled_icon_bg_osc = true
M.color_bg_icon_osc = "120F08"
M.alpha_bg_icon_osc = "FF"

-- Button radius retains the documented zero default.
M.enabled_border_icon_osc = true
M.width_border_icon_osc = 2
M.color_border_icon_osc = "806000"
M.alpha_border_icon_osc = "8F"

-- Use the documented row-decoration height field.
M.osc_group_overrides = {
    L = {
        button = {
            height = 44,
        },
    },

    C = {
        button = {
            height = 44,
        },
    },

    R = {
        button = {
            height = 44,
        },
    },
}

----------------------------------------------------------
-- HARDWARE GROUP HOUSINGS
----------------------------------------------------------

M.enabled_bg_icon_group_osc = true
M.color_bg_icon_group_osc = "120F08"
M.alpha_bg_icon_group_osc = "FF"

M.pad_bg_icon_group_osc = 4
M.height_bg_icon_group_osc = 52

-- Group radius retains the documented zero default.
M.enabled_border_icon_group_osc = true
M.color_border_icon_group_osc = "806000"
M.alpha_border_icon_group_osc = "7F"
M.width_border_icon_group_osc = 2

----------------------------------------------------------
-- CHAPTERS AND PREVIEW CARDS
----------------------------------------------------------

M.color_chapter_mark = "FFB000"
M.alpha_chapter_mark = "AF"
M.chapter_mark_width = 3

M.chapter_tooltip_bg_color = "201A0D"
M.chapter_tooltip_bg_alpha = "DF"
M.chapter_tooltip_radius = 0

M.inset_bottom_pl = 140

return M