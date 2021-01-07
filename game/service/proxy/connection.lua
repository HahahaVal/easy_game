local Skynet    = require "znet"

local mt = {}
mt.__index = mt

function mt:on_open(fd, addr)
    print("new connection fd:",fd," addr:",addr)
    self.conns[fd] = {fd = fd, addr = addr}

    self.gate:forward(fd, Skynet.self())
    self.gate:start(fd)
end

function mt:on_close(fd)
    local conn = self.conns[fd]
    if conn then
        self.conns[fd] = nil
        print("connection closed fd:",fd," addr:",conn.addr)
    else
        print("connection closed fd:",fd)
    end
end

local M = {}

function M.new(gate)
    local self = {
        gate = gate,
        conns = {}
    }
    return setmetatable(self, mt)
end

return M
