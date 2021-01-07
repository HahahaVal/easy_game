local Skynet = require "skynet"
local Env    = require "global"

local M = {}

function M.open(fd, addr)
    Env.conns:on_open(fd, addr)
end

function M.close(fd)
    Env.conns:on_close(fd)
end


return M