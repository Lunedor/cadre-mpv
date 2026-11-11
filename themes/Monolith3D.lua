-- Monolith — Cadre Player
-- Replace the previous theme module completely.
-- Simulated depth through gradients, edge lighting and icon shadows.
-- Static inspection only; not runtime-tested.

local M = {}

local P = {
    surface = "10151D",
    raised  = "273241",
    recess  = "121922",
    edge    = "64778D",
    text    = "E9EFF7",
    dim     = "9AAABC",
    accent  = "79CFFF",
    shadow  = "000000",
}

-- Shared appearance ----------------------------------------------------------
-- Shared keys follow the component fallback chains documented in the reference.

M.surface_color = P.surface
M.text_color = P.text
M.dim_color = P.dim
M.accent_color = P.accent

M.border_all_color = P.edge
M.border_all_alpha = "6F"
M.border_all_width = 1

M.alpha_panel_bg = "EF"

-- OSC surface ----------------------------------------------------------------

M.surface_color_osc = P.surface
M.alpha_panel_bg_osc = "E7"
M.height_panel_osc = 116
M.max_width_panel_osc = 1060

M.color_border_panel_osc = P.edge
M.width_border_panel_osc = 1

M.size_icon_osc = 22
M.spacing_icon_osc = 44

-- Independent seekbar --------------------------------------------------------

M.position_seekbar_osc = "above_buttons"
M.height_normal_seekbar = 4
M.height_hover_seekbar = 7
M.height_thumb_seekbar_osc = 10

-- Floating title: no window-top title slot.
M.enabled_title_osc = true
M.position_title_osc = "above_seekbar"
M.align_title_osc = "left"
M.size_font_title_osc = 18
M.enabled_time_tooltip_seekbar_osc = true
M.chapter_tooltip_offset_y = 5

-- Do not add osc_L1_top = "title".
-- That would place an additional title at the top of the window.

-- OSC contents ---------------------------------------------------------------
-- Every base slot is assigned deliberately.
-- volume_slider is the only volume-related slot.

M.osc_L1 = "time"
M.osc_L2 = "playlist"
M.osc_L3 = "subtitle_list"
M.osc_L4 = "audio_list"

M.osc_C1 = "prev"
M.osc_C2 = "play"
M.osc_C3 = "next"

M.osc_R1 = "volume_slider"
M.osc_R2 = "settings"
M.osc_R3 = "info"
M.osc_R4 = "screenshot"
M.osc_R5 = "fullscreen"

M.width_time_item_osc = 132
M.width_volume_slider_osc = 110

-- Row decoration -------------------------------------------------------------
-- The reference supports icon, button and group subtables.
-- Hover decoration belongs in osc_slot_overrides, not this button table.

M.osc_group_overrides = {
    L = {
        button = {
            height = 34,
            padding = 6,
            radius = 8,
            background = false,
            border = false,
        },
    },

    C = {
        icon = {
            shadow = true,
            shadow_color = P.shadow,
            shadow_alpha = "B7",
            shadow_x = 0,
            shadow_y = 1,
            shadow_blur = 1,
        },

        button = {
            background = true,

            -- Lighter upper face fading into a darker lower face.
            color = P.raised,
            gradient_color = P.recess,
            gradient_type = "top_to_bottom",
            alpha = "FF",

            height = 40,
            padding = 10,
            radius = 10,

            border = true,
            border_color = P.edge,
            border_alpha = "87",
            border_width = 1,
        },

        group = {
            background = true,
            color = "0A0F16",
            alpha = "EF",
            padding = 10,
            height = 54,
            radius = 16,

            border = true,
            border_color = "334254",
            border_alpha = "8F",
            border_width = 1,
        },
    },

    R = {
        button = {
            height = 34,
            padding = 6,
            radius = 8,
            background = false,
            border = false,
        },
    },
}

-- Exact-slot appearance ------------------------------------------------------
-- Keys are slot names, NOT action names such as "play" or "time".

