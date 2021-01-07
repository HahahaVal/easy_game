local Skynet    = require "znet"
local Monitor   = require "monitor_api"
local Watcher = require "watcher"
local Protocol = require "protocol"
local Gate      = require "hall_gate_api"
local Env = require "global"
local SprotoService  = require "lualib.sproto_service"
local Login = require "service.login"
local Command = require "command"
local GateApi = require "hall_gate_api"
local AgentPool = require "lualib.agent_pool"
local TimerObj  = require "timer_obj"

local function atexit()
    print("hall exit")
end

Skynet.register_protocol(Protocol[Protocol.PTYPE_GATE_NAME])

local function __init__()
    Skynet.dispatch("text", function (session, address, message)
        local id, cmd , parm = string.match(message, "(%d+) (%w+) ?(.*)")
        id = tonumber(id)
        local f = assert(Watcher[cmd], cmd)
        f(id,parm)
    end)
    
    Skynet.dispatch("lua", function(session, address, cmd, ...)
        local f = assert(Command[cmd], cmd)
        f(...)
    end)


    --gate
    local login_port = assert(Skynet.getenv("login_port"), "login_port")
    local max_agent = assert(Skynet.getenv("max_agent"), "max_agent")
    Env.gate = GateApi.launch(login_port, max_agent, SprotoService.PTYPE_SPROTO)


    --register callback
    SprotoService.enable(Login)

    
    --agent
    local agent_pool_count = assert(Skynet.getenv("agent_pool_count"), "agent_pool_count")
    local agent_pool_threshold = assert(Skynet.getenv("agent_pool_threshold"), "agent_pool_threshold")
    agent_pool_count = tonumber(agent_pool_count)
    agent_pool_threshold = tonumber(agent_pool_threshold)
    Env.agent_pool = AgentPool.new(agent_pool_count, agent_pool_threshold)
    Env.agent_pool:reset_nodes()
    Env.timers = TimerObj.new(10)
    Env.timers:add_timer(10, function()
        Env.agent_pool:update()
    end)
    Env.timers:start()


    Monitor.register("hall", atexit)
    Skynet.register ".hall"
end

Skynet.start(__init__)