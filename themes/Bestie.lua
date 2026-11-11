local M = {}

M.theme_name = "Bestie"
M.theme_author = "Lunedor"

----------------------------------------------------------
-- SHARED DESIGN
----------------------------------------------------------

M.accent_color = "63B8FF"
M.text_color = "E8EDF5"
M.dim_color = "94A3B8"
M.surface_color = "10141C"
M.background_color = "0A0D13"

M.font_text = "Inter"
M.font_icon = "Material Icons Outlined"

----------------------------------------------------------
-- FLOATING BOTTOM PANEL
----------------------------------------------------------

M.height_panel_osc = 128
M.inset_bottom_panel_osc = 12
M.radius_panel_osc = 20

M.alpha_panel_bg_osc = "19"

----------------------------------------------------------
-- TIMELINE AND CONTROL ROW
----------------------------------------------------------

M.osc_layout = {
    button_row = {
        anchor = "center",
        offset = 11,
    },
    seekbar = {
        anchor = "panel_top",
        panel_inset = 12,
    },
}

----------------------------------------------------------
-- MEDIA TITLE
----------------------------------------------------------

M.enabled_title_osc = true
M.position_title_osc = "below_seekbar"
M.gap_title_seekbar_osc = 6

----------------------------------------------------------
-- GROUPED BACKGROUNDS
----------------------------------------------------------

M.enabled_bg_icon_group_osc = true
M.height_bg_icon_group_osc = 40
M.radius_bg_icon_group_osc = 12
M.alpha_bg_icon_group_osc = "A7"

----------------------------------------------------------
-- OSC SLOTS
----------------------------------------------------------

M.osc_L1 = "prev"
M.osc_L2 = "play"
M.osc_L3 = "next"
M.osc_L4 = "playlist"

M.osc_C1 = "speed_control_wheel"

M.osc_R1 = "volume_slider"
M.osc_R2 = "subtitle"
M.osc_R3 = "settings"
M.osc_R4 = "fullscreen"
M.osc_R5 = "pip"

----------------------------------------------------------
-- SEEKBAR
----------------------------------------------------------

M.height_normal_seekbar = 6
M.height_hover_seekbar = 10

M.color_track_fg_osc = "63B8FF"
M.color_track_bg_osc = "2B3547"
M.color_thumb_seekbar_osc = "DCEBFF"
M.position_time_label_osc = "inline"
M.enabled_time_tooltip_seekbar_osc = true
M.width_speed_control_wheel_osc = 210
M.size_font_osc = 21
----------------------------------------------------------
-- PLAYLIST / pl
----------------------------------------------------------

M.width_panel_pl = 420
M.radius_panel_pl = 20

M.alpha_panel_bg_pl = "CF"

M.color_text_pl = "E8EDF5"
M.color_dim_pl = "94A3B8"
M.color_icon_pl = "C7D2E2"

M.size_font_pl = 16
M.size_font_title_pl = 18
M.size_icon_pl = 18

M.height_row_pl = 42
M.gap_row_pl = 2
M.radius_row_pl = 8

M.color_hover_pl = "26334A"
M.alpha_hover_pl = "AF"

M.color_row_selected_pl = "63B8FF"
M.alpha_row_selected_pl = "B7"

M.color_row_current_pl = "63B8FF"
M.alpha_row_current_pl = "87"

M.height_toolbar_pl = 44
M.height_search_pl = 40

M.width_scrollbar_pl = 5
M.color_scroll_fg_pl = "5B6B84"
M.color_scroll_bg_pl = "161C27"

M.inset_top_pl = 48
M.inset_bottom_pl = 118
M.exclusion_bottom_osc_pl = 125

----------------------------------------------------------
-- TITLEBAR / tb
----------------------------------------------------------

M.height_panel_tb = 38
M.width_button_tb = 44
M.radius_button_tb = 8
M.radius_close_button_tb = 8

M.alpha_panel_bg_tb = "19"

M.color_text_tb = "E8EDF5"
M.size_font_title_tb = 15

M.color_bg_hover_tb = "26334A"
M.alpha_bg_hover_tb = "9F"

M.color_bg_button_pressed_tb = "1D2637"
M.alpha_bg_button_pressed_tb = "8F"

M.color_bg_close_tb = "EF4444"
M.alpha_bg_close_tb = "8F"

M.mode_show_titlebar_tb = "auto"
M.side_button_titlebar_tb = "right"
M.style_button_titlebar_tb = "symbols"

----------------------------------------------------------
-- CONTEXT MENU / mn
----------------------------------------------------------

M.width_menu_mn = 260
M.height_item_menu_mn = 34
M.pad_menu_mn = 8
M.radius_menu_mn = 12
M.max_visible_items_menu_mn = 14

M.alpha_panel_bg_mn = "ED"

M.color_text_mn = "E8EDF5"
M.color_dim_mn = "94A3B8"
M.size_font_mn = 15

M.color_selected_mn = "63B8FF"
M.alpha_selected_mn = "C7"

M.scrollbar_width_mn = 5
M.color_scroll_fg_mn = "5B6B84"
M.color_scroll_bg_mn = "161C27"
M.alpha_scroll_bg_mn = "9F"

return M