local Env = require "global"

local watcher = {}

function watcher:open(parm)
    local _, addr = string.match(parm,"(%d+) ([^%s]+)")
    local ip, port = string.match(addr,"([^:]+):([^:]+)")
    Env.gate:forward(fd, Skynet.self())
    Env.gate:start(fd)
end

function watcher:close()
    
end

return watcher

