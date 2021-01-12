local Skynet = require "znet"

local mt = {}
mt.__index = mt

function mt:forward(fd, agent, client)
    Skynet.send(self.gate, "text", "forward", fd, Skynet.address(agent), Skynet.address(client))
end

function mt:start(fd)
    Skynet.send(self.gate, "text", "start", fd)
end

function mt:close()
    Skynet.send(self.gate, "text", "close")
end


function mt:kick(fd)
    Skynet.send(self.gate, "text", "kick", fd)
end


local M = {}
function M.new(port, tag, max_agent)
    local obj = {}
    obj.gate = assert(
        Skynet.launch("gate", "S", Skynet.address(Skynet.self()), port, tag, max_agent), 
    "launch gate failed")
    setmetatable(obj,mt)
    return obj
end
return M

