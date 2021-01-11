local Env = require "global"
local Connection = require "connection"
local RoleApi = require "role_api"
local RoleFactory = require "role_factory" 
local Skynet = require "znet"

local mt = {}
mt.__index = mt

function mt:get_uid()
    return self.uid
end

function mt:get_role()
    if not self.role then
        self.role = RoleApi.get(self.uid, self.roleid)
    end
    return self.role
end

function mt:create_role(name)
    if self.role then
        return false
    end
    local role = RoleFactory.create(self.uid, name)
    if not role then
        return false
    end
    self.role = role
    self.roleid = self.role.roleid
    return self.roleid
end

function mt:enter_game()
    local fd = self.session:get_fd()
    if self.agent then
        return false
    end
    local agent = Env.agent_pool:get(self.uid)
    if not agent then
        return false
    end

    local ok, inited = pcall(Skynet.call, agent, "lua", "start", fd, self.role.roleid)
    if not ok or not inited then
        Env.agent_pool:put(self.uid)
        return false
    end

    if not Connection.forward(fd, agent) then
        Env.agent_pool:put(self.uid)
        return false
    end
    self.agent = agent
    return true
end


function mt:on_kicked(reason)
    local fd = self.session:get_fd()
    Connection.kick(fd, reason)
end


local M = {}
function M.new(uid, roleid, session)
    local obj = {
        uid = uid,
        roleid = roleid,
        session = session,
        role = nil,
    }
    return setmetatable(obj,mt)
end
return M