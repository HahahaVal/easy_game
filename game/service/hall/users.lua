local User = require "user"
local Env = require "global"

local mt = {}
mt.__index = mt

function mt:create(uid, roleid, session)
    local fd = session:get_fd()
    if self.users[uid] then
        self:kick(uid, "repeated login")
    end
    local user = User.new(uid, roleid, session)
    self.users[uid] = user
    return user
end


function mt:kick(uid, reason)
    local user = self.users[uid]
    if user then
        user:on_kicked(reason)
    end
end


function mt:destroy(uid, reason)
    local user = self.users[uid]
    if user then
        user:leave_game(reason)
        self.users[uid] = nil
    end
end

local M = {}

function M.new()
    local obj = {
        users = {},
    }
    setmetatable(obj,mt)
end

return M