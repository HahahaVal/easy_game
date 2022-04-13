local Httpc = require "http.httpc"
local Json = require "json"
local Log = require "log_api"
local Skynet = require "skynet"

local M = {}

local mt = {}
mt.__index = mt

local fail_hosts = {}

Httpc.dns() -- 异步查询 dns，避免阻塞整个 skynet 的网络消息

local function url_decode(str)
    local str = str:gsub('+', ' ')
    return (str:gsub("%%(%x%x)", function(c)
                         return string.char(tonumber(c, 16))
                                 end))
end

local function url_encode(str)
    return (str:gsub("([^A-Za-z0-9%_%.%-%~])", function(v)
                         return string.upper(string.format("%%%02x", string.byte(v)))
                                               end))
end

local function tab_exist(val)
    if type(val) == "table" then
        if next(val) then
            return true
        end
    end
    return false
end

local function format_params(params)
    local paramsT = {}
	for k, v in pairs(params) do
		local key = tostring(k)
		local value = tostring(v)
        table.insert(paramsT, url_encode(key) .. "=" .. url_encode(value))
	end
	return table.concat(paramsT, "&")
end

local function get_real_key(prefix, key)
    return (type(prefix) == 'string' and prefix or "") .. key
end

function mt:_report_failure(etcd_host)
    if type(etcd_host) ~= "string" then
        return false
    end
    fail_hosts[etcd_host] = Skynet.now() + self.fail_time
end

function mt:_get_target_status(etcd_host)
    if type(etcd_host) ~= "string" then
        return false
    end
    local fail_expired_time = fail_hosts[etcd_host]
    if fail_expired_time and fail_expired_time >= Skynet.now() then
        return false
    else
        return true
    end
end

function mt:_choose_endpoint()
    local hosts = self.hosts
    for _, host in ipairs(hosts) do
        if self:_get_target_status(host) then
            return host
        end
    end
    return false
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

    Httpc.timeout = timeout and timeout * 100

	local header = {
		["content-type"] = "application/x-www-form-urlencoded"
	}
	local recvheader = {}

    local success, status, rspData = pcall(Httpc.request, method, reqHost, action, recvheader, header, reqData)
    Log.debug("request method:%s host:%s action:%s reqData:%s rspData:%s", method, reqHost, action, reqData, rspData)
    if not success then
        self:_report_failure(reqHost)
        Log.error("request error status:%s", status)
        return false
    end
    if status > 500 then
        self:_report_failure(reqHost)
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

    attr = attr or {}
    local prev_exist
    if attr.prev_exist ~= nil then
        prev_exist = attr.prev_exist and 'true' or 'false'
    end

    local dir
    if attr.dir then
        dir = attr.dir and 'true' or 'false'
    end

    local refresh
    if attr.refresh then
        refresh =  attr.refresh and 'true' or 'false'
    end

    if value and tab_exist(value) then
        value = Json.encode(value)
    end

    local opts = {
        body = {
            value = value,
            ttl = attr.ttl,
            dir = dir,
            prevValue = attr.prev_value and tab_exist(attr.prev_value) and Json.encode(attr.prev_value),
            prevIndex = attr.prev_index,
            prevExist = prev_exist,
            refresh = refresh,
        },
    }
    local action = self.full_prefix .. key
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

    local dir
    if attr.dir then
        dir = attr.dir and 'true' or 'false'
    end

    local opts = {
        query = {
            dir = dir,
            wait = attr_wait,
            waitIndex = attr.wait_index,
            recursive = attr_recursive,
        }
    }

    local action = self.full_prefix .. key
    local rspData = self:_request("GET", action, opts, attr.timeout)
    if not rspData or not tab_exist(rspData) then
        Log.error("ectd error get key rspData:%s, key:%s", rspData, key)
        return false
    end

    return rspData
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
            prevValue = attr.prev_value and tab_exist(attr.prev_value) and Json.encode(attr.prev_value),
        },
    }
    local action = self.full_prefix .. key
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

    local rspData = self:_get(key)

    if rspData and rspData.node.value then
        local tb = Json.decode(rspData.node.value)
        if tb then
            return tb
        end
    end
    return rspData and rspData.node.value
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

    local rspData = self:_get(key, attr)
    return rspData and rspData.node.key
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
    refresh key-val and ttl
--]]
function mt:refresh_val(key, ttl)
    local attr = {}
    attr.ttl = ttl
    attr.prev_exist = true
    attr.refresh = true

    key = get_real_key(self.keyPrefix, key)

    return self:_set(key, nil, attr)
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
    refresh dir and ttl
--]]
function mt:refresh_dir(key, ttl)
    local attr = {}
    attr.ttl = ttl
    attr.dir = true
    attr.prev_exist = true
    attr.refresh = true

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

    local rspData = self:_get(key, attr)

    if rspData and rspData.node.nodes then
        local nodes = rspData.node.nodes
        for _, node in pairs(nodes) do
            local tb = Json.decode(node.value)
            if tb then
                node.value = tb
            end
        end
    end
    return rspData and rspData.node.nodes
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

    local rspData = self:_get(key, attr)
    return rspData and rspData.node.key
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

function M.new(hosts, key_prefix, timeout)
    if type(hosts) ~= "table" then
        Log.error("hosts must be table")
        return false
    end
    local obj = {
        full_prefix = "/v2/keys",
        hosts = hosts,
        key_prefix = key_prefix,
        timeout = timeout or 5,
        fail_time = 30,
    }
    return setmetatable(obj, mt)
end

return M