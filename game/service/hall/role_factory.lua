local RoleApi = require "role_api"

local M = {}

function M.create(uid)
    local roleid = Env.allocator:acquire()
    assert(roleid, "roleid is nil")

    local obj = {
        uid = uid,
        roleid = roleid,
    }

    local ok = RoleApi.add(obj)
    if not ok then
        return Skynet.retpack(false)
    end
    Log.Infof("create role, roleid:%d", roleid)
    Skynet.retpack(obj)

end

return M
