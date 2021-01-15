local Skynet = require "znet"

local function launch_share()
    Skynet.uniqueservice("logger")
    Skynet.monitor("monitor")
    
    local port = assert(tonumber(Skynet.getenv("console_port")))
    Skynet.uniqueservice("debug_console", port)
end

local function launch_local()
    Skynet.uniqueservice("proxy")
    Skynet.uniqueservice(true, "role_db")
    Skynet.uniqueservice("hall")
end

local function init()
    launch_share()
    launch_local()
end

local function __init__()
    local start_result, errmsg = true, nil
    xpcall(init,function (err)
        start_result = false
        errmsg = err..debug.traceback()
    end)
    Skynet.call("monitor", "lua", "start_info", start_result, errmsg)
    if not start_result then
        Skynet.abort()
    end
end

Skynet.start(__init__)