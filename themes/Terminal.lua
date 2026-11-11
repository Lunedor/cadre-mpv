local M = {}

M.theme_name = "Terminal"
M.theme_author = "Lunedor"

--------------------------------------------------------------------------------
-- Typography
--------------------------------------------------------------------------------

M.font_text = "Consolas"
M.font_size = 14
M.size_font_title_osc = 16

--------------------------------------------------------------------------------
-- Shared palette
--------------------------------------------------------------------------------

M.text_color = "D5D9D2"
M.surface_color = "090B09"
M.alpha_panel_bg = "F7"

--------------------------------------------------------------------------------
-- Integrated OSC
--------------------------------------------------------------------------------

M.anchor_y_panel_osc = "bottom"
M.height_panel_osc = 78
M.autohide_sec_panel_osc = 0.3
M.alpha_panel_bg_osc = "EF"

-- Panel side inset, bottom inset, and radius retain
-- their documented zero defaults.
-- OSC surface inherits the shared surface color.

M.osc_layout = {
    button_row = {
        anchor = "center",
        offset = 11,
    },
    seekbar = {
        anchor = "panel_top",
        panel_inset = 10,
    },
}

M.inset_left_button_osc = 20
M.inset_right_button_osc = 20
M.inset_side_seekbar_osc = 20
M.inset_side_title_osc = 20

--------------------------------------------------------------------------------
-- Controls
--------------------------------------------------------------------------------

M.icon_size = 22
M.icon_spacing = 32
M.color_icon_osc = "C8D0C4"

M.color_track_fg_osc = "B5FF75"
M.color_track_bg_osc = "252A25"
M.color_slider_rail_osc = "151815"

M.height_normal_seekbar = 3

-- Hovered seekbar height retains the documented 10 px default
-- only when omitted; preserve the requested 6 px explicitly.
M.height_hover_seekbar = 6

M.offset_y_time_label_osc = 12

--------------------------------------------------------------------------------
-- Seekbar thumb
--------------------------------------------------------------------------------

M.width_thumb_seekbar_osc = 3
M.height_thumb_seekbar_osc = 8
M.radius_thumb_seekbar_osc = 0

-- Preserve the final assignment from the original theme.
M.color_thumb_seekbar_osc = "E8FFE0"

--------------------------------------------------------------------------------
-- Chapter tooltip
--------------------------------------------------------------------------------

M.color_chapter_mark = "090B09"
M.alpha_chapter_mark = "DF"

M.chapter_tooltip_bg_color = "101410"
M.chapter_tooltip_bg_alpha = "E7"
M.chapter_tooltip_radius = 0

return M