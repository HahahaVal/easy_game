local Skynet = require "znet"
local Log = require "log_api"
local Date = require "date"
local PQueue = require "priority_queue"

local M = {}

local mt = {}
mt.__index = mt

function mt:add_timer(interval, func)
    assert(interval >= self.check_sec, interval)
    self.pqueue:enqueue(func, interval)
end

function mt:remove_timer(func)
    self.pqueue:remove(func)
end

function mt:update()
    local now = Date.time()
    while not self.pqueue:empty() do
        local func, time_stamp = self.pqueue:peek()
        if time_stamp > now then
            break
        end

        local ok, msg = pcall(func, now)
        if not ok then
            Log.error("timer_line func error: %s", msg)
        end

        self.pqueue:dequeue()
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
    obj.pqueue = PQueue.new()
    return setmetatable(obj, mt)
end

return M