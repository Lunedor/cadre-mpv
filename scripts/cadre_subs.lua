local mp = require 'mp'
local utils = require 'mp.utils'
local assdraw = require 'mp.assdraw'
local common = dofile(mp.command_native({"expand-path", "~~/scripts/cadre/scripts/cadre_common.lua"}))


local O = {
  api_key = "",
  languages = {"en", "tr"},
  max_results = 20,
}


common.section("subs", O)

mp.set_property_native("user-data/cadre_subs/available", true)
mp.register_event("shutdown", function()
  mp.set_property_native("user-data/cadre_subs/available", false)
end)


local API = "https://api.opensubtitles.com/api/v1"
local UA = "Cadre-Player-Lite/1.0"
local overlay = mp.create_osd_overlay("ass-events")
local theme = common.theme or {}
local function ass_color(hex)
  hex = tostring(hex or "FFFFFF")
  return hex:sub(5, 6) .. hex:sub(3, 4) .. hex:sub(1, 2)
end
local function esc(text)
  return tostring(text or ""):gsub("\\", "\\\\"):gsub("{", "\\{"):gsub("}", "\\}"):gsub("\n", " ")
end


-- CACHE: path for last-subs index
local cadre_dir = mp.command_native({"expand-path", "~~/scripts/cadre/"})
local cache_dir = cadre_dir .. "data/subs-cache/"
local last_subs_file = cache_dir .. "last_subs.json"


local function ensure_cache_dir()
  if utils.file_info(cache_dir) then return end
  local win = package.config:sub(1, 1) == "\\"
  mp.command_native({name = "subprocess", playback_only = false,
    args = win and {"cmd", "/c", "mkdir", (cache_dir:gsub("/", "\\"))}
               or {"mkdir", "-p", cache_dir}})
end


local function load_last_subs_index()
  local f = io.open(last_subs_file, "r")
  if not f then return {} end
  local data = f:read("*a")
  f:close()
  local ok, idx = pcall(utils.parse_json, data)
  if not ok or type(idx) ~= "table" then return {} end
  return idx
end


local function save_last_subs_index(idx)
  ensure_cache_dir()
  local f = io.open(last_subs_file, "w")
  if not f then return end
  f:write(utils.format_json(idx))
  f:close()
end


local function get_cached_subtitle(path)
  local idx = load_last_subs_index()
  local entry = idx[path]
  if not entry then return nil end
  if not utils.file_info(entry.file) then return nil end
  return entry.file, entry.lang
end


local function set_cached_subtitle(path, lang, file)
  local idx = load_last_subs_index()
  idx[path] = {lang = lang, file = file}
  save_last_subs_index(idx)
end


local function osdb_hash(path)
  local f = io.open(path, "rb")
  if not f then return nil, 0 end

  local size = f:seek("end")
  if size < 128*1024 then
    f:close()
    return nil, size
  end

  f:seek("set")
  local head = f:read(64*1024)
  f:seek("end", -64*1024)
  local tail = f:read(64*1024)
  f:close()

  local function read_qwords(s)
    local sum = 0
    for i = 1, #s, 8 do
      local b0, b1, b2, b3, b4, b5, b6, b7 = s:byte(i, i+7)
      if not b7 then break end
      local w = b0 + b1*0x100 + b2*0x10000 + b3*0x1000000 +
                b4*0x100000000 + b5*0x10000000000 +
                b6*0x1000000000000 + b7*0x100000000000000
      sum = (sum + w) % 0x10000000000000000
    end
    return sum
  end

  local hash = read_qwords(head) + read_qwords(tail) + size
  hash = hash % 0x10000000000000000

  return string.format("%016x", hash), size
end


local function url_encode(value)
  return (tostring(value):gsub("([^%w%-_%.~])", function(c)
    return string.format("%%%02X", string.byte(c))
  end))
end

