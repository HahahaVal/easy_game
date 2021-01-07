local Driver   = require "skynet.socketdriver"
local Core        = require "skynet.core"

local M = {}

local conn_mt = {}
conn_mt.__index = conn_mt

local buffer_pool = {}

function conn_mt:dispatch_message()
    if self.chunksz == 0 and self.bufsz >= self.gate.hsize then
        local data = Driver.pop(self.buffer, buffer_pool, self.gate.hsize)
        self.chunksz = string.unpack(self.gate.hflag, data)
        self.bufsz = self.bufsz - self.gate.hsize
    end
    if self.chunksz > 0 and self.bufsz >= self.chunksz then
        local data = Driver.pop(self.buffer, buffer_pool, self.chunksz)
        self.bufsz = self.bufsz - self.chunksz
        self.chunksz = 0
        Core.redirect(self.agent, self.id, self.gate.watchdog_ptype, 0, data)
        -- tail call
        return self:dispatch_message()
    end
end

function conn_mt:push(data, size)
    self.bufsz = self.bufsz + size
    Driver.push(self.buffer, buffer_pool, data, size)
    self:dispatch_message()
end

function conn_mt:close()
    if self.buffer then
        Driver.close(self.id)
        Driver.clear(self.buffer, buffer_pool)
        self.buffer = nil
    end
end

function conn_mt:set_agent(agent)
    self.agent = agent
end

function M.new_connection(gate, id, addr)
    local obj = {
        gate = gate,
        id = id,
        addr = addr,
        buffer = Driver.buffer(),
        bufsz  = 0,
        chunksz = 0,
        agent = nil,
    }

    return setmetatable(obj, conn_mt)
end

return M