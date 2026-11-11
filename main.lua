local mp = require 'mp'
local utils = require 'mp.utils'
local base = mp.command_native({"expand-path", "~~/scripts/cadre/"})

local modules = {
  osc=true, playlist=true, titlebar=true, menu=false, stream=true,
  youtube=true, music_mode=true, ab_loop=true, subs=true, keep_session=true,
  webdav_browser=false,
  auto_theme=true, livecap=true,
}

local data
local f = io.open(base .. "cadre.conf", "r")
if f then
  data = utils.parse_json(f:read("*a"))
  f:close()
  local m = data and data.main and data.main.modules
  if m then for k, v in pairs(m) do if modules[k] ~= nil then modules[k] = v and true or false end end
  else mp.msg.warn("cadre.conf: missing or invalid, using defaults") end
end

local files = {
  osc="cadre_osc", playlist="cadre_playlist", titlebar="cadre_titlebar",
  menu="cadre_menu", stream="cadre_stream", youtube="cadre_youtube", music_mode="cadre_music_mode", 
  ab_loop="cadre_ab_loop", subs="cadre_subs", keep_session="cadre_keep_session",
  webdav_browser="external/webdav-browser-posters",
  auto_theme="cadre_auto_theme", livecap="cadre_livecap",
}

local mpv_opts = {
  titlebar = { border = "no" },
  osc      = { ["osd-bar"] = "no", ["autofit-smaller"] = "800x600" },
}

local conf_path = base .. "cadre.conf"

local function set_install_flag_false()
  local fh = io.open(conf_path, "r")
  if not fh then return end
  local txt = fh:read("*a"); fh:close()
  local new, n = txt:gsub('("install_fonts"%s*:%s*)true', '%1false')
  if n == 0 and not txt:find('"install_fonts"', 1, true) then
    new, n = txt:gsub('("main"%s*:%s*{)', '%1\n    "install_fonts": false,', 1)
  end
  if n > 0 then
    local w = io.open(conf_path, "w")
    if w then w:write(new); w:close() end
  end
end

local function install_fonts()
  local m = data and data.main
  if m and m.install_fonts == false then return end

  local src = base .. "fonts/"
  local dst = mp.command_native({"expand-path", "~~/fonts/"})
  local files = utils.readdir(src, "files")
  if not files then return end

  if not utils.file_info(dst) then
    local win = package.config:sub(1, 1) == "\\"
    mp.command_native({name = "subprocess", playback_only = false,
      args = win and {"cmd", "/c", "mkdir", (dst:gsub("/", "\\"))} or {"mkdir", "-p", dst}})
  end

  local copied, failed = 0, false
  for _, name in ipairs(files) do
    local ext = name:lower():match("%.(%w+)$")
    if ext == "ttf" or ext == "otf" or ext == "ttc" then
      if not utils.file_info(dst .. name) then
        local i = io.open(src .. name, "rb")
        local o = i and io.open(dst .. name, "wb")
        if i and o then o:write(i:read("*a")); copied = copied + 1 else failed = true end
        if i then i:close() end
        if o then o:close() end
      end
    end
  end

  if failed then
    mp.msg.warn("cadre: some fonts could not be copied, will retry next start")
    return
  end
  set_install_flag_false()
  if copied > 0 then
    mp.osd_message("Cadre: fonts installed, restart mpv once", 6)
  end
end
install_fonts()

local apply = true
if data and data.main and data.main.apply_mpv_options == false then apply = false end

if apply then
  for key, props in pairs(mpv_opts) do
    if modules[key] then
      for name, value in pairs(props) do
        mp.set_property(name, value)
      end
    end
  end
end

if (modules.osc or modules.titlebar) and mp.get_property_bool("osc") then
  mp.commandv("script-message", "osc-visibility", "never")
end

if (modules.osc or modules.titlebar) and mp.get_property_bool("osc") then
  mp.commandv("script-message", "osc-visibility", "never")
  mp.msg.info("stock OSC hidden via osc-visibility (osc=no in mpv.conf avoids this)")
end

if modules.livecap and data and data.livecap then
    local livecap = data.livecap
    local python = (livecap.python_path and livecap.python_path ~= "") and livecap.python_path or "python"
    local script = base .. "tools/cadre_livecap.py"

    mp.command_native_async({
        name = "subprocess",
        args = {
            python,
            script,
            conf_path
        },
        playback_only = false,
        detach = false,
        capture_stdout = false,
        capture_stderr = false,
    }, function(success, result, err)
        if not success then
            mp.msg.error("Could not start cadre_livecap.py: " .. tostring(err))
        else
            mp.msg.info("Cadre: started livecap worker")
        end
    end)
end


-- Shared compositor helper for the optional GPU-next glass backdrop effect.
mp.commandv("load-script", base .. "scripts/cadre_glass.lua")

for key, name in pairs(files) do
  if modules[key] then
    local path = key == "webdav_browser" and (base .. name .. ".lua") or (base .. "scripts/" .. name .. ".lua")
    mp.commandv("load-script", path)
  end
end
