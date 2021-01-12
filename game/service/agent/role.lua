local mt = {}
mt.__index = mt

function mt:init()
    return
end

local M = {}

function M.new(fd, roleid)
    local obj = {
        fd = fd,
        roleid = roleid,
    }
    setmetatable(obj, mt)
    return obj
end

return M