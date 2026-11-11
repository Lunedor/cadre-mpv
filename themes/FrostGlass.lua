-- Frost Glass
-- Backdrop blur is provided by cadre_glass.lua and requires vo=gpu-next.
-- The alpha values below keep the blurred video visible through each panel.
local M = {}

M.theme_name = "Frost Glass"
M.theme_author = "Lunedor"

--------------------------------------------------------------------------------
-- Shared palette and typography
--------------------------------------------------------------------------------

M.font_text = "Inter"
M.font_size = 16
M.title_font_size = 18

M.text_color = "EAF5FC"
M.dim_color = "8FA9B8"
M.surface_color = "102330"
M.alpha_bar_bg = "68"
M.accent_color = "78DDF2"
M.color_icon = "E5F7FC"
M.color_icon_dim = "7893A2"
M.color_hover_bg = "244552"

-- The denser shader kernel keeps stronger blur smoother; tune for your GPU.
M.glass_blur = true
M.glass_blur_radius = 12

--------------------------------------------------------------------------------
-- OSC
--------------------------------------------------------------------------------

M.bar_height_osc = 96
M.bar_side_inset_osc = 24
M.max_bar_width_osc = 1200
M.bar_bottom_inset_osc = 24
M.bar_radius_osc = 20
M.bar_autohide_sec_osc = 0.4

M.icon_size_osc = 25
M.icon_spacing = 38
M.color_track_fg_osc = "78DDF2"
M.color_track_bg_osc = "46616D"
M.seek_height_normal = 5
M.seek_height_hover = 8

M.color_bar_bg_osc = "102B38"
M.alpha_bar_bg_osc = "68"

--------------------------------------------------------------------------------
-- Playlist
--------------------------------------------------------------------------------

M.panel_width_pl = 420
M.row_height_pl = 43
M.header_height_pl = 44
M.toolbar_height_pl = 42
M.search_height_pl = 40
M.side_inset_pl = 22
M.top_inset_pl = 54
M.bottom_inset_pl = 112
M.bar_radius_pl = 20
M.list_radius_pl = 12

M.color_bar_bg_pl = "102B38"
M.alpha_bar_bg_pl = "68"
M.alpha_frame_pl = "68"
M.alpha_list_bg_pl = "68"
M.color_selected_pl = "286276"
M.alpha_selected_pl = "58"
M.color_current_pl = "78DDF2"
M.alpha_current_pl = "88"
M.color_scroll_fg_pl = "8EC7D5"
M.color_scroll_bg_pl = "203B47"

--------------------------------------------------------------------------------
-- Titlebar
--------------------------------------------------------------------------------

M.titlebar_show_mode_tb = "auto"
M.bar_height_tb = 38
M.color_bar_bg_tb = "102B38"
M.alpha_bar_bg_tb = "68"
M.color_text_tb = "EAF5FC"
M.color_button_bg_tb = "78DDF2"
M.alpha_button_bg_tb = "80"
M.color_button_pressed_bg_tb = "78DDF2"
M.alpha_button_pressed_bg_tb = "68"
M.color_close_bg_tb = "F06F7B"
M.alpha_close_bg_tb = "58"
M.button_radius_tb = 6
M.close_button_radius_tb = 6

return M
