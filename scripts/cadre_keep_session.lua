local mp = require 'mp'
local utils = require 'mp.utils'
local opt = require 'mp.options'
local msg = require 'mp.msg'

local o = {
    -- automatically save the previous session
    auto_save = true,

    -- run automatically in idle mode if the playlist is empty
    auto_load = false,

    -- reload the full playlist
    load_playlist = true,

    -- empty means use cadre/data/prev-session
    session_file = "",

    -- maintain position in the playlist
    maintain_pos = true,
}

opt.read_options(o, 'keep_session', function() end)

-- Default location:
-- mpv/scripts/cadre/data/prev-session
--
-- A user-defined session_file in keep_session.conf
-- still overrides this value.
if o.session_file == "" then
    o.session_file = "~~/scripts/cadre/data/prev-session"
end

local save_file = mp.command_native({
    "expand-path",
    o.session_file,
})

--saves the current playlist as a json string
local function save_playlist(file)
    if not file then file = save_file end
    msg.verbose('saving current session to', file)

    local playlist = mp.get_property_native('playlist')

    if #playlist == 0 then
        msg.verbose('session empty, aborting save')
        return
    end

    local session = io.open(file, 'w')
    if not session then return msg.error("Failed to write to file", file) end

    session:write("[playlist]\n")
    session:write(mp.get_property('playlist-pos') .. "\n")

    local working_directory = mp.get_property('working-directory')
    for _, v in ipairs(playlist) do
        msg.debug('adding ' .. v.filename .. ' to playlist')

        --if the file is available then it attempts to expand the path in-case of relative playlists
        --presumably if the file contains a protocol then it shouldn't be expanded
        if not v.filename:find("^%a*://") then
            v.filename = utils.join_path(working_directory, v.filename)
            msg.debug('expanded path: ' .. v.filename)
        end

        session:write("File=" .. v.filename .. "\n")
    end
    session:close()
end

--turns the previous json string into a table and adds all the files to the playlist
local function load_prev_session(file, load_playlist)
    if not file or file == "" then
        file = save_file
    end

    if load_playlist == "yes" then
        load_playlist = true
    elseif load_playlist == "no" then
        load_playlist = false
    else
        load_playlist = o.load_playlist
    end

    msg.info("loading previous session from " .. file)

    local session = io.open(file, "r")

    if not session then
        msg.error("cannot open session file: " .. file)
        return
    end

    local header = session:read("*l")

    if header ~= "[playlist]" then
        msg.error("invalid session header: " .. tostring(header))
        session:close()
        return
    end

    local previous_playlist_pos = tonumber(
        session:read("*l")
    )

    if not previous_playlist_pos then
        msg.error("invalid playlist position")
        session:close()
        return
    end

    msg.info(
        "previous playlist position: " ..
        tostring(previous_playlist_pos)
    )

    if load_playlist then
        msg.info("loading playlist: " .. file)

        session:close()

        if not o.maintain_pos then
            mp.commandv("loadlist", file, "replace")
        else
            local previous_playlist_start =
                mp.get_property("playlist-start")

            mp.set_property_number(
                "playlist-start",
                previous_playlist_pos
            )

            mp.commandv("loadlist", file, "replace")

            if mp.get_property_number("playlist-start")
                ~= previous_playlist_pos
            then
                mp.set_property(
                    "playlist-start",
                    previous_playlist_start
                )
            end
        end

        return
    end

    local files = {}

    for line in session:lines() do
        local filename = line:match("^File=(.+)$")

        if filename then
            table.insert(files, filename)
        end
    end

    session:close()

    local selected_file = files[previous_playlist_pos + 1]

    if selected_file then
        msg.info("loading selected file: " .. selected_file)
        mp.commandv("loadfile", selected_file, "replace")
    else
        msg.error(
            "no file found at playlist position " ..
            tostring(previous_playlist_pos)
        )
    end
end

local function shutdown()
    if o.auto_save then
        save_playlist()
    end
end

mp.register_script_message('save-session', save_playlist)
mp.register_script_message('reload-session', load_prev_session)
mp.register_event('shutdown', shutdown)

--Load the previous session if auto_load is enabled and the playlist is empty.
--This check is delayed until the playlist-count property is initialized, to allow time for macOS GUI-based
--file loading or other asynchronous playlist changes.
--This ensures compatibility with both CLI and GUI startup modes.
if o.auto_load then
    local function try_load(_, value)
        if value == 0 then
            msg.info("Auto-loading session because playlist is empty.")
            load_prev_session()
        else
            msg.info("Playlist already has content, skipping auto-load.")
        end
        mp.unobserve_property(try_load)
    end
    mp.observe_property("playlist-count", "number", try_load)
end
