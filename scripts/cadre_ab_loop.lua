-- cadre_ab_loop.lua
-- Cadre Player / mpv A-B loop manager
--
-- Active loop:
--   a                  Set A
--   q                  Set B and enable looping
--   z                  Clear an unsaved A-B loop, or stop playback of a saved loop
--
-- Saved loop queue:
--   w                  Save active A-B loop
--   Shift+w            Show queue
--   Shift+a            Load previous queued loop
--   Shift+q            Load next queued loop
--   Ctrl+z             Remove last queued loop
--   Ctrl+Backspace     Remove selected queued loop
--   Shift+z            Clear all queued loops immediately
--
-- Export:
--   e                  Export active A-B loop
--   Shift+e            Export all queued loops
--
-- ffmpeg must be in PATH. Exports are local files only.

local mp = require("mp")
local msg = require("mp.msg")
local utils = require("mp.utils")

local options = {
    ffmpeg = "ffmpeg",
    output_dir = "", -- Empty: "Cadre Exports" beside the source video.
    min_duration = 0.10,
    video_codec = "libx264",
    crf = 18,
    preset = "medium",
    audio_codec = "aac",
    audio_bitrate = "192k",
}

local state = {
    queue = {},
    current_index = nil,
    next_id = 1,
    exporting = false,
    export_jobs = {},
}

local function format_time(seconds)
    if type(seconds) ~= "number" then
        return "--:--:--.---"
    end

    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60

    return string.format("%02d:%02d:%06.3f", h, m, s)
end

local function sanitize_filename(name)
    name = tostring(name or "clip")
    name = name:gsub('[<>:"/\\|%?%*]', "_")
    name = name:gsub("^%s+", ""):gsub("%s+$", "")

    return name ~= "" and name or "clip"
end

local function is_local_path(path)
    return path and path ~= "" and not path:match("^%a[%w+.-]*://")
end

local function get_source_path()
    local path = mp.get_property("path")
    return is_local_path(path) and path or nil
end

local function get_active_loop()
    local a = mp.get_property_number("ab-loop-a")
    local b = mp.get_property_number("ab-loop-b")

    if not a or not b or b - a < options.min_duration then
        return nil, nil
    end

    return a, b
end

-- Finds an equivalent loop already stored in the queue.
-- A 1 ms tolerance avoids floating-point timestamp comparison issues.
local function find_active_queued_loop(a, b)
    local source = get_source_path()

    if not source or not a or not b then
        return nil
    end

    for index, item in ipairs(state.queue) do
        if item.source_path == source
            and math.abs(item.start_time - a) < 0.001
            and math.abs(item.end_time - b) < 0.001 then
            return index
        end
    end

    return nil
end

local function clear_active_loop(silent)
    -- Read the active loop before deleting its mpv properties.
    local a, b = get_active_loop()
    local queue_index = find_active_queued_loop(a, b)

    mp.set_property("ab-loop-a", "no")
    mp.set_property("ab-loop-b", "no")

    if silent then
        return
    end

    if queue_index then
        mp.osd_message(
            string.format(
                "Loop playback stopped — saved as #%d",
                queue_index
            ),
            2
        )
    elseif a and b then
        mp.osd_message("A-B loop cleared", 2)
    else
        mp.osd_message("No active A-B loop", 2)
    end
end

local function set_a()
    local pos = mp.get_property_number("time-pos")

    if not pos then
        mp.osd_message("Cannot set A: no playback position", 2)
        return
    end

    mp.set_property_number("ab-loop-a", pos)
    mp.set_property("ab-loop-b", "no")

    mp.osd_message("A set: " .. format_time(pos), 2)
end

local function set_b()
    local pos = mp.get_property_number("time-pos")
    local a = mp.get_property_number("ab-loop-a")

    if not pos then
        mp.osd_message("Cannot set B: no playback position", 2)
        return
    end

    if not a then
        mp.osd_message("Set A first with A", 2)
        return
    end

    if pos - a < options.min_duration then
        mp.osd_message("B must be after A", 2)
        return
    end

    mp.set_property_number("ab-loop-b", pos)

    mp.osd_message(
        string.format(
            "A-B: %s -> %s (%.3f s)",
            format_time(a),
            format_time(pos),
            pos - a
        ),
        3
    )
end

