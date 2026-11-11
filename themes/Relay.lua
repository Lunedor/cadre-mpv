local M = {}

M.theme_name = "Relay"
M.theme_author = "Lunedor"

----------------------------------------------------------
-- SHARED IDENTITY
----------------------------------------------------------

M.surface_color = "211F1E"
M.text_color = "E5DFD7"
M.accent_color = "C99570"
M.alpha_panel_bg = "F7"
M.panel_radius = 8
M.font_icon = "Material Icons Round"

----------------------------------------------------------
-- COMPACT FLOATING CONSOLE
----------------------------------------------------------

M.anchor_y_panel_osc = "bottom"
M.height_panel_osc = 124
M.inset_side_panel_osc = 20
M.max_width_panel_osc = 720
M.inset_bottom_panel_osc = 16

M.osc_layout = {
    button_row = {
        anchor = "center",
        offset = -10,
    },
    seekbar = {
        anchor = "panel_top",
        panel_inset = 20,
    },
}

M.inset_left_button_osc = 28
M.inset_right_button_osc = 28

----------------------------------------------------------
-- MAIN ROW
----------------------------------------------------------

M.osc_L1 = "volume"

M.osc_C1 = "prev"
M.osc_C2 = "play"
M.osc_C3 = "next"

M.osc_R1 = "fullscreen"

----------------------------------------------------------
-- LOWER SHELF
----------------------------------------------------------

M.offset_bottom_osc = 32

M.osc_L1_bottom_osc = "stream"
M.osc_L2_bottom_osc = "youtube"
M.osc_L3_bottom_osc = "music_mode"

M.osc_R1_bottom_osc = "playlist"
M.osc_R2_bottom_osc = "settings"

----------------------------------------------------------
-- SINGLE STANDALONE TIMELINE
----------------------------------------------------------

M.enabled_title_osc = false

M.inset_side_seekbar_osc = 28
M.height_normal_seekbar = 3
M.height_hover_seekbar = 5
M.color_track_bg_osc = "49413A"

M.position_time_label_osc = "inline"
M.size_font_osc = 14

-- No time slot is assigned.
-- The reference does not document a boolean start-label toggle.

M.width_thumb_seekbar_osc = 3
M.height_thumb_seekbar_osc = 6
M.radius_thumb_seekbar_osc = 2
M.color_thumb_seekbar_osc = "D8B394"

----------------------------------------------------------
-- ICONS AND LOCAL SURFACES
----------------------------------------------------------

M.icon_size = 22
M.icon_spacing = 42
M.color_icon_osc = "C8BEB3"

M.pad_x_bg_icon_osc = 6
M.radius_bg_icon_osc = 5

-- Permanent individual button backgrounds remain disabled.
-- Main-row surface height is set through row decorations.

M.osc_group_overrides = {
    L = {
        button = {
            height = 34,
        },
    },

    C = {
        button = {
            height = 34,
        },
    },

    R = {
        button = {
            height = 34,
        },
    },

    L_bottom_osc = {
        button = {
            height = 32,
            padding = 6,
            radius = 4,
        },

        group = {
            background = true,
            color = "161514",
            alpha = "FF",
            padding = 8,
            height = 38,
            radius = 5,

            border = true,
            border_color = "665344",
            border_alpha = "4F",
            border_width = 1,
        },
    },

    R_bottom_osc = {
        button = {
            height = 32,
            padding = 6,
            radius = 4,
        },

        group = {
            background = true,
            color = "161514",
            alpha = "FF",
            padding = 8,
            height = 38,
            radius = 5,

            border = true,
            border_color = "665344",
            border_alpha = "4F",
            border_width = 1,
        },
    },
}

----------------------------------------------------------
-- SLOT APPEARANCE
----------------------------------------------------------

M.osc_slot_overrides = {
    -- Copper glyph, not a permanently filled Play button.
    osc_C2 = {
        icon_size = 34,
        icon_color = "D8A27C",

        button_height = 44,
        button_padding = 8,
        button_radius = 6,

        hover_icon_color = "F0C6A5",
        hover_bg_color = "4A382C",
        hover_bg_alpha = "FF",
    },

    -- Quieter occasional controls.
    osc_L1 = {
        icon_size = 20,
        icon_color = "91867A",
    },

    osc_R1 = {
        icon_size = 20,
        icon_color = "91867A",
    },

    -- Prominent source launchers.
    osc_L1_bottom_osc = {
        icon_color = "D8B394",
    },

    osc_L2_bottom_osc = {
        icon_color = "D8B394",
    },

    osc_L3_bottom_osc = {
        icon_color = "D8B394",
    },

    osc_R2_bottom_osc = {
        icon_color = "D8B394",
    },
}

-- Shared hover treatment, preserving Play's distinct colors.
for _, slot in ipairs({
    "osc_L1",
    "osc_C1",
    "osc_C3",
    "osc_R1",
    "osc_L1_bottom_osc",
    "osc_L2_bottom_osc",
    "osc_L3_bottom_osc",
    "osc_R1_bottom_osc",
    "osc_R2_bottom_osc",
}) do
    local override = M.osc_slot_overrides[slot] or {}

    override.hover_icon_color = "F3EAE0"
    override.hover_bg_color = "40362E"
    override.hover_bg_alpha = "FF"

    M.osc_slot_overrides[slot] = override
end

----------------------------------------------------------
-- WARM PREVIEW CARDS
----------------------------------------------------------

M.chapter_tooltip_bg_color = "191715"
M.chapter_tooltip_text_color = "E5DFD7"
M.chapter_tooltip_radius = 5

-- Seekbar time-tooltip text, background, and radius inherit
-- the chapter-tooltip settings through documented fallbacks.

M.inset_bottom_pl = 160

return M