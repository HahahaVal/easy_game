local Httpc = require "http.httpc"
local Json = require "json"
local Log = require "log_api"

local INIT_COUNT_RESIZE = 2e8

local M = {}

local mt = {}
mt.__index = mt

Httpc.dns() -- 异步查询 dns，避免阻塞整个 skynet 的网络消息

local function format_params(params)
    local paramsT = {}
	for k, v in pairs(params) do
		local key = tostring(k)
		local value = tostring(v)
        table.insert(paramsT, key .. "=" .. value)
	end
	return table.concat(paramsT, "&")
end

local function get_real_key(prefix, key)
    return (type(prefix) == 'string' and prefix or "") .. key
end

function mt:_choose_endpoint()
    local hosts = self.hosts
    local hosts_len = #hosts
    if hosts_len == 1 then
        return hosts[1]
    end

    self.init_count = (self.init_count or 0) + 1
    local pos = self.init_count % hosts_len + 1
    if self.init_count >= INIT_COUNT_RESIZE then
        self.init_count = 0
    end
    return hosts[pos]
end

function mt:_request(method, action, opts, timeout)
    opts = opts or {}

    local reqHost = self:_choose_endpoint()

    if opts.query and next(opts.query) then
        action = action .. '?' .. format_params(opts.query)
    end

    local reqData
    if opts.body and next(opts.body) then
        reqData = format_params(opts.body)
    end

    Httpc.timeout = timeout * 100

	local header = {
		["content-type"] = "application/x-www-form-urlencoded"
	}
	local recvheader = {}

    local success, status, rspData = pcall(Httpc.request, method, reqHost, action, recvheader, header, reqData)
    Log.debug("request method:%s host:%s action:%s reqData:%s rspData:%s", method, reqHost, action, reqData, rspData)
    if not success then
        Log.error("request error status:%s", status)
        return false
    end
    if status < 200 or status >= 300 then
        Log.error("invalid response status:%s", status)
        return false
    end
    return Json.decode(rspData)
end

function mt:_set(key, value, attr)
    if not key or key == '/' then
        Log.error("set key invalid")
        return false
    end
    if value then
        value = Json.encode(value)
    end

    attr = attr or {}
    local prev_exist
    if attr.prev_exist ~= nil then
        prev_exist = attr.prev_exist and 'true' or 'false'
    end

    local dir
    if attr.dir then
        dir = attr.dir and 'true' or 'false'
    end

    local opts = {
        body = {
            value = value,
            ttl = attr.ttl,
            dir = dir,
            prevValue = attr.prev_value and Json.encode(attr.prev_value),
            prevIndex = attr.prev_index,
            prevExist = prev_exist,
        },
    }
    local action = self.full_prefix .. "/" .. key
    local rspData = self:_request(attr.in_order and 'POST' or 'PUT', action, opts, self.timeout)
    if not rspData then
        Log.error("ectd error set key rspData:%s, key:%s, value:%s", rspData, key, value)
        return false
    end
    return true
end

function mt:_get(key, attr)
    if not key or key == '/' then
        Log.error("get key invalid")
        return false
    end

    attr = attr or {}
    local attr_wait
    if attr.wait ~= nil then
        attr_wait = attr.wait and 'true' or 'false'
    end

    local attr_recursive
    if attr.recursive then
        attr_recursive = attr.recursive and 'true' or 'false'
    end

    local opts = {
        query = {
            wait = attr_wait,
            waitIndex = attr.wait_index,
            recursive = attr_recursive,
        }
    }

    local action = self.full_prefix .. "/" .. key
    local rspData = self:_request("GET", action, opts, attr.timeout or self.timeout)
    if not rspData then
        Log.error("ectd error get key rspData:%s, key:%s", rspData, key)
        return false
    end

    if attr.dir then
        return rspData.node.nodes
    end
    return rspData.node.value
end

function mt:_delete(key, attr)
    if not key or key == '/' then
        Log.error("delete key invalid")
        return false
    end

    attr = attr or {}
    local attr_dir
    if attr.dir then
        attr_dir = attr.dir and 'true' or 'false'
    end

    local attr_recursive
    if attr.recursive then
        attr_recursive = attr.recursive and 'true' or 'false'
    end

    local opts = {
        query = {
            dir = attr_dir,
            prevIndex = attr.prev_index,
            recursive = attr_recursive,
            prevValue = attr.prev_value and Json.encode(attr.prev_value),
        },
    }
    local action = self.full_prefix .. "/" .. key
    local rspData = self:_request("DELETE", action, opts, self.timeout)
    if not rspData then
        Log.error("ectd error delete key rspData:%s, key:%s", rspData, key)
        return false
    end
    return true