local function add_current_loop()
    local source = get_source_path()
    local a, b = get_active_loop()

    if not source then
        mp.osd_message("Queue works with local files only", 3)
        return
    end

    if not a or not b then
        mp.osd_message("Create a complete A-B loop first", 2)
        return
    end

    local base = mp.get_property("filename/no-ext") or "clip"

    local item = {
        id = state.next_id,
        label = sanitize_filename(base .. "-" .. string.format("%02d", state.next_id)),
        source_path = source,
        start_time = a,
        end_time = b,
    }

    state.queue[#state.queue + 1] = item
    state.current_index = #state.queue
    state.next_id = state.next_id + 1

    mp.osd_message(
        string.format(
            "Saved #%d: %s -> %s",
            #state.queue,
            format_time(a),
            format_time(b)
        ),
        3
    )
end

local function show_queue()
    if #state.queue == 0 then
        mp.osd_message("Loop queue is empty", 2)
        return
    end

    local lines = {
        "Saved loops: " .. #state.queue
    }

    for i, item in ipairs(state.queue) do
        local selected = i == state.current_index and "> " or "  "

        lines[#lines + 1] = string.format(
            "%s%d. %s  %s -> %s",
            selected,
            i,
            item.label,
            format_time(item.start_time),
            format_time(item.end_time)
        )
    end

    mp.osd_message(
        table.concat(lines, "\n"),
        math.min(8, #state.queue + 2)
    )
end

local function load_queue_item(index)
    local item = state.queue[index]

    if not item then
        mp.osd_message("No saved loop", 2)
        return
    end

    if get_source_path() ~= item.source_path then
        mp.osd_message("This saved loop belongs to another file", 3)
        return
    end

    state.current_index = index

    mp.set_property_number("ab-loop-a", item.start_time)
    mp.set_property_number("ab-loop-b", item.end_time)
    mp.commandv("seek", item.start_time, "absolute", "exact")

    mp.osd_message(
        string.format(
            "Loop %d/%d: %s -> %s",
            index,
            #state.queue,
            format_time(item.start_time),
            format_time(item.end_time)
        ),
        3
    )
end

local function previous_queue_item()
    if #state.queue == 0 then
        mp.osd_message("Loop queue is empty", 2)
        return
    end

    local index = (state.current_index or 1) - 1

    if index < 1 then
        index = #state.queue
    end

    load_queue_item(index)
end

local function next_queue_item()
    if #state.queue == 0 then
        mp.osd_message("Loop queue is empty", 2)
        return
    end

    local index = (state.current_index or 0) + 1

    if index > #state.queue then
        index = 1
    end

    load_queue_item(index)
end

local function remove_queue_item(index)
    local item = state.queue[index]

    if not item then
        mp.osd_message("No saved loop to remove", 2)
        return
    end

    table.remove(state.queue, index)

    if #state.queue == 0 then
        state.current_index = nil
    elseif not state.current_index or state.current_index > #state.queue then
        state.current_index = #state.queue
    elseif index < state.current_index then
        state.current_index = state.current_index - 1
    end

    mp.osd_message("Removed saved loop " .. index, 2)
end

local function remove_last_queue_item()
    remove_queue_item(#state.queue)
end

local function remove_current_queue_item()
    if not state.current_index then
        mp.osd_message("Select a saved loop with Shift+A / Shift+Q first", 3)
        return
    end

    remove_queue_item(state.current_index)
end

local function clear_queue()
    local count = #state.queue

    state.queue = {}
    state.current_index = nil

    mp.osd_message("Cleared " .. count .. " saved loop(s)", 2)
end

local function join_path(dir, file)
    local sep = package.config:sub(1, 1)

    if dir:sub(-1) == "/" or dir:sub(-1) == "\\" then
        return dir .. file
    end

    return dir .. sep .. file
end

local function path_exists(path)
    return utils.file_info(path) ~= nil
end

local function ensure_directory(path)
    if path_exists(path) then
        return true
    end

    local args

    if package.config:sub(1, 1) == "\\" then
        args = { "cmd", "/C", "mkdir", path }
    else
        args = { "mkdir", "-p", path }
    end

    local result = utils.subprocess({
        args = args,
        cancellable = false,
    })

    return result.status == 0 or path_exists(path)
end

local function build_output_path(item)
    local dir

    if options.output_dir ~= "" then
        dir = options.output_dir
    else
        local source_dir = utils.split_path(item.source_path)
        dir = join_path(source_dir, "Cadre Exports")
    end

    if not ensure_directory(dir) then
        return nil
    end

    local base = sanitize_filename(item.label)
    local candidate = join_path(dir, base .. ".mp4")
    local n = 2

    while path_exists(candidate) do
        candidate = join_path(dir, base .. "_" .. n .. ".mp4")
        n = n + 1
    end

    return candidate
end

local function ffmpeg_args(item, output)
    return {
        options.ffmpeg,
        "-hide_banner",
        "-y",
        "-ss",
        string.format("%.3f", item.start_time),
        "-to",
        string.format("%.3f", item.end_time),
        "-i",
        item.source_path,
        "-map",
        "0:v:0?",
        "-map",
        "0:a?",
        "-c:v",
        options.video_codec,
        "-crf",
        tostring(options.crf),
        "-preset",
        options.preset,
        "-c:a",
        options.audio_codec,
        "-b:a",
        options.audio_bitrate,
        "-movflags",
        "+faststart",
        output,
    }
end

local function run_next_export()
    local item = table.remove(state.export_jobs, 1)

    if not item then
        state.exporting = false
        mp.osd_message("All exports completed", 3)
        return
    end

    local output = build_output_path(item)

    if not output then
        mp.osd_message("Cannot create export folder", 3)
        run_next_export()
        return
    end

    mp.osd_message(
        string.format(
            "Exporting %s (%d left)",
            item.label,
            #state.export_jobs
        ),
        2
    )

    mp.command_native_async({
        name = "subprocess",
        playback_only = false,
        capture_stdout = true,
        capture_stderr = true,
        args = ffmpeg_args(item, output),
    }, function(success, result, error)
        if success and result and result.status == 0 then
            mp.osd_message("Exported: " .. item.label, 3)
        else
            msg.error(
                "FFmpeg error: "
                .. tostring(error or (result and result.stderr) or "unknown")
            )
            mp.osd_message("Export failed: " .. item.label, 3)
        end

        run_next_export()
    end)
end

local function start_exports(items)
    if state.exporting then
        mp.osd_message("Export already in progress", 2)
        return
    end

    if #items == 0 then
        mp.osd_message("No queued loops to export", 2)
        return
    end

    state.export_jobs = {}

    for _, item in ipairs(items) do
        if is_local_path(item.source_path) then
            state.export_jobs[#state.export_jobs + 1] = item
        end
    end

    if #state.export_jobs == 0 then
        mp.osd_message("No local loops to export", 2)
        return
    end

    state.exporting = true
    run_next_export()
end

local function export_current_loop()
    local source = get_source_path()
    local a, b = get_active_loop()

    if not source then
        mp.osd_message("Export works with local files only", 3)
        return
    end

    if not a or not b then
        mp.osd_message("Create a complete A-B loop first", 2)
        return
    end

    local name = mp.get_property("filename/no-ext") or "clip"

    start_exports({
        {
            label = sanitize_filename(name .. "-loop"),
            source_path = source,
            start_time = a,
            end_time = b,
        }
    })
end

local function export_queue()
    if #state.queue == 0 then
        mp.osd_message("Loop queue is empty", 2)
        return
    end

    start_exports(state.queue)
end

mp.register_event("file-loaded", function()
    clear_active_loop(true)
    state.current_index = nil
end)

mp.register_event("end-file", function()
    state.current_index = nil
end)

-- Lowercase bindings: active A-B loop workflow.
mp.add_key_binding("a", "abq-set-a", set_a)
mp.add_key_binding("q", "abq-set-b", set_b)
mp.add_key_binding("z", "abq-clear-active", clear_active_loop)

-- Queue management.
mp.add_key_binding("w", "abq-save-loop", add_current_loop)
mp.add_key_binding("W", "abq-show-queue", show_queue)
mp.add_key_binding("A", "abq-previous", previous_queue_item)
mp.add_key_binding("Q", "abq-next", next_queue_item)
mp.add_key_binding("Ctrl+z", "abq-remove-last", remove_last_queue_item)
mp.add_key_binding("Ctrl+BS", "abq-remove-current", remove_current_queue_item)
mp.add_key_binding("Z", "abq-clear-queue", clear_queue)

-- Export.
mp.add_key_binding("e", "abq-export-current", export_current_loop)
mp.add_key_binding("E", "abq-export-queue", export_queue)