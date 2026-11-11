local M = {}

M.theme_name = "Netflixy"
M.theme_author = "Lunedor"

----------------------------------------------------------
-- SHARED IDENTITY
----------------------------------------------------------

M.text_color = "FFFFFF"
M.surface_color = "141414"
M.accent_color = "E50914"
M.font_size = 15

----------------------------------------------------------
-- OSC PANEL
----------------------------------------------------------

M.anchor_y_panel_osc = "bottom"
M.alpha_panel_bg_osc = "00"
M.autohide_sec_panel_osc = 0.45

-- Retain documented defaults:
--   height_panel_osc = 100
--   inset_side_panel_osc = 0
--   inset_bottom_panel_osc = 0
--   radius_panel_osc = 0
--
-- surface_color_osc inherits surface_color.

M.inset_left_button_osc = 22
M.inset_right_button_osc = 22

M.osc_layout = {
    button_row = {
        anchor = "center",
        offset = 12,
    },
    seekbar = {
        anchor = "panel_top",
        panel_inset = 14,
    },
}

----------------------------------------------------------
-- CONTROL ROW
----------------------------------------------------------

M.osc_L1 = "play"
M.osc_L2 = "seekbar_back"
M.osc_L3 = "seekbar_forward"
M.osc_L4 = "volume"

M.osc_C1 = "title"

M.osc_R1 = "next"
M.osc_R2 = "settings"
M.osc_R3 = "subtitle"
M.osc_R4 = "fullscreen"

M.icon_size = 25
M.alpha_icon_dim_osc = "AA"
M.enabled_outline_icon_osc = true

-- Icon spacing retains the documented 36 px default.
-- Icons inherit the shared white text color.
-- Individual and group backgrounds remain disabled by default.

----------------------------------------------------------
-- CENTERED MEDIA TITLE
----------------------------------------------------------

M.width_title_item_osc = 600
M.enabled_shadow_title_osc = true
M.alpha_shadow_title_osc = "AA"

-- Title-shadow offsets retain their documented 1 px defaults.
-- Title-shadow color retains its documented black default.
-- The title slot replaces floating-title placement.

M.osc_slot_overrides = {
    osc_C1 = {
        font_size = 17,
    },
}

----------------------------------------------------------
-- RED CINEMATIC SEEKBAR
----------------------------------------------------------

M.inset_side_seekbar_osc = 22
M.height_normal_seekbar = 4
M.height_hover_seekbar = 8
M.mode_resize_hover_seekbar_osc = "segment"
M.color_track_bg_osc = "4D4D4D"

-- Progress inherits the red accent.
-- Seekbar border width retains its documented zero default.

----------------------------------------------------------
-- CHAPTER MARKERS
----------------------------------------------------------

M.color_chapter_mark = "141414"
M.alpha_chapter_mark = "BA"
M.chapter_hover_px = 10

-- Marker width retains the documented 2 px default.

----------------------------------------------------------
-- SEEKBAR THUMB
----------------------------------------------------------

M.width_thumb_seekbar_osc = 6
M.height_thumb_seekbar_osc = 6
M.radius_thumb_seekbar_osc = 6
M.color_thumb_seekbar_osc = "FFFFFF"
M.width_border_thumb_osc = 0

----------------------------------------------------------
-- TIME LABELS
----------------------------------------------------------

M.size_font_osc = 18
M.position_time_label_osc = "inline"
M.gap_time_label_inline_osc = 10

-- No "time" slot is assigned; standalone seekbar time labels
-- remain in use. width_time_item_osc is therefore unnecessary.
-- Time-label text inherits the shared white text color.

----------------------------------------------------------
-- VOLUME POPUP SLIDER
----------------------------------------------------------

-- The row contains "volume", not a persistent volume_slider.
M.width_volume_slider_osc = 100
M.height_volume_slider_osc = 4
M.radius_volume_slider_osc = 2
M.color_track_volume_slider_osc = "4D4D4D"
M.width_thumb__volume_slider_osc = 6
M.height_thumb__volume_slider_osc = 6

-- Volume fill retains its documented white default.

return M