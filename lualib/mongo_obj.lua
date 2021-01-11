local Mongo   = require "skynet.db.mongo"
local Bson    = require "bson"


-- all funcion begin with ack, will get last error after excute
local coll_mt = {}
local prefix = 'ack_'
local sz = #prefix
coll_mt.__index = function(self, k)
    if k:sub(1, sz) == prefix then
        return function(self, ...)
            local func_name = k:sub(sz+1)
            local raw = self.coll[func_name]
            raw(self.coll, ...)
            local r = self.db:runCommand('getLastError')
            local ok = (r.ok == 1 and r.code == nil)
            return ok, r.err, r
        end
    else
        return function(self, ...)
            local raw = self.coll[k]
            return raw(self.coll, ...)
        end
    end
end



local mt = {}
mt.__index = mt

function mt:get_collection(name)
    if not self.config.collections[name] then
        print("get collection failed, collection:", name)
        return
    end

    if not self.collections[name] then
        self.collections[name] = setmetatable({db=self.db, coll=self.db[name]}, coll_mt)
        self:ensure_indexes(name)
    end
    return self.collections[name]
end

function mt:ensure_indexes(name)
    local config = self.config.collections[name]
    if not config or not config.auto_create_index then
        return
    end
    local obj = self.collections[name]
    if not obj then
        return
    end
    for _, index in ipairs(config.indexes) do
        local ret = obj:createIndex(index.keys, index.options or {})
        if not ret.ok then
            print("createIndex, fail:", ret)
        end
    end
end


local function load_config(path)
    local env = {}
    local f = assert(loadfile(path, "t", env))
    f()
    return env
end

local M = {}
function M.new(name)
    local path = assert(Skynet.getenv("mongodb"))
    local config = load_config(path)
    local client = Mongo.client(config.addr)
    local db = client:getDB(name)

    local obj = {}
    obj.db = db
    obj.collections = {}
    obj.config = config

    return setmetatable(obj, mt)
end
return M
