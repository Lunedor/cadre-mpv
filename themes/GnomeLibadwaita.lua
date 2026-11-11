local M = {}

M.theme_name = "GNOMELibadwaita"
M.theme_author = "Lunedor"

----------------------------------------------------------
-- CORE PALETTE
----------------------------------------------------------

M.accent_color = "3584E4"
M.background_color = "242424"
M.surface_color = "303030"
M.text_color = "FFFFFF"

M.font_text = "Cantarell"
M.font_size = 15

----------------------------------------------------------
-- FLOATING OSC PANEL
----------------------------------------------------------

M.anchor_y_panel_osc = "bottom"
M.height_panel_osc = 106
M.inset_side_panel_osc = 28
M.inset_bottom_panel_osc = 28
M.radius_panel_osc = 16
M.alpha_panel_bg_osc = "EF"

-- OSC surface, text, and icons inherit shared colors.

M.inset_left_button_osc = 52
M.inset_right_button_osc = 52

M.osc_layout = {
    button_row = {
        anchor = "center",
        offset = 13,
    },
    seekbar = {
        anchor = "panel_top",
        panel_inset = 20,
    },
}

----------------------------------------------------------
-- BUTTON LAYOUT
----------------------------------------------------------

-- Left: integrated mute and volume slider
M.osc_L1 = "volume_slider"

-- Center: playback
M.osc_C1 = "prev"
M.osc_C2 = "seekbar_back"
M.osc_C3 = "play"
M.osc_C4 = "seekbar_forward"
M.osc_C5 = "next"

-- Right: utilities
M.osc_R1 = "playlist"
M.osc_R2 = "fullscreen"

----------------------------------------------------------
-- VOLUME SLIDER
----------------------------------------------------------

M.enabled_mute_volume_slider_osc = true
M.enabled_thumb_volume_slider_osc = true

M.width_volume_slider_osc = 70
M.height_volume_slider_osc = 2
M.height_thumb__volume_slider_osc = 6
M.pad_right_volume_slider_osc = 18

-- Volume thumb width retains the documented 4 px default.

----------------------------------------------------------
-- BLUE TIMELINE
----------------------------------------------------------

-- 28 px panel inset + 24 px internal clearance.
M.inset_side_seekbar_osc = 52

M.height_normal_seekbar = 4
M.height_hover_seekbar = 8
M.color_track_bg_osc = "555555"

-- Progress inherits the blue accent.
-- Seekbar border width retains the documented zero default.

----------------------------------------------------------
-- PLAYHEAD
----------------------------------------------------------

M.width_thumb_seekbar_osc = 12
M.height_thumb_seekbar_osc = 12
M.radius_thumb_seekbar_osc = 6
M.color_thumb_seekbar_osc = "FFFFFF"

----------------------------------------------------------
-- TIME LABELS
----------------------------------------------------------

M.enabled_shadow_time_label_osc = false

-- OSC font size inherits the shared 15 px font size.
-- No time slot is assigned, so width_time_item_osc is omitted.

----------------------------------------------------------
-- ICONS
----------------------------------------------------------

M.icon_size = 22
M.icon_spacing = 44

-- Icon font retains the documented
-- "Material Icons Outlined" default.

----------------------------------------------------------
-- ROUNDED BUTTON SURFACES
----------------------------------------------------------

M.enabled_icon_bg_osc = true
M.color_bg_icon_osc = "3A3A3A"
M.alpha_bg_icon_osc = "CF"
M.pad_x_bg_icon_osc = 8
M.radius_bg_icon_osc = 20

-- Use the documented row-decoration height field.
M.osc_group_overrides = {
    L = {
        button = {
            height = 40,
        },
    },

    C = {
        button = {
            height = 40,
        },
    },

    R = {
        button = {
            height = 40,
        },
    },
}

-- Group backgrounds retain their documented disabled default.

----------------------------------------------------------
-- CHAPTERS AND PREVIEW CARDS
----------------------------------------------------------

M.color_chapter_mark = "3584E4"
M.alpha_chapter_mark = "AF"

-- Chapter marker width retains the documented 2 px default.

M.chapter_tooltip_bg_color = "303030"
M.chapter_tooltip_bg_alpha = "EF"
M.chapter_tooltip_radius = 10

M.inset_bottom_pl = 140

return M