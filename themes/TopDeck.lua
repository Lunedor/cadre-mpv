local M = {}

M.theme_name = "TopDeck"
M.theme_author = "Lunedor"

----------------------------------------------------------
-- SHARED IDENTITY
----------------------------------------------------------

M.text_color = "EDF1F5"
M.surface_color = "182029"
M.accent_color = "78C9BB"

----------------------------------------------------------
-- TOP-MOUNTED TOOLBAR
----------------------------------------------------------

M.anchor_y_panel_osc = "top"
M.height_panel_osc = 96
M.inset_top_panel_osc = 36
M.alpha_panel_bg_osc = "FF"

M.osc_layout = {
    button_row = {
        anchor = "center",
        offset = -16,
    },
    seekbar = {
        anchor = "panel_bottom",
        panel_inset = 16,
    },
}

----------------------------------------------------------
-- CONTROL LAYOUT
----------------------------------------------------------

M.osc_L1 = "title"
M.width_title_item_osc = 180

M.osc_C1 = "prev"
M.osc_C2 = "play"
M.osc_C3 = "next"

M.osc_R1 = "volume"
M.osc_R2 = "playlist"
M.osc_R3 = "fullscreen"
M.osc_R4 = "quit"

-- The title slot replaces floating-title placement.

----------------------------------------------------------
-- TIMELINE AND TIME LABELS
----------------------------------------------------------

-- No time slot: use standalone elapsed/duration labels.
M.position_time_label_osc = "inline"

M.height_normal_seekbar = 4
M.height_hover_seekbar = 6
M.color_track_bg_osc = "3D4C59"

M.width_thumb = 3
M.height_thumb = 7
M.radius_thumb = 2

----------------------------------------------------------
-- VOLUME POPUP
----------------------------------------------------------

M.offset_y_volume_popup_osc = 45

----------------------------------------------------------
-- PLAY ACCENT
----------------------------------------------------------

M.osc_slot_overrides = {
    osc_C2 = {
        icon_color = "78C9BB",
    },
}

M.inset_top_pl = 140
M.inset_bottom_pl = 40

return M