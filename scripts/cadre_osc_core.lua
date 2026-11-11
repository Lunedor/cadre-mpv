--[[
cadre_osc_core.lua (configuration, drawing primitives, and layout)
]]
mp = require "mp"
assdraw = require "mp.assdraw"
utils = require "mp.utils"
msg = require "mp.msg"

common = dofile(mp.command_native({"expand-path", "~~/scripts/cadre/scripts/cadre_common.lua"}))
common.register_script("cadre_osc")

thumbfast = {width = 0, height = 0, disabled = true, available = false}
mp.register_script_message(
    "thumbfast-info",
    function(json)
        local data = utils.parse_json(json)
        if type(data) ~= "table" or not data.width or not data.height then
            msg.error("thumbfast-info: received json didn't produce a table with thumbnail information")
        else
            thumbfast = data
        end
    end
)

--------------------------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------------------------

theme = common.theme
structured_layout, structured_row, structured_seek, seekbar_panel_inset = nil, nil, nil, nil
icon_size, icon_bg_height, icon_bg_width, cfg = nil, nil, nil, nil
GLASS_BLUR, GLASS_BLUR_RADIUS = nil, nil
normalize_group_widths = nil
ICON_DEFAULTS = {
    play = "E037",
    pause = "E034",
    prev = "E045",
    next = "E044",
    stop = "E047",
    volume_up = "E050",
    volume_off = "E04F",
    add = "E145",
    fullscreen = "E5D0",
    seekbar_back = "E059",
    seekbar_forward = "E056",
    playlist = "E05F",
    add_file = "E24D",
    add_folder = "E2CC",
    add_url = "E157",
    cc_on = "E01C",
    cc_off = "F1DC",
    settings = "E8B8",
    youtube = "F06A",
    stream = "E02C",
    webdav = "E1C3",
    info = "E88E",
    music_mode = "E063",
    screenshot = "E412",
    pin = "F10D",
    picture_in_picture = "E911",
    always_on_top = "E8AA",
    close = "E5CD",
    frame_back = "E408",
    frame_forward = "E409",
    audio = "E1B8",
    subtitles = "E048",
    chapter_list = "E02F",
    chapter_prev = "E5DC",
    chapter_next = "E5DD",
    speed_down = "E020",
    speed_reset = "E9E4",
    speed_up = "E01F",
    ab_loop = "E040",
    shuffle = "E043",
    repeat_all = "E040",
    repeat_one = "E041",
    repeat_auto = "F053",
    globe = "E80B"
}
ICON = nil
function apply_theme(updated)
theme = updated
ICON = common.resolve_icon_map(
    ICON_DEFAULTS,
    theme.icon_codepoints,
    theme.font_icon_osc or theme.font_icon or "Material Icons Outlined"
)
GLASS_BLUR = theme.enabled_glass_blur_osc == true
    or (theme.enabled_glass_blur_osc == nil and theme.glass_blur == true)
GLASS_BLUR_RADIUS = theme.radius_glass_blur_osc or theme.radius_glass_blur or 12

structured_layout = type(theme.osc_layout) == "table" and theme.osc_layout or nil
structured_row = structured_layout and type(structured_layout.button_row) == "table"
    and structured_layout.button_row or nil
structured_seek = structured_layout and type(structured_layout.seekbar) == "table"
    and structured_layout.seekbar or nil

seekbar_panel_inset = structured_seek and structured_seek.panel_inset
if type(seekbar_panel_inset) ~= "number" or seekbar_panel_inset < 0
    or seekbar_panel_inset == math.huge or seekbar_panel_inset ~= seekbar_panel_inset then
    seekbar_panel_inset = nil
end

icon_size = theme.size_icon_osc or theme.icon_size or 24
icon_bg_height = theme.height_icon_bg_osc or theme.icon_bg_height or (icon_size + 12)
icon_bg_width = theme.width_icon_bg_osc or icon_bg_height

cfg = {
    SEEKBAR_ENABLED = theme.enabled_seekbar_osc ~= false,

    UI_FONT = theme.font_ui or theme.font_text or theme.font_text_osc or "Inter",
    ICON_FONT = theme.font_icon_osc or theme.font_icon or "Material Icons Outlined",
    ICON_COLOR = common.bgr(theme.color_icon_osc or theme.text_color or "F8FAFC"),
    TEXT = common.bgr(theme.color_text_osc or theme.text_color or "F8FAFC"),
    FONT_SIZE = theme.size_font_osc or theme.font_size or 16,

    BARBG = common.bgr(theme.surface_color_osc or theme.surface_color or "0D1117"),
    ALPHA_BAR_BG = common.ass_alpha(theme.alpha_panel_bg_osc or theme.alpha_panel_bg or "E3"),

    TRACK_FG = common.bgr(theme.color_track_fg_osc or theme.accent_color or "63B8FF"),
    TRACK_BG = common.bgr(theme.color_track_bg_osc or "303845"),
    SLIDER_RAIL = common.bgr(theme.color_slider_rail_osc or "1E293B"),
    THUMB_WCOLOR = common.bgr(
        theme.color_thumb_seekbar_osc
        or theme.color_track_fg_osc
        or theme.accent_color
        or "F8FAFC"
    ),

    ICON_DIM_A = common.ass_alpha(theme.alpha_icon_dim_osc or theme.alpha_icon_dim or "9F"),

    HOVER_ICON_COLOR = common.bgr(
        theme.color_icon_hover_osc
        or theme.color_icon_osc
        or theme.text_color
        or "F8FAFC"
    ),

    HOVER_BG_COLOR = common.bgr(
        theme.color_bg_hover_osc
        or theme.surface_color_osc
        or theme.surface_color
        or "181C26"
    ),

    HOVER_BG_ALPHA = common.ass_alpha(theme.alpha_bg_hover_osc or "CF"),

    POPUP_HOVER_COLOR = common.bgr(
        theme.popup_hover_color
        or theme.color_bg_hover_osc
        or theme.color_hover_pl
        or theme.accent_color
        or "63B8FF"
    ),
    POPUP_HOVER_ALPHA = common.ass_alpha(theme.popup_hover_alpha or "1F"),

    HOVER_SCALE = theme.scale_hover_osc or 1.0,
    HOVER_BORDER = theme.enabled_border_hover_osc == true,
    HOVER_BORDER_COLOR = common.bgr(
        theme.color_border_hover_osc
        or theme.border_all_color
        or "FFFFFF"
    ),

    HOVER_BORDER_ALPHA = common.ass_alpha(theme.alpha_border_hover_osc or theme.border_all_alpha or "DF"),

    HOVER_BORDER_WIDTH = theme.width_border_hover_osc or theme.border_all_width or 1,

    BAR_HEIGHT = theme.height_panel_osc or theme.height_panel or 100,
    BAR_SIDE_INSET = theme.inset_side_panel_osc or theme.side_inset_panel or 0,
    BAR_Y_ANCHOR =
        theme.anchor_y_panel_osc == "top" and "top"
        or theme.anchor_y_panel_osc == "center" and "center"
        or "bottom",
    BAR_TOP_INSET = theme.inset_top_panel_osc or 0,
    BAR_BOTTOM_INSET = theme.inset_bottom_panel_osc or theme.panel_bottom_inset or 0,
    BAR_RADIUS = theme.radius_panel_osc or theme.panel_radius or 0,

    BAR_BORDER_COLOR = common.bgr(
        theme.color_border_panel_osc
        or theme.border_all_color
        or "FFFFFF"
    ),
    BAR_BORDER_ALPHA = common.ass_alpha(theme.alpha_border_panel_osc or theme.border_all_alpha or "00"),
    BAR_BORDER_WIDTH = theme.width_border_panel_osc or theme.border_all_width or 0,

    AUTOHIDE_SEC = theme.autohide_sec_panel_osc or theme.autohide_sec_panel or 0.4,


    THUMB_WW = theme.width_thumb_seekbar_osc or 4,
    THUMB_WH = theme.height_thumb_seekbar_osc or 10,
    THUMB_WRADIUS = theme.radius_thumb_seekbar_osc or 5,

    SEEKBAR_BORDER_COLOR = common.bgr(
        theme.color_border_seekbar_osc
        or theme.border_all_color
        or "FFFFFF"
    ),
    SEEKBAR_BORDER_ALPHA = common.ass_alpha(theme.alpha_border_seekbar_osc or theme.border_all_alpha or "00"),
    SEEKBAR_BORDER_WIDTH = theme.width_border_seekbar_osc or theme.border_all_width or 0,

    THUMB_WBORDER_COLOR = common.bgr(
        theme.color_border_thumb_osc
        or theme.border_all_color
        or "000000"
    ),
    THUMB_WBORDER_ALPHA = common.ass_alpha(theme.alpha_border_thumb_osc or theme.border_all_alpha or "00"),
    THUMB_WBORDER_WIDTH = theme.width_border_thumb_osc or theme.border_all_width or 1,

    SEEKBAR_BAR_Y_OFFSET = theme.offset_y_seekbar_osc or 0,
    SEEKBAR_POSITION = (structured_seek and structured_seek.anchor)
        or theme.position_seekbar_osc
        or "top",
    SEEKBAR_BUTTON_GAP = (structured_seek and structured_seek.gap)
        or theme.gap_button_seekbar_osc
        or 12,
    SEEKBAR_PANEL_INSET = seekbar_panel_inset or 0,

    SEEKBAR_HEIGHT_NORMAL = theme.height_normal_seekbar or 6,
    SEEKBAR_HEIGHT_HOVER = theme.height_hover_seekbar or 10,
    SEEKBAR_RADIUS = theme.radius_seekbar_osc,
    SEEKBAR_HOVER_RESIZE_MODE = theme.mode_resize_hover_seekbar_osc or "all",
    SEEKBAR_SIDE_INSET = theme.inset_side_seekbar_osc or theme.side_margin or 24,

    BUTTON_LEFT_INSET = theme.inset_left_button_osc or theme.side_margin or 24,
    BUTTON_RIGHT_INSET = theme.inset_right_button_osc or theme.side_margin or 24,
    BUTTON_Y_ANCHOR = (structured_row and structured_row.anchor)
        or theme.anchor_y_button_osc
        or "center",
    BUTTON_ROW_OFFSET = theme.offset_button_row_osc or theme.offset_button_row or 0,

    MAIN_ROW_OFFSET = (structured_row and structured_row.offset)
        or theme.offset_row_main_osc
        or theme.offset_button_row_osc
        or theme.offset_button_row
        or 0,

    OSC_TOP_OFFSET = theme.offset_top_osc
        or theme.offset_button_row_osc
        or theme.offset_button_row
        or 0,
    OSC_CENTER_OFFSET = theme.offset_center_osc
        or theme.offset_button_row_osc
        or theme.offset_button_row
        or 0,
    OSC_BOTTOM_OFFSET = theme.offset_bottom_osc
        or theme.offset_button_row_osc
        or theme.offset_button_row
        or 0,

    BUTTON_GROUP_GAP = theme.gap_button_group_osc,
    BUTTON_GROUP_GAP_LEFT = theme.gap_button_group_left_osc,
    BUTTON_GROUP_GAP_RIGHT = theme.gap_button_group_right_osc,

    BUTTON_GROUP_LAYOUT = {
        left = {
            width = theme.width_button_group_left_osc,
            min_width = theme.width_min_button_group_left_osc,
            max_width = theme.width_max_button_group_left_osc,
            align = theme.align_button_group_left_osc,
        },
        center = {
            width = theme.width_button_group_center_osc,
            min_width = theme.width_min_button_group_center_osc,
            max_width = theme.width_max_button_group_center_osc,
            align = theme.align_button_group_center_osc,
        },
        right = {
            width = theme.width_button_group_right_osc,
            min_width = theme.width_min_button_group_right_osc,
            max_width = theme.width_max_button_group_right_osc,
            align = theme.align_button_group_right_osc,
        },
    },


    ICON_SPACING = theme.spacing_icon_osc or theme.icon_spacing or 36,
    ICON_SIZE = icon_size,

    SEPARATOR_WIDTH = theme.width_separator_osc or 2,
    SEPARATOR_HEIGHT = theme.height_separator_osc
        or math.max(1, math.floor(icon_size * 0.65 + 0.5)),
    SEPARATOR_RADIUS = theme.radius_separator_osc or 1,

    TIME_ITEM_WIDTH = theme.width_time_item_osc or 150,

    SEEKBAR_START_LABEL = theme.label_start_seekbar_osc,
    SEEKBAR_END_LABEL = theme.label_end_seekbar_osc,
    SEEKBAR_EDGE_LABELS = theme.enabled_edge_labels_seekbar_osc ~= false,

    TIME_LABEL_POSITION = theme.position_time_label_osc or "auto",
    TITLE_ITEM_WIDTH = theme.width_title_item_osc or 240,
    TIME_LABEL_OFFSET_Y = theme.offset_y_time_label_osc or 16,
    TIME_LABEL_INLINE_GAP = theme.gap_time_label_inline_osc or 8,

    TIME_LABEL_OUTLINE_WIDTH =
        theme.enabled_outline_time_label_osc
        and (theme.width_outline_time_label_osc or 2)
        or 0,
    TIME_LABEL_OUTLINE_COLOR = common.bgr(theme.color_outline_time_label_osc or "000000"),
    TIME_LABEL_OUTLINE_ALPHA = common.ass_alpha(theme.alpha_outline_time_label_osc or "CF"),
    TIME_LABEL_OUTLINE_BLUR = math.max(theme.blur_outline_time_label_osc or 0, 0),

    TIME_LABEL_SHADOW = theme.enabled_shadow_time_label_osc and 1 or 0,
    TIME_LABEL_SHADOW_X = theme.offset_x_shadow_time_label_osc or 1,
    TIME_LABEL_SHADOW_Y = theme.offset_y_shadow_time_label_osc or 1,
    TIME_LABEL_SHADOW_COLOR = common.bgr(theme.color_shadow_time_label_osc or "000000"),
    TIME_LABEL_SHADOW_ALPHA = common.ass_alpha(theme.alpha_shadow_time_label_osc or "BF"),
    TIME_LABEL_SHADOW_BLUR = math.max(theme.blur_shadow_time_label_osc or 0, 0),

    VOLUME_SLIDER_WIDTH = theme.width_volume_slider_osc or 110,
    SPEED_WHEEL_WIDTH = theme.width_speed_control_wheel_osc or 180,
    VOLUME_SLIDER_HEIGHT = theme.height_volume_slider_osc or 6,
    VOLUME_SLIDER_START_HEIGHT = theme.height_volume_slider_start_osc,
    VOLUME_SLIDER_SHAPE_ALIGN = theme.align_volume_slider_osc or "center",

    VOLUME_SLIDER_THUMB_WIDTH = theme.width_thumb_volume_slider_osc or 4,
    VOLUME_SLIDER_THUMB_HEIGHT = theme.height_thumb_volume_slider_osc or 12,
    VOLUME_SLIDER_THUMB = theme.enabled_thumb_volume_slider_osc ~= false,
    VOLUME_SLIDER_RADIUS = theme.radius_volume_slider_osc or 3,

    VOLUME_SLIDER_COLOR = common.bgr(theme.color_volume_slider_osc or "FFFFFF"),
    VOLUME_SLIDER_COLOR_RGB = theme.color_volume_slider_osc or "FFFFFF",
    VOLUME_SLIDER_COLOR_END = theme.color_end_volume_slider_osc,
    VOLUME_SLIDER_THUMB_COLOR = common.bgr(
        theme.color_thumb_volume_slider_osc
        or theme.color_volume_slider_osc
        or "FFFFFF"
    ),
    VOLUME_SLIDER_TRACK_COLOR = common.bgr(theme.color_track_volume_slider_osc or "444444"),

    VOLUME_SLIDER_MUTE = theme.enabled_mute_volume_slider_osc ~= false,
    VOLUME_SLIDER_MUTE_WIDTH = theme.width_mute_volume_slider_osc or theme.icon_size or 24,
    VOLUME_SLIDER_MUTE_GAP = theme.gap_mute_volume_slider_osc or 8,
    VOLUME_SLIDER_PAD_LEFT = theme.pad_left_volume_slider_osc or 6,
    VOLUME_SLIDER_PAD_RIGHT = theme.pad_right_volume_slider_osc or 6,

    ADD_POPUP_OFFSET_Y = theme.offset_y_add_popup_osc or 0,
    VOLUME_POPUP_OFFSET_Y = theme.offset_y_volume_popup_osc or 0,
    TRACK_POPUP_OFFSET_Y = theme.offset_y_track_popup_osc or 0,

    TRACK_POPUP_BG = common.bgr(
        theme.color_bg_track_popup_osc
        or theme.surface_color_osc
        or theme.surface_color
        or "0D1117"
    ),
    TRACK_POPUP_BG_ALPHA = common.ass_alpha(theme.alpha_bg_track_popup_osc or theme.alpha_panel_bg or "E3"),
    TRACK_POPUP_TEXT = common.bgr(
        theme.color_text_track_popup_osc
        or theme.color_text_osc
        or theme.text_color
        or "F8FAFC"
    ),
    TRACK_POPUP_ACCENT = common.bgr(
        theme.color_accent_track_popup_osc
        or theme.color_track_fg_osc
        or theme.accent_color
        or "63B8FF"
    ),
    TRACK_POPUP_RADIUS = theme.radius_track_popup_osc or 10,

    TRACK_POPUP_BORDER_COLOR = common.bgr(
        theme.color_border_track_popup_osc
        or theme.border_all_color
        or "FFFFFF"
    ),
    TRACK_POPUP_BORDER_ALPHA = common.ass_alpha(theme.alpha_border_track_popup_osc
        or theme.border_all_alpha
        or "E3"),
    TRACK_POPUP_BORDER_WIDTH = theme.width_border_track_popup_osc
        or theme.border_all_width
        or 0,

    TRACK_POPUP_GLASS = theme.enabled_glass_blur_track_popup_osc == nil
        and GLASS_BLUR
        or theme.enabled_glass_blur_track_popup_osc == true,
    TRACK_POPUP_GLASS_RADIUS = theme.radius_glass_blur_track_popup_osc or GLASS_BLUR_RADIUS,

    VOLUME_POPUP_BG = common.bgr(
        theme.color_bg_volume_popup_osc
        or theme.surface_color_osc
        or theme.surface_color
        or "0D1117"
    ),
    VOLUME_POPUP_BG_ALPHA = common.ass_alpha(theme.alpha_bg_volume_popup_osc or theme.alpha_panel_bg or "E3"),
    VOLUME_POPUP_RADIUS = theme.radius_volume_popup_osc or 10,

    VOLUME_POPUP_BORDER_COLOR = common.bgr(
        theme.color_border_volume_popup_osc
        or theme.border_all_color
        or "FFFFFF"
    ),
    VOLUME_POPUP_BORDER_ALPHA = common.ass_alpha(theme.alpha_border_volume_popup_osc
        or theme.border_all_alpha
        or "00"),
    VOLUME_POPUP_BORDER_WIDTH = theme.width_border_volume_popup_osc
        or theme.border_all_width
        or 0,

    VOLUME_POPUP_GLASS = theme.enabled_glass_blur_volume_popup_osc == nil
        and GLASS_BLUR
        or theme.enabled_glass_blur_volume_popup_osc == true,
    VOLUME_POPUP_GLASS_RADIUS = theme.radius_glass_blur_volume_popup_osc or GLASS_BLUR_RADIUS,

    ADD_POPUP_BG = common.bgr(
        theme.color_bg_add_popup_osc
        or theme.surface_color_osc
        or theme.surface_color
        or "0D1117"
    ),
    ADD_POPUP_BG_ALPHA = common.ass_alpha(theme.alpha_bg_add_popup_osc or theme.alpha_panel_bg or "E3"),
    ADD_POPUP_RADIUS = theme.radius_add_popup_osc or 10,

    ADD_POPUP_BORDER_COLOR = common.bgr(
        theme.color_border_add_popup_osc
        or theme.border_all_color
        or "FFFFFF"
    ),
    ADD_POPUP_BORDER_ALPHA = common.ass_alpha(theme.alpha_border_add_popup_osc
        or theme.border_all_alpha
        or "00"),
    ADD_POPUP_BORDER_WIDTH = theme.width_border_add_popup_osc
        or theme.border_all_width
        or 0,

    ADD_POPUP_GLASS = theme.enabled_glass_blur_add_popup_osc == nil
        and GLASS_BLUR
        or theme.enabled_glass_blur_add_popup_osc == true,
    ADD_POPUP_GLASS_RADIUS = theme.radius_glass_blur_add_popup_osc or GLASS_BLUR_RADIUS,

    SETTINGS_BG = common.bgr(
        theme.color_bg_settings_dialog_osc
        or theme.surface_color_osc
        or theme.surface_color
        or "0D1117"
    ),
    SETTINGS_BG_ALPHA = common.ass_alpha(theme.alpha_bg_settings_dialog_osc or "FF"),
    SETTINGS_RADIUS = theme.radius_settings_dialog_osc or 14,

    SETTINGS_BORDER_COLOR = common.bgr(
        theme.color_border_settings_dialog_osc
        or theme.border_all_color
        or "F8FAFC"
    ),
    SETTINGS_BORDER_ALPHA = common.ass_alpha(theme.alpha_border_settings_dialog_osc
        or theme.border_all_alpha
        or "4F"),
    SETTINGS_BORDER_WIDTH = theme.width_border_settings_dialog_osc
        or theme.border_all_width
        or 1,

    SETTINGS_GLASS = theme.enabled_glass_blur_settings_dialog_osc == nil
        and GLASS_BLUR
        or theme.enabled_glass_blur_settings_dialog_osc == true,
    SETTINGS_GLASS_RADIUS = theme.radius_glass_blur_settings_dialog_osc or GLASS_BLUR_RADIUS,

    ICON_BG_ENABLED = theme.enabled_icon_bg_osc or false,
    ICON_BG_COLOR = common.bgr(
        theme.color_bg_icon_osc
        or theme.surface_color
        or "0D1117"
    ),
    ICON_BG_ALPHA = common.ass_alpha(theme.alpha_bg_icon_osc or "DF"),
    ICON_BG_PAD_X = theme.pad_x_bg_icon_osc
        or math.max(0, (icon_bg_width - icon_size) / 2),
    ICON_BG_HEIGHT = icon_bg_height,
    ICON_BG_RADIUS = theme.radius_bg_icon_osc or 0,

    ICON_BORDER_ENABLED = theme.enabled_border_icon_osc or false,
    ICON_BORDER_COLOR = common.bgr(theme.color_border_icon_osc or "FFFFFF"),
    ICON_BORDER_ALPHA = common.ass_alpha(theme.alpha_border_icon_osc or "00"),
    ICON_BORDER_WIDTH = theme.width_border_icon_osc or 1,

    ICON_GROUP_BG_ENABLED = theme.enabled_bg_icon_group_osc or false,
    ICON_GROUP_BG_COLOR = common.bgr(
        theme.color_bg_icon_group_osc
        or theme.surface_color
        or "0D1117"
    ),
    ICON_GROUP_BG_ALPHA = common.ass_alpha(theme.alpha_bg_icon_group_osc or "BF"),
    ICON_GROUP_BG_PADDING = theme.pad_bg_icon_group_osc or 8,
    ICON_GROUP_BG_HEIGHT = theme.height_bg_icon_group_osc
        or (icon_bg_height + 16),
    ICON_GROUP_BG_RADIUS = theme.radius_bg_icon_group_osc or 0,

    ICON_GROUP_BORDER_ENABLED = theme.enabled_border_icon_group_osc or false,
    ICON_GROUP_BORDER_COLOR = common.bgr(theme.color_border_icon_group_osc or "FFFFFF"),
    ICON_GROUP_BORDER_ALPHA = common.ass_alpha(theme.alpha_border_icon_group_osc or "00"),
    ICON_GROUP_BORDER_WIDTH = theme.width_border_icon_group_osc or 1,

    ICON_OUTLINE_ENABLED = theme.enabled_outline_icon_osc or false,
    ICON_OUTLINE_COLOR = common.bgr(theme.color_outline_icon_osc or "000000"),
    ICON_OUTLINE_ALPHA = common.ass_alpha(theme.alpha_outline_icon_osc or "FF"),
    ICON_OUTLINE_WIDTH = theme.width_outline_icon_osc or 1,
    ICON_OUTLINE_BLUR = math.max(theme.blur_outline_icon_osc or 0, 0),

    ICON_SHADOW_ENABLED = theme.enabled_shadow_icon_osc or false,
    ICON_SHADOW_COLOR = common.bgr(theme.color_shadow_icon_osc or "000000"),
    ICON_SHADOW_ALPHA = common.ass_alpha(theme.alpha_shadow_icon_osc or "BF"),
    ICON_SHADOW_X = theme.offset_x_shadow_icon_osc or 1,
    ICON_SHADOW_Y = theme.offset_y_shadow_icon_osc or 1,
    ICON_SHADOW_BLUR = math.max(theme.blur_shadow_icon_osc or 0, 0),


    CHAPTER_TOOLTIP_FONT = theme.font_chapter_tooltip or theme.font_text or "Inter",
    CHAPTER_TOOLTIP_FONT_SIZE = theme.chapter_tooltip_size or 18,
    CHAPTER_TOOLTIP_FONT_COLOR = common.bgr(theme.chapter_tooltip_text_color or "FFFFFF"),
    CHAPTER_TOOLTIP_FONT_ALPHA = common.ass_alpha(theme.chapter_tooltip_text_alpha or "FF"),

    CHAPTER_MARK_COLOR = common.bgr(
        theme.color_chapter_mark
        or theme.background_color
        or "0A0C10"
    ),
    CHAPTER_MARK_ALPHA = common.ass_alpha(theme.alpha_chapter_mark or "00"),
    CHAPTER_MARK_W = theme.chapter_mark_width or 2,
    CHAPTER_HOVER_PX = theme.chapter_hover_px or 8,

    CHAPTER_TOOLTIP_OFFSET_Y = theme.offset_y_chapter_tooltip_osc
        or theme.chapter_tooltip_offset_y
        or 0,
    CHAPTER_TOOLTIP_BG_COLOR = common.bgr(
        theme.chapter_tooltip_bg_color
        or theme.background_color
        or "0A0C10"
    ),
    CHAPTER_TOOLTIP_BG_ALPHA = common.ass_alpha(theme.chapter_tooltip_bg_alpha or "FF"),
    CHAPTER_TOOLTIP_RADIUS = theme.chapter_tooltip_radius or 8,
    CHAPTER_TOOLTIP_PAD_X = theme.chapter_tooltip_pad_x or 8,
    CHAPTER_TOOLTIP_PAD_Y = theme.chapter_tooltip_pad_y or 10,

    CHAPTER_TOOLTIP = theme.enabled_chapter_tooltip_osc ~= false,
    BUTTON_TOOLTIP = theme.enabled_button_tooltip_osc or false,
    SEEKBAR_TIME_TOOLTIP = theme.enabled_time_tooltip_seekbar_osc ~= false,

    SEEKBAR_TIME_TOOLTIP_FONT = theme.font_time_tooltip_seekbar_osc
        or theme.font_chapter_tooltip
        or theme.font_text
        or "Inter",
    SEEKBAR_TIME_TOOLTIP_SIZE = theme.size_font_time_tooltip_seekbar_osc
        or theme.chapter_tooltip_size
        or 18,
    SEEKBAR_TIME_TOOLTIP_COLOR = common.bgr(
        theme.color_text_time_tooltip_seekbar_osc
        or theme.chapter_tooltip_text_color
        or "FFFFFF"
    ),
    SEEKBAR_TIME_TOOLTIP_ALPHA = common.ass_alpha(theme.alpha_text_time_tooltip_seekbar_osc
        or theme.chapter_tooltip_text_alpha
        or "FF"),
    SEEKBAR_TIME_TOOLTIP_OFFSET_Y = theme.offset_y_time_tooltip_seekbar_osc
        or theme.offset_y_chapter_tooltip_osc
        or theme.chapter_tooltip_offset_y
        or 0,
    SEEKBAR_TIME_TOOLTIP_BG_COLOR = common.bgr(
        theme.color_bg_time_tooltip_seekbar_osc
        or theme.chapter_tooltip_bg_color
        or theme.background_color
        or "0A0C10"
    ),
    SEEKBAR_TIME_TOOLTIP_BG_ALPHA = common.ass_alpha(theme.alpha_bg_time_tooltip_seekbar_osc
        or theme.chapter_tooltip_bg_alpha
        or "FF"),
    SEEKBAR_TIME_TOOLTIP_RADIUS = theme.radius_time_tooltip_seekbar_osc
        or theme.chapter_tooltip_radius
        or 8,
    SEEKBAR_TIME_TOOLTIP_PAD_X = theme.pad_x_time_tooltip_seekbar_osc
        or theme.chapter_tooltip_pad_x
        or 8,
    SEEKBAR_TIME_TOOLTIP_PAD_Y = theme.pad_y_time_tooltip_seekbar_osc
        or theme.chapter_tooltip_pad_y
        or 10,

    TITLE_ENABLED = theme.enabled_title_osc == true,
    TITLE_POSITION = theme.position_title_osc or "below_seekbar",
    TITLE_ALIGN = theme.align_title_osc,

    TITLE_FONT = theme.font_title_osc
        or theme.font_ui
        or theme.font_text
        or "Inter",
    TITLE_SIZE = theme.size_font_title_osc
        or theme.size_font_osc
        or theme.font_size
        or 16,
    TITLE_COLOR = common.bgr(
        theme.color_title_osc
        or theme.color_text_osc
        or theme.text_color
        or "F8FAFC"
    ),
    TITLE_ALPHA = common.ass_alpha(theme.alpha_title_osc or "FF"),
    TITLE_GAP = theme.gap_title_osc or 4,
    TITLE_SEEKBAR_GAP = theme.gap_title_seekbar_osc,
    TITLE_SIDE_INSET = theme.inset_side_title_osc or theme.side_margin or 24,

    TITLE_OUTLINE_WIDTH =
        theme.enabled_outline_title_osc
        and (theme.width_outline_title_osc or 2)
        or 0,
    TITLE_OUTLINE_COLOR = common.bgr(theme.color_outline_title_osc or "000000"),
    TITLE_OUTLINE_ALPHA = common.ass_alpha(theme.alpha_outline_title_osc or "CF"),
    TITLE_OUTLINE_BLUR = math.max(theme.blur_outline_title_osc or 0, 0),

    TITLE_SHADOW = theme.enabled_shadow_title_osc and 1 or 0,
    TITLE_SHADOW_X = theme.offset_x_shadow_title_osc or 1,
    TITLE_SHADOW_Y = theme.offset_y_shadow_title_osc or 1,
    TITLE_SHADOW_COLOR = common.bgr(theme.color_shadow_title_osc or "000000"),
    TITLE_SHADOW_ALPHA = common.ass_alpha(theme.alpha_shadow_title_osc or "BF"),
    TITLE_SHADOW_BLUR = math.max(theme.blur_shadow_title_osc or 0, 0),

    PIP_SCALE = theme.scale_pip_osc or 0.35,
    PIP_MARGIN = theme.margin_pip_osc or 20,
    SHOW_PANEL_ON_PAUSE = theme.show_panel_on_pause ~= false,
}
if cfg.SEEKBAR_START_LABEL == nil then
    cfg.SEEKBAR_START_LABEL = cfg.SEEKBAR_EDGE_LABELS
