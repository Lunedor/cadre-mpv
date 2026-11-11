local M = {}

M.theme_name = "Cinema"
M.theme_author = "Lunedor"

----------------------------------------------------------
-- SHARED IDENTITY
----------------------------------------------------------

M.text_color = "FFFFFF"
M.surface_color = "101216"
M.accent_color = "FFFFFF"
M.font_icon_osc = "Material Icons Round"

M.inset_left_button_osc = 42
M.inset_right_button_osc = 42
M.font_size = 18
----------------------------------------------------------
-- INVISIBLE BOTTOM PANEL
----------------------------------------------------------

M.height_panel_osc = 110
M.alpha_panel_bg_osc = "00"

M.osc_layout = {
    button_row = {
        anchor = "center",
        offset = 12,
    },
    seekbar = {
        anchor = "panel_top",
        panel_inset = 12,
    },
}

----------------------------------------------------------
-- WINDOW-TOP ROW
----------------------------------------------------------

M.offset_top_osc = 64

M.osc_L1_top = "title"
M.width_title_item_osc = 360

M.osc_R1_top = "add"
M.osc_R2_top = "volume"
M.osc_R3_top = "speed_control"
M.osc_R4_top = "settings"

----------------------------------------------------------
-- WINDOW-CENTER TRANSPORT
----------------------------------------------------------

M.osc_C1_center = "prev"
M.osc_C2_center = "play"
M.osc_C3_center = "next"

----------------------------------------------------------
-- BOTTOM ROW
----------------------------------------------------------

M.osc_L1 = "time"
M.osc_R2 = "fullscreen"

----------------------------------------------------------
-- TIMELINE
----------------------------------------------------------

M.height_normal_seekbar = 3
M.height_hover_seekbar = 5
M.color_track_bg_osc = "737780"

M.height_thumb_seekbar_osc = 4
M.radius_thumb_seekbar_osc = 4

----------------------------------------------------------
-- TOP-RIGHT UTILITY CAPSULE
----------------------------------------------------------

M.osc_group_overrides = {
    R_top = {
        group = {
            background = true,
            color = "101216",
            alpha = "0F",
            padding = 8,
            height = 40,
            radius = 20,

            border = true,
            border_color = "FFFFFF",
            border_alpha = "4F",
            border_width = 1,
        },
    },
	C_center = {
		icon = {
			outline = true,
			outline_color = "101216",
			outline_alpha = "FF",
			outline_width = 1,
			outline_blur = 0,
		},
	},
	L = {
		group = {
			background = true,
			color = "101216",
			alpha = "0F",
			padding = 8,
			height = 40,
			radius = 20,

			border = true,
			border_color = "FFFFFF",
			border_alpha = "4F",
			border_width = 1,
		},
	},
}



----------------------------------------------------------
-- SLOT APPEARANCE
----------------------------------------------------------

M.osc_slot_overrides = {
    osc_L1_top = {
        font_size = 21,
    },

    osc_C1_center = {
        icon_size = 52,
        spacing = 46,
    },

    osc_C2_center = {
        icon_size = 72,
        spacing = 46,
    },

    osc_C3_center = {
        icon_size = 52,
    },
}


----------------------------------------------------------
-- SHARED CIRCULAR HOVERS
----------------------------------------------------------

local hover_slots = {
    "osc_R1_top",
    "osc_R2_top",
    "osc_R3_top",
    "osc_R4_top",
    "osc_C1_center",
    "osc_C2_center",
    "osc_C3_center",
    "osc_R2",
}

for _, slot in ipairs(hover_slots) do
    local appearance = M.osc_slot_overrides[slot] or {}
    local icon_size = appearance.icon_size or 24
    local diameter = icon_size + 12

    appearance.button_height = diameter
    appearance.button_padding = 6
    appearance.button_radius = diameter / 2

    appearance.hover_bg_color = "FFFFFF"
    appearance.hover_bg_alpha = "30"
    appearance.hover_icon_color = M.text_color
    appearance.hover_radius = diameter / 2
    appearance.hover_border = false
    appearance.hover_scale = 1

    M.osc_slot_overrides[slot] = appearance
end

return M