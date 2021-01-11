local Connection = require "connection"

local watcher = {}

function watcher.open(fd, parm)
    local _, addr = string.match(parm,"(%d+) ([^%s]+)")
    local ip, port = string.match(addr,"([^:]+):([^:]+)")
    Connection.open(fd, ip, port)
end

function watcher.close(fd)
    Connection.close(fd)
end

return watcher

