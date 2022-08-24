local Log = require "log_api"

local mt = {}
mt.__index = mt

--订阅
function mt:sub(event, obj)
    assert(event and obj)

    if not obj[event] then
        Log.error("event:%s has't handler", event)
        return
    end

    --事件处理过程中
    if self.event_lock == event then
        if not self.event_lock_add[event] then
            self.event_lock_add[event] = {}
        end
        self.event_lock_add[event][obj] = true
        return
    end

    if not self.event_map[event] then
        self.event_map[event] = {}
    end
    self.event_map[event][obj] = true
end

--取消订阅
function mt:unsub(event, obj)
    assert(event and obj)

    if not self.event_map[event] then
        return
    end

    --事件处理过程中
    if self.event_lock == event then
        if not self.event_lock_del[event] then
            self.event_lock_del[event] = {}
        end
        self.event_lock_del[event][obj] = true
        return
    end

    self.event_map[event][obj] = false
end

--发布
function mt:pub(event, ...)
    assert(event)

    local args = {...}
    local event_objs = self.event_map[event]
    if not event_objs then
        return
    end

    self.event_lock = event
    for obj, _ in pairs(event_objs) do
        local ok, errmsg = xpcall(obj[event], debug.traceback, obj, table.unpack(args))
        if not ok then
            Log.error("event:%s callback failed:%s", event, errmsg)
        end
    end
    self.event_lock = nil

    local event_add_objs = self.event_lock_add[event]
    if event_add_objs then
        for obj, _ in pairs(event_add_objs) do
            self.event_map[event][obj] = true
        end
        self.event_lock_add[event] = nil
    end
    local event_del_objs = self.event_lock_del[event]
    if event_del_objs then
        for obj, _ in pairs(event_del_objs) do
            self.event_map[event][obj] = false
        end
        self.event_lock_del[event] = nil
    end
end

local M = {}

function M.new()
    return setmetatable({
        event_map = {},         --{[event]={[obj1]=true,[obj2]=true}}
        event_lock = nil,
        event_lock_add = {},    --{[event]={[obj1]=true,[obj2]=true}}
        event_lock_del = {},    --{[event]={[obj1]=true,[obj2]=true}}
    }, mt)
end

return M