--[[
cadre_osc.lua (control bar entry point)
]]
local mp = require "mp"
local base = mp.command_native({"expand-path", "~~/scripts/cadre/scripts/"})

-- Each source module runs in the same private environment. Top-level names
-- are shared between modules; function-local state stays local as usual.
local scope = setmetatable({}, {__index = _G})
local function load_module(name)
    local chunk, err = loadfile(base .. name)
    if not chunk then error("cadre_osc: " .. tostring(err)) end
    setfenv(chunk, scope)
    chunk()
end

load_module("cadre_osc_core.lua")
load_module("cadre_osc_ui.lua")