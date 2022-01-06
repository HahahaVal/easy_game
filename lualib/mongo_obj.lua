local Mongo   = require "skynet.db.mongo"
local Log     = require "log_api"
local Skynet  = require "znet"


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
        Log.error("get collection failed, collection:%s", name)
        return
    end

    if not self.collections[name] then
        local collectObj = {
            db = self.db,
            coll = self.db[name],
        }
        self.collections[name] = setmetatable(collectObj, coll_mt)
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
            Log.error("createIndex, fail:%s", ret)
        end
    end
end

function mt:drop_index(name, index)
    if not name or not index then
        return
    end

    local coll = self.db[name]
    coll:dropIndex(index)
end

function mt:drop_indexes(name)
    self:drop_index(name, "*")
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
    local addr = config.addr
    local ok, client = xpcall(Mongo.client, debug.traceback, addr)
    if not ok then
        Log.Errorf('can not connect to [%s:%d]', addr.host, addr.port)
        Log.Errorf('无法连接到%s:%d, 请检查%s', addr.host, addr.port, path)
    end

    local db = client:getDB(name)

    local obj = {
        db = db,
        collections = {},
        config = config,
    }
    return setmetatable(obj, mt)
end
return M
