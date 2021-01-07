local Skynet    = require "znet"
local Monitor   = require "monitor_api"
local Command = require "command"
local Env = require "global"

local function atexit()
    print("agent exit")
end



local function __init__()
    Skynet.dispatch("lua", function(_, _, cmd, ...)
        local f = assert(Command[cmd], cmd)
        f(...)
    end)

    Monitor.register("agent", atexit)
end

Skynet.start(__init__)