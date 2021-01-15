-- 基于定时器的lru算法

local Skynet = require "znet"

local mt = {}
mt.__index = function(self, k)
    local v = self.__data[k]
    if v == nil then
        return v
    end
    self.__expires[k] = Skynet.time() + self.__life
    return v
end

mt.__newindex = function(self, k, v)
    if v == nil then
        self.__data[k] = nil
        self.__expires[k] = nil
    else
        self.__data[k] = v
        self.__expires[k] = Skynet.time() + self.__life
    end
end

mt.__pairs = function(self)
    return next, self.__data, nil
end

local function update(cache)
    assert(getmetatable(cache) == mt)
    local now = Skynet.time()
    for k,v in pairs(cache.__expires) do
        if v < now then
            local data = cache.__data[k]
            cache.__expires[k] = nil
            cache.__data[k] = nil

            if cache.__cb then
                cache.__cb(k, data)
            end
        end
    end
end

local M = {}
function M.new(life, check, cb)
    local obj = {
        __data = {},
        __expires = {},
        __life = life,
        __cb   = cb,
    }

    Skynet.fork(function()
        while true do
            Skynet.sleep(check*100)
            update(obj)
        end
    end)
    return setmetatable(obj, mt)
end
return M

