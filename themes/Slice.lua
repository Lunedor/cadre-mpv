local M = {}

M.theme_name = "Slice"
M.theme_author = "Lunedor"

-- Appearance
M.font_icon = "Material Icons"
M.accent_color = "F28C1E"
M.size_icon_osc = 18
M.color_icon_osc = "858585"
M.color_text_osc = "BDBDBD"

-- Centered single-row controller
M.height_panel_osc = 56
M.alpha_panel_bg_osc = "EF"
M.inset_left_button_osc = 16
M.inset_right_button_osc = 16

M.osc_layout = {
    button_row = {
        anchor = "center",
        offset = 0,
    },
}

-- Playback
M.osc_L1 = "prev"
M.osc_L2 = "play"
M.osc_L3 = "next"
M.width_time_item_osc = 130

-- Inline timeline
M.osc_C1 = "seekbar"
M.enabled_seekbar_osc = true
M.width_thumb_seekbar_osc = 3
M.height_thumb_seekbar_osc = 8
M.radius_thumb_seekbar_osc = 2

-- Volume and utilities
M.osc_R1 = "volume_slider"
M.osc_R2 = "audio_list"
M.osc_R3 = "subtitle_list"
M.osc_R4 = "speed_control"
M.osc_R5 = "settings"
M.osc_R6 = "playlist"

M.color_volume_slider_osc = "FFC639"
M.color_end_volume_slider_osc = "A4C639"
M.color_track_volume_slider_osc = "2A2A2A"
M.width_volume_slider_osc = 80
M.height_volume_slider_start_osc = 9
M.height_volume_slider_osc = 14
M.pad_right_volume_slider_osc = 15

-- Quiet rounded hover tiles
M.enabled_border_hover_osc = false
M.osc_slot_overrides = {}

for _, slot in ipairs({
    "osc_L1", "osc_L3",
    "osc_R2", "osc_R3", "osc_R4", "osc_R5", "osc_R6",
}) do
    M.osc_slot_overrides[slot] = {
        button_height = 30,
        button_padding = 6,
        hover_icon_color = "BDBDBD",
        hover_bg_color = "292929",
        hover_bg_alpha = "FF",
        hover_radius = 5,
        hover_scale = 1,
    }
end

-- Primary playback action
M.osc_slot_overrides.osc_L2 = {
    icon_size = 24,
    icon_color = "000000",
    button_background = true,
    button_color = M.accent_color,
    button_alpha = "FF",
    button_height = 28,
    button_padding = 11,
    button_radius = 5,
    hover_icon_color = "171717",
    hover_bg_color = "FFA040",
    hover_bg_alpha = "FF",
    hover_scale = 1,
    hover_border = false,
    hover_radius = 5,
}

M.alpha_icon_dim_osc = "FF"

-- Compact tooltips; positioning comes from your corrected OSC code
M.chapter_tooltip_size = 18
M.chapter_tooltip_pad_x = 6
M.chapter_tooltip_pad_y = 4
M.chapter_tooltip_radius = 2
M.chapter_tooltip_bg_color = "202020"
M.chapter_tooltip_text_color = "D0D0D0"

M.autohide_sec_panel_osc = 1

M.position_time_label_osc = "inline"
M.gap_time_label_inline_osc = -25

return M