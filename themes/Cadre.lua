local M = {}

M.theme_name = "Cadre"
M.theme_author = "Lunedor"

----------------------------------------------------------
-- SHARED APPEARANCE
----------------------------------------------------------

M.font_icon = "Material Icons Round"
M.surface_color = "141414"
M.alpha_panel_bg = "97"
M.glass_blur = true

-- Blur radius retains the documented 12 px default.
-- Button tooltips retain the documented disabled default.

----------------------------------------------------------
-- FLOATING PANEL
----------------------------------------------------------

M.anchor_y_panel_osc = "bottom"
M.height_panel_osc = 64
M.radius_panel_osc = 14
M.inset_side_panel_osc = 24
M.inset_bottom_panel_osc = 24
M.max_width_panel_osc = 900
M.autohide_sec_panel_osc = 1

M.inset_left_button_osc = 16
M.inset_right_button_osc = 16
M.gap_button_group_osc = 0

M.osc_layout = {
    button_row = {
        anchor = "center",
        offset = 0,
    },
}

----------------------------------------------------------
-- SIZES
----------------------------------------------------------

M.size_icon_osc = 23
M.size_font_osc = 19
M.width_time_item_osc = 88

----------------------------------------------------------
-- SLOT-BASED SEEKBAR
----------------------------------------------------------

-- The seekbar lives only in osc_C1.
-- Do not also configure standalone seekbar placement.
M.color_track_fg_osc = "FFFFFF"
M.color_track_bg_osc = "3A3A3A"

M.height_normal_seekbar = 3
M.height_hover_seekbar = 8

M.height_thumb_seekbar_osc = 8
M.width_thumb_seekbar_osc = 3
M.radius_thumb_seekbar_osc = 2

M.enabled_edge_labels_seekbar_osc = false
M.inset_side_seekbar_osc = 8

----------------------------------------------------------
-- LEFT: TRANSPORT
----------------------------------------------------------

M.osc_L1 = "prev"
M.osc_L2 = "play"
M.osc_L3 = "stop"
M.osc_L4 = "next"

----------------------------------------------------------
-- CENTER: SEEKBAR AND TIME
----------------------------------------------------------

M.osc_C1 = "seekbar"
M.osc_C2 = "time"

----------------------------------------------------------
-- RIGHT: UTILITIES
----------------------------------------------------------

M.osc_R1 = "volume"
M.osc_R2 = "settings"
M.osc_R3 = "subtitle_list"
M.osc_R4 = "speed_control"
M.osc_R5 = "fullscreen"

M.gap_button_group_right_osc = 16

----------------------------------------------------------
-- ROUNDED HOVER SURFACES
----------------------------------------------------------

M.osc_group_overrides = {
    L = {
        button = {
            radius = 8,
        },
    },

    C = {
        button = {
            radius = 8,
        },
    },

    R = {
        button = {
            radius = 8,
        },
    },
}

M.osc_slot_overrides = {}

-- Time and seekbar slots do not support hover-background fields.
for _, slot in ipairs({
    "osc_L1",
    "osc_L2",
    "osc_L3",
    "osc_L4",
    "osc_R1",
    "osc_R2",
    "osc_R3",
    "osc_R4",
    "osc_R5",
}) do
    M.osc_slot_overrides[slot] = {
        hover_bg_color = "FFFFFF",
        hover_bg_alpha = "27",
        hover_radius = 8,
    }
end

----------------------------------------------------------
-- CHAPTERS AND SETTINGS DIALOG
----------------------------------------------------------

M.chapter_mark_width = 0.75
M.alpha_bg_settings_dialog_osc = "FF"

----------------------------------------------------------
-- PLAYLIST / pl
----------------------------------------------------------

M.width_panel_pl = 380
M.radius_panel_pl = 14

M.alpha_panel_bg_pl = "97"

M.color_dim_pl = "9A9A9A"
M.color_icon_pl = "D9D9D9"

M.size_font_pl = 16
M.size_font_title_pl = 18
M.size_icon_pl = 18

M.height_row_pl = 38
M.gap_row_pl = 2
M.radius_row_pl = 8

M.color_hover_pl = "2A2A2A"
M.alpha_hover_pl = "AF"

M.color_row_selected_pl = "FFFFFF"
M.alpha_row_selected_pl = "2F"

M.color_row_current_pl = "FFFFFF"
M.alpha_row_current_pl = "4F"

M.height_toolbar_pl = 40
M.height_search_pl = 38

M.width_scrollbar_pl = 4
M.color_scroll_fg_pl = "5A5A5A"
M.color_scroll_bg_pl = "1F1F1F"

M.inset_top_pl = 48
M.inset_bottom_pl = 100
M.exclusion_bottom_osc_pl = 100


----------------------------------------------------------
-- TITLEBAR / tb
----------------------------------------------------------

M.height_panel_tb = 36
M.width_button_tb = 42
M.radius_button_tb = 6
M.radius_close_button_tb = 6

M.alpha_panel_bg_tb = "97"

M.size_font_title_tb = 15

M.color_bg_hover_tb = "2A2A2A"
M.alpha_bg_hover_tb = "9F"

M.color_bg_button_pressed_tb = "222222"
M.alpha_bg_button_pressed_tb = "8F"

M.mode_show_titlebar_tb = "auto"
M.side_button_titlebar_tb = "right"
M.style_button_titlebar_tb = "symbols"


----------------------------------------------------------
-- CONTEXT MENU / mn
----------------------------------------------------------

M.width_menu_mn = 240
M.height_item_menu_mn = 32
M.pad_menu_mn = 8
M.radius_menu_mn = 10
M.max_visible_items_menu_mn = 12

M.alpha_panel_bg_mn = "CF"

M.color_dim_mn = "9A9A9A"
M.size_font_mn = 15

M.color_selected_mn = "FFFFFF"
M.alpha_selected_mn = "5F"

M.scrollbar_width_mn = 4
M.color_scroll_fg_mn = "5A5A5A"
M.color_scroll_bg_mn = "1F1F1F"
M.alpha_scroll_bg_mn = "9F"

M.show_panel_on_pause = false

return M