local RoleApi = require "role_api"
local Env = require "global"

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
        print("create role, roleid:", roleid)
        return obj
    end
end

return M