local function search_subs(query, hash, size, use_hash)
  local langs = table.concat(O.languages, ",")

  local params = {
    "languages=" .. langs,
    "limit=" .. tostring(O.max_results),
  }

  if use_hash and hash and hash ~= "" then
    params[#params + 1] = "movie_hash=" .. hash
    params[#params + 1] = "movie_bytesize=" .. tostring(size)
  end

  if query and query ~= "" then
    params[#params + 1] = "query=" .. url_encode(query)
  end

  local url = API .. "/subtitles?" .. table.concat(params, "&")

  local args = {"curl", "-s", "-L", "--max-time", "10", "-A", UA,
                "-H", "Api-Key: " .. O.api_key,
                "-H", "Accept: application/json", url}

  local res = mp.command_native({name="subprocess", capture_stdout=true, playback_only=false, args=args})
  if res.status ~= 0 then return {} end

  local data = utils.parse_json(res.stdout)
  if not data or not data.data then return {} end

  local list = data.data

  if list[1] and list[1].attributes and list[1].attributes.score then
    table.sort(list, function(a, b)
      local sa = a.attributes.score or 0
      local sb = b.attributes.score or 0
      return sa > sb
    end)
  end

  if #list > O.max_results then
    list = {unpack(list, 1, O.max_results)}
  end

  return list
end


local function download_file(file_id)
  local args = {"curl", "-s", "-L", "--max-time", "10", "-A", UA,
                "-H", "Api-Key: " .. O.api_key,
                "-H", "Content-Type: application/json",
                "-X", "POST", "-d", utils.format_json({file_id=file_id}),
                API .. "/download"}
  local res = mp.command_native({name="subprocess", capture_stdout=true, playback_only=false, args=args})
  if res.status ~= 0 then return nil end
  local data = utils.parse_json(res.stdout)
  if not data or not data.link then return nil end
  return data.link
end


local function save_subtitle(url, dest)
  local args = {"curl", "-s", "-L", "--fail", "--max-time", "10", "-o", dest, url}
  local res = mp.command_native({name="subprocess", playback_only=false, args=args})
  return res.status == 0
end


local function base_name(path)
  local name = path:match("([^/\\]+)$") or path
  return name:gsub("%.%w+$", "")
end


local function open_subtitles_picker()
  if not O.api_key or O.api_key == "" then
    mp.osd_message("OpenSubtitles: API key missing in cadre.conf")
    return
  end
  local path = mp.get_property("path")
  if not path then return end

  local name = base_name(path)
  local hash, size = osdb_hash(path)

  local selected, results, closed, search_term, list_offset = 1, {}, false, name, 0
  local visible_rows = 5
  local field_focus = true
  local last_clicked_index, last_click_time = nil, 0
  local render
  local function layout(w, h)
    local cw = math.min(760, w - 64)
    local ch = math.min(480, h - 96)
    local x1 = math.floor((w - cw) / 2)
    local y1 = math.floor((h - ch) / 2)

    return {
      w = w, h = h,
      x1 = x1, y1 = y1,
      x2 = x1 + cw, y2 = y1 + ch,
      pad = 24,
      search_y1 = y1 + 82,
      search_y2 = y1 + 124,
      list_y1 = y1 + 148,
      row_h = 52,
      visible_rows = 5,
      details_x1 = x1 + cw - 208,
      details_x2 = x1 + cw - 24,
    }
  end
  local function max_offset()
    return math.max(0, #results - visible_rows)
  end
  local function scroll_by(amount)
    if #results <= visible_rows then return end
    list_offset = math.max(
      0,
      math.min(max_offset(), list_offset + amount)
    )
    render()
  end
  local function clear_bindings()
    for _, key in ipairs({"UP", "DOWN", "ENTER", "ESC", "BACKSPACE", "BS", "SPACE", "Ctrl+a", "ANY_UNICODE", "MBTN_LEFT", "WHEEL_UP", "WHEEL_DOWN"}) do
      mp.remove_key_binding("cadre-subs-" .. key)
    end
    overlay.data = ""
    overlay:update()
    closed = true
  end

  local function choose(index)
      local r = results[index]
      if not r or not r.attributes.files or not r.attributes.files[1] then
        mp.osd_message("This result has no downloadable file")
        return
      end
      clear_bindings()
      local file_id = r.attributes.files[1].file_id
      local link = download_file(file_id)
      if not link then
        mp.osd_message("Download failed")
        return
      end

      ensure_cache_dir()
      local dest = cache_dir .. base_name(path) .. "." .. r.attributes.language .. ".srt"

      if save_subtitle(link, dest) then
        mp.commandv("sub_add", dest)
        set_cached_subtitle(path, r.attributes.language, dest)
        mp.osd_message("Subtitle loaded")
      else
        mp.osd_message("Save failed")
      end
  end

    render = function()
    if closed then return end

    local w, h = mp.get_osd_size()
    local L = layout(w, h)
    local x1, y1, x2, y2 = L.x1, L.y1, L.x2, L.y2
    local ass = assdraw.ass_new()

    -- Explicit dark surfaces: avoid translucent light overlays.
    local bg       = ass_color("191C22")
    local border   = ass_color("353B46")
    local input_bg = ass_color("111419")
    local panel_bg = ass_color("20242C")
    local selected_bg = ass_color("29372D")
    local text     = ass_color("F0F2F5")
    local muted    = ass_color("A8AFBA")
    local accent   = ass_color("80C85A")
    local dark     = ass_color("11170E")

    local function rect(ax, ay, bx, by, color, alpha)
      ass:new_event()
      ass:append(string.format(
        "{\\r\\pos(0,0)\\an7\\alpha&H00&" ..
        "\\1c&H%s&\\1a&H%s&\\bord0\\shad0}",
        color, alpha or "00"
      ))
      ass:draw_start()
      ass:rect_cw(ax, ay, bx, by)
      ass:draw_stop()
    end

    -- Optional clipping keeps long titles inside their own region.
    local function label(str, x, y, size, color, bold, align, clip)
      ass:new_event()

      local clip_tag = ""
      if clip then
        clip_tag = string.format(
          "\\clip(%d,%d,%d,%d)",
          clip[1], clip[2], clip[3], clip[4]
        )
      end

      ass:append(string.format(
        "{\\r\\pos(%d,%d)\\an%d\\fn%s\\fs%d" ..
        "\\alpha&H00&\\1c&H%s&\\bord0\\shad0" ..
        "\\b%d\\q2%s}%s",
        x, y, align or 4,
        esc(theme.font_ui or "Inter"),
        size, color, bold and 1 or 0,
        clip_tag, esc(str)
      ))
    end

    -- Backdrop and dialog.
    rect(0, 0, w, h, "000000", "88")
    rect(x1, y1, x2, y2, border)
    rect(x1 + 1, y1 + 1, x2 - 1, y2 - 1, bg)

    label("Find subtitles", x1 + L.pad, y1 + 28, 22, text, true)
    label(
      "Search OpenSubtitles by title or release",
      x1 + L.pad, y1 + 56, 14, muted
    )

    -- Close button: matches the existing mouse hit box.
    label("×", x2 - 26, y1 + 24, 24, muted, false, 5)

    -- Search input and buttons.
    local input_x1 = x1 + L.pad
    local input_x2 = x2 - L.pad - 144
    local clear_x1 = x2 - L.pad - 132
    local clear_x2 = x2 - L.pad - 96
    local search_x1 = x2 - L.pad - 88
    local search_x2 = x2 - L.pad
    local search_mid = math.floor((L.search_y1 + L.search_y2) / 2)

    -- Draw the border first, then the darker interior.
    rect(
      input_x1, L.search_y1, input_x2, L.search_y2,
      field_focus and accent or border
    )
    rect(
      input_x1 + 1, L.search_y1 + 1,
      input_x2 - 1, L.search_y2 - 1,
      input_bg
    )

    label(
      search_term ~= "" and search_term or "Title or release name",
      input_x1 + 12, search_mid, 16,
      search_term ~= "" and text or muted,
      false, 4,
      {input_x1 + 8, L.search_y1 + 2,
       input_x2 - 8, L.search_y2 - 2}
    )

    -- No fake caret: proportional text cannot use #text * 8.
    rect(clear_x1, L.search_y1, clear_x2, L.search_y2, panel_bg)
    label(
      "×", math.floor((clear_x1 + clear_x2) / 2),
      search_mid, 22, muted, false, 5
    )

    rect(search_x1, L.search_y1, search_x2, L.search_y2, accent)
    label(
      "Search", math.floor((search_x1 + search_x2) / 2),
      search_mid, 15, dark, true, 5
    )

    local list_x1 = x1 + L.pad
    local list_x2 = L.details_x1 - 16
    local list_y1 = L.list_y1
    local list_y2 = list_y1 + L.visible_rows * L.row_h

    if #results == 0 then
      -- Empty state: no meaningless details panel or 0% score.
      local cx = math.floor((x1 + x2) / 2)
      local cy = math.floor((list_y1 + list_y2) / 2)

      label("No subtitles found", cx, cy - 15, 20, text, true, 5)
      label(
        "Try a shorter title or a different release name.",
        cx, cy + 18, 14, muted, false, 5
      )
    else
      local last_index = math.min(
        #results, list_offset + L.visible_rows
      )

      for i = list_offset + 1, last_index do
        local a = results[i].attributes or {}
        local file = a.files and a.files[1] or {}
        local release = a.release or file.file_name or "Unknown release"
        local language =
          a.language_name or a.languageName or a.language or "Unknown"

        local ry = list_y1 + (i - list_offset - 1) * L.row_h
        local row_bottom = ry + L.row_h - 6
        local active = i == selected

        rect(
          list_x1, ry, list_x2, row_bottom,
          active and selected_bg or panel_bg
        )

        if active then
          rect(list_x1, ry, list_x1 + 3, row_bottom, accent)
        end

        label(
          string.format("%02d", i),
          list_x1 + 14, ry + 22,
          13, active and accent or muted, true
        )

        label(
          release, list_x1 + 46, ry + 14,
          16, text, active, 4,
          {list_x1 + 46, ry, list_x2 - 12, ry + 27}
        )

        label(
          language, list_x1 + 46, ry + 34,
          13, muted, false, 4,
          {list_x1 + 46, ry + 25, list_x2 - 12, row_bottom}
        )
      end

      -- Selected result details; everything fits within the panel.
      local a = results[selected] and results[selected].attributes or {}
      local file = a.files and a.files[1] or {}
      local release = a.release or file.file_name or "Unknown release"
      local language =
        a.language_name or a.languageName or a.language or "Unknown"
      local format = (file.file_name or ""):match("%.([%w]+)$")

      local dx = L.details_x1 + 14
      local right = L.details_x2 - 14
      local detail_clip = {
        dx, list_y1 + 1, right, list_y2 - 1
      }

      rect(L.details_x1, list_y1, L.details_x2, list_y2, panel_bg)

      label("SELECTED SUBTITLE", dx, list_y1 + 20, 11, muted, true)
      label(
        release, dx, list_y1 + 48,
        15, text, true, 4, detail_clip
      )

      rect(dx, list_y1 + 72, right, list_y1 + 73, border)

      label("Language", dx, list_y1 + 96, 12, muted)
      label(
        language, dx, list_y1 + 118,
        16, text, false, 4, detail_clip
      )

      label("Format", dx, list_y1 + 153, 12, muted)
      label(
        format and format:upper() or "Unknown",
        dx, list_y1 + 175, 16, text
      )

      label("Enter to load", dx, list_y2 - 22, 13, accent)

      -- Scroll indicator outside the list and details content.
      if #results > L.visible_rows then
        local track_h = list_y2 - list_y1
        local thumb_h = math.max(
          24, math.floor(track_h * L.visible_rows / #results)
        )
        local thumb_y = list_y1 + math.floor(
          (track_h - thumb_h) * list_offset / max_offset()
        )

        rect(x2 - 16, list_y1, x2 - 12, list_y2, border)
        rect(x2 - 16, thumb_y, x2 - 12, thumb_y + thumb_h, accent)
      end
    end

    rect(x1 + L.pad, y2 - 50, x2 - L.pad, y2 - 49, border)

    label(
      field_focus
        and "Enter: search    |    Esc: close"
        or "Enter: load    |    Up / Down: browse    |    Esc: close",
      x1 + L.pad, y2 - 28, 13, muted
    )

    overlay.res_x = w
    overlay.res_y = h
    overlay.data = ass.text
    overlay:update()
  end

  local function run_search(query, use_hash)
    if not query or query:match("^%s*$") then render(); return end
    search_term = query
    mp.osd_message("Searching OpenSubtitles...")
    results = search_subs(query, hash, size, use_hash)
    selected = 1
    list_offset = 0
    render()
  end

  local bindings = {
    {"UP", function()
      selected = math.max(1, selected - 1)
      if selected <= list_offset then list_offset = selected - 1 end
      if #results > 0 then field_focus = false end
      render()
    end},
    {"DOWN", function()
      selected = math.min(#results, selected + 1)
      if selected > list_offset + visible_rows then list_offset = selected - visible_rows end
      if #results > 0 then field_focus = false end
      render()
    end},
    {"WHEEL_UP", function() scroll_by(-3) end},
    {"WHEEL_DOWN", function() scroll_by(3) end},
    {"ENTER", function()
      if field_focus then run_search(search_term, false) else choose(selected) end
    end},
    {"ESC", clear_bindings},
    {"BS", function() search_term = search_term:sub(1, -2); field_focus = true; render() end},
    {"SPACE", function() search_term = search_term .. " "; field_focus = true; render() end},
    {"Ctrl+a", function() search_term = ""; field_focus = true; render() end},
  }
  for _, binding in ipairs(bindings) do
    mp.add_forced_key_binding(binding[1], "cadre-subs-" .. binding[1], binding[2], {repeatable = false})
  end
  mp.add_forced_key_binding("ANY_UNICODE", "cadre-subs-ANY_UNICODE", function(event)
    if event.event ~= "down" then return end
    local key = event.key_text or event.key_name or ""
    if key == " " or key == "SPACE" then
      search_term = search_term .. " "
      field_focus = true
      render()
    elseif #key == 1 and key:match("[%w%p]") then
      search_term = search_term .. key
      field_focus = true
      render()
    end
  end, {complex = true})
  mp.add_forced_key_binding("MBTN_LEFT", "cadre-subs-MBTN_LEFT", function()
    local w, h = mp.get_osd_size()
    local L = layout(w, h)
    local x1, y1, x2 = L.x1, L.y1, L.x2
    local mouse = mp.get_property_native("mouse-pos") or {}
    local mx, my = mouse.x or -1, mouse.y or -1
        if mx >= x2 - 44 and mx <= x2 - 8 and my >= y1 + 8 and my <= y1 + 38 then
      clear_bindings()

    elseif mx >= x2 - L.pad - 132 and mx <= x2 - L.pad - 96
        and my >= L.search_y1 and my <= L.search_y2 then
      search_term = ""
      field_focus = true
      render()

    elseif mx >= x2 - L.pad - 88 and mx <= x2 - L.pad
        and my >= L.search_y1 and my <= L.search_y2 then
      field_focus = false
      run_search(search_term, false)

    elseif mx >= x1 + L.pad and mx <= x2 - L.pad - 144
       and my >= L.search_y1 and my <= L.search_y2 then
      field_focus = true
      render()

    elseif mx >= x1 + L.pad and mx <= L.details_x1 - 16
        and my >= L.list_y1
        and my < L.list_y1 + L.visible_rows * L.row_h then
      local index = list_offset
        + math.floor((my - L.list_y1) / L.row_h) + 1

      if results[index] then
        local now = mp.get_time()
        if last_clicked_index == index and now - last_click_time <= 0.35 then
          last_clicked_index, last_click_time = nil, 0
          choose(index)
        else
          last_clicked_index, last_click_time = index, now
          selected = index
          field_focus = false
          render()
        end
      end
    end
  end, {repeatable = false})
  run_search(name, true)
  if #results == 0 then render() end
end


-- CACHE: auto-load last subtitle for this file on start
local function try_load_cached_subtitle()
  if not O.api_key or O.api_key == "" then return end
  local path = mp.get_property("path")
  if not path then return end

  local file, _= get_cached_subtitle(path)
  if not file then return end

  mp.commandv("sub_add", file)
end

mp.register_event("file-loaded", try_load_cached_subtitle)

common.bind("subs_search", "ctrl+u", "cadre-subs-search", open_subtitles_picker)
mp.register_script_message("cadre-subs-search", open_subtitles_picker)
