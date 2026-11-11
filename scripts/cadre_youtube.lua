-- cadre_youtube.lua

local mp = require "mp"
local utils = require "mp.utils"
local msg = require "mp.msg"

local opts = {
    python_path = "pythonw",
    ui_script = "~~/scripts/cadre/tools/cadre_youtube.py",
    yt_dlp_path = "yt-dlp",
    pipe_prefix = "cadre_youtube",
    search_key = "Ctrl+y",
}

local common = dofile(mp.command_native({"expand-path", "~~/scripts/cadre/scripts/cadre_common.lua"}))

common.section("youtube", opts)

opts.search_key = common.key("youtube", opts.search_key)

local function expand(p)
    if p and p:sub(1, 2) == "~~" then return mp.command_native({"expand-path", p}) end
    return p
end

local proc_token = nil

local function ipc_path()
    local suffix = "-" .. tostring(utils.getpid())
    local prefix = opts.pipe_prefix
    local path

    if package.config:sub(1, 1) == "\\" then
        path = "\\\\.\\pipe\\" .. prefix .. suffix
    else
        path = "/tmp/" .. prefix .. suffix .. ".sock"
    end

    mp.set_property("input-ipc-server", path)
    return path
end

local function ytdl_extra_args()
    local raw = mp.get_property_native("options/ytdl-raw-options") or {}
    local args = {}
    for k, v in pairs(raw) do
        table.insert(args, "--" .. k)
        if v ~= "" then table.insert(args, v) end
    end
    return utils.format_json(args)
end

local function toggle_ui()
    if proc_token then
        mp.abort_async_command(proc_token)
        proc_token = nil
        return
    end
    proc_token = mp.command_native_async({
        name = "subprocess", playback_only = false,
        capture_stdout = false, capture_stderr = true,
        args = {
            opts.python_path, expand(opts.ui_script),
            "--ipc", ipc_path(),
            "--yt-dlp", expand(opts.yt_dlp_path),
            "--extra", ytdl_extra_args(),
        },
    }, function(_, res)
        proc_token = nil
        if res and res.status ~= 0 and res.stderr and res.stderr ~= "" then
            msg.error("ytsearch_ui: " .. res.stderr)
        end
    end)
end
common.bind("youtube", opts.search_key, "mpv-youtube-search", toggle_ui)
mp.register_script_message("mpv-youtube-search-open", function ()
    toggle_ui()
end)
