local httpc = require "http.httpc"
local json = require "json"
local Log = require "log_api"

local host = "127.0.0.1"

local M = {}

function M.post(url, data)
    local header = {
        ["content-type"] = "application/json"
    }
    local recvheader = {}

    local body = json.encode(data)
    local ret, status, rspData = pcall(httpc.request, "POST", host, url, recvheader, header, body)
    if not ret then
        Log.error("post error, host:%s, url:%s, status:%s, rspData:%s", host, url, status, rspData)
    end
    return status, rspData
end

return M