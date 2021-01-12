local Lock = require "lock"

local Default = 1000
local CacheCount = 10
local WARNING_COUNT = 10000


local mt = {}
mt.__index = mt


function mt:_fill_cache()
    if #self.cache > 0 then
        return
    end

    local doc = self.db:findAndModify({
        query = {name = self.name},
        update = {["$inc"] = {nextid = CacheCount}},
    })
    local start = doc.value.nextid
    print(string.format("inc uid from %d, count: %d", start, CacheCount))
    local max_id = 2^self.bias_size
    if start + WARNING_COUNT > max_id then
        print(string.format("lack of %s warning, current:%d, max:%d", self.name, start, max_id))
    end

    if self.offset then
        local bias = self.offset << self.bias_size
        for i=start, start+CacheCount-1 do
            table.insert(self.cache, i+bias)
        end
    else 
        for i=start, start+CacheCount-1 do
            table.insert(self.cache, i)
        end
    end
end

function mt:_check_cache()
    if #self.cache > 0 then
        return
    end
    self.lock:lock_func(self._fill_cache, self)
end

-- 分配一个id，若缓存为空，会修改数据库
function mt:acquire()
    self:_check_cache()
    return table.remove(self.cache, 1)
end


function mt:init()
    local o = self.db:findOne({name=self.name})
    if not o then
        self.db:insert({name=self.name, nextid=Default})
    end
end

local M = {}
function M.new(db, name, offset, bias_size)
    local obj = {
        db = db,
        name = name,
        offset = offset,
        lock = Lock.new(),
        cache = {},
        bias_size = bias_size,
    }
    local allocator = setmetatable(obj, mt)
    allocator:init()
    return allocator
end

return M