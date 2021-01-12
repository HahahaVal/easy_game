local Skynet    = require "znet"
local Log = require "log_api"

local mt = {}
mt.__index = mt

function mt:on_open(fd, addr)
    Log.info("new connection fd:%d, addr:%s", fd, addr)
    self.conns[fd] = {fd = fd, addr = addr}

    self.gate:forward(fd, Skynet.self())
    self.gate:start(fd)
end

function mt:on_close(fd)
    local conn = self.conns[fd]
    if conn then
        self.conns[fd] = nil
        Log.info("connection closed fd:%d, addr:%s", fd ,conn.addr)
    else
        Log.info("connection closed fd:%d",fd)
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
