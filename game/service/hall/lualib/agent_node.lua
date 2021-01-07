local Skynet = require "znet"

local M = {}

local mt = {}
mt.__index = mt

function mt:apply()
    self.online_count = self.online_count + 1
    self.work_times = self.work_times + 1
end

function mt:freed()
    assert(self.online_count > 0)
    self.online_count = self.online_count - 1
end

function mt:get_count()
    return self.online_count
end

function mt:get_work_times()
    return self.work_times
end

function mt:get_addr()
    return self.addr
end

function mt:init()
    self.addr = Skynet.newservice("agent")
end

function mt:fini()
    Skynet.kill(self.addr)
end

function M.new()
    local obj = {
        online_count = 0,
        work_times = 0,
    }
    return setmetatable(obj, mt)
end

return M