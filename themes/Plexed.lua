local M = {}

M.theme_name = "Plexed"
M.theme_author = "Lunedor"

----------------------------------------------------------
-- CORE PALETTE
----------------------------------------------------------

M.accent_color = "E5A00D"
M.background_color = "090909"
M.surface_color = "171717"
M.text_color = "FFFFFF"

M.font_text = "Inter"
M.font_size = 15

----------------------------------------------------------
-- OSC PANEL
----------------------------------------------------------

M.anchor_y_panel_osc = "bottom"
M.height_panel_osc = 120
M.inset_side_panel_osc = 30
M.inset_bottom_panel_osc = 26
M.radius_panel_osc = 14
M.alpha_panel_bg_osc = "ED"

-- OSC surface inherits the shared surface color.

M.osc_layout = {
    button_row = {
        anchor = "center",
        offset = 12,
    },
    seekbar = {
        anchor = "panel_top",
        panel_inset = 18,
    },
}

-- Window-edge insets keep controls inside the floating panel.
M.inset_left_button_osc = 54
M.inset_right_button_osc = 54

----------------------------------------------------------
-- BUTTON LAYOUT
----------------------------------------------------------

-- Playback cluster
M.osc_L1 = "prev"
M.osc_L2 = "seekbar_back"
M.osc_L3 = "play"
M.osc_L4 = "seekbar_forward"
M.osc_L5 = "next"

-- Information
M.osc_C1 = "time"

-- Theater controls
M.osc_R1 = "playlist"
M.osc_R2 = "volume"
M.osc_R3 = "fullscreen"
M.osc_R4 = "add"

----------------------------------------------------------
-- SEEKBAR
----------------------------------------------------------

-- 30 px panel inset + 22 px internal clearance.
M.inset_side_seekbar_osc = 52

M.height_normal_seekbar = 5
M.height_hover_seekbar = 9
M.color_track_bg_osc = "404040"

-- Progress inherits the gold accent.
-- Seekbar border width retains the documented zero default.

----------------------------------------------------------
-- THUMB
----------------------------------------------------------

M.width_thumb_seekbar_osc = 14
M.height_thumb_seekbar_osc = 14
M.radius_thumb_seekbar_osc = 7
M.color_thumb_seekbar_osc = "FFFFFF"

----------------------------------------------------------
-- TIME
----------------------------------------------------------

M.size_font_osc = 18
M.width_time_item_osc = 160
M.enabled_shadow_time_label_osc = true
M.alpha_shadow_time_label_osc = "9F"

-- OSC text inherits the shared white text color.
-- The time slot replaces standalone elapsed/duration labels.

----------------------------------------------------------
-- ICONS
----------------------------------------------------------

M.icon_size = 25
M.icon_spacing = 52

-- OSC icons inherit the shared white text color.

----------------------------------------------------------
-- BUTTON SURFACES
----------------------------------------------------------

M.enabled_icon_bg_osc = true
M.color_bg_icon_osc = "262626"
M.alpha_bg_icon_osc = "CF"
M.radius_bg_icon_osc = 20

-- Apply the documented row-decoration height field
-- consistently to transport, information, and utility rows.
M.osc_group_overrides = {
    L = {
        button = {
            height = 35,
        },
    },

    C = {
        button = {
            height = 35,
        },
    },

    R = {
        button = {
            height = 35,
        },
    },
}

----------------------------------------------------------
-- GROUP HOUSINGS
----------------------------------------------------------

M.enabled_bg_icon_group_osc = true
M.color_bg_icon_group_osc = "111111"
M.alpha_bg_icon_group_osc = "DF"
M.pad_bg_icon_group_osc = 4
M.height_bg_icon_group_osc = 54
M.radius_bg_icon_group_osc = 25

----------------------------------------------------------
-- CHAPTERS
----------------------------------------------------------

M.color_chapter_mark = "E5A00D"
M.alpha_chapter_mark = "AF"

-- Chapter marker width retains the documented 2 px default.

M.chapter_tooltip_bg_color = "171717"
M.chapter_tooltip_bg_alpha = "DF"
M.chapter_tooltip_radius = 10

return M