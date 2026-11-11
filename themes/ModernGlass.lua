local M = {}

M.theme_name = "ModernGlass"
M.theme_author = "Lunedor"

----------------------------------------------------------
-- SHARED IDENTITY
----------------------------------------------------------

M.font_icon = "FluentSystemIcons-Filled"
M.text_color = "F5F4ED"
M.surface_color = "505249"
M.alpha_panel_bg = "9F"
M.accent_color = "F2F2DF"
M.panel_radius = 22
M.glass_blur = true

----------------------------------------------------------
-- FLOATING BOTTOM PANEL
----------------------------------------------------------

-- Panel height retains the documented 100 px default.
M.anchor_y_panel_osc = "bottom"
M.max_width_panel_osc = 1400
M.inset_side_panel_osc = 24
M.inset_bottom_panel_osc = 18

M.osc_layout = {
    button_row = {
        anchor = "center",
        offset = 24,
    },
    seekbar = {
        anchor = "panel_top",
        panel_inset = 44,
    },
}

M.inset_left_button_osc = 18
M.inset_right_button_osc = 18
M.gap_button_group_osc = 24

----------------------------------------------------------
-- UPPER-LEFT MEDIA TITLE
----------------------------------------------------------

M.enabled_title_osc = true
M.position_title_osc = "above_seekbar"
M.align_title_osc = "left"
M.inset_side_title_osc = 18
M.gap_title_seekbar_osc = 5

-- Title font size inherits the documented 16 px OSC default.

----------------------------------------------------------
-- TIMELINE AND TIME LABELS
----------------------------------------------------------

M.inset_side_seekbar_osc = 18
M.position_time_label_osc = "inline"

M.height_normal_seekbar = 3
M.height_hover_seekbar = 5
M.color_track_bg_osc = "77796F"

-- OSC font size retains the documented 16 px default.
-- Progress inherits the shared warm-white accent.
-- No time slot is assigned, so standalone time labels remain in use.

----------------------------------------------------------
-- PLAYHEAD
----------------------------------------------------------

-- Width retains the documented 4 px default.
-- Preserve the supplied geometry without assuming half-dimensions.
M.height_thumb_seekbar_osc = 4
M.radius_thumb_seekbar_osc = 4
M.color_thumb_seekbar_osc = "FFFFE8"

----------------------------------------------------------
-- CHAPTER MARKERS
----------------------------------------------------------

M.color_chapter_mark = "24251F"
M.alpha_chapter_mark = "FF"

----------------------------------------------------------
-- COMPACT CONTROLS
----------------------------------------------------------

M.icon_size = 18
M.icon_spacing = 30

-- Permanent individual/group backgrounds retain their
-- documented disabled defaults.

-- Left: Add and popup volume control.
M.osc_L1 = "add"
M.osc_L2 = "volume"

-- Center: seek back, play/pause, seek forward.
M.osc_C1 = "seekbar_back"
M.osc_C2 = "play"
M.osc_C3 = "seekbar_forward"

-- Right: subtitles, audio, playlist, settings, fullscreen.
M.osc_R1 = "subtitle_list"
M.osc_R2 = "audio_list"
M.osc_R3 = "speed_control"
M.osc_R4 = "playlist"
M.osc_R5 = "settings"
M.osc_R6 = "fullscreen"

----------------------------------------------------------
-- VOLUME POPUP SLIDER
----------------------------------------------------------

M.width_volume_slider_osc = 64
M.height_volume_slider_osc = 3
M.radius_volume_slider_osc = 1.5
M.enabled_thumb_volume_slider_osc = false
M.color_volume_slider_osc = "F5F4ED"
M.color_track_volume_slider_osc = "77796F"

----------------------------------------------------------
-- SLOT APPEARANCE
----------------------------------------------------------

M.osc_slot_overrides = {
    osc_C1 = {
        icon_size = 22,
        spacing = 40,
    },

    osc_C2 = {
        icon_size = 30,
        spacing = 40,
    },

    osc_C3 = {
        icon_size = 22,
    },
}

-- Supported per-slot hover color.
for _, slot in ipairs({
    "osc_L1",
    "osc_L2",
    "osc_C1",
    "osc_C2",
    "osc_C3",
    "osc_R1",
    "osc_R2",
    "osc_R3",
    "osc_R4",
    "osc_R5",
}) do
    local override = M.osc_slot_overrides[slot] or {}

    override.hover_icon_color = "FFFFE8"

    M.osc_slot_overrides[slot] = override
end

----------------------------------------------------------
-- CHAPTER / TIME HOVER CARDS
----------------------------------------------------------

M.chapter_tooltip_size = 12
M.offset_y_chapter_tooltip_osc = 30
M.chapter_tooltip_bg_color = "181A17"
M.chapter_tooltip_bg_alpha = "C7"
M.chapter_tooltip_radius = 6
M.chapter_tooltip_pad_y = 5

----------------------------------------------------------
-- SHARED BORDERS
----------------------------------------------------------

M.border_all_color = "F5F4ED"
M.border_all_alpha = "87"
M.border_all_width = 1

M.inset_bottom_pl = 130

return M