end
if cfg.SEEKBAR_END_LABEL == nil then
    cfg.SEEKBAR_END_LABEL = cfg.SEEKBAR_EDGE_LABELS
end
cfg.TITLE_SEEKBAR_GAP = cfg.TITLE_SEEKBAR_GAP
    or math.max(cfg.TITLE_GAP, cfg.THUMB_WH + 2)
end
apply_theme(theme)

function parse_group_width(value, key)
    if value == nil then
        return nil
    end
    if type(value) == "number" and value >= 0 then
        return {pixels = value}
    end
    if type(value) == "string" then
        local percent = value:match("^%s*(%d+%.?%d*)%%%s*$")
        if percent then
            return {ratio = tonumber(percent) / 100}
        end
    end
    msg.warn("cadre_osc: " .. key .. " must be a non-negative number or percentage; ignoring it")
    return nil
end

function resolve_group_width(value, available_width)
    if not value then
        return nil
    end
    return value.pixels or value.ratio * available_width
end

normalize_group_widths = function()
    for group, layout in pairs(cfg.BUTTON_GROUP_LAYOUT) do
        local prefix = "button_group_" .. group
        layout.width = parse_group_width(layout.width, prefix .. "_width_osc")
        layout.min_width = parse_group_width(layout.min_width, prefix .. "_min_width_osc")
        layout.max_width = parse_group_width(layout.max_width, prefix .. "_max_width_osc")
        layout.has_custom_width = layout.width ~= nil or layout.min_width ~= nil or layout.max_width ~= nil
        if layout.align == nil then
            layout.align = group == "left" and "start" or group == "right" and "end" or "center"
        elseif layout.align ~= "start" and layout.align ~= "center" and layout.align ~= "end" then
            msg.warn("cadre_osc: " .. prefix .. "_align_osc must be 'start', 'center', or 'end'; using the default")
            layout.align = group == "left" and "start" or group == "right" and "end" or "center"
        end
    end
end
normalize_group_widths()

cfg.TIME_LABEL_POSITION = type(cfg.TIME_LABEL_POSITION) == "string"
    and string.lower(cfg.TIME_LABEL_POSITION) or "auto"
if cfg.TIME_LABEL_POSITION == "same_level" then
    cfg.TIME_LABEL_POSITION = "inline"
end
if cfg.TIME_LABEL_POSITION ~= "auto" and
    cfg.TIME_LABEL_POSITION ~= "above_seekbar" and
    cfg.TIME_LABEL_POSITION ~= "below_seekbar" and
    cfg.TIME_LABEL_POSITION ~= "inline" then
    cfg.TIME_LABEL_POSITION = "auto"
end
if cfg.SEEKBAR_RADIUS ~= nil and
    (type(cfg.SEEKBAR_RADIUS) ~= "number" or cfg.SEEKBAR_RADIUS < 0
        or cfg.SEEKBAR_RADIUS ~= cfg.SEEKBAR_RADIUS or cfg.SEEKBAR_RADIUS == math.huge) then
    msg.warn("cadre_osc: radius_seekbar_osc must be a non-negative number; using the pill radius")
    cfg.SEEKBAR_RADIUS = nil
end
cfg.SEEKBAR_HOVER_RESIZE_MODE = type(cfg.SEEKBAR_HOVER_RESIZE_MODE) == "string"
    and string.lower(cfg.SEEKBAR_HOVER_RESIZE_MODE) or "all"
if cfg.SEEKBAR_HOVER_RESIZE_MODE ~= "all" and cfg.SEEKBAR_HOVER_RESIZE_MODE ~= "segment" then
    msg.warn("cadre_osc: hover_resize_mode_seekbar_osc must be 'all' or 'segment'; using 'all'")
    cfg.SEEKBAR_HOVER_RESIZE_MODE = "all"
end
if type(cfg.TIME_LABEL_INLINE_GAP) ~= "number" or cfg.TIME_LABEL_INLINE_GAP < 0
    or cfg.TIME_LABEL_INLINE_GAP ~= cfg.TIME_LABEL_INLINE_GAP or cfg.TIME_LABEL_INLINE_GAP == math.huge then
    msg.warn("cadre_osc: time_label_inline_gap_osc must be a non-negative number; using 8")
    cfg.TIME_LABEL_INLINE_GAP = 8
end
if type(cfg.PIP_SCALE) ~= "number" or cfg.PIP_SCALE <= 0 or cfg.PIP_SCALE >= 1 then
    msg.warn("cadre_osc: osc_pip_scale must be between 0 and 1; using 0.35")
    cfg.PIP_SCALE = 0.35
end
if type(cfg.PIP_MARGIN) ~= "number" or cfg.PIP_MARGIN < 0 then
    msg.warn("cadre_osc: osc_pip_margin must be a non-negative number; using 20")
    cfg.PIP_MARGIN = 20
