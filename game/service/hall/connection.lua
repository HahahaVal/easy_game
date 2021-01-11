local Skynet   = require "znet"
local Env      = require "global"

local M = {}

function M.open(fd, ip, port)
    Env.sessions:open_session(fd, ip, port)
    Env.gate:forward(fd, Skynet.self(), fd)
    Env.gate:start(fd)
end

-- 被动关闭连接
function M.close(fd)
    Env.sessions:close_session(fd, string.format("fd<%d> closed by client", fd))
end

-- 数据转发到指定agent
function M.forward(fd, agent)
    if not Env.sessions:get_session(fd) then
        return false
    end
    Env.gate:forward(fd, agent, fd)
    return true
end

-- 主动关闭连接
function M.kick(fd, reason)
    Env.gate:kick(fd)
    Env.sessions:close_session(fd, reason)
end



return M

