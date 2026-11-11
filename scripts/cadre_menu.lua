-- Cadre's standalone, theme-aware context menu.
local mp = require "mp"
local msg = require "mp.msg"
local assdraw = require "mp.assdraw"
local unpack_args = table.unpack or unpack
local common = dofile(mp.command_native({"expand-path", "~~/scripts/cadre/scripts/cadre_common.lua"}))
common.register_script("cadre_menu")

local base = mp.command_native({"expand-path", "~~/scripts/cadre/"})
local overlay = mp.create_osd_overlay("ass-events")
local menu = {}
local hidden, replace_defaults = {}, false
local opened, mouse_x, mouse_y, anchor_x, anchor_y = false, 0, 0, 0, 0
local stack, boxes, root_items = {}, {}, {}
local root_selected, root_first, active_depth = 1, 1, 0
local scrollbar_drag_depth
local submenu_hover_timer, submenu_hover_depth, submenu_hover_item
local ROW_H, PAD, WIDTH, MAX_VISIBLE_ITEMS = 34, 8, 250, 12
overlay.z = 1000

local function clamp_number(value, fallback, min_value, max_value)
  value = tonumber(value) or fallback
  return math.max(min_value, math.min(max_value, value))
end

local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
local function split_words(command)
  local words, word = {}, {}
  local quote, escaped, started = nil, false, false
  local function finish()
    if started then words[#words + 1] = table.concat(word); word = {}; started = false end
  end
  for i = 1, #command do
    local char = command:sub(i, i)
    if escaped then
      word[#word + 1] = char
      escaped, started = false, true
    elseif quote then
      if char == quote then quote = nil
      elseif char == "\\" and quote == '"' then escaped = true
      else word[#word + 1] = char end
      started = true
    elseif char == '"' or char == "'" then
      quote, started = char, true
    elseif char:match("%s") then finish()
    else word[#word + 1] = char; started = true end
  end
  if quote or escaped then return nil end
  finish()
  return words
end
local function ass_escape(s)
  return tostring(s):gsub("\\", "\\\\"):gsub("{", "\\{"):gsub("}", "\\}"):gsub("\n", " ")
end
local function fit_text(text, max_width, font_size)
  text = tostring(text or "")
  local max_units = max_width / math.max(1, font_size)
  local used, chars, truncated = 0, {}, false
  local i = 1
  while i <= #text do
    local first = text:byte(i)
    local length = first < 0x80 and 1 or (first < 0xE0 and 2 or (first < 0xF0 and 3 or 4))
    local char = text:sub(i, i + length - 1)
    local units = length == 1 and 0.56 or 1.0
    if used + units > max_units then truncated = true; break end
    chars[#chars + 1] = char
    used, i = used + units, i + length
  end
  if i <= #text then truncated = true end
  if truncated then
    while #chars > 0 and used + 1.0 > max_units do
      local last = table.remove(chars)
      local first = last:byte(1)
      used = used - (first < 0x80 and 0.56 or 1.0)
    end
    chars[#chars + 1] = "…"
  end
  return table.concat(chars)
end
local function node(items, id, title)
  for _, item in ipairs(items) do
    if item.id == id and item.type == "submenu" then return item end
  end
  local item = {id=id, title=title, type="submenu", items={}}
  local insert_at
  if items == menu and not replace_defaults then
    for i, existing in ipairs(items) do
      if existing.id == "quit.separator" or existing.id == "quit_separator" then insert_at = i; break end
    end
  end
  if insert_at then table.insert(items, insert_at, item) else items[#items + 1] = item end
  return item
end
local function append_user_item(items, item)
  if items == menu and not replace_defaults then
    for i, existing in ipairs(items) do
      if existing.id == "quit.separator" or existing.id == "quit_separator" then table.insert(items, i, item); return end
    end
  end
  items[#items + 1] = item
end
-- menu.conf is intended to accept normal mpv input.conf commands, including
-- command prefixes and semicolon-separated command lists. Let mpv parse the
-- action instead of maintaining a partial command allowlist here.
local function valid_command(command)
  return type(command) == "string" and trim(command) ~= ""
end
local dynamic_sources = {
  audio_tracks=true, subtitle_tracks=true, editions=true, chapters=true, playlist_actions=true,
  playback_speed=true, ab_loop=true, video_rotation=true, video_mirror=true,
  video_zoom_pan=true, video_filters=true, audio_channels=true,
}
local function parse_file(path, is_user)
  local f = io.open(path, "r")
  if not f then return 0 end
  local count = 0
  local lines = {}
  for line in f:lines() do
    lines[#lines + 1] = line
  end

  if is_user then
    for _, raw in ipairs(lines) do
      if trim(raw) == "hide_all" then
        menu = {}
        replace_defaults = true
        break
      end
    end
  end

  for line_no, raw in ipairs(lines) do
    local line = trim(raw)
    if line ~= "" and not line:match("^#") then
      if is_user then
        if line == "hide_all" then replace_defaults = true; count = count + 1
        else
          local id = line:match("^hide%s+([%w_.%-]+)%s*$")
          if id then
            -- Keep the earlier descriptive ID accepted as an alias.
            hidden[id == "open.locate_current_file" and "open.locate" or id] = true
            count = count + 1
          else
            local action, entry_id, path_text = line:match("^(.-)%s+#!%s*([%w_.%-]+)%s*|%s*(.-)%s*$")
            if not action then
              action, path_text = line:match("^(.-)%s+#!%s*(.-)%s*$")
            end
            action = action and trim(action)
            local kind, source = "command", nil
            if action and action:match("^dynamic:") then
              kind, source = "dynamic", action:match("^dynamic:([%w_]+)$")
            elseif action == "separator" then kind = "separator" end
            local allowed_dynamic = dynamic_sources[source] == true
            local valid = kind == "separator" or (kind == "dynamic" and allowed_dynamic)
              or (kind == "command" and valid_command(action or "", true))
            local parts = {}
            for part in tostring(path_text or ""):gmatch("[^>]+") do
              part = trim(part)
              if part ~= "" then parts[#parts + 1] = part end
            end
            if valid and #parts > 0 then
              if not entry_id then
                local slugs = {}
                for _, part in ipairs(parts) do
                  slugs[#slugs + 1] = part:lower():gsub("[^%w]+", "_"):gsub("^_+", ""):gsub("_+$", "")
                end
                entry_id = table.concat(slugs, ".")
              end
              local target, parent_id = menu, ""
              local root_separator = kind == "separator" and #parts == 1 and parts[1]:lower() == "root"
              local parent_count = kind == "separator" and (root_separator and 0 or #parts) or #parts - 1
              for i = 1, parent_count do
                local slug = parts[i]:lower():gsub("[^%w]+", "_"):gsub("^_+", ""):gsub("_+$", "")
                parent_id = parent_id == "" and slug or (parent_id .. "." .. slug)
                target = node(target, parent_id, parts[i]).items
              end
              if kind == "dynamic" then
                append_user_item(target, {type="dynamic", id=entry_id, title=parts[#parts], source=source, custom=true})
              elseif kind == "separator" then
                append_user_item(target, {type="separator", id=entry_id, custom=true})
              else
                append_user_item(target, {type="command", id=entry_id, title=parts[#parts], command=action, custom=true})
              end
              count = count + 1
            else
              msg.warn("cadre_menu: menu.conf:" .. line_no .. ": expected hide <id>, hide_all, or command #! [id |] Menu > Item")
            end
          end
        end
      else
        local action, id, path_text = line:match("^(.-)%s+#!%s*([%w_.%-]+)%s*|%s*(.-)%s*$")
        local kind, source = "command", nil
        if action and action:match("^dynamic:") then
          kind, source = "dynamic", action:match("^dynamic:([%w_]+)$")
        elseif action == "separator" then kind = "separator" end
        local allowed_dynamic = dynamic_sources[source] == true
        local valid = kind == "separator" or (kind == "dynamic" and allowed_dynamic)
          or (kind == "command" and valid_command(action or "", false))
        if action and id and path_text and valid then
          local parts = {}; for part in path_text:gmatch("[^>]+") do parts[#parts + 1] = trim(part) end
          if #parts > 0 then
            local target = menu
            local parent_id = ""
            local root_separator = kind == "separator" and #parts == 1 and parts[1]:lower() == "root"
            local parent_count = kind == "separator" and (root_separator and 0 or #parts) or #parts - 1
            for i = 1, parent_count do
              local slug = parts[i]:lower():gsub("[^%w]+", "_"):gsub("^_+", ""):gsub("_+$", "")
              parent_id = parent_id == "" and slug or (parent_id .. "." .. slug)
              target = node(target, parent_id, parts[i]).items
            end
            if kind == "dynamic" then
              target[#target + 1] = {type="dynamic", id=id, title=parts[#parts], source=source}
            elseif kind == "separator" then
              target[#target + 1] = {type="separator", id=id}
            else target[#target + 1] = {type="command", id=id, title=parts[#parts], command=action} end
            count = count + 1
          end
        else msg.warn("cadre_menu: default menu line " .. line_no .. " is invalid or uses a disallowed action") end
      end
    end
  end
  f:close()
  return count
end

local defaults = base .. "data/cadre_menu_default.conf"
if parse_file(defaults, false) == 0 then msg.error("cadre_menu: no valid built-in menu entries") end
parse_file(base .. "menu.conf", true)

local function track_label(track, kind, ordinal)
  local parts = {}
  local title = trim(tostring(track.title or ""))
  local lang = trim(tostring(track.lang or ""))
  local codec = trim(tostring(track["codec-desc"] or track.codec or ""))
  if title ~= "" then parts[#parts + 1] = title end
  if lang ~= "" and lang:lower() ~= "und" and lang ~= title:lower() then parts[#parts + 1] = lang end
  if kind == "audio" then
    local channels = track["demux-channels"] or track["audio-channels"] or track["demux-channel-count"]
    if channels and tostring(channels) ~= "" then parts[#parts + 1] = tostring(channels) end
  end
  if codec ~= "" then parts[#parts + 1] = codec end
  if #parts == 0 then parts[1] = (kind == "audio" and "Audio" or "Subtitle") .. " Track " .. ordinal end
  parts[#parts + 1] = "[#" .. tostring(track.id or ordinal) .. "]"
  return table.concat(parts, " · ")
end
local function dynamic_audio_tracks()
  local tracks = mp.get_property_native("track-list", {})
  local items, ordinal = {}, 0
  for _, track in ipairs(type(tracks) == "table" and tracks or {}) do
    if track.type == "audio" and track.id ~= nil then
      ordinal = ordinal + 1
      items[#items + 1] = {type="command", id="audio_tracks." .. tostring(track.id),
        title=track_label(track, "audio", ordinal), checked=track.selected == true,
        action={property="aid", value=track.id}}
    end
  end
  return items
end
local function dynamic_subtitle_tracks()
  local tracks = mp.get_property_native("track-list", {})
  local current = mp.get_property("sid", "no")
  local items, ordinal = {}, 0
  for _, track in ipairs(type(tracks) == "table" and tracks or {}) do
    if track.type == "sub" and track.id ~= nil then
      ordinal = ordinal + 1
      if ordinal == 1 then
        items[#items + 1] = {type="command", id="subtitle_tracks.off", title="Off", checked=current == "no",
          action={property="sid", value="no"}}
      end
      items[#items + 1] = {type="command", id="subtitle_tracks." .. tostring(track.id),
        title=track_label(track, "sub", ordinal), checked=track.selected == true,
        action={property="sid", value=track.id}}
    end
  end
  return items
end
local function dynamic_editions()
  local editions = mp.get_property_native("edition-list", {})
  if type(editions) ~= "table" or #editions < 2 then return {} end
  local current = mp.get_property_number("current-edition", mp.get_property_number("edition", 0))
  local items = {}
  for i, edition in ipairs(editions) do
    local id = tonumber(edition.id) or (i - 1)
    local title = trim(tostring(edition.title or ""))
    if title == "" then title = "Edition " .. i end
    items[#items + 1] = {type="command", id="editions." .. tostring(id),
      title=title, checked=id == current,
      action={property="edition", value=id}}
  end
  return items
end
local function dynamic_chapters()
  local chapters = mp.get_property_native("chapter-list", {})
  if type(chapters) ~= "table" or #chapters == 0 then return {} end
  local current = mp.get_property_number("chapter", -1)
  local items = {}
  for i, chapter in ipairs(chapters) do
    local seconds = math.max(0, tonumber(chapter.time) or 0)
    local hh = math.floor(seconds / 3600)
    local mm = math.floor(seconds / 60) % 60
    local ss = math.floor(seconds) % 60
    local time = hh > 0 and string.format("%d:%02d:%02d", hh, mm, ss) or string.format("%02d:%02d", mm, ss)
    local title = trim(tostring(chapter.title or ""))
    if title == "" then title = "Chapter " .. i end
    items[#items + 1] = {type="command", id="chapters." .. tostring(i - 1),
      title=string.format("%02d  %s  ·  %s", i, title, time), checked=current == i - 1,
      action={property="chapter", value=i - 1}}
  end
  return items
end
local function dynamic_playlist_actions()
  local shuffle = mp.get_property_native("user-data/cadre_playlist/shuffle", false) == true
  local repeat_mode = mp.get_property("user-data/cadre_playlist/repeat", "off")
  return {
    {type="command", id="playlist.actions.shuffle", title="Shuffle", checked=shuffle,
      command="script-message toggle-shuffle"},
    {type="command", id="playlist.actions.repeat", title="Repeat: " .. repeat_mode,
      command="script-message cycle-repeat"},
  }
end

local function dynamic_playback_speed()
  local current = mp.get_property_number("speed", 1)
  local items = {}
  for _, speed in ipairs({0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2}) do
    items[#items + 1] = {type="command", id="playback.speed." .. tostring(speed),
      title=tostring(speed) .. "×", checked=math.abs(current - speed) < 0.001,
      action={property="speed", value=speed}}
  end
  return items
end

local function dynamic_ab_loop()
  local a = mp.get_property("ab-loop-a", "no")
  local b = mp.get_property("ab-loop-b", "no")
  local position = mp.get_property_number("time-pos")
  return {
    {type=position and "command" or "disabled", id="playback.ab_loop.set_a", title="Set A to Current Position",
      action=position and {property="ab-loop-a", value=position} or nil},
    {type=position and "command" or "disabled", id="playback.ab_loop.set_b", title="Set B to Current Position",
      action=position and {property="ab-loop-b", value=position} or nil},
    {type="command", id="playback.ab_loop.clear", title="Clear A-B Loop",
      checked=a ~= "no" or b ~= "no", action={property="ab-loop-a", value="no"}},
  }
end

local function dynamic_video_rotation()
  local current = mp.get_property_number("video-rotate", 0)
  local items = {}
  for _, angle in ipairs({0, 90, 180, 270}) do
    items[#items + 1] = {type="command", id="video.rotation." .. angle,
      title=angle .. "°", checked=current == angle,
      action={property="video-rotate", value=angle}}
  end
  return items
end

local function active_video_filters()
  local active = {}
  local filters = mp.get_property_native("vf", {})
  for _, filter in ipairs(type(filters) == "table" and filters or {}) do
    if type(filter) == "table" then
      local name = filter.name or filter.label
      if type(name) == "string" then active[name:gsub("^@", "")] = true end
    end
  end
  return active
end

local function filter_toggle_item(id, title, filter, active)
  return {type="command", id=id, title=title, checked=active[filter], command="vf toggle " .. filter}
end

local function dynamic_video_mirror()
  local active = active_video_filters()
  return {
    filter_toggle_item("video.mirror.horizontal", "Mirror Horizontally", "hflip", active),
    filter_toggle_item("video.mirror.vertical", "Mirror Vertically", "vflip", active),
  }
end

local function dynamic_video_zoom_pan()
  return {
    {type="command", id="video.zoom_pan.zoom_in", title="Zoom In", command="add video-zoom 0.1"},
    {type="command", id="video.zoom_pan.zoom_out", title="Zoom Out", command="add video-zoom -0.1"},
    {type="command", id="video.zoom_pan.reset_zoom", title="Reset Zoom", command="set video-zoom 0"},
    {type="command", id="video.zoom_pan.pan_left", title="Pan Left", command="add video-pan-x -0.05"},
    {type="command", id="video.zoom_pan.pan_right", title="Pan Right", command="add video-pan-x 0.05"},
    {type="command", id="video.zoom_pan.pan_up", title="Pan Up", command="add video-pan-y -0.05"},
    {type="command", id="video.zoom_pan.pan_down", title="Pan Down", command="add video-pan-y 0.05"},
    {type="command", id="video.zoom_pan.reset_pan_x", title="Reset Pan X", command="set video-pan-x 0"},
    {type="command", id="video.zoom_pan.reset_pan_y", title="Reset Pan Y", command="set video-pan-y 0"},
  }
end

local function dynamic_video_filters()
  local active = active_video_filters()
  return {
    filter_toggle_item("video.filters.deband", "Deband", "deband", active),
    filter_toggle_item("video.filters.equalizer", "Equalizer", "eq", active),
    filter_toggle_item("video.filters.sharpen", "Sharpen", "unsharp", active),
    {type="command", id="video.filters.clear", title="Clear All Video Filters", command="vf clr"},
  }
end

local function dynamic_audio_channels()
  local current = mp.get_property("audio-channels", "auto-safe")
  local items = {}
  for _, layout in ipairs({"auto-safe", "auto", "stereo", "mono", "5.1", "7.1"}) do
    items[#items + 1] = {type="command", id="audio.channels." .. layout, title=layout,
      checked=current == layout, action={property="audio-channels", value=layout}}
  end
  return items
end

local dynamic_providers = {
  audio_tracks=dynamic_audio_tracks, subtitle_tracks=dynamic_subtitle_tracks,
  editions=dynamic_editions, chapters=dynamic_chapters, playlist_actions=dynamic_playlist_actions,
  playback_speed=dynamic_playback_speed, ab_loop=dynamic_ab_loop,
  video_rotation=dynamic_video_rotation, video_mirror=dynamic_video_mirror,
  video_zoom_pan=dynamic_video_zoom_pan, video_filters=dynamic_video_filters,
  audio_channels=dynamic_audio_channels,
}
local dynamic_empty_titles = {
  audio_tracks="No audio tracks available",
  subtitle_tracks="No subtitles available",
  editions="No editions available",
  chapters="No chapters available",
  playlist_actions="No playlist actions available",
  playback_speed="No playback speeds available",
  ab_loop="A-B loop is unavailable",
  video_rotation="Video rotation is unavailable",
  video_mirror="Video mirroring is unavailable",
  video_zoom_pan="Video zoom and pan are unavailable",
  video_filters="Video filters are unavailable",
  audio_channels="Audio channel layouts are unavailable",
}
local function locate_current_file()
  local path = mp.get_property("path")
  if not path or path == "" or path:match("^[%a][%w+.-]*://") then
    mp.osd_message("Cadre: current source is not a local file", 2)
    return
  end
  local windows = package.config:sub(1, 1) == "\\"
  local args
  if windows then
    args = {"explorer.exe", "/select," .. path}
  elseif type(jit) == "table" and jit.os == "OSX" then
    args = {"open", "-R", path}
  else
    local directory = path:gsub("[/\\][^/\\]*$", "")
    if directory == "" then directory = "." end
    args = {"xdg-open", directory}
  end
  local result = mp.command_native({name="subprocess", args=args, playback_only=false, capture_stdout=false, capture_stderr=false})
  if not result or result.status ~= 0 then msg.warn("cadre_menu: could not open the file manager") end
end
local local_messages = {
  ["cadre-menu-open-file"] = common.do_add_file,
  ["cadre-menu-open-folder"] = common.do_add_folder,
  ["cadre-menu-open-url"] = common.do_add_url,
  ["cadre-menu-locate-current-file"] = locate_current_file,
}

local function visible_items(items, custom_only)
  local result = {}
  if custom_only == nil then custom_only = replace_defaults end
  for _, item in ipairs(items or {}) do
    if not hidden[item.id] then
      if item.type == "dynamic" then
        if not custom_only or item.custom then
          local provider = dynamic_providers[item.source]
          local children = provider and visible_items(provider(), false) or {}
          if #children == 0 then
            children = {{type="disabled", id=item.id .. ".empty", title=dynamic_empty_titles[item.source] or "No items available"}}
          end
          if #children > 0 then result[#result + 1] = {type="submenu", id=item.id, title=item.title, items=children, visible_items=children} end
        end
      elseif item.type == "submenu" then
        item.visible_items = visible_items(item.items, custom_only)
        if #item.visible_items > 0 then result[#result + 1] = item end
      elseif not custom_only or item.custom then result[#result + 1] = item end
    end
  end
  local compact = {}
  for _, item in ipairs(result) do
    if item.type ~= "separator" or (#compact > 0 and compact[#compact].type ~= "separator") then compact[#compact + 1] = item end
  end
  if compact[#compact] and compact[#compact].type == "separator" then compact[#compact] = nil end
  return compact
end
local function items_at(depth)
  return depth == 0 and root_items or stack[depth].item.visible_items
end
local function selected_at(depth)
  return depth == 0 and root_selected or stack[depth].selected
end
local function first_at(depth)
  return depth == 0 and root_first or stack[depth].first
end
local function set_first(depth, first)
  if depth == 0 then root_first = first else stack[depth].first = first end
end
local function row_height(item)
  return item.type == "separator" and 10 or ROW_H
end
local function menu_height(items, first, last)
  local height = PAD * 2
  for i = first, last do height = height + row_height(items[i]) end
  return height
end
local function visible_count(items, screen_h)
  return math.min(MAX_VISIBLE_ITEMS, #items, math.max(1, math.floor((screen_h - PAD * 2 - 8) / ROW_H)))
end
local function visible_bounds(items, selected, screen_h, first_hint)
  local count = visible_count(items, screen_h)
  local first = math.max(1, math.min(first_hint or 1, #items - count + 1))
  local last = math.min(#items, first + count - 1)
  local available = math.max(ROW_H, screen_h - PAD * 2 - 8)
  while menu_height(items, first, last) - PAD * 2 > available and last > first do last = last - 1 end
  return first, last
end
local function item_top(items, index, y, first)
  local top = y + PAD
  for i = first, index - 1 do top = top + row_height(items[i]) end
  return top
end
local function item_at_y(items, y, first, last)
  local cursor = y - PAD
  for i = first, last do
    local item = items[i]
    local h = row_height(item)
    if cursor >= 0 and cursor < h then return i end
    cursor = cursor - h
  end
end
local function first_selectable(items)
  for i, item in ipairs(items) do if item.type ~= "separator" and item.type ~= "disabled" then return i end end
  return 1
end
local function set_selected(depth, value)
  local items = items_at(depth)
  value = math.max(1, math.min(#items, value))
  if items[value] and (items[value].type == "separator" or items[value].type == "disabled") then
    local step = value >= selected_at(depth) and 1 or -1
    while value >= 1 and value <= #items and (items[value].type == "separator" or items[value].type == "disabled") do value = value + step end
    value = math.max(1, math.min(#items, value))
  end
  if depth == 0 then root_selected = value else stack[depth].selected = value end
end
local function keep_selected_visible(depth)
  local items = items_at(depth)
  local dimensions = mp.get_property_native("osd-dimensions") or {}
  local selected = selected_at(depth)
  local first, last = visible_bounds(items, selected, dimensions.h or 720, first_at(depth))
  local shown = last - first + 1
  if selected < first then first = selected
  elseif selected > last then first = selected - shown + 1 end
  set_first(depth, math.max(1, math.min(first, math.max(1, #items - shown + 1))))
end
local function prune_after(depth)
  for i = #stack, depth + 1, -1 do stack[i] = nil end
end
local function cancel_submenu_hover()
  if submenu_hover_timer then submenu_hover_timer:kill() end
  submenu_hover_timer, submenu_hover_depth, submenu_hover_item = nil, nil, nil
end
local function open_child(depth, item)
  cancel_submenu_hover()
  if stack[depth + 1] and stack[depth + 1].item == item then
    prune_after(depth + 1)
    return
  end
  prune_after(depth)
  stack[depth + 1] = {item=item, selected=1, first=1}
end
local function close()
  if not opened then return end
  cancel_submenu_hover()
  opened, stack, boxes, root_items = false, {}, {}, {}
  mp.set_property_bool("user-data/cadre_menu/visible", false)
  scrollbar_drag_depth = nil
  overlay.data = ""; overlay:update()
  local dims = mp.get_property_native("osd-dimensions") or {w=1280,h=720}
  for depth = 0, 7 do
    common.publish_glass_region(depth == 0 and "menu" or ("menu_sub" .. depth), false, nil,
      dims.w or 1280, dims.h or 720, 0, 0)
  end
  mp.remove_key_binding("cadre_menu_left")
  mp.remove_key_binding("cadre_menu_escape")
  mp.remove_key_binding("cadre_menu_up")
  mp.remove_key_binding("cadre_menu_down")
  mp.remove_key_binding("cadre_menu_enter")
  mp.remove_key_binding("cadre_menu_right")
  mp.remove_key_binding("cadre_menu_back")
  mp.remove_key_binding("cadre_menu_bs")
  mp.remove_key_binding("cadre_menu_wheel_up")
  mp.remove_key_binding("cadre_menu_wheel_down")
end
local function render()
  if not opened then return end
  local root_level = items_at(0)
  if #root_level == 0 then close(); return end
  local dims = mp.get_property_native("osd-dimensions") or {w=1280,h=720}
  local theme = common.theme or {}

  local font = theme.font_text_mn
      or theme.font_ui
      or theme.font_text
      or "Inter"

  local fs = clamp_number(
      theme.size_font_mn or theme.font_size,
      16, 8, 64
  )

  ROW_H = clamp_number(theme.height_item_menu_mn, 34, 16, 96)
  PAD = clamp_number(theme.pad_menu_mn, 8, 2, 32)
  WIDTH = clamp_number(
      theme.width_menu_mn,
      250, 140,
      math.max(140, (dims.w or 1280) - 8)
  )
  MAX_VISIBLE_ITEMS = clamp_number(
      theme.max_visible_items_menu_mn,
      16, 3, 40
  )

  local screen_w, screen_h = dims.w or 1280, dims.h or 720

  local bg = common.bgr(
      theme.surface_color_mn
      or theme.surface_color
      or theme.surface_color_osc
      or "111820"
  )
  local fg = common.bgr(theme.color_text_mn or theme.text_color or "F8FAFC")
  local dim = common.bgr(
      theme.color_dim_mn
      or theme.dim_color
      or theme.color_icon_dim_osc
      or "9299A3"
  )
  local accent = common.bgr(
      theme.color_selected_mn
      or theme.accent_color
      or "63B8FF"
  )

  local alpha = common.ass_alpha(theme.alpha_panel_bg_mn or theme.alpha_panel_bg or "E7")

  local selected_alpha = common.ass_alpha(theme.alpha_selected_mn or "A7")

  local scrollbar_bg = common.bgr(theme.color_scroll_bg_mn or "64748B")
  local scrollbar_fg = common.bgr(
      theme.color_scroll_fg_mn
      or theme.accent_color
      or "63B8FF"
  )

  local scrollbar_alpha = common.ass_alpha(theme.alpha_scroll_bg_mn or "47")

  local radius = clamp_number(
      theme.radius_menu_mn or theme.panel_radius,
      8, 0, 20
  )

  local border_color = common.bgr(
      theme.color_border_menu_mn
      or theme.border_all_color
      or "FFFFFF"
  )

  local border_alpha = common.ass_alpha(
      theme.alpha_border_menu_mn
      or theme.border_all_alpha
      or "00"
  )

  local border_width = clamp_number(
      theme.width_border_menu_mn
      or theme.border_all_width,
      0, 0, 20
  )

  local menu_glass = theme.enabled_glass_blur_menu_mn == nil
      and theme.glass_blur == true
      or theme.enabled_glass_blur_menu_mn == true

  local menu_glass_radius = theme.radius_glass_blur_menu_mn
      or theme.radius_glass_blur
      or 12
  local ass = assdraw.ass_new()
  boxes = {}
  local glass_regions = {}
  for depth = 0, #stack do
    local items = items_at(depth)
    if #items == 0 then prune_after(depth - 1); break end
    local selection = selected_at(depth)
    local first, last = visible_bounds(items, selection, screen_h, first_at(depth))
    set_first(depth, first)
    local h = menu_height(items, first, last)
    local x, y
    if depth == 0 then
      x = math.max(4, math.min(anchor_x, screen_w - WIDTH - 4))
      y = math.max(4, math.min(anchor_y, screen_h - h - 4))
    else
      local parent_box = boxes[depth - 1]
      local parent_index = selected_at(depth - 1)
      y = item_top(items_at(depth - 1), parent_index, parent_box.y, parent_box.first)
      local side = parent_box.side
      if not side then
        side = parent_box.x + WIDTH * 2 - 2 <= screen_w - 4 and "right" or "left"
      end
      x = side == "left" and parent_box.x - WIDTH + 2 or parent_box.x + WIDTH + 6
      x = math.max(4, math.min(x, screen_w - WIDTH - 4))
      y = math.max(4, math.min(y, screen_h - h - 4))
      boxes[depth] = {side=side}
    end
    local side = boxes[depth] and boxes[depth].side
    boxes[depth] = {x=x, y=y, w=WIDTH, h=h, first=first, last=last, side=side}
    glass_regions[depth] = {x1=x, y1=y, x2=x + WIDTH, y2=y + h}
    common.draw_rrect(ass, x, y, x + WIDTH, y + h, radius, bg, alpha)
    common.draw_rrect_outline(ass, x, y, x + WIDTH, y + h, radius, border_color, border_alpha, border_width)
    local visible_count = last - first + 1
    if #items > visible_count then
      local scrollbar_w = clamp_number(theme.scrollbar_width_mn, 4, 2, math.min(10, WIDTH / 8))
      local track = {x1=x + WIDTH - scrollbar_w - 5, x2=x + WIDTH - 3, y1=y + PAD, y2=y + h - PAD}
      track.height = math.max(1, track.y2 - track.y1)
      local thumb_h = math.max(22, track.height * visible_count / #items)
      local max_offset = math.max(1, #items - visible_count)
      local thumb_y = track.y1 + (track.height - thumb_h) * (first - 1) / max_offset
      track.thumb_y1, track.thumb_y2 = thumb_y, thumb_y + thumb_h
      boxes[depth].scrollbar = track
      common.draw_rrect(ass, track.x1 + (track.x2-track.x1-scrollbar_w)/2, track.y1, track.x1 + (track.x2-track.x1+scrollbar_w)/2, track.y2, 1, scrollbar_bg, scrollbar_alpha)
      common.draw_rrect(ass, track.x1 + (track.x2-track.x1-scrollbar_w)/2, track.thumb_y1, track.x1 + (track.x2-track.x1+scrollbar_w)/2, track.thumb_y2, 2, scrollbar_fg, "18")
    end
    local row_y = y + PAD
    for i = first, last do
      local item = items[i]
      local item_h = row_height(item)
      if item.type == "separator" then
        common.draw_rrect(ass, x + 12, row_y + 4, x + WIDTH - 12, row_y + 5, 0, fg, "A0")
        row_y = row_y + item_h
      else
      local ry = row_y
      if i == selection and item.type ~= "disabled" then
        common.draw_rrect(ass, x + 4, ry, x + WIDTH - 4, ry + item_h - 1, math.max(0, radius - 2), accent, selected_alpha)
      end
      local label_color = item.type == "disabled" and dim or fg
      common.draw_text(ass, ass_escape(fit_text(item.title, WIDTH - 14 - 40 - 12, fs)), x + 14, ry + item_h / 2, fs, label_color, "00", 4, false, font)
      if item.checked then common.draw_text(ass, "✓", x + WIDTH - 34, ry + item_h / 2, fs, accent, "00", 5, false, font) end
      if item.type == "submenu" then
        common.draw_text(ass, ">", x + WIDTH - 16, ry + item_h / 2, fs, accent, "00", 5, false, font)
      end
      row_y = row_y + item_h
      end
    end
  end
  overlay.res_x, overlay.res_y = dims.w or 1280, dims.h or 720
  overlay.data = ass.text
  overlay:update()
  for depth = 0, 7 do
    local bounds = glass_regions[depth]
    common.publish_glass_region(depth == 0 and "menu" or ("menu_sub" .. depth),
      menu_glass and bounds ~= nil, bounds, dims.w or 1280, dims.h or 720, radius, menu_glass_radius)
  end
end
local function schedule_submenu_hover(depth, item)
  if submenu_hover_depth == depth and submenu_hover_item == item then return end
  cancel_submenu_hover()
  submenu_hover_depth, submenu_hover_item = depth, item
  submenu_hover_timer = mp.add_timeout(0.18, function()
    local target_depth, target_item = submenu_hover_depth, submenu_hover_item
    submenu_hover_timer, submenu_hover_depth, submenu_hover_item = nil, nil, nil
    if opened and target_depth ~= nil and active_depth == target_depth
      and items_at(target_depth)[selected_at(target_depth)] == target_item then
      open_child(target_depth, target_item)
      render()
    end
  end)
end
local function activate()
  local depth = active_depth
  local items = items_at(depth); local item = items[selected_at(depth)]
  if not item or item.type == "disabled" or item.type == "separator" then return end
  if item.type == "submenu" then
    if not stack[depth + 1] or stack[depth + 1].item ~= item then open_child(depth, item) end
    active_depth = depth + 1
    render(); return
  end
  close()
  if item.action and item.action.property then
    mp.set_property(item.action.property, tostring(item.action.value))
    return
  end
  if not item.command then return end
  local words = split_words(item.command)
  if words and words[1] == "script-message" then
    local callback = local_messages[words[2]]
    if callback then callback(); return end
  end
  mp.command(item.command)
end
local function back()
  if #stack > 0 then stack[#stack] = nil; active_depth = #stack; render() else close() end
end
local function scroll_to_position(depth, pointer_y)
  local box = boxes[depth]
  local scroll = box and box.scrollbar
  if not scroll then return end
  local items = items_at(depth)
  local ratio = (pointer_y - scroll.y1) / math.max(1, scroll.height)
  ratio = math.max(0, math.min(1, ratio))
  local shown = box.last - box.first + 1
  local max_first = math.max(1, #items - shown + 1)
  set_first(depth, math.floor(1 + ratio * (max_first - 1) + 0.5))
  active_depth = depth
  cancel_submenu_hover()
  prune_after(depth)
  render()
end
local function scroll_by(delta)
  local depth = active_depth
  for d = #boxes, 0, -1 do
    local box = boxes[d]
    if box and mouse_x >= box.x and mouse_x <= box.x + box.w and mouse_y >= box.y and mouse_y <= box.y + box.h then
      depth = d
      break
    end
  end
  local box, items = boxes[depth], items_at(depth)
  if not box or #items <= box.last - box.first + 1 then return end
  local shown = box.last - box.first + 1
  local max_first = math.max(1, #items - shown + 1)
  set_first(depth, math.max(1, math.min(max_first, first_at(depth) + delta)))
  active_depth = depth
  cancel_submenu_hover()
  prune_after(depth)
  render()
end
local function move_selection(delta)
  cancel_submenu_hover()
  set_selected(active_depth, selected_at(active_depth) + delta)
  keep_selected_visible(active_depth)
  prune_after(active_depth)
  render()
end
local function open()
  if opened then close(); return end
  opened, stack, root_selected, root_first, active_depth = true, {}, 1, 1, 0
  mouse_x = (mp.get_property_native("mouse-pos") or {}).x or mouse_x
  mouse_y = (mp.get_property_native("mouse-pos") or {}).y or mouse_y
  anchor_x, anchor_y = mouse_x, mouse_y
  root_items = visible_items(menu)
  root_selected = first_selectable(root_items)
  if #root_items == 0 then opened = false; return end
  mp.set_property_bool("user-data/cadre_menu/visible", true)
  mp.add_forced_key_binding("MBTN_LEFT", "cadre_menu_left", function(e)
    if e.event == "up" or e.event == "release" then scrollbar_drag_depth = nil; return end
    if e.event ~= "down" and e.event ~= "press" then return end
    local depth
    for d = #boxes, 0, -1 do
      local b = boxes[d]
      if b and mouse_x >= b.x and mouse_x <= b.x+b.w and mouse_y >= b.y and mouse_y <= b.y+b.h then depth = d; break end
    end
    if depth == nil then close(); return end
    local items, b = items_at(depth), boxes[depth]
    if b.scrollbar and mouse_x >= b.scrollbar.x1 and mouse_x <= b.scrollbar.x2 then
      scrollbar_drag_depth = depth
      scroll_to_position(depth, mouse_y)
      return
    end
    local idx = item_at_y(items, mouse_y-b.y, b.first, b.last)
    if idx and items[idx].type ~= "separator" and items[idx].type ~= "disabled" then
      active_depth = depth; set_selected(depth, idx)
      local item = items[idx]
      if item.type == "submenu" then open_child(depth, item) else prune_after(depth) end
      render()
      if item.type ~= "submenu" then activate() end
    end
  end, {complex=true})
  mp.add_forced_key_binding("ESC", "cadre_menu_escape", back)
  mp.add_forced_key_binding("UP", "cadre_menu_up", function() move_selection(-1) end, {repeatable=true})
  mp.add_forced_key_binding("DOWN", "cadre_menu_down", function() move_selection(1) end, {repeatable=true})
  mp.add_forced_key_binding("ENTER", "cadre_menu_enter", activate)
  mp.add_forced_key_binding("RIGHT", "cadre_menu_right", activate)
  mp.add_forced_key_binding("LEFT", "cadre_menu_back", back)
  mp.add_forced_key_binding("BS", "cadre_menu_bs", back)
  mp.add_forced_key_binding("WHEEL_UP", "cadre_menu_wheel_up", function() scroll_by(-3) end)
  mp.add_forced_key_binding("WHEEL_DOWN", "cadre_menu_wheel_down", function() scroll_by(3) end)
  render()
end
mp.add_forced_key_binding("MBTN_RIGHT", "cadre_menu_toggle", function(e)
  if e.event == "down" or e.event == "press" then
    local pos = mp.get_property_native("mouse-pos") or {}
    mouse_x, mouse_y = pos.x or mouse_x, pos.y or mouse_y
    open()
  end
end, {complex=true})
mp.observe_property("mouse-pos", "native", function(_, pos)
  if not pos then return end
  mouse_x, mouse_y = pos.x or mouse_x, pos.y or mouse_y
  if opened then
    if scrollbar_drag_depth ~= nil then
      scroll_to_position(scrollbar_drag_depth, mouse_y)
      return
    end
    local hovered_depth
    for depth = #boxes, 0, -1 do
      local b = boxes[depth]
      if b and mouse_x >= b.x and mouse_x <= b.x+b.w and mouse_y >= b.y+PAD and mouse_y <= b.y+b.h-PAD
        and not (b.scrollbar and mouse_x >= b.scrollbar.x1) then
        hovered_depth = depth; break
      end
    end
    if hovered_depth ~= nil then
      local b, items = boxes[hovered_depth], items_at(hovered_depth)
      local idx = item_at_y(items, mouse_y-b.y, b.first, b.last)
      if idx and items[idx].type ~= "separator" and items[idx].type ~= "disabled" then
        local item = items[idx]
        local changed = idx ~= selected_at(hovered_depth) or hovered_depth ~= active_depth
        if changed then
          active_depth = hovered_depth
          set_selected(hovered_depth, idx)
        end
        if item.type == "submenu" then
          local child = stack[hovered_depth + 1]
          if child and child.item == item then cancel_submenu_hover()
          else
            prune_after(hovered_depth)
            schedule_submenu_hover(hovered_depth, item)
          end
        else
          cancel_submenu_hover()
          prune_after(hovered_depth)
        end
        if changed then render() end
      else
        cancel_submenu_hover()
      end
    else cancel_submenu_hover() end
  end
end)
mp.register_script_message("cadre-menu-open", open)
mp.register_script_message("cadre-menu-close", close)
mp.register_script_message("cadre-menu-toggle", open)
common.on_theme_reload(function() if opened then render() end end)
mp.register_script_message("cadre-theme-reload", function() common.reload_theme() end)
mp.register_event("shutdown", close)
