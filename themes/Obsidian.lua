-- Cadre: Paper & Teal
-- Standalone theme module; documented settings only.
-- Layout target: 960+ logical units wide; no responsive reflow assumed.
-- Panel: H-92 .. H-16. Row center: H-46; seekbar: H-80.
-- Unspecified slots retain the loader's behavior; no undocumented empty ID.
local M = {}

-- Shared palette: inherited by panels, dialogs, menus and playlist.
M.background_color = "181A19"
M.surface_color = "222523"
M.text_color = "EEEDE6"
M.dim_color = "A6ADA7"
M.accent_color = "70B9AE"
M.alpha_panel_bg = "FF"
M.panel_radius = 12
M.border_all_color = "393F3B"
M.border_all_alpha = "FF"
M.border_all_width = 1

-- Compact playback deck.
M.height_panel_osc = 76
M.inset_bottom_panel_osc = 16
M.inset_side_panel_osc = 16
M.inset_left_button_osc = 40
M.inset_right_button_osc = 40
M.inset_side_seekbar_osc = 40
M.enabled_title_osc = false
M.enabled_seekbar_osc = true
M.enabled_border_hover_osc = false
M.osc_layout = {
    button_row = { anchor = "center", offset = 8 },
    seekbar = { anchor = "panel_top", panel_inset = 12 },
}
M.height_normal_seekbar = 3
M.height_hover_seekbar = 5
M.height_thumb_seekbar_osc = 8
M.radius_thumb_seekbar_osc = 4
M.radius_seekbar_osc = 2
M.color_track_bg_osc = "393F3B"
M.width_border_seekbar_osc = 0
M.width_border_thumb_osc = 0
M.enabled_time_tooltip_seekbar_osc = true
M.chapter_tooltip_text_color = M.text_color

M.osc_L1 = "play"
M.osc_L2 = "prev"
M.osc_L3 = "next"
M.osc_L4 = "time"
M.osc_C1 = "speed_control_wheel"
M.osc_R1 = "audio_list"
M.osc_R2 = "subtitle_list"
M.osc_R3 = "volume"
M.osc_R4 = "playlist"
M.osc_R5 = "fullscreen"
M.width_speed_control_wheel_osc = 160
M.gap_button_group_osc = 24
M.radius_bg_icon_osc = 7

-- Shared slot decoration rather than repeated per-button values.
local hover = {
    hover_icon_color = M.accent_color,
    hover_bg_color = "303833",
    hover_bg_alpha = "FF",
    hover_scale = 1,
    hover_border = false,
}
M.osc_slot_overrides = {
    osc_L1 = hover, osc_L2 = hover, osc_L3 = hover,
    osc_R1 = hover, osc_R2 = hover, osc_R3 = hover,
    osc_R4 = hover, osc_R5 = hover,
    osc_C1 = {
        button_background = true,
        button_color = "303833",
        button_alpha = "FF",
        button_height = 32,
        button_radius = 7,
        button_border = true,
        button_border_color = M.border_all_color,
        button_border_alpha = "FF",
        button_border_width = 1,
        icon_color = M.accent_color,
        hover_icon_color = M.accent_color,
        hover_bg_color = "303833",
        hover_bg_alpha = "FF",
        hover_scale = 1,
        hover_border = false,
    },
}
M.color_slider_rail_osc = M.border_all_color
M.color_track_volume_slider_osc = M.border_all_color
M.color_volume_slider_osc = M.accent_color
M.height_volume_slider_osc = 4
M.radius_volume_slider_osc = 2

-- Playlist clears the deck by 12 units; titlebar clearance is explicit.
M.width_panel_pl = 360
M.inset_bottom_pl = 104
M.exclusion_bottom_osc_pl = 104
M.color_hover_pl = "303833"
M.alpha_hover_pl = "FF"
M.alpha_row_current_pl = "2F"
M.alpha_row_selected_pl = "3F"
M.color_scroll_bg_pl = M.border_all_color
M.color_scroll_fg_pl = M.dim_color

-- Titlebar uses the darker base; hover/pressed inherit one shared tone.
M.surface_color_tb = M.background_color
M.color_bg_hover_tb = M.color_hover_pl
M.size_font_title_tb = 15

-- Menus and shared Add-media popups use quiet, readable highlights.
M.alpha_selected_mn = "2F"
M.color_scroll_bg_mn = M.border_all_color
M.popup_hover_color = M.color_hover_pl
M.alpha_popup_hover = "FF"

return M