end

--[[
    get value by key
--]]
function mt:get(key)
    if not tostring(key) then
        Log.error('key must be string')
        return false
    end

    key = get_real_key(self.key_prefix, key)

    return self:_get(key)
end

--[[
    wait key
    modified_index:
	    * index 小于等于当前 index ，即事件已经发生，那么监听会立即返回该事件
	    * index 大于当前 index，等待 index 之后的事件发生并返回
    timeout：超时等待时间
--]]
function mt:wait(key, modified_index, timeout)
    if not tostring(key) then
        Log.error('key must be string')
        return false
    end
    if modified_index and not tonumber(modified_index) then
        Log.error('modified_index must be number')
        return false
    end

    local attr = {}
    attr.wait = true
    attr.wait_index = modified_index
    attr.timeout = timeout

    key = get_real_key(self.key_prefix, key)

    return self:_get(key, attr)
end

--[[
    set key-val and ttl
    ttl:存活时长
--]]
function mt:set(key, val, ttl)
    if not tostring(key) then
        Log.error('key must be string')
        return false
    end

    local attr = {}
    attr.ttl = ttl

    key = get_real_key(self.key_prefix, key)

    return self:_set(key, val, attr)
end

--[[
    set key-val and ttl if key does not exists atomic create
--]]
function mt:setnx(key, val, ttl)
    local attr = {}
    attr.ttl = ttl
    attr.prev_exist = false

    key = get_real_key(self.key_prefix, key)

    return self:_set(key, val, attr)
end

--[[
    set key-val and ttl if key is exists atomic update
--]]
function mt:setx(key, val, ttl, modified_index)
    if modified_index and not tonumber(modified_index) then
        Log.error('modified_index must be number')
        return false
    end

    local attr = {}
    attr.ttl = ttl
    attr.prev_exist = true
    attr.prev_index = modified_index

    key = get_real_key(self.key_prefix, key)

    return self:_set(key, val, attr)
end

--[[
   delete key
--]]
function mt:delete(key, prev_val, modified_index)
    if modified_index and not tonumber(modified_index) then
        Log.error('modified_index must be number')
        return false
    end

    local attr = {}
    attr.prev_value = prev_val
    attr.prev_index = modified_index

    key = get_real_key(self.key_prefix, key)

    return self:_delete(key, attr)
end

--[[
    create dir and ttl
--]]
function mt:mkdir(key, ttl)
    local attr = {}
    attr.ttl = ttl
    attr.dir = true

    key = get_real_key(self.key_prefix, key)

    return self:_set(key, nil, attr)
end

--[[
    read dir
    recursive:true递归读取
--]]
function mt:read_dir(key, recursive)
    local attr = {}
    attr.dir = true
    attr.recursive = recursive

    key = get_real_key(self.key_prefix, key)

    return self:_get(key, attr)
end

--[[
    wait dir with recursive
--]]
function mt:wait_dir(key, modified_index, timeout)
    if modified_index and not tonumber(modified_index) then
        Log.error('modified_index must be number')
        return false
    end

    local attr = {}
    attr.wait = true
    attr.dir = true
    attr.recursive = true
    attr.wait_index = modified_index
    attr.timeout = timeout

    key = get_real_key(self.key_prefix, key)

    return self:_get(key, attr)
end

--[[
   delete dir
--]]
function mt:rm_dir(key, recursive)
    local attr = {}
    attr.dir = true
    attr.recursive = recursive

    key = get_real_key(self.key_prefix, key)

    return self:_delete(key, attr)
end

--[[
   in-order keys
--]]
function mt:push(key, val, ttl)
    local attr = {}
    attr.ttl = ttl
    attr.in_order = true

    key = get_real_key(self.key_prefix, key)

    return self:_set(key, val, attr)
end

function M.new(hosts, full_prefix, timeout)
    if type(hosts) ~= "table" then
        Log.error("hosts must be table")
        return false
    end
    local obj = {
        hosts = hosts,
        init_count = 0,
        key_prefix = "",
        full_prefix = full_prefix or "/v2/keys",
        timeout = timeout or 5,
    }
    return setmetatable(obj, mt)
end

return M