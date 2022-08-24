local Skynet = require "znet"
local Protocol = require "protocol"

local mt = {}
mt.__index = mt

function mt:forward(fd, agent)
    Skynet.send(self.gate, Protocol.PTYPE_GATE_NAME, "forward", fd, agent)
end

function mt:start(fd)
    Skynet.send(self.gate, Protocol.PTYPE_GATE_NAME, "start", fd)
end

function mt:kick(fd)
    Skynet.send(self.gate, Protocol.PTYPE_GATE_NAME, "kick", fd)
end

function mt:close()
    Skynet.send(self.gate, Protocol.PTYPE_GATE_NAME, "close")
end

local M = {}

function M.new(listen_addrs, tag, max)
    local obj = {}
    obj.gate = assert(Skynet.newservice("proxy_gate", "S", Skynet.self(), listen_addrs, tag, max))
    return setmetatable(obj, mt)
end

return M