M.osc_slot_overrides = {
    osc_L1 = {
        font_size = 18,
        text_color = P.text,
        spacing = 88,
        button_background = false,
    },

    osc_L2 = {
        icon_size = 20,
        icon_color = P.dim,
        spacing = 42,
        hover_icon_color = P.text,
        hover_scale = 1.05,
    },

    osc_L3 = {
        icon_size = 20,
        icon_color = P.dim,
        spacing = 42,
        hover_icon_color = P.text,
        hover_scale = 1.05,
    },

    osc_L4 = {
        icon_size = 20,
        icon_color = P.dim,
        hover_icon_color = P.text,
        hover_scale = 1.05,
    },

    osc_C1 = {
        icon_size = 22,
        icon_color = P.text,
        spacing = 52,

        hover_icon_color = P.accent,
        hover_border = true,
        hover_border_color = P.accent,
        hover_border_alpha = "9F",
        hover_border_width = 1,
        hover_radius = 10,
        hover_scale = 1.04,
    },

    osc_C2 = {
        icon_size = 24,
        icon_color = P.accent,
        spacing = 52,

        button_height = 44,
        button_padding = 10,
        button_radius = 12,

        button_background = true,
        button_color = "36516A",
        button_gradient_color = "182A3B",
        button_gradient_type = "top_to_bottom",
        button_alpha = "FF",

        button_border = true,
        button_border_color = P.accent,
        button_border_alpha = "8F",
        button_border_width = 1,

        hover_icon_color = "FFFFFF",
        hover_border = true,
        hover_border_color = P.accent,
        hover_border_alpha = "DF",
        hover_border_width = 1,
        hover_radius = 12,
        hover_scale = 1.04,
    },

    osc_C3 = {
        icon_size = 22,
        icon_color = P.text,

        hover_icon_color = P.accent,
        hover_border = true,
        hover_border_color = P.accent,
        hover_border_alpha = "9F",
        hover_border_width = 1,
        hover_radius = 10,
        hover_scale = 1.04,
    },

    osc_R1 = {
        spacing = 84,
        button_background = false,
    },

    osc_R2 = {
        icon_size = 20,
        icon_color = P.dim,
        spacing = 42,
        hover_icon_color = P.text,
        hover_scale = 1.05,
    },

    osc_R3 = {
        icon_size = 20,
        icon_color = P.dim,
        spacing = 42,
        hover_icon_color = P.text,
        hover_scale = 1.05,
    },

    osc_R4 = {
        icon_size = 20,
        icon_color = P.dim,
        spacing = 42,
        hover_icon_color = P.text,
        hover_scale = 1.05,
    },

    osc_R5 = {
        icon_size = 20,
        icon_color = P.dim,
        hover_icon_color = P.text,
        hover_scale = 1.05,
    },
}

-- Playlist -------------------------------------------------------------------
-- Fixed right-side panel; no responsive width behavior is assumed.

M.width_panel_pl = 360
M.inset_side_pl = 20
M.inset_top_pl = 56

M.inset_left_list_pl = 10
M.inset_right_list_pl = 10
M.pad_x_row_pl = 14

M.alpha_bg_frame_pl = "F7"
M.alpha_bg_list_pl = "EF"
M.alpha_bg_row_pl = "D7"

M.alpha_border_panel_pl = "6F"
M.width_border_panel_pl = 1
M.width_scrollbar_pl = 3

-- Titlebar -------------------------------------------------------------------
-- Thin visible edge and restrained hover feedback.
-- Normal titlebar-button backgrounds are not assumed to be drawn.

M.surface_color_tb = "0C1118"
M.size_font_title_tb = 14
M.width_button_tb = 42

M.alpha_bg_hover_tb = "B7"
M.alpha_bg_button_pressed_tb = "E7"
M.alpha_bg_close_tb = "BF"

M.alpha_border_panel_tb = "5F"
M.width_border_panel_tb = 1

-- Menu -----------------------------------------------------------------------
-- Explicit menu colors rather than relying on OSC-only styling.

M.surface_color_mn = "151D28"
M.color_text_mn = P.text
M.color_dim_mn = P.dim
M.color_selected_mn = "365B78"

M.alpha_panel_bg_mn = "F7"
M.alpha_selected_mn = "DF"

M.size_font_mn = 14
M.height_item_menu_mn = 36
M.pad_menu_mn = 10
M.width_menu_mn = 280
M.max_visible_items_menu_mn = 12



return M