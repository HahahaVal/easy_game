local Log = require "log_api"

local mt = {}
mt.__index = mt

--订阅
function mt:sub(event, func)
    assert(event and func)

    local infos = self.handlers[event]
    if not infos then
        infos = {}
        self.handlers[event] = infos
    end
    --check duplicate'func
    for _, info in ipairs(infos) do
        assert(info.func ~= func, event)
    end

    local id = self.id
    self.id = self.id + 1
    local new_info = {id = id, func = func}
    table.insert(infos, new_info)
    return id
end

--取消订阅
function mt:unsub(event, id)
    assert(event and id)

    local infos = self.handlers[event]
    if not infos then
        return false
    end

    for i=#infos, 1, -1 do
        if infos[i].id == id then
            table.remove(infos, i)
            return true
        end
    end
    return false
end

--发布
function mt:pub(event, ...)
    assert(event)

    local args = {...}
    local infos = self.handlers[event]
    if not infos then
        Log.error("event:%s has no handler", event)
        return false
    end

    for _, info in ipairs(infos) do
        local ok, errmsg = xpcall(info.func, debug.traceback, table.unpack(args))
        if not ok then
            Log.error("event:%s call id:%d failed:%s", event, info.id, errmsg)
        end
    end
    return true
end

local M = {}

function M.new()
    return setmetatable({
        handlers = {},  --{ [event] = {{func=xx,id=xx},{func=xx,id=xx}} }
        id = 1,         --自增器
    }, mt)
end

return M