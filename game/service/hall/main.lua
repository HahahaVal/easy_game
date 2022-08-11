local Skynet = require "znet"
local Monitor = require "monitor_api"
local Watcher = require "watcher"
local Protocol = require "protocol"
local Env = require "global"
local SprotoService = require "sproto_service"
local Command = require "command"
local HallGateApi = require "hall_gate_api"
local SrvPool = require "srv_pool"
local TimerObj = require "timer_obj"
local Sessions = require "sessions"
local Users = require "users"
local MongoEx = require "mongo_ex"
local IdAllocator = require "id_allocator"
local Log = require "log_api"

local function atexit()
    Log.info("hall exit")
end

Skynet.register_protocol(Protocol[Protocol.PTYPE_GATE_NAME])

local function __init__()
    --gate
    local login_port = assert(Skynet.getenv("login_port"))
    local max_agent = assert(Skynet.getenv("max_agent"))
    Env.gate = HallGateApi.new(login_port, SprotoService.PTYPE_SPROTO, max_agent)
    Skynet.dispatch("text", function (session, address, message)
        local fd, cmd , parm = string.match(message, "(%d+) (%w+) ?(.*)")
        fd = tonumber(fd)
        local f = assert(Watcher[cmd], cmd)
        f(fd,parm)
    end)

    Skynet.dispatch("lua", function(session, address, cmd, ...)
        local f = assert(Command[cmd], cmd)
        f(...)
    end)

    --register callback
    SprotoService.enable("login")

    --agent
    local agent_pool_createor = function()
        return Skynet.newservice("agent")
    end
    local agent_pool_deleter = function(addr)
        Skynet.kill(addr)
    end
    local agent_pool_count = assert(tonumber(Skynet.getenv("agent_pool_count")))
    local agent_pool_threshold = assert(tonumber(Skynet.getenv("agent_pool_threshold")))
    Env.agent_pool = SrvPool.new(agent_pool_createor, agent_pool_deleter, agent_pool_count, agent_pool_threshold)
    Env.agent_pool:reset_nodes()

    Env.timers = TimerObj.new(10)
    Env.timers:add_timer(10, function()
        Env.agent_pool:update()
    end)
    Env.timers:start()

    --sessions/users
    Env.sessions = Sessions.new()
    Env.users = Users.new()
    local id_db = MongoEx.get_game_collection("uniqueid")
    local serverid = assert(Skynet.getenv("serverid"))
    Env.allocator = IdAllocator.new(id_db, "roleid", tonumber(serverid), 24)

    Monitor.register("hall", atexit)
    Skynet.register ".hall"
end

Skynet.start(__init__)