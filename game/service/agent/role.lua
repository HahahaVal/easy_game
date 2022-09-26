local RoleApi = require "role_api"
local Log = require "log_api"
local Date = require "date"
local event = require "event"

local mt = {}
mt.__index = mt

function mt:get_roleid()
    return self.roleid
end

function mt:get_uid()
    return self.uid
end

function mt:set_last_login_time(time)
    self.db_obj.last_login_time = time
end

function mt:get_last_login_time()
    return self.db_obj.last_login_time
end

function mt:init()
    local now = Date.time()
    if not Date.in_same_day(now, self:get_last_login_time()) then
        self:daily_update()
    end
    Log.info("role init finish")
end

function mt:daily_update()
end

function mt:fini(reason)
    Log.info("role fini finish :%s",reason)
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
        uid = uid,
        roleid = roleid,
        db_obj = db_obj,
        event = event.new(),
    }
    setmetatable(obj, mt)
    return obj
end

return M