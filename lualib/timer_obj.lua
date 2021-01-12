local Skynet = require "znet"
local Log = require "log_api"

local M = {}

local mt = {}
mt.__index = mt

function mt:add_timer(interval, func, times)
    assert(interval >= self.check_sec, interval)
    local handle = self.handle
    self.handle = handle + 1
    interval = interval * 100
    self.timers[handle] = {
        interval = interval, 
        func = func, 
        wakeup = interval + Skynet.now(),
        times = times or 0,
    }
    return handle
end

function mt:timeout(interval, func)
    local handle = self.handle
    self.handle = handle + 1
    interval = interval * 100
    self.timers[handle] = {
        interval = interval, 
        func = func, 
        wakeup = interval + Skynet.now(),
        times = 1,
    }
    return handle
end

function mt:remove_timer(handle)
    self.to_deleted[handle] = true
end

function mt:update()
    for k,_ in pairs(self.to_deleted) do
        self.timers[k] = nil
    end

    for k,v in pairs(self.timers) do
        if v.wakeup <= Skynet.now() then
            v.wakeup = v.wakeup + v.interval
            local ok, msg = xpcall(v.func, debug.traceback)
            if not ok then
                Log.error("timer failed:%s", msg)
            end
            if v.times > 0 then
                if v.times == 1 then
                    self:remove_timer(k)
                else
                    v.times = v.times - 1
                end
            end
        end
    end
end

function mt:start()
    if self.running then
        return
    end
    self.running = true
    Skynet.fork(function ()
        while self.running do
            self:update()
            Skynet.sleep(self.check_sec * 100)
        end
    end)
    return
end

function mt:stop()
    self.running = false
end

function M.new(check_sec)
    local obj = {}
    obj.running = false
    obj.check_sec = check_sec
    obj.handle = 1
    obj.to_deleted = {}
    obj.timers = {}
    return setmetatable(obj, mt)
end

return M