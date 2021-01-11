local Env = require "global"

local mt = {}
mt.__index = mt

function mt:get_fd()
    return self.fd
end

function mt:attach_user(uid, roleid)
    assert(not self.user)
    self.user = Env.users:create(uid, roleid, self)
    return self.user
end

function mt:get_user()
    return self.user
end

function mt:close(reason)
    if self.user then
        Env.users:destroy(self.user:get_uid(), reason)
    end
end

local M = {}
function M.new(fd, ip, port)
    local obj = {
        fd = fd,
        ip = ip,
        port = port,
        user = nil,
    }
    return setmetatable(obj,mt)
end
return M