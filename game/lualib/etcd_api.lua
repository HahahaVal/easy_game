local Httpc = require "http.httpc"
local Json = require "cjson"
local Log = require "log_api"

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

function mt:request(method, action, opts)
    opts = opts or {}

    local reqHost = self.addr

    if opts.query then
        action = action .. '?' .. format_params(opts.query)
    end

    local reqData
    if opts.body then
        reqData = format_params(opts.body)
    end

	local header = {
		["content-type"] = "application/x-www-form-urlencoded"
	}
	local recvheader = {}

    local success, status, rspData = pcall(Httpc.request, method, reqHost, action, recvheader, header, reqData)
    if not success then
		Log.error("request",string.format("error:%s  host:%s  params:%s", status, reqHost .. action, reqData))
    end
	return status, rspData, recvheader
end

function mt:set(key, value, attr)
    if not key or not value then
        Log.error("set key invalid")
        return false
    end

    attr = attr or {}
    local dir = attr.dir and 'true' or 'false'
    local prev_exist = attr.prev_exist and 'true' or 'false'

    local opts = {
        body = {
            value = value,
            ttl = attr.ttl,
            dir = dir,
            prevValue = attr.prev_value,
            prevIndex = attr.prev_index,
            prevExist = prev_exist,
        },
    }
    local action = self.full_prefix .. "/" .. key
    local status, rspData = self:request(attr.in_order and 'POST' or 'PUT', action, opts)
    if status ~= 200 then
        Log.error("ectd error Set key:",status, rspData, key, value)
        return false
    end
    return true
end

function mt:get(key, attr)
    if not key then
        Log.error("get key invalid")
        return false
    end

    attr = attr or {}
    local attr_wait = attr.wait and 'true' or 'false'
    local attr_recursive = attr.recursive and 'true' or 'false'

    local opts = {
        query = {
            wait = attr_wait,
            waitIndex = attr.wait_index,
            recursive = attr_recursive,
        }
    }

    local action = self.full_prefix .. "/" .. key
    local status, rspData = self:request("GET", action, opts)
    if status == 200 then
        local data = Json.decode(rspData)
        return data.node.value
    else
        Log.error("ectd error get key:", status, rspData, key)
        return false
    end
end

function mt:delete(key)
    if not key then
        Log.error("Delete key invalid")
        return false
    end
    local action = self.full_prefix .. "/" .. key
    local status, rspData = self:Request("DELETE", action)
    if status ~= 200 then
        Log.error("ectd error Delete key:",status, rspData, key)
        return false
    end
    return true
end

function M.new(hosts, full_prefix)
    if type(hosts) ~= "table" then
        Log.error("hosts must be table")
        return false
    end
    local obj = {
        hosts = hosts,
        addr = hosts[1] or "127.0.0.1:2379",
        full_prefix = full_prefix or "/v2/keys",
    }
    return setmetatable(obj, mt)
end

return M