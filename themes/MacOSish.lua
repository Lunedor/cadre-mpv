local M = {}

M.theme_name = "MacOSish"
M.theme_author = "Lunedor"

--------------------------------------------------------------------------------
-- Typography
--------------------------------------------------------------------------------

M.font_text = "Inter"
M.font_size = 18
M.size_font_title_osc = 20

--------------------------------------------------------------------------------
-- Base palette
--------------------------------------------------------------------------------

M.text_color = "F5F7FA"
M.surface_color = "1D2025"
M.alpha_panel_bg = "CF"

--------------------------------------------------------------------------------
-- Floating OSC
--------------------------------------------------------------------------------

M.height_panel_osc = 96
M.inset_side_panel_osc = 16
M.inset_bottom_panel_osc = 18
M.radius_panel_osc = 18
M.autohide_sec_panel_osc = 0.45

M.surface_color_osc = "22262C"
M.alpha_panel_bg_osc = "CB"

M.osc_layout = {
    button_row = {
        anchor = "center",
        offset = 12,
    },
    seekbar = {
        anchor = "panel_top",
        panel_inset = 15,
    },
}

--------------------------------------------------------------------------------
-- Controls
--------------------------------------------------------------------------------

M.icon_size = 25
M.icon_spacing = 40
M.color_icon_osc = "F3F5F7"

M.inset_left_button_osc = 28
M.inset_right_button_osc = 28
M.inset_side_seekbar_osc = 28
M.inset_side_title_osc = 28

M.color_track_fg_osc = "5AC8FA"
M.color_track_bg_osc = "434A53"
M.color_slider_rail_osc = "323842"

-- Normal and hovered track heights retain their documented
-- defaults of 6 px and 10 px.

--------------------------------------------------------------------------------
-- Seekbar thumb
--------------------------------------------------------------------------------

-- Width retains the documented 4 px default.
M.height_thumb_seekbar_osc = 8
M.radius_thumb_seekbar_osc = 2
M.color_thumb_seekbar_osc = "FFFFFF"

--------------------------------------------------------------------------------
-- Chapter tooltip
--------------------------------------------------------------------------------

M.color_chapter_mark = "24282F"
M.alpha_chapter_mark = "CF"

M.chapter_tooltip_bg_color = "2B3037"
M.chapter_tooltip_bg_alpha = "DB"
M.chapter_tooltip_radius = 10

M.titlebar_button_side_tb = "left"
M.style_button_titlebar_tb = "macos"

return M