local Skynet = require "skynet"
local Env    = require "global"
local Role   = require "role"
local Log    = require "log_api"

local M = {}

function M.start(fd, uid, roleid)
    local role = Role.new(fd,uid,roleid)
    role:init()
    Env.roles[fd] = role
    Skynet.retpack(true)
end

function M.stop(fd, reason)
    local role = Env.roles[fd]
    if not role then
        Log.error("offline don't find role:%s", fd)
        return Skynet.retpack(false)
    end

    Env.roles[fd] = nil
    local ok, errmsg = xpcall(role.fini, debug.traceback, role, reason)
    if not ok then
        Log.error("offline failed:%s", errmsg)
    end
    role:save_db()
    Skynet.retpack(ok)
end

return M