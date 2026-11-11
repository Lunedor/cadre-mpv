local M = {}

M.theme_name = "WMGray"
M.theme_author = "Lunedor"

-- Shared appearance
M.font_size = 14
M.text_color = "151515"
M.surface_color = "ECECEC"
M.alpha_panel_bg = "FF"
M.accent_color = "808080"
M.font_icon = "Material Icons"

-- OSC geometry
M.height_panel_osc = 88
M.inset_left_button_osc = 12
M.inset_right_button_osc = 12
M.offset_center_osc = 30

M.osc_layout = {
    button_row = {
        anchor = "center",
        offset = -8,
    },
    seekbar = {
        anchor = "panel_top",
        panel_inset = 10,
    },
}

-- Seekbar
M.inset_side_seekbar_osc = 12
M.height_normal_seekbar = 3
M.height_hover_seekbar = 3
M.radius_seekbar_osc = 0
M.color_track_bg_osc = "FFFFFF"
M.color_border_seekbar_osc = "A0A0A0"
M.alpha_border_seekbar_osc = "FF"
M.width_border_seekbar_osc = 1

-- Seekbar thumb
M.height_thumb_seekbar_osc = 5
M.radius_thumb_seekbar_osc = 0
M.color_thumb_seekbar_osc = "E6E6E6"
M.color_border_thumb_osc = "707070"
M.alpha_border_thumb_osc = "FF"

-- Title and time
M.width_time_item_osc = 140
M.width_title_item_osc = 420
M.align_title_osc = "left"
M.size_font_title_osc = 16

-- Compact transport controls
M.icon_size = 18
M.icon_spacing = 26

-- Volume slider
M.width_volume_slider_osc = 60
M.height_volume_slider_osc = 20
M.height_volume_slider_start_osc = 1
M.align_volume_slider_osc = "bottom"
M.width_thumb__volume_slider_osc = 2
M.height_thumb__volume_slider_osc = 10
M.radius_volume_slider_osc = 0
M.color_volume_slider_osc = "707070"
M.color_thumb_volume_slider_osc = "404040"
M.color_track_volume_slider_osc = "C0C0C0"

-- Main control row
M.osc_L1 = "play_only"
M.osc_L2 = "pause"
M.osc_L3 = "stop"
M.osc_L4 = "separator"
M.osc_L5 = "prev"
M.osc_L6 = "seekbar_back"
M.osc_L7 = "seekbar_forward"
M.osc_L8 = "next"
M.osc_R1 = "volume_slider"

-- Independent panel-centered metadata row
M.osc_L1_center_osc = "title"
M.osc_R1_center_osc = "time"

M.osc_slot_overrides = {
    osc_L1 = {
        button_background = true,
        button_color = "D6EBF7",
        button_alpha = "FF",
        button_height = 24,
        button_padding = 3,
        button_radius = 1,
        button_border = true,
        button_border_color = "8DB9D4",
        button_border_alpha = "FF",
        button_border_width = 1,
    },

    osc_L4 = {
        separator_color = "000000",
        separator_height = 24,
        separator_width = 1,
        separator_radius = 0,
    },

    osc_R1 = {
        icon_size = 24,
        hover_bg_color = "CDE8F8",
        hover_bg_alpha = "FF",
    },

    osc_L1_center_osc = {
        font_size = 16,
        text_color = "FFFFFF",
    },

    osc_R1_center_osc = {
        text_color = "FFFFFF",
    },
}

-- Apply documented per-slot hover fields to actionable buttons.
for _, slot in ipairs({
    "osc_L1",
    "osc_L2",
    "osc_L3",
    "osc_L5",
    "osc_L6",
    "osc_L7",
    "osc_L8",
}) do
    local override = M.osc_slot_overrides[slot] or {}

    override.hover_icon_color = "000000"
    override.hover_bg_color = "CDE8F8"
    override.hover_bg_alpha = "FF"

    M.osc_slot_overrides[slot] = override
end

-- Two half-width backgrounds form the black metadata strip.
-- Group width affects the background, not slot positions.
M.osc_group_overrides = {
    L_center_osc = {
        group = {
            background = true,
            color = "000000",
            alpha = "FF",
            width = "50%",
            height = 22,
            padding = 0,
            radius = 0,
        },
    },

    R_center_osc = {
        group = {
            background = true,
            color = "000000",
            alpha = "FF",
            width = "50%",
            height = 22,
            padding = 0,
            radius = 0,
        },
    },
}

M.color_bg_hover_tb = "000000"
M.alpha_bg_hover_tb = "5F"

return M