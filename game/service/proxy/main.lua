local Skynet    = require "znet"
local Monitor   = require "monitor_api"
local Watcher   = require "watcher"
local Protocol  = require "protocol"
local GateApi   = require "proxy_gate_api"
local Env       = require "global"
local JsService = require "lualib.jsservice"
local Connection= require "connection"
local GmWeb     = require "service.gm_web"


local function atexit()
    print("proxy exit")
end

Skynet.register_protocol(Protocol[Protocol.PTYPE_GATE_NAME])

local function __init__()
    Skynet.dispatch(Protocol.PTYPE_GATE_NAME, function(session, address, cmd, ...)
        local f = assert(Watcher[cmd], cmd)
        f(...)
    end)

    --gate
    local proxy_address = assert(Skynet.getenv("proxy_address"))
    Env.gate = GateApi.new(proxy_address, JsService.PTYPE_JSON, 1024)
    Env.conns= Connection.new(Env.gate)

    --register callback
    JsService.enable(GmWeb)

    Monitor.register("proxy", atexit)
    Skynet.register ".proxy"
end

Skynet.start(__init__)