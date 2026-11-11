local M = {}

-- FRAME / shared identity
M.surface_color = "151714"
M.background_color = "10120F"
M.text_color = "EDF0E8"
M.dim_color = "9CA396"
M.accent_color = "C8F542"
M.alpha_panel_bg = "FF"
M.panel_radius = 10

-- Deck
M.height_panel_osc = 120
M.inset_side_panel_osc = 24
M.inset_bottom_panel_osc = 20
M.radius_panel_osc = 12
M.alpha_panel_bg_osc = "FF"

M.color_border_panel_osc = "32372D"
M.alpha_border_panel_osc = "9F"
M.width_border_panel_osc = 1

-- Individual placement retains automatic seekbar clearance.
M.anchor_y_button_osc = "center"
M.position_seekbar_osc = "above_buttons"
M.gap_button_seekbar_osc = 18

M.inset_left_button_osc = 48
M.inset_right_button_osc = 48
M.inset_side_seekbar_osc = 48

M.width_button_group_left_osc = 320
M.width_button_group_right_osc = 232

M.size_icon_osc = 22
M.spacing_icon_osc = 40
M.size_font_osc = 14

-- No duplicate floating title or time slot.
M.enabled_title_osc = false

-- Timeline / information band
M.enabled_seekbar_osc = true
M.enabled_edge_labels_seekbar_osc = true
M.position_time_label_osc = "inline"
M.gap_time_label_inline_osc = 12

M.height_normal_seekbar = 4
M.height_hover_seekbar = 6
M.radius_seekbar_osc = 1
M.color_track_bg_osc = "343A2E"

M.width_thumb_seekbar_osc = 3
M.height_thumb_seekbar_osc = 10
M.radius_thumb_seekbar_osc = 1

M.enabled_time_tooltip_seekbar_osc = true
M.enabled_chapter_tooltip_osc = true
M.alpha_chapter_mark = "AF"
M.color_chapter_mark = "10120F"

-- Playback group
M.osc_L1 = "play"
M.osc_L2 = "prev"
M.osc_L3 = "next"
M.osc_L4 = "volume_slider"

-- Media tools
M.osc_R1 = "subtitle_list"
M.osc_R2 = "audio_list"
M.osc_R3 = "playlist"
M.osc_R4 = "settings"
M.osc_R5 = "fullscreen"

-- Volume / compact neutral instrument
M.width_volume_slider_osc = 88
M.height_volume_slider_osc = 4
M.height_volume_slider_start_osc = 4
M.radius_volume_slider_osc = 1

M.enabled_mute_volume_slider_osc = true
M.width_mute_volume_slider_osc = 22
M.gap_mute_volume_slider_osc = 12

M.color_volume_slider_osc = "BBC4B0"
M.color_track_volume_slider_osc = "343A2E"
M.color_slider_rail_osc = "343A2E"

M.enabled_thumb_volume_slider_osc = true
M.width_thumb_volume_slider_osc = 3
M.height_thumb_volume_slider_osc = 8
M.color_thumb_volume_slider_osc = "EDF0E8"

-- A shared vocabulary for secondary controls.
local function utility(spacing)
    return {
        spacing = spacing,
        hover_icon_color = "EDF0E8",
        hover_bg_color = "303729",
        hover_bg_alpha = "FF",
        hover_radius = 6,
        hover_border = false,
    }
end

M.osc_slot_overrides = {
    -- 28 px icon + 10 px padding per side = 48 px surface.
    osc_L1 = {
        icon_size = 28,
        icon_color = "11150A",
        spacing = 64,

        button_background = true,
        button_color = "C8F542",
        button_alpha = "FF",
        button_height = 48,
        button_padding = 10,
        button_radius = 10,

        hover_icon_color = "11150A",
        hover_bg_color = "DCFF7A",
        hover_bg_alpha = "FF",
        hover_radius = 10,
        hover_border = false,
    },

    osc_L2 = utility(40),

    -- Larger transition between transport and volume.
    osc_L3 = utility(100),

    -- No following left-group item: no arbitrary spacing override.
    osc_L4 = {
        hover_bg_color = "23281E",
        hover_bg_alpha = "FF",
        hover_radius = 6,
        hover_border = false,
    },

    osc_R1 = utility(40),
    osc_R2 = utility(40),
    osc_R3 = utility(40),

    -- Fullscreen is separated from media configuration.
    osc_R4 = utility(56),
    osc_R5 = utility(40),
}

-- Opaque elevated overlays
M.color_bg_settings_dialog_osc = "1C2019"
M.color_bg_track_popup_osc = "1C2019"
M.color_bg_volume_popup_osc = "1C2019"
M.color_bg_add_popup_osc = "1C2019"

M.alpha_bg_settings_dialog_osc = "FF"
M.alpha_bg_track_popup_osc = "FF"
M.alpha_bg_volume_popup_osc = "FF"
M.alpha_bg_add_popup_osc = "FF"

M.color_border_settings_dialog_osc = "394130"
M.alpha_border_settings_dialog_osc = "BF"
M.radius_settings_dialog_osc = 12

M.radius_track_popup_osc = 10
M.radius_volume_popup_osc = 10
M.radius_add_popup_osc = 10

M.color_bg_time_tooltip_seekbar_osc = "1C2019"
M.alpha_bg_time_tooltip_seekbar_osc = "FF"
M.radius_time_tooltip_seekbar_osc = 6
M.size_font_time_tooltip_seekbar_osc = 14

M.chapter_tooltip_bg_color = "1C2019"
M.chapter_tooltip_radius = 6
M.chapter_tooltip_size = 14

M.popup_hover_color = "39452A"
M.alpha_popup_hover = "FF"

-- Playlist / subdued lime selection, neutral hover
M.surface_color_pl = "1C2019"
M.color_hover_pl = "303729"
M.alpha_hover_pl = "FF"

M.alpha_row_current_pl = "2F"
M.alpha_row_selected_pl = "27"

M.color_scroll_bg_pl = "303729"
M.color_scroll_fg_pl = "879573"

M.radius_panel_pl = 12
M.radius_row_pl = 6
M.inset_bottom_pl = 152

-- Titlebar / neutral hover, without blue-gray fallbacks
M.color_bg_hover_tb = "303729"
M.color_bg_button_pressed_tb = "3C4533"
M.alpha_bg_hover_tb = "FF"
M.alpha_bg_button_pressed_tb = "FF"
M.size_font_title_tb = 15

-- Menu / opaque, quiet selection surface
M.surface_color_mn = "1C2019"
M.color_selected_mn = "39452A"
M.alpha_selected_mn = "FF"
M.color_scroll_bg_mn = "303729"
M.color_scroll_fg_mn = "879573"
M.radius_menu_mn = 10

return M