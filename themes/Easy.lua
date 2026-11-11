
local M = {}

M.theme_name = "Easy"
M.theme_author = "Lunedor"

----------------------------------------------------------
-- SHARED IDENTITY
----------------------------------------------------------

M.font_icon = "Material Icons Round"
M.text_color = "E8EDF3"
M.surface_color = "15191F"
M.alpha_panel_bg = "EF"
M.accent_color = "83ACD9"

----------------------------------------------------------
-- BOTTOM DOCK
----------------------------------------------------------

M.height_panel_osc = 76
M.icon_spacing = 40
M.autohide_sec_panel_osc = 2

-- Button side insets retain their documented 24 px defaults.

M.osc_layout = {
    button_row = {
        anchor = "center",
        offset = 10,
    },
}

----------------------------------------------------------
-- CONTROL LAYOUT
----------------------------------------------------------

M.osc_L1 = "play"
M.osc_L2 = "next"
M.osc_L3 = "volume"

-- Only one seekbar placement; no standalone placement.
M.osc_C1 = "seekbar"

M.osc_R2 = "subtitle_list"
M.osc_R3 = "settings"
M.osc_R5 = "fullscreen"

----------------------------------------------------------
-- TIMELINE AND TIME LABELS
----------------------------------------------------------

M.height_normal_seekbar = 4
M.height_hover_seekbar = 7
M.color_track_bg_osc = "39414C"

M.position_time_label_osc = "inline"
M.inset_side_seekbar_osc = 8
M.gap_time_label_inline_osc = 2
M.enabled_shadow_time_label_osc = true

-- No time slot is assigned; the seekbar's time labels are used.
-- The reference does not document a boolean start-label toggle.

----------------------------------------------------------
-- FLOATING OSC TITLE
----------------------------------------------------------

-- Preserve the explicitly enabled title from the original.
M.enabled_title_osc = true
M.position_title_osc = "above_seekbar"
M.align_title_osc = "center"
M.size_font_title_osc = 18

-- No title slot is assigned, so width_title_item_osc is omitted.

----------------------------------------------------------
-- PLAYHEAD
----------------------------------------------------------

M.width_thumb_seekbar_osc = 5
M.height_thumb_seekbar_osc = 5
M.color_thumb_seekbar_osc = "E8EDF3"

----------------------------------------------------------
-- PLAY BUTTON
----------------------------------------------------------

M.osc_slot_overrides = {
    osc_L1 = {
        button_background = true,
        button_color = "83ACD9",
        button_alpha = "FF",
        button_height = 40,
        button_padding = 8,
        button_radius = 12,

        icon_color = "15191F",
        hover_icon_color = "15191F",
        hover_bg_color = "A3C4E8",
        hover_bg_alpha = "FF",
        hover_scale = 1,
    },
}

----------------------------------------------------------
-- COMPACT HOVER SURFACES
----------------------------------------------------------

-- Seekbar slots do not support hover-background overrides.
for _, slot in ipairs({
    "osc_L2",
    "osc_L3",
    "osc_R2",
    "osc_R3",
    "osc_R5",
}) do
    M.osc_slot_overrides[slot] = {
        hover_bg_color = "303A46",
        hover_scale = 1,
    }
end

-- Button tooltips retain their documented disabled default.

return M