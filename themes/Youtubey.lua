local M = {}

M.theme_name = "Youtubey"
M.theme_author = "Lunedor"

-- Translucent charcoal panel.
M.surface_color_osc = "252629"
M.alpha_panel_bg_osc = "8F"
M.height_panel_osc = 88
M.radius_panel_osc = 16
M.anchor_y_panel_osc = "bottom"
M.inset_side_panel_osc = 8
M.inset_bottom_panel_osc = 8

-- Explicit vertical placement; no automatic seekbar clearance.
M.osc_layout = {
    button_row = { anchor = "center", offset = 14 },
    seekbar = { anchor = "panel_top", panel_inset = 20 },
}
M.inset_left_button_osc = 20
M.inset_right_button_osc = 20
M.inset_side_seekbar_osc = 20

-- Thin red timeline and circular handle.
M.enabled_seekbar_osc = true
M.color_track_fg_osc = "FF0038"
M.color_track_bg_osc = "58595B"
M.height_normal_seekbar = 4
M.height_hover_seekbar = 6
M.radius_seekbar_osc = 2
M.width_thumb_seekbar_osc = 12
M.height_thumb_seekbar_osc = 12
M.radius_thumb_seekbar_osc = 6
M.width_border_thumb_osc = 0
M.enabled_edge_labels_seekbar_osc = false
M.enabled_title_osc = false

-- Ordinary rows only; no center controls are assigned.
M.osc_L1 = "play"
M.osc_L2 = "volume"
M.osc_L3 = "time"
M.osc_R1 = "subtitle"
M.osc_R2 = "settings"
M.osc_R3 = "speed_control"
M.osc_R4 = "fullscreen"

M.color_icon_osc = "FFFFFF"
M.color_text_osc = "FFFFFF"
M.size_font_osc = 14
M.spacing_icon_osc = 48
M.width_time_item_osc = 112
M.enabled_outline_time_label_osc = false

M.osc_group_overrides = {
    L = {
        button = {
            background = true,
            color = "17191B",
            alpha = "AF",
            height = 40,
            padding = 8,
            radius = 20,
        },
    },
    R = {
        group = {
            background = true,
            color = "17181C",
            alpha = "AF",
            height = 40,
            padding = 10,
            radius = 20,
        },
    },
}

M.osc_slot_overrides = {
    osc_L1 = {
        spacing = 52,
        hover_bg_color = "414347",
        hover_bg_alpha = "CF",
        hover_radius = 20,
    },
    osc_L2 = {
        spacing = 84,
        hover_bg_color = "414347",
        hover_bg_alpha = "CF",
        hover_radius = 20,
    },
    osc_L3 = {
        font_size = 14,
        button_padding = 12,
    },
}

return M
