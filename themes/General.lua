local M = {}

-- Shared identity
M.surface_color = "141414"
M.background_color = "101010"
M.text_color = "F2EFE8"
M.dim_color = "A39F97"
M.accent_color = "E85D3F"
M.alpha_panel_bg = "F7"
M.panel_radius = 12

-- Compact deck
M.height_panel_osc = 88
M.inset_side_panel_osc = 16
M.inset_bottom_panel_osc = 16
M.max_width_panel_osc = 1440
M.spacing_icon_osc = 44
M.gap_button_group_osc = 24
M.enabled_title_osc = false

M.osc_layout = {
    button_row = { anchor = "center", offset = 10 },
    seekbar = { anchor = "panel_top", panel_inset = 14 },
}

-- Playback / sources / viewing tools
M.osc_L1 = "prev"
M.osc_L2 = "play"
M.osc_L3 = "next"
M.osc_L4 = "time"
M.width_time_item_osc = 124

M.osc_C1 = "stream"
M.osc_C2 = "youtube"
M.osc_C3 = "music_mode"

M.osc_R1 = "volume_slider"
M.osc_R2 = "subtitle_list"
M.osc_R3 = "audio_list"
M.osc_R4 = "playlist"
M.osc_R5 = "fullscreen"

-- Fine timeline with controlled hover thickness
M.enabled_seekbar_osc = true
M.height_normal_seekbar = 3
M.height_hover_seekbar = 6
M.height_thumb_seekbar_osc = 8
M.color_track_bg_osc = "363636"
M.enabled_time_tooltip_seekbar_osc = true

-- Integrated volume
M.width_volume_slider_osc = 88
M.height_volume_slider_osc = 4
M.enabled_mute_volume_slider_osc = true
M.color_volume_slider_osc = M.text_color
M.color_track_volume_slider_osc = M.color_track_bg_osc
M.color_slider_rail_osc = M.color_track_bg_osc

-- Uses your corrected tooltip placement
M.enabled_button_tooltip_osc = true
M.chapter_tooltip_size = 14
M.chapter_tooltip_pad_y = 7

-- Quiet hover surfaces; no permanent button boxes
M.enabled_border_hover_osc = false
M.osc_slot_overrides = {}

for _, slot in ipairs({
    "osc_L1", "osc_L2", "osc_L3",
    "osc_C1", "osc_C2", "osc_C3",
    "osc_R2", "osc_R3", "osc_R4", "osc_R5",
}) do
    M.osc_slot_overrides[slot] = {
        button_height = 40,
        hover_icon_color = M.accent_color,
        hover_bg_color = "292929",
        hover_bg_alpha = "FF",
        hover_radius = 8,
    }
end

M.osc_slot_overrides.osc_L2.icon_size = 30
M.osc_slot_overrides.osc_L2.icon_color = M.accent_color
M.osc_slot_overrides.osc_L3.spacing = 68
M.osc_slot_overrides.osc_L4 = {
    font_size = 15,
    text_color = M.dim_color,
}

-- Playlist ends 16 px above the deck
M.width_panel_pl = 360
M.inset_bottom_pl = 120
M.exclusion_bottom_osc_pl = 120
M.height_header_pl = 54
M.size_font_title_pl = 19
M.height_row_pl = 48
M.gap_row_pl = 4
M.radius_row_pl = 8
M.alpha_row_current_pl = "4F"
M.alpha_row_selected_pl = "67"
M.alpha_index_pl = "9F"
M.color_duration_pl = M.dim_color
M.color_hover_pl = "292929"
M.color_scroll_bg_pl = M.surface_color
M.color_scroll_fg_pl = "68645F"

-- Neutralize independent cool-color fallbacks
M.color_bg_hover_tb = M.color_hover_pl
M.color_scroll_bg_mn = M.surface_color
M.height_item_menu_mn = 38

return M