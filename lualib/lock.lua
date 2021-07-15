-- 加锁：
--      无锁则直接加锁
--      请求锁的协程与当前已上锁的协程一致，则采用计数方式，否则将协程插入等待队列挂起当前协程

-- 解锁：
--      解锁的协程必须和锁所属协程一致，计数减一。
--      把锁转移到弹出等待队列的协程，并唤醒协程


local Skynet = require "znet"

local mt = {}
mt.__index = mt

function mt:_lock(co)
    assert(self.locked == false)
    self.locked = co
    self.lock_count = 1
end

function mt:lock()
    local co = coroutine.running()
    if self.locked == co then
        self.lock_count = self.lock_count + 1
        return
    end

    if not self.locked then
        self:_lock(co)
        return
    end
    table.insert(self.lock_waiter, co)
    Skynet.wait()
    assert(self.locked == co)
end

function mt:unlock()
    local co = coroutine.running()
    assert(self.locked == co)
    self.lock_count = self.lock_count - 1
    if self.lock_count > 0 then
        return
    end
    self.locked = false
    self.lock_count = nil

    local co = table.remove(self.lock_waiter, 1)
    if co then
        self:_lock(co)
        Skynet.wakeup(co)
    end
end

function mt:lock_func(func, ...)
    self:lock()
    local ret = { xpcall(func, debug.traceback, ...) }
    self:unlock()
    assert(ret[1], "in lock:" .. tostring(ret[2]))
    return table.unpack(ret, 2)
end

local M = {}

function M.new()
    local obj = {
        locked = false,
        lock_count = nil,
        lock_waiter = {}
    }
    return setmetatable(obj, mt)
end

return M

