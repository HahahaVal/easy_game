local Skynet = require "skynet"
local Env    = require "global"

local M = {}

function M.start(fd, roleid)

    Skynet.retpack(ok)
end

function M.stop(fd, reason)

    Skynet.retpack(ok)
end

return M