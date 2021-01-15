local Skynet = require "znet"
local Env = require "global"
local Command = require "command"

Skynet.register_protocol {
    name = "client",
    id = Skynet.PTYPE_CLIENT,
    unpack = function() end,
    dispatch = function(session, address)
        Command.unregister(address)
	end
}

local function __init__()
    Skynet.dispatch("lua", function(session, addr, cmd, ...)
        local f = assert(Command[cmd], cmd)
        f(...)
    end)
    Skynet.register "monitor"
end

Skynet.start(__init__)