local Driver   = require "skynet.socketdriver"
local Connect = require "connect"
local Protocol = require "protocol"

local M = {}

local mt = {}
mt.__index = mt

-------------------------------socket

function mt:listen()
    assert(not self.lfd)
    self.lfd = Driver.listen(self.ip, self.port)
    Driver.start(self.lfd)
end

function mt:push_data(id, data, size)
    local conn = self.conns[id]
    if conn then
        conn:push(data, size)
        return true
    end
    return false
end

function mt:open_conn(id)
    if id == self.lfd or self.conns[id] then
        return true
    end
    return false
end

function mt:close_conn(id)
    if self:kick_conn(id) then
        Skynet.send(self.watchdog, Protocol.PTYPE_GATE_NAME, "close", id)
    end
end

function mt:add_conn(id, addr)
    if self.cur_con >= self.max_con then
        Driver.close(id)
        return
    end
    local conn = Connect.new_connection(self, id, addr)
    self.conns[id] = conn
    self.cur_con = self.cur_con + 1
    Skynet.send(self.watchdog, Protocol.PTYPE_GATE_NAME, "open", conn.id, conn.addr)
end

function mt:close()
    if self.lfd then
        Driver.close(self.lfd)
        self.lfd = nil
    end
end

-------------------------------
function mt:forward_conn(id, agent)
    local conn = self.conns[id]
    if conn then
        conn:set_agent(agent)
    end
end

function mt:start_conn(id)
    local conn = self.conns[id]
    assert(conn.agent, "please forward before start")
    if conn then
        Driver.start(id)
    end
end

function mt:kick_conn(id)
    local conn = self.conns[id]
    if conn then
        self.conns[id] = nil
        self.cur_con = self.cur_con - 1
        conn:close()
        return true
    end
    return false
end

function M.newgate(header, watchdog, listen_addrs, watchdog_ptype, max)
    local obj = {}
    if header == "S" then
        obj.hsize = 2
        obj.hflag = ">H"
    else
        obj.hsize = 4
        obj.hflag = ">I"
    end
    obj.watchdog = watchdog
    obj.watchdog_ptype = watchdog_ptype

    local ip, port = listen_addrs:match("([%w%.]*):([%d]+)")
    obj.ip = ip
    obj.port = assert(tonumber(port))

    obj.cur_con  = 0
    obj.max_con  = max
    obj.conns = {}

    obj.lfd = nil
    return setmetatable(obj, mt)
end

return M