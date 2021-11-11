local Skynet = require "znet"
local Monitor = require "monitor_api"
local Command = require "command"
local Env = require "global"
local SprotoService  = require "sproto_service"
local Log = require "log_api"

local function atexit()
    Log.info("agent exit")
end

local function _unknown_request(session, address, ...)
    local role = Env.roles[address]
    Log.error("recv unknown request:%s",session)
end

local function gen_unpack_f(f)
    local nparam = debug.getinfo(f,"u").nparams
    local src = {}
    for i=2,nparam do
        local arg_name = debug.getlocal(f,i)
        if arg_name == "_all" then
            table.insert(src , "param")
        elseif arg_name == "_addr" then
            table.insert(src , "addr")
        elseif arg_name == "_timestamp" then
            table.insert(src, "timestamp")
        else
            table.insert(src , "param."..arg_name)
        end
    end
    return assert(load("return function(param, addr, timestamp) return " .. table.concat(src,",") .. " end"))()
end

local function make_callback(f)
    local unpack_f = gen_unpack_f(f)
    return function(param, addr, timestamp)
        local role = Env.roles[addr]
        return f(role, unpack_f(param, addr, timestamp))
    end
end

local function register_sproto(name)
    local command = require("service."..name)
    for k, v in pairs(command) do
        if type(v) == "function" then
            local interface = name .. "." .. k
            SprotoService.register(interface, make_callback(v))
        end
    end
end

register_sproto("hello")
register_sproto("login")

local function __init__()
    Skynet.dispatch("lua", function(_, _, cmd, ...)
        local f = assert(Command[cmd], cmd)
        f(...)
    end)

    Monitor.register("agent", atexit)
end

Skynet.start(__init__)