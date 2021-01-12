local Skynet = require "znet"
local Env = require "global"
local Command = require "command"

local function __init__()
    Skynet.dispatch("lua", function(session, source, cmd, ...)
		local f = assert(Command[cmd], cmd .. " not found")
		f(source, ...)
	end)
    Skynet.register(".logger")
end


Skynet.start(__init__)