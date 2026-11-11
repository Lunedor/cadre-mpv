local M = {}

M.theme_name = "Spotilike"
M.theme_author = "Lunedor"

----------------------------------------------------------
-- CORE PALETTE
----------------------------------------------------------

M.accent_color = "1DB954"
M.background_color = "080808"
M.surface_color = "181818"
M.text_color = "FFFFFF"

M.font_text = "Inter"
M.font_size = 15

----------------------------------------------------------
-- OSC PANEL
----------------------------------------------------------

M.anchor_y_panel_osc = "bottom"
M.height_panel_osc = 82
M.inset_side_panel_osc = 20
M.inset_bottom_panel_osc = 18
M.radius_panel_osc = 18
M.alpha_panel_bg_osc = "F7"

-- surface_color_osc inherits surface_color.

M.osc_layout = {
    button_row = {
        anchor = "center",
        offset = 9,
    },
    seekbar = {
        anchor = "panel_top",
        panel_inset = 14,
    },
}

----------------------------------------------------------
-- BUTTON LAYOUT
----------------------------------------------------------

-- Left: elapsed / total time
M.osc_L1 = "time"

-- Center: playback
M.osc_C1 = "prev"
M.osc_C2 = "seekbar_back"
M.osc_C3 = "play"
M.osc_C4 = "seekbar_forward"
M.osc_C5 = "next"

-- Right: player actions
M.osc_R1 = "volume"
M.osc_R2 = "playlist"
M.osc_R3 = "fullscreen"

----------------------------------------------------------
-- SEEKBAR
----------------------------------------------------------

-- 38 px from the window edge leaves 18 px inside
-- the panel's 20 px side inset.
M.inset_side_seekbar_osc = 38

M.height_normal_seekbar = 3
M.height_hover_seekbar = 6
M.color_track_bg_osc = "535353"

-- Progress inherits the green accent.
-- Seekbar border width retains the documented zero default.

----------------------------------------------------------
-- THUMB
----------------------------------------------------------

M.width_thumb_seekbar_osc = 10
M.color_thumb_seekbar_osc = "FFFFFF"

-- Thumb height and radius retain their documented
-- defaults of 10 px and 5 px.

----------------------------------------------------------
-- TIME
----------------------------------------------------------

M.size_font_osc = 14
M.width_time_item_osc = 120
M.enabled_shadow_time_label_osc = false
M.enabled_outline_time_label_osc = false

-- OSC text inherits the shared white text color.

----------------------------------------------------------
-- ICONS
----------------------------------------------------------

M.icon_size = 22
M.icon_spacing = 42

-- OSC icons inherit the shared white text color.
-- Individual and group backgrounds retain their
-- documented disabled defaults.

----------------------------------------------------------
-- CHAPTERS
----------------------------------------------------------

M.color_chapter_mark = "1DB954"
M.alpha_chapter_mark = "8F"
M.chapter_mark_width = 1

M.chapter_tooltip_bg_color = "181818"
M.chapter_tooltip_bg_alpha = "EF"

return M