end
title_positions = {
    up = "above_seekbar",
    above = "above_seekbar",
    above_seekbar = "above_seekbar",
    below = "below_seekbar",
    below_seekbar = "below_seekbar",
    above_osc = "above_osc",
    below_osc = "below_osc",
    above_buttons = "above_osc",
    below_buttons = "below_osc",
}
title_legacy_align = {
    left = "left",
    right = "right",
    middle = "center",
    center = "center",
}
raw_title_position = string.lower(tostring(cfg.TITLE_POSITION))
cfg.TITLE_POSITION = title_positions[raw_title_position] or "below_seekbar"
cfg.TITLE_ALIGN = title_legacy_align[raw_title_position]
    or (type(cfg.TITLE_ALIGN) == "string" and string.lower(cfg.TITLE_ALIGN))
    or "center"
if cfg.TITLE_ALIGN ~= "left" and cfg.TITLE_ALIGN ~= "right" and cfg.TITLE_ALIGN ~= "center" then
    cfg.TITLE_ALIGN = "center"
end
if cfg.SEEKBAR_POSITION == "panel_top" then
    cfg.SEEKBAR_POSITION = "top"
end
if cfg.SEEKBAR_POSITION ~= "above_buttons" and cfg.SEEKBAR_POSITION ~= "below_buttons"
    and cfg.SEEKBAR_POSITION ~= "panel_bottom" then
    cfg.SEEKBAR_POSITION = "top"
end
if type(cfg.BUTTON_Y_ANCHOR) == "string" then
    cfg.BUTTON_Y_ANCHOR = string.lower(cfg.BUTTON_Y_ANCHOR)
end
if cfg.BUTTON_Y_ANCHOR ~= "top" and
    cfg.BUTTON_Y_ANCHOR ~= "center" and
    cfg.BUTTON_Y_ANCHOR ~= "bottom" then
    cfg.BUTTON_Y_ANCHOR = "top"
end
--------------------------------------------------------------------------------
-- YOUTUBE CHAPTER LOADER
--------------------------------------------------------------------------------

chapters_load_pending = false

function load_youtube_chapters()
    if chapters_load_pending then
        return -- Already loading
    end
    local path = mp.get_property("path")
    if not path then
        return
    end
    if not (path:find("youtube%.com") or path:find("youtu%.be")) then
        return
    end
    chapters_load_pending = true
    mp.command_native_async(
        {
            name = "subprocess",
            playback_only = false,
            capture_stdout = true,
            args = {"yt-dlp", "-J", "--no-warnings", "--quiet", path}
        },
        function(success, result)
            chapters_load_pending = false
            if not success or not result or result.status ~= 0 or not result.stdout then
                msg.warn("yt-dlp failed or returned no data")
                return
            end
            local json = utils.parse_json(result.stdout)
            if json and json.chapters then
                local yt_chapters = {}
                for i, ch in ipairs(json.chapters) do
                    yt_chapters[#yt_chapters + 1] = {
                        time = ch.start_time,
                        title = ch.title or ("Chapter " .. i)
                    }
                end
                if #yt_chapters > 0 then
                    mp.set_property_native("chapter-list", yt_chapters)
                end
            end
        end
    )
end

mp.register_script_message("load-chapters-if-needed", function()
    local existing = mp.get_property_native("chapter-list", {})
    if #existing == 0 then
        load_youtube_chapters()
    end
end)

--------------------------------------------------------------------------------
-- STATE
--------------------------------------------------------------------------------

osd = mp.create_osd_overlay("ass-events")
-- Keep OSC dialogs above the playlist overlay, which uses mpv's default z=0.
osd.z = 2
render_ctrl = common.render_controller(osd)
chapter_tooltip_osd = mp.create_osd_overlay("ass-events")
chapter_tooltip_osd.z = 3
chapter_tooltip_render_ctrl = common.render_controller(chapter_tooltip_osd)
screen_w, screen_h = mp.get_osd_size()
osd.res_x = screen_w
osd.res_y = screen_h
mouse_x, mouse_y = -1, -1
playlist_mouse_relayed = false

bar_visible = true
bar_pinned = false
pip_state = nil
hide_timer = nil
file_loaded = false

duration, position = 0, 0
media_title = mp.get_property("media-title") or mp.get_property("filename/no-ext") or ""
function display_media_title()
    if media_title ~= "" then
        return media_title
    end
    return mp.get_property("filename/no-ext") or "No file"
end
paused = true
idle_active = true
muted = false
volume = 100

volume_popup_open = false
speed_popup_open = false
speed_popup_slot = nil
speed_popup_geo = nil
speed_zero_selected = false
speed_inline_dragging = false
speed_inline_start_x = 0
speed_inline_start_index = 1
speed_inline_last_index = -1
speed_inline_spacing = 20
speed_inline_click_index = nil
last_speed_wheel_bounds_key = nil
speed_dragging = false
speed_drag_start_x = 0
speed_drag_start_value = 1
speed_click_value = nil
speed_click_index = nil
speed_drag_start_index = 4
speed_drag_last_index = -1
add_menu_open = false
track_popup_open = false
track_popup_type = nil
track_popup_slot = nil
track_popup_geo = nil
track_popup_scroll = 0
track_popup_max_scroll = 0
volume_popup_slot = nil
add_menu_slot = nil
settings_menu_open = false
volume_dragging = false
volume_slider_dragging = false
seekbar_dragging = false
hitboxes = {}
active_ass = nil
popup_geo = nil
add_menu_geo = nil
settings_menu_geo = nil
chapters = {}
hovered_chapter = nil
settings_menu_scroll = 0
settings_menu_max_scroll = 0
last_subtitle_sid = nil
last_osc_hover = nil
settings_track_list_mode = nil
settings_active_tab = nil
render_timer = nil

--------------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------------

function fmt_time(t)
    if not t or t ~= t or t < 0 then
        return "00:00"
    end
    t = math.floor(t)
    local h = math.floor(t / 3600)
    local m = math.floor((t % 3600) / 60)
    local s = t % 60
    if h > 0 then
        return string.format("%d:%02d:%02d", h, m, s)
    end
    return string.format("%02d:%02d", m, s)
end

function utf8_char_count(str)
    local _, count = str:gsub("[^\128-\191]", "")
    return count
end

function add_hitbox(name, x1, y1, x2, y2, cb)
    local popup_action = name:match("^addmenu")
        or name:match("^track_popup_row")
        or name == "track_popup_subs_search"
        or name == "track_popup_livecap_toggle"
        or name:match("^set")
    if active_ass and popup_action then
        common.draw_hover_rrect(active_ass, x1, y1, x2, y2, 6,
            cfg.POPUP_HOVER_COLOR, cfg.POPUP_HOVER_ALPHA,
            mouse_x >= x1 and mouse_x <= x2 and mouse_y >= y1 and mouse_y <= y2)
    end
    common.add_hitbox(hitboxes, name, x1, y1, x2, y2, cb)
end
function settings_control_hovered(x1, y1, x2, y2)
    return mouse_x >= x1 and mouse_x <= x2 and mouse_y >= y1 and mouse_y <= y2
end
function point_in(px, py, b)
    return common.point_in(px, py, b)
end
function draw_icon(ass, glyph, cx, cy, size, color, alpha, effects)
    common.draw_icon(ass, cfg.ICON_FONT, glyph, cx, cy, size, color, alpha, effects)
end

function draw_effect_text(ass, text, x, y, align, font, size, color, alpha,
    outline_color, outline_alpha, outline_width, outline_blur,
    shadow, shadow_x, shadow_y, shadow_color, shadow_alpha, shadow_blur)
    if outline_blur > 0 or shadow_blur > 0 then
        if shadow and shadow_alpha ~= "FF" then
            ass:new_event()
            ass:append(string.format(
                "{\\pos(%d,%d)\\an%d\\fn%s\\fs%d\\1a&HFF&\\3a&HFF&\\4c&H%s&\\4a&H%s&\\bord0\\shad1\\xshad%d\\yshad%d\\blur%g\\b0}%s",
                x, y, align, font, size, shadow_color, shadow_alpha, shadow_x, shadow_y, shadow_blur, text
            ))
        end
        if outline_width > 0 and outline_alpha ~= "FF" then
            ass:new_event()
            ass:append(string.format(
                "{\\pos(%d,%d)\\an%d\\fn%s\\fs%d\\1a&HFF&\\3c&H%s&\\3a&H%s&\\bord%d\\shad0\\blur%g\\b0}%s",
                x, y, align, font, size, outline_color, outline_alpha, outline_width, outline_blur, text
            ))
        end
        ass:new_event()
        ass:append(string.format(
            "{\\pos(%d,%d)\\an%d\\fn%s\\fs%d\\1c&H%s&\\1a&H%s&\\bord0\\shad0\\b0}%s",
            x, y, align, font, size, color, alpha, text
        ))
        return
    end
    ass:new_event()
    ass:append(string.format(
        "{\\pos(%d,%d)\\an%d\\fn%s\\fs%d\\1c&H%s&\\1a&H%s&\\3c&H%s&\\3a&H%s&\\bord%d\\shad%d\\xshad%d\\yshad%d\\4c&H%s&\\4a&H%s&\\b0}%s",
        x, y, align, font, size, color, alpha, outline_color, outline_alpha, outline_width,
        shadow and 1 or 0, shadow_x, shadow_y, shadow_color, shadow_alpha, text
    ))
end

function draw_time_label(ass, text, x, y, align, font_size, color)
    draw_effect_text(ass, text, x, y, align, cfg.UI_FONT, font_size or cfg.FONT_SIZE,
        color or cfg.TEXT, "10", cfg.TIME_LABEL_OUTLINE_COLOR, cfg.TIME_LABEL_OUTLINE_ALPHA,
        cfg.TIME_LABEL_OUTLINE_WIDTH, cfg.TIME_LABEL_OUTLINE_BLUR, cfg.TIME_LABEL_SHADOW > 0,
        cfg.TIME_LABEL_SHADOW_X, cfg.TIME_LABEL_SHADOW_Y, cfg.TIME_LABEL_SHADOW_COLOR,
        cfg.TIME_LABEL_SHADOW_ALPHA, cfg.TIME_LABEL_SHADOW_BLUR)
end

