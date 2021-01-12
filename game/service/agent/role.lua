local RoleApi = require "role_api"
local Log = require "log_api"

local mt = {}
mt.__index = mt

function mt:init()
    self.db_obj.last_login_time = Skynet.now()
    Log.info("role init finish")
end

function mt:fini(reason)
    Log.info("role fini finish")
end

function mt:save_db()
    RoleApi.update(self.db_obj.uid, self.db_obj)
    Log.info("save_db:%d", self.db_obj.uid)
end


local M = {}

function M.new(fd, uid, roleid)
    local db_obj = assert(RoleApi.get(uid, roleid),uid)
    local obj = {
        fd = fd,
        roleid = roleid,
        db_obj = db_obj,
    }
    setmetatable(obj, mt)
    return obj
end

return M