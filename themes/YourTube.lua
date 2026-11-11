local M = {}

M.theme_name = "YourTube"
M.theme_author = "Lunedor"

----------------------------------------------------------
-- SHARED IDENTITY
----------------------------------------------------------

M.font_icon_osc = "Material Icons"
M.text_color = "FFFFFF"
M.surface_color = "0F0F0F"
M.accent_color = "FF0000"
M.font_size = 15

----------------------------------------------------------
-- OSC PANEL
----------------------------------------------------------

M.anchor_y_panel_osc = "bottom"
M.height_panel_osc = 104
M.alpha_panel_bg_osc = "D7"

-- Panel side inset, bottom inset, and radius retain
-- their documented zero defaults.
-- OSC surface inherits the shared surface color.
-- Autohide retains the documented 0.4-second fallback.

M.inset_left_button_osc = 18
M.inset_right_button_osc = 18

M.osc_layout = {
    button_row = {
        anchor = "center",
        offset = 7,
    },
    seekbar = {
        anchor = "panel_top",
        panel_inset = 18,
    },
}

----------------------------------------------------------
-- LEFT: PLAYBACK, VOLUME, AND TIME
----------------------------------------------------------

M.osc_L1 = "play"
M.osc_L2 = "next"
M.osc_L3 = "volume_slider"
M.osc_L4 = "time"

----------------------------------------------------------
-- RIGHT: CAPTIONS AND PLAYER UTILITIES
----------------------------------------------------------

M.osc_R1 = "subtitle"
M.osc_R2 = "settings"
M.osc_R3 = "speed_control"
M.osc_R4 = "fullscreen"
M.osc_R5 = "playlist"

----------------------------------------------------------
-- CLEAN ICONS
----------------------------------------------------------

M.icon_spacing = 34
M.alpha_icon_dim_osc = "AA"

-- Icon size retains the documented 24 px default.
-- Icons inherit the shared white text color.
-- Individual and group backgrounds remain disabled by default.

----------------------------------------------------------
-- RED TIMELINE
----------------------------------------------------------

M.inset_side_seekbar_osc = 18
M.height_normal_seekbar = 4
M.height_hover_seekbar = 8
M.mode_resize_hover_seekbar_osc = "segment"
M.color_track_bg_osc = "3D3D3D"

-- Progress inherits the shared red accent.
-- Seekbar border width retains the documented zero default.

----------------------------------------------------------
-- WHITE PLAYHEAD
----------------------------------------------------------

M.width_thumb = 6
M.height_thumb = 6
M.radius_thumb = 6
M.thumb_color = "FFFFFF"
M.width_border_thumb_osc = 0

----------------------------------------------------------
-- TIME DISPLAY
----------------------------------------------------------

M.size_font_osc = 14
M.width_time_item_osc = 132

-- The time slot replaces standalone elapsed/duration labels.
-- Standalone inline-label placement and gap settings are omitted.
-- Time text inherits the shared white text color.

----------------------------------------------------------
-- VOLUME SLIDER
----------------------------------------------------------

M.width_volume_slider_osc = 96
M.height_volume_slider_osc = 4
M.radius_volume_slider_osc = 2
M.color_track_volume_slider_osc = "3D3D3D"

M.width_thumb_volume_slider_osc = 6
M.height_thumb_volume_slider_osc = 6
M.pad_left_volume_slider_osc = 12

-- Volume fill retains the documented white default.

----------------------------------------------------------
-- CHAPTER MARKERS
----------------------------------------------------------

M.color_chapter_mark = "0F0F0F"
M.chapter_hover_px = 10

-- Chapter marker width retains the documented 2 px default.
-- Marker transparency retains the invisible "FF" default.

return M