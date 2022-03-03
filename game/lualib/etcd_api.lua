local skynet = require "skynet"
local httpc = require "http.httpc"
local Json = require "cjson"

local M = {}

local mt = {}
mt.__index = mt

httpc.dns() -- 异步查询 dns，避免阻塞整个 skynet 的网络消息

local function escape(s)
	return (string.gsub(s, "([^A-Za-z0-9_])", function(c)
		return string.format("%%%02X", string.byte(c))
	end))
end

local function format_params(params)
    local paramsT = {}
	for k, v in pairs(params) do
		local key = tostring(k)
		local value = tostring(v)
		if key and key ~= "" and value and value ~= "" then
			table.insert(paramsT, escape(key) .. "=" .. escape(value))
		end
	end
	return table.concat(paramsT, "&")
end

function mt:request(method, action, params)
	local header = {
		["content-type"] = "application/x-www-form-urlencoded"
	}
    local reqHost = self.addr
	local recvheader = {}

    local reqData = format_params(params)

    local success, status, rspData = pcall(httpc.request, method, reqHost, action, recvheader, header, reqData)
    if not success then
		skynet.logerror("mt.request",string.format("error:%s  host:%s  params:%s", status, reqHost .. action, reqData))
    end
	return status, rspData, recvheader
end

function mt:get(key, opts)
    if not key then
        skynet.logerror("get key invalid")
        return false
    end

    local action = self.root .. "/" .. key
    local limit = (opts and opts.limit) or 0
    local opt = {
        limit = limit,
    }
    local status, rspData = self:request("GET", action, opt)
    if status == 200 then
        local data = Json.decode(rspData)
        return data.node.value
    else
        skynet.logerror("ectd error get key:",status, rspData, key)
        return false
    end
end

function mt:set(key, value, opts)
    if not key or not value then
        skynet.logerror("set key invalid")
        return false
    end

    local action = self.root .. "/" .. key

    local ttl = (opts and opts.ttl) or 10
    local opt = {
        value = value,
        ttl = ttl,
    }
    local status, rspData = self:request("PUT", action, opt)
    if status ~= 200 then
        skynet.logerror("ectd error set key:",status, rspData, key, value)
    end
end

function M.new(hosts, root)
    if type(hosts) ~= "table" then
        skynet.logerror("hosts must be table")
        return false
    end
    local obj = {
        hosts = hosts,
        addr = hosts[1] or "127.0.0.1:2379",
        root = root or "/v2/keys",
    }
    return setmetatable(obj, mt)
end

return M--[[Hotfix]]