function draw_volume_slider(ass, x, y, style, icon_style)
    style = style or {}
    local slider_width = cfg.VOLUME_SLIDER_WIDTH

    local slider_x1

    if cfg.VOLUME_SLIDER_MUTE then
        local mute_width = math.max(cfg.VOLUME_SLIDER_MUTE_WIDTH, style.icon_size or 0)
        local total_item_width =
            mute_width + cfg.VOLUME_SLIDER_MUTE_GAP + slider_width +
			cfg.VOLUME_SLIDER_PAD_LEFT + cfg.VOLUME_SLIDER_PAD_RIGHT

        local mute_x = x - total_item_width / 2 + mute_width / 2 + cfg.VOLUME_SLIDER_PAD_LEFT

        draw_icon(
            ass,
            muted and ICON.volume_off or ICON.volume_up,
            mute_x,
            y,
            style.icon_size or cfg.ICON_SIZE,
            style.icon_color and common.bgr(style.icon_color) or cfg.ICON_COLOR,
            "00",
            icon_style
        )

        slider_x1 = x + total_item_width / 2 - slider_width - cfg.VOLUME_SLIDER_PAD_RIGHT
    else
        local total_item_width = slider_width + cfg.VOLUME_SLIDER_PAD_LEFT + cfg.VOLUME_SLIDER_PAD_RIGHT

        slider_x1 = x - total_item_width / 2 + cfg.VOLUME_SLIDER_PAD_LEFT
    end

    local slider_x2 = slider_x1 + slider_width

    local ratio = math.min(1, math.max(0, volume / 100))
    local thumb_x = slider_x1 + (slider_x2 - slider_x1) * ratio

    local start_height = cfg.VOLUME_SLIDER_START_HEIGHT
    if start_height == nil then start_height = cfg.VOLUME_SLIDER_HEIGHT end
    local end_height = cfg.VOLUME_SLIDER_HEIGHT
    start_height = math.max(0, start_height)
    end_height = math.max(0, end_height)
    if start_height == 0 and end_height == 0 then start_height, end_height = 0, cfg.VOLUME_SLIDER_HEIGHT end
    local max_height = math.max(start_height, end_height)
    local align = cfg.VOLUME_SLIDER_SHAPE_ALIGN
    if align ~= "top" and align ~= "bottom" then align = "center" end
    local function edges(px)
        local t = math.min(1, math.max(0, (px - slider_x1) / slider_width))
        local h = start_height + (end_height - start_height) * t
        if align == "bottom" then return y + max_height / 2 - h, y + max_height / 2 end
        if align == "top" then return y - max_height / 2, y - max_height / 2 + h end
        return y - h / 2, y + h / 2
    end
    local function slice(x1, x2, color)
        if x2 <= x1 then return end
        local mid = (x1 + x2) / 2
        local top, bottom = edges(mid)
        if bottom <= top then return end
        common.draw_rrect(ass, x1, top, x2, bottom, 0, color, "00")
    end
    local tapered = start_height ~= end_height
    if not tapered and not cfg.VOLUME_SLIDER_COLOR_END then
        local top, bottom = edges(slider_x1)
        common.draw_rrect(ass, slider_x1, top, slider_x2, bottom,
            cfg.VOLUME_SLIDER_RADIUS, cfg.VOLUME_SLIDER_TRACK_COLOR, "00")
        if thumb_x > slider_x1 then
            common.draw_rrect(ass, slider_x1, top, thumb_x, bottom,
                cfg.VOLUME_SLIDER_RADIUS, cfg.VOLUME_SLIDER_COLOR, "00")
        end
    else
        local start_rgb = cfg.VOLUME_SLIDER_COLOR_RGB
        local end_rgb = cfg.VOLUME_SLIDER_COLOR_END or start_rgb
        local function color_at(t)
            local out = {}
            for i = 1, 6, 2 do
                local a = tonumber(start_rgb:sub(i, i + 1), 16) or 255
                local b = tonumber(end_rgb:sub(i, i + 1), 16) or a
                out[#out + 1] = string.format("%02X", math.floor(a + (b - a) * t + 0.5))
            end
            return common.bgr(table.concat(out))
        end
        local bands = math.max(1, math.ceil(cfg.VOLUME_SLIDER_WIDTH))
        for i = 0, bands - 1 do
            local xa = slider_x1 + cfg.VOLUME_SLIDER_WIDTH * i / bands
            local xb = slider_x1 + cfg.VOLUME_SLIDER_WIDTH * (i + 1) / bands
            slice(xa, xb + 0.2, cfg.VOLUME_SLIDER_TRACK_COLOR)
        end
        for i = 0, bands - 1 do
            local xa = slider_x1 + cfg.VOLUME_SLIDER_WIDTH * i / bands
            local xb = slider_x1 + cfg.VOLUME_SLIDER_WIDTH * (i + 1) / bands
            local fill_xb = math.min(thumb_x, xb)
            if fill_xb > xa then slice(xa, fill_xb + 0.2, color_at((i + 0.5) / bands)) end
        end
    end

    local top, bottom = edges(thumb_x)
    local thumb_y = (top + bottom) / 2

    if cfg.VOLUME_SLIDER_THUMB then
        common.draw_rrect(
            ass,
            thumb_x - cfg.VOLUME_SLIDER_THUMB_WIDTH,
            thumb_y - cfg.VOLUME_SLIDER_THUMB_HEIGHT,
            thumb_x + cfg.VOLUME_SLIDER_THUMB_WIDTH,
            thumb_y + cfg.VOLUME_SLIDER_THUMB_HEIGHT,
            cfg.VOLUME_SLIDER_THUMB_WIDTH,
            cfg.VOLUME_SLIDER_THUMB_COLOR,
            "00"
        )
    end
end

function mix_hex(first, last, ratio)
    local result = {}
    for index = 1, 6, 2 do
        local a = tonumber(first:sub(index, index + 1), 16) or 0
        local b = tonumber(last:sub(index, index + 1), 16) or 0
        result[#result + 1] = string.format("%02X", math.floor(a + (b - a) * ratio + 0.5))
    end
    return table.concat(result)
end

function draw_gradient_rrect(ass, x1, y1, x2, y2, radius, color, end_color, gradient_type, alpha)
    if not end_color or end_color == color or not gradient_type then
        return common.draw_rrect(ass, x1, y1, x2, y2, radius, color, alpha)
    end
    local width, height = math.max(1, x2 - x1), math.max(1, y2 - y1)
    if gradient_type == "circular" then
        -- Nested ellipses approximate a radial gradient without leaving the
        -- rectangular background shape. Larger ellipses are painted first.
        local bands = math.max(48, math.min(96, math.ceil(math.max(width, height))))
        common.draw_rrect(ass, x1, y1, x2, y2, radius, end_color, alpha)
        local cx, cy = (x1 + x2) / 2, (y1 + y2) / 2
        for index = 1, bands do
            -- Paint the largest ellipse first, then layer smaller ellipses
            -- toward the center so each pass leaves the outer colors visible.
            local scale = 1 - (index - 1) / bands
            local half_w, half_h = width / 2 * scale, height / 2 * scale
            local c = mix_hex(end_color, color, index / bands)
            common.draw_rrect(ass, cx - half_w, cy - half_h, cx + half_w, cy + half_h,
                radius * scale, c, alpha)
        end
        return
    end
    -- Use one band per logical pixel along the gradient axis. Subpixel bands
    -- with alpha clips can leave visible seams that look like fence stripes.
    local extent = gradient_type == "top_to_bottom" and height or width
    local bands = math.max(1, math.min(128, math.ceil(extent)))
    for index = 1, bands do
        local t1, t2 = (index - 1) / bands, index / bands
        local bx1, by1, bx2, by2
        if gradient_type == "top_to_bottom" then
            bx1, bx2 = x1, x2
            by1 = index == 1 and y1 or math.floor(y1 + height * t1 + 0.5)
            by2 = index == bands and y2 or math.floor(y1 + height * t2 + 0.5)
        else
            bx1 = index == 1 and x1 or math.floor(x1 + width * t1 + 0.5)
            bx2 = index == bands and x2 or math.floor(x1 + width * t2 + 0.5)
            by1, by2 = y1, y2
        end
        if bx2 > bx1 and by2 > by1 then
            local start = #ass.text
            common.draw_rrect(ass, x1, y1, x2, y2, radius,
                mix_hex(color, end_color, (t1 + t2) / 2), alpha)
            local added = ass.text:sub(start + 1)
            added = added:gsub("{", string.format("{\\clip(%.2f,%.2f,%.2f,%.2f)", bx1, by1, bx2, by2), 1)
            ass.text = ass.text:sub(1, start) .. added
        end
    end
end

function draw_rrect_outline(ass, x1, y1, x2, y2, radius, color, alpha, width)
    if not width or width <= 0 or alpha == "FF" then
        return
    end
    ass:new_event()
    ass:append(string.format("{\\pos(0,0)\\an7\\1a&HFF&\\3c&H%s&\\3a&H%s&\\bord%g\\shad0}", color, alpha, width))
    ass:draw_start()
    ass:round_rect_cw(x1, y1, x2, y2, radius)
    ass:draw_stop()
end

function draw_sided_border(ass, x1, y1, x2, y2, radius, color, alpha, width, sides)
    if type(sides) ~= "table" then
        return draw_rrect_outline(ass, x1, y1, x2, y2, radius, color, alpha, width)
    end
    if not width or width <= 0 or alpha == "FF" then return end
    ass:new_event()
    ass:append(string.format("{\\pos(0,0)\\an7\\1a&HFF&\\3c&H%s&\\3a&H%s&\\bord%g\\shad0}", color, alpha, width))
    ass:draw_start()
    if sides.top then ass:move_to(x1, y1); ass:line_to(x2, y1) end
    if sides.right then ass:move_to(x2, y1); ass:line_to(x2, y2) end
    if sides.bottom then ass:move_to(x2, y2); ass:line_to(x1, y2) end
    if sides.left then ass:move_to(x1, y2); ass:line_to(x1, y1) end
    ass:draw_stop()
end

function item_decoration_bounds(cx, cy, content_w, style)
    style = style or {}
    local background = style.background and style.alpha ~= "FF"
    local border = style.border and style.border_width > 0 and style.border_alpha ~= "FF"
    local decoration_visible = background or border
    local pad = decoration_visible and style.padding or 0
    local border_width = border and style.border_width or 0
    local x1 = cx - (content_w / 2 + pad)
    local x2 = cx + (content_w / 2 + pad)
    local y1 = decoration_visible and cy - style.height / 2 or cy
    local y2 = decoration_visible and cy + style.height / 2 or cy

    return {
        background = background,
        border = border,
        x1 = x1,
        y1 = y1,
        x2 = x2,
        y2 = y2,
        visual_x1 = x1 - border_width,
        visual_y1 = y1 - border_width,
        visual_x2 = x2 + border_width,
        visual_y2 = y2 + border_width,
        horizontal_pad = pad + border_width,
    }
end

function draw_item_background(ass, cx, cy, content_w, style)
    style = style or {}
    local bounds = item_decoration_bounds(cx, cy, content_w, style)
    if not bounds.background then
        return
    end
    draw_gradient_rrect(
        ass,
        bounds.x1,
        bounds.y1,
        bounds.x2,
        bounds.y2,
        style.radius,
        style.color,
        style.gradient_color,
        style.gradient_type,
        style.alpha
    )
end

function draw_item_border(ass, cx, cy, content_w, style)
    style = style or {}
    local bounds = item_decoration_bounds(cx, cy, content_w, style)
    if not bounds.border then
        return
    end
    draw_sided_border(
        ass,
        bounds.x1,
        bounds.y1,
        bounds.x2,
        bounds.y2,
        style.radius,
        style.border_color,
        style.border_alpha,
        style.border_width,
        style.border_sides
    )
end

function group_decoration_bounds(buttons, row_y, group_bounds, group, style)
    if #buttons == 0 then
        return nil
    end
    style = style or {}
    local background = style.background and style.alpha ~= "FF"
    local border = style.border and style.border_width > 0 and style.border_alpha ~= "FF"
    if not background and not border then
        return nil
    end

    local x1, x2
    if style.width then
        local width = resolve_group_width(style.width, screen_w)
        if group == "left" then
            x1, x2 = 0, width
        elseif group == "right" then
            x1, x2 = screen_w - width, screen_w
        else
            x1, x2 = (screen_w - width) / 2, (screen_w + width) / 2
        end
    elseif group_bounds and cfg.BUTTON_GROUP_LAYOUT[group].has_custom_width then
        x1 = group_bounds.x1
        x2 = group_bounds.x2
    else
        x1 = math.huge
        x2 = -math.huge
        for _, button in ipairs(buttons) do
            local button_padding = button.group_style and button.group_style.button.padding or 0
            x1 = math.min(x1, button.x - button.width / 2 - button_padding)
            x2 = math.max(x2, button.x + button.width / 2 + button_padding)
        end
    end
    x1 = x1 - style.padding
    x2 = x2 + style.padding
    local y1 = row_y - style.height / 2
    local y2 = row_y + style.height / 2
    local border_width = border and style.border_width or 0

    return {
        background = background,
        border = border,
        x1 = x1,
        y1 = y1,
        x2 = x2,
        y2 = y2,
        visual_x1 = x1 - border_width,
        visual_y1 = y1 - border_width,
        visual_x2 = x2 + border_width,
        visual_y2 = y2 + border_width,
    }
end

function group_buttons_by_y(buttons, fallback_y)
    local rows = {}
    for _, button in ipairs(buttons) do
        local y = button.y or fallback_y
        local group_style_key = button.group_style_key or button.group
        local row
        for _, candidate in ipairs(rows) do
            if candidate.y == y and candidate.group_style_key == group_style_key then
                row = candidate
                break
            end
        end
        if not row then
            row = {y = y, group_style_key = group_style_key, buttons = {}}
            rows[#rows + 1] = row
        end
        row.buttons[#row.buttons + 1] = button
    end
    return rows
end

function draw_icon_group_background(ass, buttons, row_y, group_bounds, group, style)
    style = style or {}
    local bounds = group_decoration_bounds(buttons, row_y, group_bounds, group, style)
    if not bounds then
        return
    end
    if bounds.background then
        draw_gradient_rrect(
            ass,
            bounds.x1,
            bounds.y1,
            bounds.x2,
            bounds.y2,
            style.radius,
            style.color,
            style.gradient_color,
            style.gradient_type,
            style.alpha
        )
    end
    if bounds.border then
        draw_sided_border(
            ass,
            bounds.x1,
            bounds.y1,
            bounds.x2,
            bounds.y2,
            style.radius,
            style.border_color,
            style.border_alpha,
            style.border_width,
            style.border_sides
        )
    end
end

function playlist_script_loaded()
    return common.is_script_loaded("cadre_playlist")
end

function run_playlist_action(action, fallback)
    if playlist_script_loaded() then
        mp.commandv("script-message", action)
    else
        mp.command(fallback)
    end
end

toggle_osc_pin = nil
toggle_picture_in_picture = nil

DEFAULT_BUTTON_LAYOUT = {
    left = {"prev", "play", "next", "stop"},
    center = {},
    right = {"volume", "add", "settings", "subtitle_list", "fullscreen", "playlist"}
}

function default_button_layout()
    local layout = {left = {}, center = {}, right = {}}
    for group, ids in pairs(DEFAULT_BUTTON_LAYOUT) do
        for index, id in ipairs(ids) do
            layout[group][index] = {
                id = id,
                slot = "default_" .. group .. index,
                style = {},
            }
        end
    end
    return layout
end

warned_slot_overrides = {}
warned_group_overrides = {}

function parse_icon_effect_style(raw, defaults, key)
    local style = {}
    for name, default in pairs(defaults) do
        style[name] = default
    end
    if raw == nil then
        return style
    end
    if type(raw) ~= "table" then
        if not warned_group_overrides[key .. ":table"] then
            msg.warn("cadre_osc: osc_group_overrides." .. key .. " must be a table; ignoring it")
            warned_group_overrides[key .. ":table"] = true
        end
        return style
    end

    for name, value in pairs(raw) do
        local valid
        if name == "outline" or name == "shadow" then
            valid = type(value) == "boolean"
        elseif name == "outline_color" or name == "shadow_color" then
            valid = type(value) == "string" and value:match("^%x%x%x%x%x%x$")
            if valid then
                value = common.bgr(value)
            end
        elseif name == "outline_alpha" or name == "shadow_alpha" then
            valid = type(value) == "string" and value:match("^%x%x$")
            if valid then value = common.ass_alpha(value) end
        elseif name == "outline_width" or name == "outline_blur" or name == "shadow_blur" then
            valid = type(value) == "number" and value >= 0 and value < math.huge and value == value
        elseif name == "shadow_x" or name == "shadow_y" then
            valid = type(value) == "number" and value > -math.huge
                and value < math.huge and value == value
        end
        if valid then
            style[name] = value
        else
            local warning_key = key .. ":" .. tostring(name)
            if not warned_group_overrides[warning_key] then
                msg.warn(
                    "cadre_osc: invalid osc_group_overrides." .. key .. "." ..
                        tostring(name) .. "; ignoring it"
                )
                warned_group_overrides[warning_key] = true
            end
        end
    end
    return style
end

function parse_group_decoration_style(raw, defaults, key, allowed_numeric)
    if raw == nil then
        return defaults
    end
    if type(raw) ~= "table" then
        if not warned_group_overrides[key .. ":table"] then
            msg.warn("cadre_osc: osc_group_overrides." .. key .. " must be a table; ignoring it")
            warned_group_overrides[key .. ":table"] = true
        end
        return defaults
    end

    local style = {}
    for name, default in pairs(defaults) do
        style[name] = default
    end
    for name, value in pairs(raw) do
        local valid
        if name == "background" or name == "border" then
            valid = type(value) == "boolean"
        elseif name == "color" or name == "border_color" or name == "gradient_color" then
            valid = type(value) == "string" and value:match("^%x%x%x%x%x%x$")
            if valid then
                value = common.bgr(value)
            end
        elseif name == "alpha" or name == "border_alpha" then
            valid = type(value) == "string" and value:match("^%x%x$")
            if valid then value = common.ass_alpha(value) end
        elseif name == "gradient_type" then
            valid = value == "left_to_right" or value == "top_to_bottom" or value == "circular"
        elseif name == "border_sides" and type(value) == "table" then
            valid = true
            for side, enabled in pairs(value) do
                if (side ~= "top" and side ~= "right" and side ~= "bottom" and side ~= "left")
                    or type(enabled) ~= "boolean" then valid = false; break end
            end
        elseif name == "width" then
            value = parse_group_width(value, key .. ".width")
            valid = value ~= nil
        elseif allowed_numeric[name] then
            valid = type(value) == "number" and value >= 0
                and value < math.huge and value == value
        end
        if valid then
            style[name] = value
        else
            local warning_key = key .. ":" .. tostring(name)
            if not warned_group_overrides[warning_key] then
                msg.warn(
                    "cadre_osc: invalid osc_group_overrides." .. key .. "." ..
                        tostring(name) .. "; ignoring it"
                )
                warned_group_overrides[warning_key] = true
            end
        end
    end
    return style
end

function configured_button_layout()
    local layout = {left = {}, center = {}, right = {}}
    local overrides = theme.osc_slot_overrides
    if overrides == nil then
        overrides = {}
    elseif type(overrides) ~= "table" then
        if not warned_slot_overrides.root then
            msg.warn("cadre_osc: osc_slot_overrides must be a table; ignoring it")
            warned_slot_overrides.root = true
        end
        overrides = {}
    end
    local group_overrides = theme.osc_group_overrides
    if group_overrides == nil then
        group_overrides = {}
    elseif type(group_overrides) ~= "table" then
        if not warned_group_overrides.root then
            msg.warn("cadre_osc: osc_group_overrides must be a table; ignoring it")
            warned_group_overrides.root = true
        end
        group_overrides = {}
    end
    local resolved_group_styles = {}
    local function group_style(key)
        if resolved_group_styles[key] then
            return resolved_group_styles[key]
        end
        local group_override = group_overrides[key]
        if group_override == nil then
            group_override = {}
        elseif type(group_override) ~= "table" then
            if not warned_group_overrides[key .. ":table"] then
                msg.warn("cadre_osc: osc_group_overrides." .. key .. " must be a table; ignoring it")
                warned_group_overrides[key .. ":table"] = true
            end
            group_override = {}
        end
        local style = {
            icon = parse_icon_effect_style(
                group_override.icon,
                {
                    outline = cfg.ICON_OUTLINE_ENABLED,
                    outline_color = cfg.ICON_OUTLINE_COLOR,
                    outline_alpha = cfg.ICON_OUTLINE_ALPHA,
                    outline_width = cfg.ICON_OUTLINE_WIDTH,
                    outline_blur = cfg.ICON_OUTLINE_BLUR,
                    shadow = cfg.ICON_SHADOW_ENABLED,
                    shadow_color = cfg.ICON_SHADOW_COLOR,
                    shadow_alpha = cfg.ICON_SHADOW_ALPHA,
                    shadow_x = cfg.ICON_SHADOW_X,
                    shadow_y = cfg.ICON_SHADOW_Y,
                    shadow_blur = cfg.ICON_SHADOW_BLUR,
                },
                key .. ".icon"
            ),
            button = parse_group_decoration_style(
                group_override.button,
                {
                    background = cfg.ICON_BG_ENABLED,
                    color = cfg.ICON_BG_COLOR,
                    gradient_color = nil,
                    gradient_type = nil,
                    border_sides = nil,
                    alpha = cfg.ICON_BG_ALPHA,
                    padding = cfg.ICON_BG_PAD_X,
                    height = cfg.ICON_BG_HEIGHT,
                    radius = cfg.ICON_BG_RADIUS,
                    border = cfg.ICON_BORDER_ENABLED,
                    border_color = cfg.ICON_BORDER_COLOR,
                    border_alpha = cfg.ICON_BORDER_ALPHA,
                    border_width = cfg.ICON_BORDER_WIDTH,
                    separator_width = cfg.SEPARATOR_WIDTH,
                    separator_height = cfg.SEPARATOR_HEIGHT,
                    separator_radius = cfg.SEPARATOR_RADIUS,
                },
                key .. ".button",
                {padding = true, height = true, radius = true, border_width = true,
                    separator_width = true, separator_height = true, separator_radius = true}
            ),
            group = parse_group_decoration_style(
                group_override.group,
                {
                    background = cfg.ICON_GROUP_BG_ENABLED,
                    color = cfg.ICON_GROUP_BG_COLOR,
                    gradient_color = nil,
                    gradient_type = nil,
                    border_sides = nil,
                    alpha = cfg.ICON_GROUP_BG_ALPHA,
                    padding = cfg.ICON_GROUP_BG_PADDING,
                    height = cfg.ICON_GROUP_BG_HEIGHT,
                    radius = cfg.ICON_GROUP_BG_RADIUS,
                    border = cfg.ICON_GROUP_BORDER_ENABLED,
                    border_color = cfg.ICON_GROUP_BORDER_COLOR,
                    border_alpha = cfg.ICON_GROUP_BORDER_ALPHA,
                    border_width = cfg.ICON_GROUP_BORDER_WIDTH,
                },
                key .. ".group",
                {padding = true, height = true, radius = true, border_width = true}
            ),
        }
        resolved_group_styles[key] = style
        return style
    end
    local configured = false
    local has_named_button = false

    for _, group in ipairs(
        {
            {name = "left", prefix = "L"},
            {name = "center", prefix = "C"},
            {name = "right", prefix = "R"}
        }
    ) do
        -- Keep the slot range roomy so custom themes can build wide control rows.
        for i = 1, 32 do
            local base_slot = "osc_" .. group.prefix .. i
            local slots = {
                {key = base_slot},
                {key = base_slot .. "_top", anchor = "top", space = "window"},
                {key = base_slot .. "_center", anchor = "center", space = "window"},
                {key = base_slot .. "_bottom", anchor = "bottom", space = "window"},
                {key = base_slot .. "_top_osc", anchor = "top", space = "osc"},
                {key = base_slot .. "_center_osc", anchor = "center", space = "osc"},
                {key = base_slot .. "_bottom_osc", anchor = "bottom", space = "osc"},
            }
            for _, slot in ipairs(slots) do
                local value = theme[slot.key]
                if value ~= nil then
                    configured = true
                end
                if type(value) == "string" and value ~= "" then
                    has_named_button = true
                    local style = overrides[slot.key]
                    if style ~= nil and type(style) ~= "table" then
                        local warning_key = slot.key .. ":table"
                        if not warned_slot_overrides[warning_key] then
                            msg.warn("cadre_osc: osc_slot_overrides." .. slot.key .. " must be a table; ignoring it")
                            warned_slot_overrides[warning_key] = true
                        end
                        style = nil
                    end
                    local group_style_key = group.prefix ..
                        (slot.anchor and ("_" .. slot.anchor) or "") ..
                        (slot.space == "osc" and "_osc" or "")
                    local base_group_style = group_style(group_style_key)
                    local item_group_style = {button = {}, group = {}}
                    for key, setting in pairs(base_group_style.button) do
                        item_group_style.button[key] = setting
                    end
                    for key, setting in pairs(base_group_style.group) do
                        item_group_style.group[key] = setting
                    end
                    local item_icon_style = {}
                    for key, setting in pairs(base_group_style.icon) do
                        item_icon_style[key] = setting
                    end
                    local item = {
                        id = value,
                        slot = slot.key,
                        anchor = slot.anchor,
                        anchor_space = slot.space,
                        group_style_key = group_style_key,
                        group_style = item_group_style,
                        icon_style = item_icon_style,
                        style = {},
                    }
                    if style then
                        for key, setting in pairs(style) do
                            local valid, applicable
                            if key == "icon_size" or key == "font_size" then
                                valid = type(setting) == "number" and setting > 0
                                    and setting < math.huge and setting == setting
                            elseif key == "spacing" or key == "button_height"
                                or key == "button_padding" or key == "button_radius"
                                or key == "button_border_width" or key == "hover_border_width"
                                or key == "hover_radius" or key == "separator_width"
                                or key == "separator_height" or key == "separator_radius"
                                or key == "icon_outline_width" or key == "icon_outline_blur"
                                or key == "icon_shadow_blur" then
                                valid = type(setting) == "number" and setting >= 0
                                    and setting < math.huge and setting == setting
                            elseif key == "hover_scale" then
                                valid = type(setting) == "number" and setting > 0
                                    and setting < math.huge and setting == setting
                            elseif key == "icon_shadow_x" or key == "icon_shadow_y" then
                                valid = type(setting) == "number" and setting > -math.huge
                                    and setting < math.huge and setting == setting
                            elseif key == "button_border_sides" then
                                valid = type(setting) == "table"
                                if valid then
                                    for side, enabled in pairs(setting) do
                                        if (side ~= "top" and side ~= "right" and side ~= "bottom" and side ~= "left")
                                            or type(enabled) ~= "boolean" then valid = false; break end
                                    end
                                end
                            elseif key == "icon_color" or key == "text_color"
                                or key == "button_color" or key == "button_border_color"
                                or key == "button_gradient_color" or key == "separator_color"
                                or key == "hover_icon_color" or key == "hover_bg_color"
                                or key == "hover_border_color" then
                                valid = type(setting) == "string" and setting:match("^%x%x%x%x%x%x$")
                            elseif key == "icon_outline_color" or key == "icon_shadow_color" then
                                valid = type(setting) == "string" and setting:match("^%x%x%x%x%x%x$")
                            elseif key == "button_alpha" or key == "button_border_alpha"
                                or key == "hover_bg_alpha" or key == "hover_border_alpha" then
                                valid = type(setting) == "string" and setting:match("^%x%x$")
                            elseif key == "icon_outline_alpha" or key == "icon_shadow_alpha" then
                                valid = type(setting) == "string" and setting:match("^%x%x$")
                            elseif key == "button_gradient_type" then
                                valid = setting == "left_to_right" or setting == "top_to_bottom"
                                    or setting == "circular"
                            elseif key == "separator_alpha" then
                                valid = type(setting) == "string" and setting:match("^%x%x$")
                            elseif key == "icon_outline" or key == "icon_shadow"
                                or key == "button_background" or key == "button_border"
                                or key == "hover_border" then
                                valid = type(setting) == "boolean"
                            else
                                local warning_key = slot.key .. ":" .. tostring(key)
                                if not warned_slot_overrides[warning_key] then
                                    msg.warn(
                                        "cadre_osc: unsupported osc_slot_overrides." .. slot.key ..
                                            " option '" .. tostring(key) .. "'; ignoring it"
                                    )
                                    warned_slot_overrides[warning_key] = true
                                end
                            end
                            if key == "icon_size" or key == "icon_color" then
                                applicable = item.id ~= "time" and item.id ~= "title" and item.id ~= "seekbar"
                            elseif key == "font_size" or key == "text_color" then
                                applicable = item.id == "time" or item.id == "title"
                            elseif key == "hover_icon_color" or key == "hover_scale" then
                                applicable = item.id ~= "time" and item.id ~= "title"
                                    and item.id ~= "seekbar" and item.id ~= "volume_slider"
                            elseif key == "hover_bg_color" or key == "hover_bg_alpha"
                                or key == "hover_border" or key == "hover_border_color"
                                or key == "hover_border_alpha" or key == "hover_border_width"
                                or key == "hover_radius" then
                                applicable = item.id ~= "time" and item.id ~= "title"
                                    and item.id ~= "seekbar"
                            elseif key == "spacing" then
                                applicable = true
                            elseif key:match("^separator_") then
                                applicable = item.id == "separator"
                            elseif key == "button_height" or key == "button_padding"
                                or key == "button_radius"
                                or (type(key) == "string" and key:match("^button_")) then
                                applicable = item.id ~= "seekbar"
                            elseif key == "icon_outline" or key == "icon_outline_color"
                                or key == "icon_outline_alpha" or key == "icon_outline_width"
                                or key == "icon_outline_blur"
                                or key == "icon_shadow" or key == "icon_shadow_color"
                                or key == "icon_shadow_alpha" or key == "icon_shadow_x"
                                or key == "icon_shadow_y" or key == "icon_shadow_blur" then
                                applicable = item.id ~= "time" and item.id ~= "title" and item.id ~= "seekbar"
                            end
                            if valid and applicable then
                                if key == "button_alpha" or key == "button_border_alpha"
                                    or key == "hover_bg_alpha" or key == "hover_border_alpha"
                                    or key == "icon_outline_alpha" or key == "icon_shadow_alpha"
                                    or key == "separator_alpha" then
                                    setting = common.ass_alpha(setting)
                                end
                                if key == "button_height" then
                                    item.group_style.button.height = setting
                                elseif key == "button_padding" then
                                    item.group_style.button.padding = setting
                                elseif key == "button_radius" then
                                    item.group_style.button.radius = setting
                                elseif key == "button_background" then
                                    item.group_style.button.background = setting
                                elseif key == "button_color" then
                                    item.group_style.button.color = common.bgr(setting)
                                elseif key == "button_gradient_color" then
                                    item.group_style.button.gradient_color = common.bgr(setting)
                                elseif key == "button_gradient_type" then
                                    item.group_style.button.gradient_type = setting
                                elseif key == "separator_width" then
                                    item.style.width = setting
                                elseif key == "separator_height" then
                                    item.style.height = setting
                                elseif key == "separator_radius" then
                                    item.style.radius = setting
                                elseif key == "separator_color" then
                                    item.style.color = common.bgr(setting)
                                elseif key == "separator_alpha" then
                                    item.style.alpha = setting
                                elseif key == "button_alpha" then
                                    item.group_style.button.alpha = setting
                                elseif key == "button_border" then
                                    item.group_style.button.border = setting
                                elseif key == "button_border_color" then
                                    item.group_style.button.border_color = common.bgr(setting)
                                elseif key == "button_border_alpha" then
                                    item.group_style.button.border_alpha = setting
                                elseif key == "button_border_width" then
                                    item.group_style.button.border_width = setting
                                elseif key == "button_border_sides" then
                                    item.group_style.button.border_sides = setting
                                elseif key == "hover_icon_color" then
                                    item.style[key] = setting
                                elseif key == "hover_bg_color" or key == "hover_border_color"
                                    or key == "hover_bg_alpha" or key == "hover_border_alpha"
                                    or key == "hover_scale" or key == "hover_border"
                                    or key == "hover_border_width" or key == "hover_radius" then
                                    item.style[key] = setting
                                elseif key:match("^icon_outline") then
                                    local name = key:gsub("^icon_", "")
                                    item.icon_style[name] = key == "icon_outline_color"
                                        and common.bgr(setting) or setting
                                elseif key:match("^icon_shadow") then
                                    local name = key:gsub("^icon_", "")
                                    item.icon_style[name] = key == "icon_shadow_color"
                                        and common.bgr(setting) or setting
                                else
                                    item.style[key] = setting
                                end
                            elseif key == "icon_size" or key == "font_size"
                                or key == "icon_color" or key == "text_color" or key == "spacing"
                                or key == "button_height" or key == "button_padding"
                                or key == "button_radius" or key == "button_background"
                                or key == "button_color" or key == "button_alpha"
                                or key == "button_border" or key == "button_border_color"
                                or key == "button_border_alpha" or key == "button_border_width"
                                or key == "button_border_sides"
                                or key == "hover_icon_color" or key == "hover_bg_color"
                                or key == "hover_bg_alpha" or key == "hover_scale"
                                or key == "hover_border" or key == "hover_border_color"
                                or key == "hover_border_alpha" or key == "hover_border_width"
                                or key == "hover_radius"
                                or key == "icon_outline"
                                or key == "icon_outline_color" or key == "icon_outline_alpha"
                                or key == "icon_outline_width" or key == "icon_shadow"
                                or key == "icon_outline_blur" or key == "icon_shadow_blur"
                                or key == "icon_shadow_color" or key == "icon_shadow_alpha"
                                or key == "icon_shadow_x" or key == "icon_shadow_y" then
                                local warning_key = slot.key .. ":" .. key
                                if not warned_slot_overrides[warning_key] then
                                    local reason = not valid and "invalid value"
                                        or "not applicable to " .. item.id
                                    msg.warn(
                                        "cadre_osc: osc_slot_overrides." .. slot.key ..
                                            "." .. key .. " is " .. reason .. "; ignoring it"
                                    )
                                    warned_slot_overrides[warning_key] = true
                                end
                            end
                        end
                    end
                    layout[group.name][#layout[group.name] + 1] = item
                end
            end
        end
    end

    if not configured then
        local defaults = default_button_layout()
        for _, group in ipairs({"left", "center", "right"}) do
            local prefix = group == "left" and "L" or group == "center" and "C" or "R"
            for _, item in ipairs(defaults[group]) do
                item.group_style_key = prefix
                item.group_style = group_style(prefix)
                item.icon_style = item.group_style.icon
            end
        end
        return defaults, true
    end
    return layout, has_named_button
end

function get_volume_slider_geometry(button)
    local slider_x1

    if cfg.VOLUME_SLIDER_MUTE then
        local mute_width = math.max(cfg.VOLUME_SLIDER_MUTE_WIDTH, button.style.icon_size or 0)
        local total_item_width =
            mute_width + cfg.VOLUME_SLIDER_MUTE_GAP + cfg.VOLUME_SLIDER_WIDTH +
			cfg.VOLUME_SLIDER_PAD_LEFT + cfg.VOLUME_SLIDER_PAD_RIGHT

        slider_x1 = button.x + total_item_width / 2 - cfg.VOLUME_SLIDER_WIDTH - cfg.VOLUME_SLIDER_PAD_RIGHT
    else
        local total_item_width = cfg.VOLUME_SLIDER_WIDTH + cfg.VOLUME_SLIDER_PAD_LEFT + cfg.VOLUME_SLIDER_PAD_RIGHT

        slider_x1 = button.x - total_item_width / 2 + cfg.VOLUME_SLIDER_PAD_LEFT
    end

    return {
        slider_x1 = slider_x1,
        slider_x2 = slider_x1 + cfg.VOLUME_SLIDER_WIDTH
    }
end

function set_volume_from_y(py, geo)
    local r = (geo.track_y2 - py) / (geo.track_y2 - geo.track_y1)
    mp.set_property_number("volume", math.min(1, math.max(0, r)) * 100)
end

function set_volume_from_x(px, button)
    if not px or not button then
        return
    end

    local geo = get_volume_slider_geometry(button)
    local slider_w = geo.slider_x2 - geo.slider_x1

    local ratio = (px - geo.slider_x1) / slider_w
    ratio = math.min(1, math.max(0, ratio))

    mp.set_property_number("volume", ratio * 100)
end


function get_subtitle_tracks()
    local all_tracks = mp.get_property_native("track-list", {})
    local tracks = {}
    for _, track in ipairs(all_tracks) do
        if track.type == "sub" then
            tracks[#tracks + 1] = track
        end
    end
    return tracks
end

function subtitle_track_text(track, index)
    local title = track.title
    local language = track.lang
    if title and title ~= "" then
        return title, language
    end
    if language and language ~= "" then
        return language, nil
    end
    if track["external-filename"] and track["external-filename"] ~= "" then
        local filename = track["external-filename"]
        filename = filename:match("([^/\\]+)$") or filename
        filename = filename:gsub("%.[^%.]+$", "")
        if filename ~= "" then
            return filename, nil
        end
    end
    return "Track " .. tostring(index), nil
end

toggle_settings_menu = nil
open_track_picker = nil
fit_title_to_width = nil
escape_ass_text = nil

BUTTONS = {
    separator = {kind = "separator"},
    prev = {
        tooltip = "Previous playlist item",
        icon = ICON.prev,
        click = function()
            run_playlist_action("playlist-prev", "playlist-prev")
        end
    },
    seekbar_back = {
        tooltip = "Seek back 10 seconds",
        icon = ICON.seekbar_back,
        click = function()
            mp.commandv("seek", -10, "relative")
        end
    },
    play = {
        tooltip = "Play or pause",
        icon = function()
            return (idle_active or paused) and ICON.play or ICON.pause
        end,
        click = function()
            mp.commandv("cycle", "pause")
        end,
    },
    pause = {
        tooltip = "Pause",
        icon = ICON.pause,
        alpha = function()
            return paused and "60" or "00"
        end,
        click = function()
            mp.set_property_bool("pause", true)
        end
    },
    play_only = {
        tooltip = "Play",
        icon = ICON.play,
        alpha = function()
            return paused and "00" or "60"
        end,
        click = function()
            mp.set_property_bool("pause", false)
        end
    },
    seekbar_forward = {
        tooltip = "Seek forward 10 seconds",
        icon = ICON.seekbar_forward,
        click = function()
            mp.commandv("seek", 10, "relative")
        end
    },
    next = {
        tooltip = "Next playlist item",
        icon = ICON.next,
        click = function()
            run_playlist_action("playlist-next", "playlist-next")
        end
    },
    stop = {
        tooltip = "Stop playback",
        icon = ICON.stop,
        click = function()
            mp.commandv("stop", "keep-playlist")
        end
    },
    volume = {
        tooltip = "Volume",
        icon = function()
            return (muted or volume == 0) and ICON.volume_off or ICON.volume_up
        end,
        click = function(_, _, button)
            volume_popup_open = not volume_popup_open
            volume_popup_slot = volume_popup_open and button and button.slot or nil
            add_menu_open = false
            add_menu_slot = nil
            track_popup_open = false
        end
    },
    volume_slider = {
        tooltip = "Adjust volume",
        kind = "volume_slider",
        click = function(px, _, button)
            if not button then
                return
            end

            volume_slider_dragging = true
            set_volume_from_x(px, button)
        end
    },
    mute = {
        tooltip = "Toggle mute",
        icon = function()
            return muted and ICON.volume_off or ICON.volume_up
        end,
        click = function()
            mp.commandv("cycle", "mute")
        end
    },
    add = {
        tooltip = "Add media",
        icon = ICON.add,
        click = function(_, _, button)
            add_menu_open = not add_menu_open
            add_menu_slot = add_menu_open and button and button.slot or nil
            volume_popup_open = false
            volume_popup_slot = nil
            track_popup_open = false
        end
    },
    fullscreen = {
        tooltip = "Toggle fullscreen",
        icon = ICON.fullscreen,
        click = function()
            mp.commandv("cycle", "fullscreen")
        end
    },
    screenshot = {
        tooltip = "Take screenshot",
        icon = ICON.screenshot,
        click = function()
            mp.commandv("screenshot")
        end
    },
    ontop = {
        tooltip = "Toggle always on top",
        icon = ICON.always_on_top,
        alpha = function()
            return mp.get_property_bool("ontop", false) and "00" or "60"
        end,
        click = function()
            mp.commandv("cycle", "ontop")
        end
    },
    pip = {
        tooltip = "Toggle picture in picture",
        icon = ICON.picture_in_picture,
        alpha = function()
            return pip_state and "00" or "60"
        end,
        click = function()
            toggle_picture_in_picture()
        end
    },
    pin = {
        tooltip = "Pin OSC controls",
        icon = ICON.pin,
        alpha = function()
            return bar_pinned and "00" or "60"
        end,
        click = function()
            toggle_osc_pin()
        end
    },
    playlist = {
        tooltip = "Toggle playlist",
        icon = ICON.playlist,
        alpha = function()
            return mp.get_property_native("user-data/cadre_playlist/visible", false) and "00" or "60"
        end,
        click = function()
            run_playlist_action("toggle-playlist", "show-text ${playlist}")
        end
    },
    shuffle = {
        tooltip = "Toggle playlist shuffle",
        icon = ICON.shuffle,
        alpha = function()
            return mp.get_property_native("user-data/cadre_playlist/shuffle", false) and "00" or "60"
        end,
        click = function()
            run_playlist_action("toggle-shuffle", "show-text 'Load cadre_playlist to use shuffle'")
        end
    },
    ["repeat"] = {
        tooltip = "Change playlist repeat mode",
        icon = function()
            local mode = mp.get_property("user-data/cadre_playlist/repeat", "off")
            if mode == "all" then return ICON.repeat_all end
            if mode == "one" then return ICON.repeat_one end
            if mode == "auto" then return ICON.repeat_auto end
            return ICON.repeat_all
        end,
        alpha = function()
            return mp.get_property("user-data/cadre_playlist/repeat", "off") ~= "off" and "00" or "60"
        end,
        click = function()
            run_playlist_action("cycle-repeat", "show-text 'Load cadre_playlist to use repeat modes'")
        end
    },
    time = {
        kind = "time",
        click = function()
        end
    },
    title = {
        kind = "title",
        click = function()
        end
    },
    quit = {
        tooltip = "Quit mpv",
        icon = ICON.close,
        click = function() mp.commandv("quit") end
    },
    frame_back_step = {
        tooltip = "Step back one frame",
        icon = ICON.frame_back,
        click = function() mp.commandv("frame-back-step") end
    },
    frame_step = {
        tooltip = "Step forward one frame",
        icon = ICON.frame_forward,
        click = function() mp.commandv("frame-step") end
    },
    audio_list = {
        tooltip = "Select audio track",
        icon = ICON.audio,
        click = function(_, _, button) open_track_picker("audio", button) end
    },
    subtitle_list = {
        tooltip = "Select subtitle track",
        icon = ICON.subtitles,
        click = function(_, _, button) open_track_picker("sub", button) end
    },
    chapter_list = {
        tooltip = "View chapter list",
        icon = ICON.chapter_list,
        click = function(_, _, button) open_track_picker("chapters", button) end
    },
    chapter_prev = {
        tooltip = "Go to previous chapter",
        icon = ICON.chapter_prev,
        click = function() mp.commandv("add", "chapter", "-1") end
    },
    chapter_next = {
        tooltip = "Go to next chapter",
        icon = ICON.chapter_next,
        click = function() mp.commandv("add", "chapter", "1") end
    },
    speed_down = {
        tooltip = "Decrease playback speed",
        icon = ICON.speed_down,
        click = function()
            speed_zero_selected = false
            mp.commandv("add", "speed", "-0.1")
        end
    },
    speed_reset = {
        tooltip = "Reset playback speed to 1×",
        icon = ICON.speed_reset,
        alpha = function()
            return mp.get_property_number("speed", 1) == 1 and "60" or "00"
        end,
        click = function()
            speed_zero_selected = false
            mp.commandv("set", "speed", "1")
        end
    },
    speed_up = {
        tooltip = "Increase playback speed",
        icon = ICON.speed_up,
        click = function()
            speed_zero_selected = false
            mp.commandv("add", "speed", "0.1")
        end
    },
    speed_control = {
        tooltip = "Playback speed",
        icon = ICON.speed_reset,
        click = function(_, _, button)
            speed_popup_open = not speed_popup_open
            speed_popup_slot = speed_popup_open and button and button.slot or nil
            volume_popup_open, add_menu_open, track_popup_open = false, false, false
            volume_popup_slot, add_menu_slot, track_popup_slot = nil, nil, nil
        end
    },
    speed_control_wheel = {
        tooltip = "Playback speed",
        kind = "speed_control_wheel",
        click = function() end
    },
    ab_loop = {
        tooltip = "Toggle A-B loop",
        icon = ICON.ab_loop,
        alpha = function()
            local a = mp.get_property("ab-loop-a", "no")
            local b = mp.get_property("ab-loop-b", "no")
            return (a ~= "no" or b ~= "no") and "00" or "60"
        end,
        click = function() mp.commandv("ab-loop") end
    },
    seekbar = {
        kind = "seekbar",
        click = function()
        end
    },
    subtitle = {
        tooltip = "Toggle subtitles",
        icon = function()
            local sid = mp.get_property_native("sid")
            local visible = mp.get_property_bool("sub-visibility", true)

            if sid == nil or sid == "no" then
                return ICON.cc_off
            end

            for _, track in ipairs(mp.get_property_native("track-list", {})) do
                if track.type == "sub" and track.id == sid then
                    return visible and ICON.cc_on or ICON.cc_off
                end
            end

            return ICON.cc_off
        end,

        alpha = function()
            local sid = mp.get_property_native("sid")
            local visible = mp.get_property_bool("sub-visibility", true)

            if sid == nil or sid == "no" then
                return "60"
            end

            for _, track in ipairs(mp.get_property_native("track-list", {})) do
                if track.type == "sub" and track.id == sid then
                    return visible and "00" or "60"
                end
            end

            return "60"
        end,

        click = function()
            local sid = mp.get_property_native("sid")
            local has_selected_track = sid ~= nil and sid ~= "no"

            if has_selected_track then
                mp.commandv("cycle", "sub-visibility")
                return
            end

            if last_subtitle_sid ~= nil then
                for _, track in ipairs(get_subtitle_tracks()) do
                    if track.id == last_subtitle_sid then
                        mp.set_property_number("sid", last_subtitle_sid)
                        mp.set_property_bool("sub-visibility", true)
                        return
                    end
                end
            end

            local tracks = get_subtitle_tracks()
            if #tracks == 0 then
                return
            end

            last_subtitle_sid = tracks[1].id
            mp.set_property_number("sid", last_subtitle_sid)
            mp.set_property_bool("sub-visibility", true)
        end,
    },
    settings = {
        tooltip = "Open settings",
        icon = ICON.settings,
        click = function()
            toggle_settings_menu()
        end
    },
    stream = {
        tooltip = "Open stream controls",
        icon = ICON.stream,
        click = function()
            mp.msg.info("Opening cadre-stream script")
            mp.commandv("script-message-to", "cadre_stream", "cadre-stream-open")
        end
    },
    webdav = {
        tooltip = "Open WebDAV browser",
        icon = ICON.webdav,
        click = function()
            mp.commandv("script-message", "webdav-browser-toggle")
        end
    },
	info = {
        tooltip = "Toggle playback statistics",
        icon = ICON.info,
        click = function()
            mp.commandv("script-binding", "stats/display-stats-toggle")
        end
    },
    youtube = {
        tooltip = "Search YouTube",
        icon = ICON.youtube,
        click = function()
            mp.commandv("script-message", "mpv-youtube-search-open")
        end
    },
	music_mode = {
		tooltip = "Toggle music mode",
		icon = ICON.music_mode,
		alpha = function()
			return mp.get_property_native("user-data/music_mode/active", false) and "00" or "60"
		end,
		click = function()
			mp.commandv("script-message", "music-mode-toggle")
		end
	}
}

function normalize_chapters(raw)
    local out = {}
    if type(raw) ~= "table" then
        return out
    end
    for i, c in ipairs(raw) do
        local t = c.time
        if type(t) == "number" then
            out[#out + 1] = {
                time = t,
                title = (c.title and c.title ~= "" and c.title) or ("Chapter " .. i)
            }
        end
    end
    table.sort(
        out,
        function(a, b)
            return a.time < b.time
        end
    )
    return out
end

function ratio_to_x(bar_x1, bar_w, ratio)
    return bar_x1 + bar_w * math.min(1, math.max(0, ratio))
end

function draw_chapter_marks(ass, bar_x1, bar_x2, bar_w, seekbar_y, track_h, dur)
    if not dur or dur <= 0 or #chapters == 0 then
        return
    end
    local half_h = track_h / 2
    for _, c in ipairs(chapters) do
        if c.time > 0 and c.time < dur then
            local cx = ratio_to_x(bar_x1, bar_w, c.time / dur)
            local mx1 = math.max(bar_x1, cx - cfg.CHAPTER_MARK_W)
            local mx2 = math.min(bar_x2, cx + cfg.CHAPTER_MARK_W)
            if mx2 > mx1 then
                common.draw_rrect(
                    ass,
                    mx1,
                    seekbar_y - half_h,
                    mx2,
                    seekbar_y + half_h,
                    0,
                    cfg.CHAPTER_MARK_COLOR,
                    cfg.CHAPTER_MARK_ALPHA
                )
            end
        end
    end
end

function find_hovered_chapter(bar_x1, bar_w, dur, px)
    if not dur or dur <= 0 or #chapters == 0 then
        return nil
    end
    for _, c in ipairs(chapters) do
        if c.time > 0 and c.time < dur then
            local cx = ratio_to_x(bar_x1, bar_w, c.time / dur)
            if math.abs(px - cx) <= cfg.CHAPTER_HOVER_PX then
                return c
            end
        end
    end
    return nil
end

function chapter_segments(bar_x1, bar_x2, bar_w, dur)
    local gap = cfg.CHAPTER_MARK_W
    local segs, start = {}, bar_x1
    if dur and dur > 0 then
        for _, c in ipairs(chapters) do
            if c.time > 0 and c.time < dur then
                local cx = ratio_to_x(bar_x1, bar_w, c.time / dur)
                local e = cx - gap
                if e > start then segs[#segs + 1] = {start, e} end
                start = math.max(start, cx + gap)
            end
        end
    end
    if bar_x2 > start then segs[#segs + 1] = {start, bar_x2} end
    return segs
end

function nearest_seekbar_segment(segs, px)
    local nearest, nearest_distance
    for index, segment in ipairs(segs) do
        local distance = math.max(segment[1] - px, 0, px - segment[2])
        if nearest_distance == nil or distance < nearest_distance then
            nearest = index
            nearest_distance = distance
        end
    end
    return nearest
end

function with_clip(ass, cx1, cy1, cx2, cy2, draw)
    local n = #ass.text
    draw()
    local added = ass.text:sub(n + 1)
    added = added:gsub("{", string.format("{\\clip(%.2f,%.2f,%.2f,%.2f)", cx1, cy1, cx2, cy2), 1)
    ass.text = ass.text:sub(1, n) .. added
end

function seekbar_radius(track_h)
    return cfg.SEEKBAR_RADIUS and math.min(cfg.SEEKBAR_RADIUS, track_h / 2) or track_h / 2
end

function draw_segmented(ass, segs, center_y, track_heights, color, alpha, limit_x)
    if #segs == 0 then return end
    local first_x, last_x = segs[1][1], segs[#segs][2]
    local right = math.min(limit_x or last_x, last_x)
    if right <= first_x then return end
    for index, s in ipairs(segs) do
        local cx1, cx2 = s[1], math.min(s[2], right)
        if cx2 > cx1 then
            local track_h = track_heights[index]
            local y1, y2 = center_y - track_h / 2, center_y + track_h / 2
            with_clip(ass, cx1, y1 - 2, cx2, y2 + 2, function()
                common.draw_rrect(ass, first_x, y1, right, y2, seekbar_radius(track_h), color, alpha)
            end)
        end
    end
end

function draw_segmented_outline(ass, segs, center_y, track_heights, color, alpha, width)
    if #segs == 0 then return end
    local first_x, last_x = segs[1][1], segs[#segs][2]
    for index, s in ipairs(segs) do
        local track_h = track_heights[index]
        local y1, y2 = center_y - track_h / 2, center_y + track_h / 2
        with_clip(ass, s[1], y1 - width - 2, s[2], y2 + width + 2, function()
            draw_rrect_outline(ass, first_x, y1, last_x, y2, seekbar_radius(track_h), color, alpha, width)
        end)
    end
end

function button_dimensions(item)
    local id = item.id
    if id == "time" then
        return cfg.TIME_ITEM_WIDTH, item.style.font_size or cfg.FONT_SIZE
    end

    if id == "separator" then
        return item.style.width or cfg.SEPARATOR_WIDTH,
            item.style.height or (item.group_style and item.group_style.button.separator_height)
                or cfg.SEPARATOR_HEIGHT
    end

    if id == "title" then
        return cfg.TITLE_ITEM_WIDTH, item.style.font_size or cfg.TITLE_SIZE
    end

    if id == "seekbar" then
        return 0, math.max(cfg.SEEKBAR_HEIGHT_HOVER, cfg.THUMB_WH * 2)
    end

    if id == "volume_slider" then
        local mute_width = math.max(cfg.VOLUME_SLIDER_MUTE_WIDTH, item.style.icon_size or 0)
        local width = cfg.VOLUME_SLIDER_WIDTH + cfg.VOLUME_SLIDER_PAD_LEFT + cfg.VOLUME_SLIDER_PAD_RIGHT

        if cfg.VOLUME_SLIDER_MUTE then
            width =
                mute_width + cfg.VOLUME_SLIDER_MUTE_GAP +
				cfg.VOLUME_SLIDER_WIDTH + cfg.VOLUME_SLIDER_PAD_LEFT +
                cfg.VOLUME_SLIDER_PAD_RIGHT
        end

        local height = math.max(
            cfg.VOLUME_SLIDER_HEIGHT,
            cfg.VOLUME_SLIDER_START_HEIGHT or cfg.VOLUME_SLIDER_HEIGHT,
            item.style.icon_size or cfg.ICON_SIZE
        )
        if cfg.VOLUME_SLIDER_THUMB then
            height = math.max(height, cfg.VOLUME_SLIDER_THUMB_HEIGHT * 2)
        end

        return width, height
    end

    if id == "speed_control_wheel" then
        return item.style.width or cfg.SPEED_WHEEL_WIDTH,
            item.style.height or math.max(cfg.ICON_SIZE, 28)
    end

    local size = item.style.icon_size or cfg.ICON_SIZE
    return size, size
end

--------------------------------------------------------------------------------
-- LAYOUT
--------------------------------------------------------------------------------

measure_text_width = nil
inline_time_width_key, inline_time_width = nil, nil
last_group_overlap_key = nil
last_vertical_overflow_key = nil

local cached_layout = nil
local layout_dirty = true

function invalidate_layout()
    layout_dirty = true
end

function get_layout()
    if not layout_dirty and cached_layout then
        return cached_layout
    end

    cached_layout = compute_layout() -- your existing get_layout body
    layout_dirty = false

    return cached_layout
end

function compute_layout()
    local natural_x1 = cfg.BAR_SIDE_INSET
    local natural_x2 = screen_w - cfg.BAR_SIDE_INSET
    local natural_w = natural_x2 - natural_x1
    local BAR_MAX_WIDTH = theme.max_width_panel_osc or screen_w

    local pill_x1, pill_x2
    if natural_w > BAR_MAX_WIDTH then
        local cx = screen_w / 2
        pill_x1 = cx - BAR_MAX_WIDTH / 2
        pill_x2 = cx + BAR_MAX_WIDTH / 2
    else
        pill_x1 = natural_x1
        pill_x2 = natural_x2
    end

    local pill_y1, pill_y2
    if cfg.BAR_Y_ANCHOR == "top" then
        pill_y1 = cfg.BAR_TOP_INSET
        pill_y2 = pill_y1 + cfg.BAR_HEIGHT
    elseif cfg.BAR_Y_ANCHOR == "center" then
        pill_y1 = (screen_h - cfg.BAR_HEIGHT) / 2
        pill_y2 = pill_y1 + cfg.BAR_HEIGHT
    else
        pill_y2 = screen_h - cfg.BAR_BOTTOM_INSET
        pill_y1 = pill_y2 - cfg.BAR_HEIGHT
    end

        local seekbar_extent = math.max(cfg.THUMB_WH, cfg.SEEKBAR_HEIGHT_HOVER / 2)
        local seekbar_y
    local row_y
    if cfg.BUTTON_Y_ANCHOR == "bottom" then
        row_y = pill_y2 - cfg.MAIN_ROW_OFFSET
    elseif cfg.BUTTON_Y_ANCHOR == "center" then
        row_y = (pill_y1 + pill_y2) / 2 + cfg.MAIN_ROW_OFFSET
    else
        row_y = pill_y1 + cfg.MAIN_ROW_OFFSET
    end
    local spacing = cfg.ICON_SPACING

    local button_x1, button_x2 = pill_x1 + cfg.BUTTON_LEFT_INSET, pill_x2 - cfg.BUTTON_RIGHT_INSET

    local button_layout, has_named_button = configured_button_layout()
    local function anchored_visual_extent(item)
        local item_width, item_height = button_dimensions(item)
        local extent = item_height / 2
        local button_decoration = item_decoration_bounds(
            0,
            0,
            item_width,
            item.group_style.button
        )
        if button_decoration.background or button_decoration.border then
            extent = math.max(
                extent,
                -button_decoration.visual_y1,
                button_decoration.visual_y2
            )
        end

        local style = item.group_style.group
        local background = style.background and style.alpha ~= "FF"
        local border = style.border and style.border_width > 0 and style.border_alpha ~= "FF"
        if background or border then
            extent = math.max(
                extent,
                style.height / 2 + (border and style.border_width or 0)
            )
        end
        return extent
    end
    local function anchored_y(item)
        local top, bottom
        if item.anchor_space == "osc" then
            top, bottom = pill_y1, pill_y2
        else
            top, bottom = 0, screen_h
        end
        if item.anchor == "top" then
            local top_clearance = top
            local minimum_offset = math.max(
                0,
                anchored_visual_extent(item) - top_clearance
            )
            return top + math.max(cfg.OSC_TOP_OFFSET, minimum_offset)
        elseif item.anchor == "bottom" then
            local offset = cfg.OSC_BOTTOM_OFFSET
            local bottom_clearance = screen_h - bottom
            local minimum_offset = math.max(
                0,
                anchored_visual_extent(item) - bottom_clearance
            )
            return bottom - math.max(offset, minimum_offset)
        end
        return (top + bottom) / 2 + cfg.OSC_CENTER_OFFSET
    end
    local positions = {left = {}, center = {}, right = {}, by_id = {}, by_slot = {}}
    local valid_groups = {}

    local function valid_group_buttons(group)
        if valid_groups[group] then
            return valid_groups[group]
        end
        local valid = {}
        for _, item in ipairs(button_layout[group]) do
            if BUTTONS[item.id] then
                valid[#valid + 1] = item
            else
                msg.warn("cadre_osc: unknown button '" .. item.id .. "' in " .. group .. " layout")
            end
        end
        valid_groups[group] = valid
        return valid
    end

    local slot_seekbar_width = 0
    local seekbar_slot_count = 0
    local found_seekbar = false
    local has_title_slot = false
    local has_time_slot = false
    for _, group in ipairs({"left", "center", "right"}) do
        local valid, filtered = valid_group_buttons(group), {}
        for _, item in ipairs(valid) do
            if item.id == "seekbar" then
                if cfg.SEEKBAR_ENABLED then
                    if found_seekbar then
                        msg.warn("cadre_osc: configure the seekbar in only one OSC button slot")
                    else
                        found_seekbar = true
                        seekbar_slot_count = 1
                        filtered[#filtered + 1] = item
                    end
                end
            else
                filtered[#filtered + 1] = item
                if item.id == "title" then
                    has_title_slot = true
                elseif item.id == "time" then
                    has_time_slot = true
                end
            end
        end
        valid_groups[group] = filtered
    end

    local floating_title = cfg.TITLE_ENABLED and not has_title_slot
    local title_seekbar_offset = not structured_layout and floating_title and cfg.TITLE_POSITION == "above_seekbar"
            and cfg.SEEKBAR_POSITION == "top"
            and (cfg.TITLE_SIZE + cfg.TITLE_SEEKBAR_GAP * 2) or 0
    local panel_top_seekbar_inset = seekbar_panel_inset or cfg.SEEKBAR_BAR_Y_OFFSET
    seekbar_y = pill_y1 + panel_top_seekbar_inset + title_seekbar_offset

    local button_extent = cfg.ICON_SIZE / 2
    for _, group in ipairs({"left", "center", "right"}) do
        for _, item in ipairs(valid_groups[group]) do
            if not item.anchor then
                local item_width, item_height = button_dimensions(item)
                button_extent = math.max(button_extent, item_height / 2)
                if item.id ~= "seekbar" then
                    local decoration = item_decoration_bounds(0, 0, item_width, item.group_style.button)
                    if decoration.background or decoration.border then
                        button_extent = math.max(
                            button_extent,
                            -decoration.visual_y1,
                            decoration.visual_y2
                        )
                    end
                end
            end
        end
    end
    for _, group in ipairs({"left", "center", "right"}) do
        for _, item in ipairs(valid_groups[group]) do
            if not item.anchor then
                local style = item.group_style.group
                local background = style.background and style.alpha ~= "FF"
                local border = style.border and style.border_width > 0 and style.border_alpha ~= "FF"
                if background or border then
                    button_extent = math.max(
                        button_extent,
                        style.height / 2 + (border and style.border_width or 0)
                    )
                end
            end
        end
    end
    if not structured_layout then
        if cfg.BUTTON_Y_ANCHOR == "top" then
            row_y = math.max(row_y, pill_y1 + button_extent)
        elseif cfg.BUTTON_Y_ANCHOR == "bottom" then
            row_y = math.min(row_y, pill_y2 - button_extent)
        end
    end
    local required_below_row = 0
    if floating_title and cfg.TITLE_POSITION == "below_osc" then
        required_below_row = button_extent + cfg.TITLE_SIZE + cfg.TITLE_GAP * 2
    end
    if cfg.SEEKBAR_ENABLED and not found_seekbar and cfg.SEEKBAR_POSITION == "below_buttons" then
        local title_before_seekbar = floating_title and
            cfg.TITLE_POSITION == "above_seekbar" and
            (cfg.TITLE_SIZE + cfg.TITLE_SEEKBAR_GAP) or 0
        local title_after_seekbar = floating_title and
            (cfg.TITLE_POSITION == "below_seekbar" or cfg.TITLE_POSITION == "below_osc") and
            (cfg.TITLE_SIZE + cfg.TITLE_GAP * 2) or 0
        required_below_row = math.max(
            required_below_row,
            button_extent + cfg.SEEKBAR_BUTTON_GAP +
                title_before_seekbar + seekbar_extent * 2 + title_after_seekbar
        )
    end
    if required_below_row > 0 and not structured_layout then
        if cfg.BUTTON_Y_ANCHOR == "bottom" then
            row_y = math.min(row_y, pill_y2 - required_below_row)
        else
            row_y = math.max(row_y, pill_y2 - required_below_row)
        end
    end
    if cfg.SEEKBAR_ENABLED and not structured_layout and not found_seekbar and cfg.SEEKBAR_POSITION == "top" then
        local title_after_seek = floating_title and
            cfg.TITLE_POSITION == "below_seekbar" and
            (cfg.TITLE_SIZE + cfg.TITLE_GAP) or 0
        local title_below_seekbar = floating_title and cfg.TITLE_POSITION == "below_seekbar"
        local time_label_above = cfg.TIME_LABEL_POSITION == "above_seekbar" or
            (cfg.TIME_LABEL_POSITION == "auto" and title_below_seekbar)
        local standalone_time_below = (cfg.SEEKBAR_START_LABEL or cfg.SEEKBAR_END_LABEL) and not has_time_slot
            and cfg.TIME_LABEL_POSITION ~= "inline"
            and not time_label_above
        row_y = math.max(
            row_y,
            seekbar_y + seekbar_extent + title_after_seek + cfg.SEEKBAR_BUTTON_GAP + button_extent
        )
        if standalone_time_below then
            local label_y = seekbar_y + cfg.TIME_LABEL_OFFSET_Y + 3
            local label_extent = cfg.FONT_SIZE / 2 + cfg.TIME_LABEL_OUTLINE_WIDTH
                + cfg.TIME_LABEL_OUTLINE_BLUR * 2
                + (cfg.TIME_LABEL_SHADOW > 0
                    and math.abs(cfg.TIME_LABEL_SHADOW_Y) + cfg.TIME_LABEL_SHADOW_BLUR * 2 or 0)
            row_y = math.max(
                row_y,
                label_y + label_extent + cfg.SEEKBAR_BUTTON_GAP + button_extent
            )
        end
    end

    local spacing_gap = math.max(0, spacing - cfg.ICON_SIZE)
    local function group_decoration_extra(group)
        local extra = 0
        for _, item in ipairs(valid_groups[group] or {}) do
            local style = item.group_style and item.group_style.group or {}
            local background = style.background and style.alpha ~= "FF"
            local border = style.border and style.border_width > 0 and style.border_alpha ~= "FF"
            if background or border then
                extra = math.max(
                    extra,
                    (style.padding or 0) + (border and style.border_width or 0)
                )
            end
        end
        return extra
    end
    local function valid_group_gap(value)
        if type(value) == "number" and value >= 0 and value < math.huge and value == value then
            return value
        end
        return nil
    end
    local general_group_gap = valid_group_gap(cfg.BUTTON_GROUP_GAP)
    local left_group_gap = valid_group_gap(cfg.BUTTON_GROUP_GAP_LEFT) or general_group_gap
    local right_group_gap = valid_group_gap(cfg.BUTTON_GROUP_GAP_RIGHT) or general_group_gap
    local has_group_gap_constraint = general_group_gap ~= nil
        or valid_group_gap(cfg.BUTTON_GROUP_GAP_LEFT) ~= nil
        or valid_group_gap(cfg.BUTTON_GROUP_GAP_RIGHT) ~= nil
    local function configured_group_gap(left_group, right_group)
        if left_group == "left" and right_group == "center" then
            return left_group_gap or 0
        elseif left_group == "center" and right_group == "right" then
            return right_group_gap or 0
        end
        if general_group_gap ~= nil then
            return general_group_gap
        end
        return math.max(left_group_gap or 0, right_group_gap or 0)
    end
    local function required_group_separation(left_group, right_group)
        return spacing_gap
            + group_decoration_extra(left_group)
            + group_decoration_extra(right_group)
            + configured_group_gap(left_group, right_group)
    end
    local function layout_group_separation(left_group, right_group)
        if has_group_gap_constraint then
            return required_group_separation(left_group, right_group)
        end
        return spacing_gap
    end
    local function item_visual_pad(item)
        if item.id == "seekbar" then
            return 0
        end
        local item_width = button_dimensions(item)
        return item_decoration_bounds(
            0,
            0,
            item_width,
            item.group_style.button
        ).horizontal_pad
    end
    local function gap_between(first_item, second_item)
        local item_spacing = first_item.style and first_item.style.spacing or spacing
        -- Keep the icon-sized baseline when a wide control sits beside an icon.
        local gap = math.max(0, item_spacing - cfg.ICON_SIZE)
        return gap + item_visual_pad(first_item) + item_visual_pad(second_item)
    end
    local function group_content_width(group, seekbar_width)
        local ids = valid_groups[group] or {}
        local width = 0
        for index, item in ipairs(ids) do
            local item_width = button_dimensions(item)
            if item.id == "seekbar" then
                item_width = seekbar_width or 0
            end
            width = width + item_width
            if index < #ids then
                width = width + gap_between(item, ids[index + 1])
            end
        end
        if #ids > 0 then
            width = width + item_visual_pad(ids[1]) + item_visual_pad(ids[#ids])
        end
        return width
    end
    local function group_fixed_width(group)
        return group_content_width(group, 0)
    end
    local group_widths = {}
    local function group_width(group)
        return group_widths[group] or 0
    end
    local function constrained_group_width(group, natural_width, minimum_width)
        if #(valid_groups[group] or {}) == 0 then
            return 0
        end
        minimum_width = minimum_width or natural_width
        local settings = cfg.BUTTON_GROUP_LAYOUT[group]
        local min_width = resolve_group_width(settings.min_width, button_x2 - button_x1)
        local max_width = resolve_group_width(settings.max_width, button_x2 - button_x1)
        if min_width and max_width and min_width > max_width then
            if not settings.invalid_range_reported then
                msg.warn("cadre_osc: minimum width exceeds maximum width for the " .. group .. " button group")
                settings.invalid_range_reported = true
            end
            max_width = min_width
        end
        if max_width and max_width < minimum_width and not settings.invalid_range_reported then
            if not settings.content_exceeds_max_reported then
                msg.warn("cadre_osc: fixed items exceed the maximum width for the " .. group .. " button group")
                settings.content_exceeds_max_reported = true
            end
            max_width = minimum_width
        end
        local requested_width = resolve_group_width(settings.width, button_x2 - button_x1)
        local width = requested_width or natural_width
        if min_width then
            width = math.max(width, min_width)
        end
        if max_width then
            width = math.min(width, max_width)
        end
        return math.max(minimum_width, width)
    end
    for _, group in ipairs({"left", "center", "right"}) do
        group_widths[group] = constrained_group_width(group, group_fixed_width(group))
    end

    if seekbar_slot_count > 0 then
        local flex_group
        for _, group in ipairs({"left", "center", "right"}) do
            for _, item in ipairs(valid_groups[group] or {}) do
                if item.id == "seekbar" then
                    flex_group = group
                end
            end
        end

        local fixed_width = group_fixed_width(flex_group)
        local settings = cfg.BUTTON_GROUP_LAYOUT[flex_group]
        local requested_width = resolve_group_width(settings.width, button_x2 - button_x1)
        local available
        local center_seekbar_x1
        if requested_width then
            available = math.max(0, group_widths[flex_group] - fixed_width)
            if has_group_gap_constraint and flex_group == "center" then
                local left_width = group_widths.left
                local right_width = group_widths.right
                local left_end = button_x1 + left_width
                local right_start = button_x2 - right_width
                local left_active = #valid_groups.left > 0 and left_width > 0
                local right_active = #valid_groups.right > 0 and right_width > 0
                local lower = left_active
                    and left_end + required_group_separation("left", "center") or button_x1
                local upper = right_active
                    and right_start - required_group_separation("center", "right") or button_x2
                available = math.min(available, math.max(0, upper - lower - fixed_width))
                center_seekbar_x1 = lower
            end
        else
            local left_width = group_widths.left
            local center_width = group_widths.center
            local right_width = group_widths.right
            local left_end = button_x1 + left_width
            local center_start = screen_w / 2 - center_width / 2
            local center_end = center_start + center_width
            local right_start = button_x2 - right_width
            local left_active = #valid_groups.left > 0 and left_width > 0
            local center_active = #valid_groups.center > 0 and center_width > 0
            local right_active = #valid_groups.right > 0 and right_width > 0

            if flex_group == "left" then
                local boundary = button_x2
                if center_active then
                    boundary = math.min(boundary,
                        center_start - layout_group_separation("left", "center"))
                end
                if right_active then
                    boundary = math.min(boundary,
                        right_start - layout_group_separation("left", "right"))
                end
                local edge_gap = 0
                available = boundary - button_x1 - fixed_width - edge_gap
            elseif flex_group == "right" then
                local boundary = button_x1
                if left_active then
                    boundary = math.max(boundary,
                        left_end + layout_group_separation("left", "right"))
                end
                if center_active then
                    boundary = math.max(boundary,
                        center_end + layout_group_separation("center", "right"))
                end
                local edge_gap = 0
                available = button_x2 - boundary - fixed_width - edge_gap
            else
                local lower = button_x1
                local upper = button_x2
                if left_active then
                    lower = left_end + required_group_separation("left", flex_group)
                end
                if right_active then
                    upper = right_start - required_group_separation(flex_group, "right")
                end
                available = upper - lower - fixed_width
                center_seekbar_x1 = lower
            end

            local natural_width = fixed_width + math.max(0, available)
            group_widths[flex_group] = constrained_group_width(flex_group, natural_width, fixed_width)
            available = math.max(0, group_widths[flex_group] - fixed_width)
        end
        slot_seekbar_width = available
        positions.center_seekbar_x1 = center_seekbar_x1
    end

    local function place_group(group, box_x1, direction)
        local ids = valid_group_buttons(group)
        if #ids == 0 then
            return
        end
        local box_width = group_width(group)
        local content_width = group_content_width(group, slot_seekbar_width)
        local content_x1 = box_x1
        local free_width = math.max(0, box_width - content_width)
        local align = cfg.BUTTON_GROUP_LAYOUT[group].align
        if align == "center" then
            content_x1 = content_x1 + free_width / 2
        elseif align == "end" then
            content_x1 = content_x1 + free_width
        end
        local cursor = direction > 0
            and content_x1 + item_visual_pad(ids[1])
            or content_x1 + content_width - item_visual_pad(ids[#ids])
        for index = 1, #ids do
            local item = direction < 0 and ids[#ids - index + 1] or ids[index]
            local id = item.id
            local item_width, height = button_dimensions(item)
            if id == "seekbar" then
                item_width = slot_seekbar_width
            end
            local x = direction > 0 and cursor + item_width / 2 or cursor - item_width / 2
            local button = {
                id = id,
                slot = item.slot,
                anchor = item.anchor,
                anchor_space = item.anchor_space,
                group = group == "left" and "L" or group == "center" and "C" or "R",
                group_style_key = item.group_style_key,
                group_style = item.group_style,
                icon_style = item.icon_style,
                style = item.style,
                x = x,
                y = item.anchor and anchored_y(item) or row_y,
                width = item_width,
                height = height
            }
            positions[group][#positions[group] + 1] = button
            positions.by_id[id] = positions.by_id[id] or button.x
            positions.by_slot[button.slot] = button
            if id == "seekbar" then
                positions.seekbar = button
            end
            if direction > 0 then
                cursor = cursor + item_width
                if index < #ids then
                    cursor = cursor + gap_between(item, ids[index + 1])
                end
            else
                cursor = cursor - item_width
                if index < #ids then
                    cursor = cursor - gap_between(ids[#ids - index], item)
                end
            end
        end
    end

    local group_bounds = {}
    local function place_all_groups()
        local left_width = group_width("left")
        local right_width = group_width("right")
        local center_width = group_width("center")
        local center_start = positions.center_seekbar_x1 or (screen_w / 2 - center_width / 2)
        group_bounds.left = {x1 = button_x1, x2 = button_x1 + left_width}
        group_bounds.center = {x1 = center_start, x2 = center_start + center_width}
        group_bounds.right = {x1 = button_x2 - right_width, x2 = button_x2}
        place_group("left", group_bounds.left.x1, 1)
        place_group("right", group_bounds.right.x1, -1)
        place_group("center", center_start, 1)
    end

    place_all_groups()
    if has_named_button and #positions.left == 0 and #positions.center == 0 and #positions.right == 0 then
        msg.warn("cadre_osc: no valid configured buttons; using default layout")
        button_layout = default_button_layout()
        positions = {left = {}, center = {}, right = {}, by_id = {}, by_slot = {}}
        positions.seekbar = nil
        valid_groups = {}
        positions.center_seekbar_x1 = nil
        slot_seekbar_width = 0
        for _, group in ipairs({"left", "center", "right"}) do
            valid_group_buttons(group)
            group_widths[group] = constrained_group_width(group, group_fixed_width(group))
        end
        place_all_groups()
    end

    local has_anchored_buttons = false
    for _, group in ipairs({"left", "center", "right"}) do
        for _, button in ipairs(positions[group]) do
            if button.anchor then
                has_anchored_buttons = true
                break
            end
        end
        if has_anchored_buttons then
            break
        end
    end
    if has_anchored_buttons then
        if positions.seekbar then
            local seekbar_group
            local row_buttons = {left = {}, center = {}, right = {}}
            for _, group in ipairs({"left", "center", "right"}) do
                for _, button in ipairs(positions[group]) do
                    if button.y == positions.seekbar.y then
                        row_buttons[group][#row_buttons[group] + 1] = button
                    end
                    if button.id == "seekbar" then
                        seekbar_group = group
                    end
                end
            end

            local function row_content_width(group, seekbar_width)
                local buttons = row_buttons[group]
                local width = 0
                for index, button in ipairs(buttons) do
                    width = width + (button.id == "seekbar" and seekbar_width or button.width)
                    if index < #buttons then
                        local first, second = button, buttons[index + 1]
                        if group == "right" then
                            first, second = second, first
                        end
                        width = width + gap_between(first, second)
                    end
                end
                if #buttons > 0 then
                    width = width
                        + item_visual_pad(buttons[1])
                        + item_visual_pad(buttons[#buttons])
                end
                return width
            end

            local fixed_width = row_content_width(seekbar_group, 0)
            local requested_width = resolve_group_width(
                cfg.BUTTON_GROUP_LAYOUT[seekbar_group].width,
                button_x2 - button_x1
            )
            local available
            local center_seekbar_x1
            if requested_width then
                local width = constrained_group_width(seekbar_group, requested_width, fixed_width)
                available = math.max(0, width - fixed_width)
                if has_group_gap_constraint and seekbar_group == "center" then
                    local left_width = row_content_width("left")
                    local right_width = row_content_width("right")
                    local left_end = button_x1 + left_width
                    local right_start = button_x2 - right_width
                    local left_active = #row_buttons.left > 0 and left_width > 0
                    local right_active = #row_buttons.right > 0 and right_width > 0
                    local lower = left_active
                        and left_end + required_group_separation("left", "center") or button_x1
                    local upper = right_active
                        and right_start - required_group_separation("center", "right") or button_x2
                    available = math.min(available, math.max(0, upper - lower - fixed_width))
                    center_seekbar_x1 = lower
                end
            else
                local row_widths = {}
                for _, group in ipairs({"left", "center", "right"}) do
                    local natural_width = group == seekbar_group
                        and fixed_width or row_content_width(group)
                    row_widths[group] = constrained_group_width(group, natural_width)
                end
                local left_width = row_widths.left
                local center_width = row_widths.center
                local right_width = row_widths.right
                local left_end = button_x1 + left_width
                local center_start = screen_w / 2 - center_width / 2
                local center_end = center_start + center_width
                local right_start = button_x2 - right_width
                local left_active = #row_buttons.left > 0 and left_width > 0
                local center_active = #row_buttons.center > 0 and center_width > 0
                local right_active = #row_buttons.right > 0 and right_width > 0

                if seekbar_group == "left" then
                    local boundary = button_x2
                    if center_active then
                        boundary = math.min(boundary,
                            center_start - layout_group_separation("left", "center"))
                    end
                    if right_active then
                        boundary = math.min(boundary,
                            right_start - layout_group_separation("left", "right"))
                    end
                    local edge_gap = 0
                    available = boundary - button_x1 - fixed_width - edge_gap
                elseif seekbar_group == "right" then
                    local boundary = button_x1
                    if left_active then
                        boundary = math.max(boundary,
                            left_end + layout_group_separation("left", "right"))
                    end
                    if center_active then
                        boundary = math.max(boundary,
                            center_end + layout_group_separation("center", "right"))
                    end
                    local edge_gap = 0
                    available = button_x2 - boundary - fixed_width - edge_gap
                else
                    local lower = button_x1
                    local upper = button_x2
                    if left_active then
                        lower = left_end + required_group_separation("left", seekbar_group)
                    end
                    if right_active then
                        upper = right_start - required_group_separation(seekbar_group, "right")
                    end
                    available = upper - lower - fixed_width
                    center_seekbar_x1 = lower
                end

                local natural_width = fixed_width + math.max(0, available)
                local width = constrained_group_width(seekbar_group, natural_width, fixed_width)
                available = math.max(0, width - fixed_width)
            end
            slot_seekbar_width = available
            positions.seekbar.width = available
            positions.seekbar.row_start_x = center_seekbar_x1
        end

        for _, group in ipairs({"left", "center", "right"}) do
            local union_x1, union_x2
            for _, row in ipairs(group_buttons_by_y(positions[group], row_y)) do
                local buttons = row.buttons
                local content_width = 0
                for index, button in ipairs(buttons) do
                    content_width = content_width + button.width
                    if index < #buttons then
                        local first, second = button, buttons[index + 1]
                        if group == "right" then
                            first, second = second, first
                        end
                        content_width = content_width + gap_between(first, second)
                    end
                end
                if #buttons > 0 then
                    content_width = content_width
                        + item_visual_pad(buttons[1])
                        + item_visual_pad(buttons[#buttons])
                end
                local box_width = constrained_group_width(group, content_width)
                local box_x1
                if group == "left" then
                    box_x1 = button_x1
                elseif group == "right" then
                    box_x1 = button_x2 - box_width
                else
                    local seekbar
                    for _, button in ipairs(buttons) do
                        if button.id == "seekbar" then
                            seekbar = button
                            break
                        end
                    end
                    box_x1 = seekbar and seekbar.row_start_x
                        or screen_w / 2 - box_width / 2
                end
                local content_x1 = box_x1
                local free_width = math.max(0, box_width - content_width)
                local align = cfg.BUTTON_GROUP_LAYOUT[group].align
                if align == "center" then
                    content_x1 = content_x1 + free_width / 2
                elseif align == "end" then
                    content_x1 = content_x1 + free_width
                end
                local cursor = group == "right"
                    and content_x1 + content_width - item_visual_pad(buttons[1])
                    or content_x1 + item_visual_pad(buttons[1])
                for index = 1, #buttons do
                    local button = buttons[index]
                    if group == "right" then
                        button.x = cursor - button.width / 2
                        cursor = cursor - button.width
                        if index < #buttons then
                            cursor = cursor - gap_between(buttons[index + 1], buttons[index])
                        end
                    else
                        button.x = cursor + button.width / 2
                        cursor = cursor + button.width
                        if index < #buttons then
                            cursor = cursor + gap_between(button, buttons[index + 1])
                        end
                    end
                    positions.by_id[button.id] = positions.by_id[button.id] or button.x
                    positions.by_slot[button.slot] = button
                    button.row_bounds = {x1 = box_x1, x2 = box_x1 + box_width}
                end
                union_x1 = math.min(union_x1 or box_x1, box_x1)
                union_x2 = math.max(union_x2 or box_x1 + box_width, box_x1 + box_width)
            end
            if union_x1 then
                group_bounds[group] = {x1 = union_x1, x2 = union_x2}
            end
        end
    end

    local function group_visual_bounds(group)
        local buttons = positions[group]
        if #buttons == 0 then
            return {}
        end

        local rows = {}
        for _, row in ipairs(group_buttons_by_y(buttons, row_y)) do
            local x1, x2 = math.huge, -math.huge
            local y1, y2 = math.huge, -math.huge
            for _, button in ipairs(row.buttons) do
                local bounds = item_decoration_bounds(
                    button.x,
                    row.y,
                    button.width,
                    button.group_style.button
                )
                x1 = math.min(x1, bounds.visual_x1)
                x2 = math.max(x2, bounds.visual_x2)
                y1 = math.min(y1, bounds.visual_y1)
                y2 = math.max(y2, bounds.visual_y2)
            end
            local group_surface = group_decoration_bounds(
                row.buttons,
                row.y,
                not row.buttons[1].anchor and
                    (row.buttons[1].row_bounds or group_bounds[group]) or nil,
                group,
                row.buttons[1].group_style.group
            )
            if group_surface then
                x1 = math.min(x1, group_surface.visual_x1)
                x2 = math.max(x2, group_surface.visual_x2)
                y1 = math.min(y1, group_surface.visual_y1)
                y2 = math.max(y2, group_surface.visual_y2)
            end
            rows[#rows + 1] = {name = group, x1 = x1, x2 = x2, y1 = y1, y2 = y2}
        end

        return rows
    end

    local function vertical_bounds_overlap(first, second)
        return first.y2 > second.y1 and second.y2 > first.y1
    end
    if has_group_gap_constraint and #positions.center > 0 then
        local center_rows = group_visual_bounds("center")
        local left_rows = group_visual_bounds("left")
        local right_rows = group_visual_bounds("right")
        local min_delta, max_delta = -math.huge, math.huge

        for _, center_row in ipairs(center_rows) do
            for _, left_row in ipairs(left_rows) do
                if vertical_bounds_overlap(center_row, left_row) then
                    local gap = configured_group_gap("left", "center")
                    min_delta = math.max(min_delta, gap - (center_row.x1 - left_row.x2))
                end
            end
            for _, right_row in ipairs(right_rows) do
                if vertical_bounds_overlap(center_row, right_row) then
                    local gap = configured_group_gap("center", "right")
                    max_delta = math.min(max_delta, (right_row.x1 - center_row.x2) - gap)
                end
            end
        end

        if min_delta > -math.huge or max_delta < math.huge then
            local delta
            if min_delta <= max_delta then
                delta = math.max(min_delta, math.min(0, max_delta))
            else
                delta = (min_delta + max_delta) / 2
            end
            if delta ~= 0 then
                for _, button in ipairs(positions.center) do
                    button.x = button.x + delta
                    if button.row_bounds then
                        button.row_bounds.x1 = button.row_bounds.x1 + delta
                        button.row_bounds.x2 = button.row_bounds.x2 + delta
                    end
                    positions.by_id[button.id] = button.x
                end
                if positions.center_seekbar_x1 then
                    positions.center_seekbar_x1 = positions.center_seekbar_x1 + delta
                end
                if group_bounds.center then
                    group_bounds.center.x1 = group_bounds.center.x1 + delta
                    group_bounds.center.x2 = group_bounds.center.x2 + delta
                end
            end
        end
    end

    local visual_groups = {}
    for _, group in ipairs({"left", "center", "right"}) do
        for _, bounds in ipairs(group_visual_bounds(group)) do
            visual_groups[#visual_groups + 1] = bounds
        end
    end
    table.sort(visual_groups, function(a, b) return a.x1 < b.x1 end)

    local overlapping_groups = {}
    local reported_overlaps = {}
    for first_index = 1, #visual_groups - 1 do
        for second_index = first_index + 1, #visual_groups do
            local first, second = visual_groups[first_index], visual_groups[second_index]
            local horizontal_overlap = first.x2 > second.x1 and second.x2 > first.x1
            local vertical_overlap = first.y2 > second.y1 and second.y2 > first.y1
            local overlap_name = first.name .. " and " .. second.name
            if first.name ~= second.name and horizontal_overlap and vertical_overlap
                and not reported_overlaps[overlap_name] then
                overlapping_groups[#overlapping_groups + 1] = overlap_name
                reported_overlaps[overlap_name] = true
            end
        end
    end
    local group_overlap_key = table.concat(overlapping_groups, ", ")
    if group_overlap_key ~= "" and group_overlap_key ~= last_group_overlap_key then
        msg.warn(
            "cadre_osc: visual bounds of the " .. group_overlap_key ..
                " button groups overlap; reduce group widths, controls, or visual padding"
        )
    end
    last_group_overlap_key = group_overlap_key ~= "" and group_overlap_key or nil

    local seekbar_x1, seekbar_x2
    if positions.seekbar then
        seekbar_x1 = positions.seekbar.x - positions.seekbar.width / 2
        seekbar_x2 = positions.seekbar.x + positions.seekbar.width / 2
        seekbar_y = positions.seekbar.anchor and positions.seekbar.y or row_y
    elseif cfg.SEEKBAR_ENABLED then
        seekbar_x1 = pill_x1 + cfg.SEEKBAR_SIDE_INSET
        seekbar_x2 = pill_x2 - cfg.SEEKBAR_SIDE_INSET
        local title_seekbar_extent = 0
        if floating_title and cfg.TITLE_POSITION == "above_seekbar" then
            title_seekbar_extent = cfg.TITLE_SIZE + cfg.TITLE_SEEKBAR_GAP
        elseif floating_title and cfg.TITLE_POSITION == "below_seekbar" then
            title_seekbar_extent = cfg.TITLE_SIZE + cfg.TITLE_GAP
        end
        if cfg.SEEKBAR_POSITION == "above_buttons" then
            seekbar_y = row_y - button_extent - cfg.SEEKBAR_BUTTON_GAP - title_seekbar_extent - seekbar_extent
        elseif cfg.SEEKBAR_POSITION == "below_buttons" then
            local title_before_seek = floating_title and
                cfg.TITLE_POSITION == "above_seekbar" and title_seekbar_extent or 0
            seekbar_y = row_y + button_extent + cfg.SEEKBAR_BUTTON_GAP + title_before_seek + seekbar_extent
        elseif cfg.SEEKBAR_POSITION == "panel_bottom" then
            seekbar_y = pill_y2 - cfg.SEEKBAR_PANEL_INSET - seekbar_extent
        elseif cfg.SEEKBAR_POSITION == "top" and not structured_layout then
            local title_after_seek = floating_title and
                cfg.TITLE_POSITION == "below_seekbar" and title_seekbar_extent or 0
            row_y = math.max(
                row_y,
                seekbar_y + seekbar_extent + title_after_seek + cfg.SEEKBAR_BUTTON_GAP + button_extent
            )
        end
        seekbar_y = seekbar_y + cfg.SEEKBAR_BAR_Y_OFFSET
    else
        seekbar_x1, seekbar_x2 = pill_x1, pill_x1
        seekbar_y = row_y
    end

    for _, group in ipairs({"left", "center", "right"}) do
        for _, button in ipairs(positions[group]) do
            if not button.anchor then
                button.y = row_y
            end
        end
    end

    -- A slotted seekbar keeps its full flex slot for layout and group
    -- decoration, while the visible track can be inset within that slot.
    local track_x1, track_x2 = seekbar_x1, seekbar_x2
    if positions.seekbar then
        track_x1 = seekbar_x1 + cfg.SEEKBAR_SIDE_INSET
        track_x2 = seekbar_x2 - cfg.SEEKBAR_SIDE_INSET
    end
    if cfg.SEEKBAR_ENABLED and (cfg.SEEKBAR_START_LABEL or cfg.SEEKBAR_END_LABEL)
        and cfg.TIME_LABEL_POSITION == "inline" and not positions.by_id.time then
        local label_text = fmt_time(duration)
        local label_width_key = label_text .. "\0" .. cfg.FONT_SIZE .. "\0" .. cfg.UI_FONT
        if label_width_key ~= inline_time_width_key then
            inline_time_width = measure_text_width(label_text, cfg.FONT_SIZE, cfg.UI_FONT)
            inline_time_width_key = label_width_key
        end
        local inset = inline_time_width + cfg.TIME_LABEL_INLINE_GAP
        if cfg.SEEKBAR_START_LABEL then
            track_x1 = track_x1 + inset
        end
        if cfg.SEEKBAR_END_LABEL then
            track_x2 = track_x2 - inset
        end
    end

    local content_top, content_bottom = math.huge, -math.huge
    local function include_vertical_bounds(center_y, extent)
        content_top = math.min(content_top, center_y - extent)
        content_bottom = math.max(content_bottom, center_y + extent)
    end

    local title_effect_extent = cfg.TITLE_SIZE / 2 + cfg.TITLE_OUTLINE_WIDTH + cfg.TITLE_OUTLINE_BLUR * 2
        + (cfg.TITLE_SHADOW > 0 and math.abs(cfg.TITLE_SHADOW_Y) + cfg.TITLE_SHADOW_BLUR * 2 or 0)
    local time_effect_extent = cfg.FONT_SIZE / 2 + cfg.TIME_LABEL_OUTLINE_WIDTH + cfg.TIME_LABEL_OUTLINE_BLUR * 2
        + (cfg.TIME_LABEL_SHADOW > 0 and math.abs(cfg.TIME_LABEL_SHADOW_Y) + cfg.TIME_LABEL_SHADOW_BLUR * 2 or 0)

    for _, group in ipairs({"left", "center", "right"}) do
        for _, button in ipairs(positions[group]) do
            local definition = BUTTONS[button.id]
            local extent = button.height / 2
            if definition.kind ~= "seekbar" and definition.kind ~= "separator" then
                local decoration = item_decoration_bounds(
                    button.x,
                    button.y,
                    button.width,
                    button.group_style.button
                )
                if decoration.background or decoration.border then
                    extent = math.max(
                        extent,
                        button.y - decoration.visual_y1,
                        decoration.visual_y2 - button.y
                    )
                end
            end
            if definition.kind == "title" then
                extent = math.max(
                    extent,
                    (button.style.font_size or cfg.TITLE_SIZE) / 2
                        + cfg.TITLE_OUTLINE_WIDTH + cfg.TITLE_OUTLINE_BLUR * 2
                        + (cfg.TITLE_SHADOW > 0 and math.abs(cfg.TITLE_SHADOW_Y)
                            + cfg.TITLE_SHADOW_BLUR * 2 or 0)
                )
            elseif definition.kind == "time" then
                extent = math.max(
                    extent,
                    (button.style.font_size or cfg.FONT_SIZE) / 2
                        + cfg.TIME_LABEL_OUTLINE_WIDTH + cfg.TIME_LABEL_OUTLINE_BLUR * 2
                        + (cfg.TIME_LABEL_SHADOW > 0 and math.abs(cfg.TIME_LABEL_SHADOW_Y)
                            + cfg.TIME_LABEL_SHADOW_BLUR * 2 or 0)
                )
            end
            if not button.anchor then
                include_vertical_bounds(button.y, extent)
            end
        end
        for _, row in ipairs(group_buttons_by_y(positions[group], row_y)) do
            local has_unanchored_button = false
            for _, button in ipairs(row.buttons) do
                if not button.anchor then
                    has_unanchored_button = true
                    break
                end
            end
            if has_unanchored_button then
                local group_surface = group_decoration_bounds(
                    row.buttons,
                    row.y,
                    not row.buttons[1].anchor and
                        (row.buttons[1].row_bounds or group_bounds[group]) or nil,
                    group,
                    row.buttons[1].group_style.group
                )
                if group_surface then
                    include_vertical_bounds(
                        row.y,
                        math.max(row.y - group_surface.visual_y1, group_surface.visual_y2 - row.y)
                    )
                end
            end
        end
    end

    local seekbar_visual_extent = math.max(
        cfg.THUMB_WH + cfg.THUMB_WBORDER_WIDTH,
        cfg.SEEKBAR_HEIGHT_HOVER / 2 + cfg.SEEKBAR_BORDER_WIDTH,
        cfg.SEEKBAR_HEIGHT_NORMAL / 2 + cfg.SEEKBAR_BORDER_WIDTH
    )
    if not (positions.seekbar and positions.seekbar.anchor) then
        include_vertical_bounds(seekbar_y, seekbar_visual_extent)
    end

    local title_below_seekbar = floating_title and
        cfg.TITLE_POSITION == "below_seekbar"
    local time_label_above = cfg.TIME_LABEL_POSITION == "above_seekbar" or
        (cfg.TIME_LABEL_POSITION == "auto" and title_below_seekbar)
    local time_label_y = cfg.TIME_LABEL_POSITION == "inline" and seekbar_y or
        seekbar_y + (time_label_above and -(cfg.TIME_LABEL_OFFSET_Y + 3)
            or (cfg.TIME_LABEL_OFFSET_Y + 3))
    if (cfg.SEEKBAR_START_LABEL or cfg.SEEKBAR_END_LABEL) and not positions.by_id.time then
        include_vertical_bounds(time_label_y, time_effect_extent)
    end

    if floating_title then
        local above = cfg.TITLE_POSITION == "above_seekbar" or cfg.TITLE_POSITION == "above_osc"
        local title_y
        if cfg.TITLE_POSITION == "above_seekbar" or cfg.TITLE_POSITION == "below_seekbar" then
            local gap = above and cfg.TITLE_SEEKBAR_GAP or cfg.TITLE_GAP
            local track_extent = math.max(cfg.THUMB_WH, cfg.SEEKBAR_HEIGHT_HOVER / 2)
            title_y = seekbar_y + (above and -1 or 1) *
                (track_extent + gap + cfg.TITLE_SIZE / 2)
        else
            title_y = above
                and pill_y1 + cfg.TITLE_GAP + cfg.TITLE_SIZE / 2
                or pill_y2 - cfg.TITLE_GAP - cfg.TITLE_SIZE / 2
        end
        include_vertical_bounds(title_y, title_effect_extent)
    end

    local top_overflow = math.max(0, pill_y1 - content_top)
    local bottom_overflow = math.max(0, content_bottom - pill_y2)
    if top_overflow > 0 or bottom_overflow > 0 then
        local content_span = math.ceil(content_bottom - content_top)
        local overflow_key = string.format(
            "%d:%d:%d",
            math.ceil(top_overflow),
            math.ceil(bottom_overflow),
            content_span
        )
        if overflow_key ~= last_vertical_overflow_key then
            msg.warn(
                string.format(
                    "cadre_osc: OSC content exceeds the bar bounds (top %.0f px, bottom %.0f px); " ..
                        "measured content span is %d px, bar_height_osc is %.0f; " ..
                        "increase the bar height or adjust anchors and offsets",
                    top_overflow,
                    bottom_overflow,
                    content_span,
                    cfg.BAR_HEIGHT
                )
            )
        end
        last_vertical_overflow_key = overflow_key
    else
        last_vertical_overflow_key = nil
    end

    return {
        pill_x1 = pill_x1,
        pill_x2 = pill_x2,
        pill_y1 = pill_y1,
        pill_y2 = pill_y2,
        seekbar_x1 = seekbar_x1,
        seekbar_x2 = seekbar_x2,
        track_x1 = track_x1,
        track_x2 = track_x2,
        button_x1 = button_x1,
        button_x2 = button_x2,
        seekbar_y = seekbar_y,
        seekbar_anchor_space = positions.seekbar and positions.seekbar.anchor_space or nil,
        row_y = row_y,
        button_group_bounds = group_bounds,
        buttons = positions
    }
end

