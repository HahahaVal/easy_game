local Session = require "session"

local mt = {}
mt.__index = mt

function mt:open_session(fd, ip, port)
    assert(not self.sessions[fd], fd)
    self.sessions[fd] = Session.new(fd, ip, port)
end

function mt:close_session(fd)
    local session = self.sessions[fd]
    if not session then
        return
    end
    self.sessions[fd] = nil
    session:close()
end

function mt:get_session(fd)
    return self.sessions[fd]
end


local M = {}

function M.new()
    local obj = {
        sessions = {}, -- fd -> session obj
    }
    setmetatable(obj,mt)
    return obj
end

return M