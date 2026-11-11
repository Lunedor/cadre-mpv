local M = {}

M.theme_name = "Review Desk"
M.theme_author = "Lunedor"

----------------------------------------------------------
-- SHARED IDENTITY
----------------------------------------------------------

M.text_color = "E9EDF2"
M.surface_color = "15191F"
M.accent_color = "E8B86D"

----------------------------------------------------------
-- INTEGRATED CONSOLE
----------------------------------------------------------

M.anchor_y_panel_osc = "bottom"
M.height_panel_osc = 142
M.alpha_panel_bg_osc = "FF"

-- Every control uses an anchored row.
-- Structured layout explicitly controls only the seekbar.
M.osc_layout = {
    seekbar = {
        anchor = "panel_top",
        panel_inset = 75,
    },
}

M.offset_top_osc = 40
M.offset_bottom_osc = 32

----------------------------------------------------------
-- UPPER LEFT: FRAME AND CHAPTER REVIEW
----------------------------------------------------------

M.osc_L1_top_osc = "frame_back_step"
M.osc_L2_top_osc = "frame_step"
M.osc_L3_top_osc = "chapter_prev"
M.osc_L4_top_osc = "chapter_next"

----------------------------------------------------------
-- UPPER CENTER: TRANSPORT
----------------------------------------------------------

M.osc_C1_top_osc = "prev"
M.osc_C2_top_osc = "play"
M.osc_C3_top_osc = "next"

----------------------------------------------------------
-- UPPER RIGHT: SPEED AND LOOP
----------------------------------------------------------

M.osc_R1_top_osc = "speed_down"
M.osc_R2_top_osc = "speed_reset"
M.osc_R3_top_osc = "speed_up"
M.osc_R4_top_osc = "ab_loop"

----------------------------------------------------------
-- LOWER ROW: IDENTITY, TIME, AND UTILITIES
----------------------------------------------------------

M.osc_L1_bottom_osc = "title"
M.width_title_item_osc = 420

M.osc_C1_bottom_osc = "time"

M.osc_R1_bottom_osc = "volume_slider"
M.osc_R2_bottom_osc = "playlist"
M.osc_R3_bottom_osc = "fullscreen"

-- The title slot replaces floating-title placement.
-- The time slot replaces standalone elapsed/duration labels.

----------------------------------------------------------
-- VOLUME SLIDER
----------------------------------------------------------

M.pad_right_volume_slider_osc = 18
M.height_volume_slider_osc = 16
M.width_thumb__volume_slider_osc = 2
M.height_thumb__volume_slider_osc = 10

-- Preserve supplied values without assuming half-dimensions.

----------------------------------------------------------
-- TIMELINE AND CHAPTERS
----------------------------------------------------------

M.height_normal_seekbar = 4
M.height_hover_seekbar = 6
M.color_track_bg_osc = "343C47"

M.alpha_chapter_mark = "FF"
M.color_chapter_mark = "15191F"

M.width_thumb_seekbar_osc = 3
M.height_thumb_seekbar_osc = 7
M.radius_thumb_seekbar_osc = 2

----------------------------------------------------------
-- PLAY BUTTON
----------------------------------------------------------

M.osc_slot_overrides = {
    osc_C2_top_osc = {
        icon_color = "15191F",

        button_background = true,
        button_color = "E8B86D",
        button_alpha = "FF",
        button_height = 36,
        button_padding = 4,
        button_radius = 6,
    },
}

M.inset_bottom_pl = 160

return M