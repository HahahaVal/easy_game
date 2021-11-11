local Skynet = require "znet"
local Monitor = require "monitor_api"
local Command = require "command"
local Log = require "log_api"

local function atexit()
    Log.info("http exit")
end

local function __init__()
    Skynet.dispatch("lua", function(_, _, cmd, ...)
        local f = assert(Command[cmd], cmd)
        f(...)
    end)

    Monitor.register("http", atexit)
end

Skynet.start(__init__)