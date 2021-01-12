local RoleApi = require "role_api"
local Env = require "global"
local Log = require "log_api"

local M = {}

function M.create(uid,name)
    local roleid = Env.allocator:acquire()
    assert(roleid, "roleid is nil")

    local obj = {
        uid = uid,
        roleid = roleid,
        name = name,
    }
    local ok = RoleApi.add(obj)
    if ok then
        Log.info("create role, roleid:%d", roleid)
        return obj
    end
end

return M
