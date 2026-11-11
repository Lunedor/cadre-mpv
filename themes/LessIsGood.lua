M = {}

-- Theme: Streaming Minimal (from mockup)
M.theme_name = "HBO"
M.theme_variant = ""

-- Shared identity
M.text_color   = "FFFFFF"
M.accent_color = "22B8E6"
M.alpha_bar_bg = "FF"                 
M.alpha_bar_bg_pl = "60" 

-- Panel and row positions
M.bar_height_osc      = 90
M.osc_top_offset      = 32

-- Icons
M.icon_size    = 28
M.icon_spacing = 48

-- Slots
M.osc_L1_top = "title"
M.osc_R1_top = "subtitle"

M.osc_C1 = "prev"
M.osc_C2 = "seek_back"
M.osc_C3 = "play"
M.osc_C4 = "seek_forward"
M.osc_C5 = "next"

M.osc_R1 = "volume"
M.osc_R2 = "fullscreen"

M.osc_slot_overrides = {
    osc_L1_top = {font_size = 22},
    osc_C3     = {icon_size = 34},
}

-- Title: left-aligned, wide enough for long names
M.osc_title_align_osc      = "left"
M.osc_title_item_width_osc = 360

-- Seekbar: below the buttons, thin track, round dot
M.seekbar_position_osc  = "below_buttons"
M.seek_height_normal    = 2
M.seek_height_hover     = 4
M.color_track_bg_osc    = "4A4F57"
M.thumb_width           = 5
M.thumb_height          = 5
M.thumb_radius          = 5
M.thumb_border_width_osc = 0
M.button_y_anchor_osc = "bottom"
M.osc_main_row_offset = 70


-- Time label at the end of the track
M.time_label_position_osc = "inline"

-- Keep the playlist hover zone clear of the OSC footprint
M.bottom_inset_pl         = 100
M.osc_bottom_exclusion_pl = 100

return M
