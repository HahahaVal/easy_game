local Skynet   = require "znet"
local Driver   = require "skynet.socketdriver"
local Gate     = require "gate"
local Protocol = require "protocol"
local Env      = require "global"

local header, watchdog, listen_addrs, watchdog_ptype, max = ...
watchdog = assert(tonumber(watchdog))
watchdog_ptype = assert(tonumber(watchdog_ptype))
max = assert(tonumber(max))



-----------------------------socket
local socket_message = {} 

-- SKYNET_SOCKET_TYPE_CONNECT = 2
socket_message[2] = function(id, _, addr)
    if not Env.gate:open_conn(id) then
        Driver.close(id)
    end
end

-- SKYNET_SOCKET_TYPE_ACCEPT = 4
socket_message[4] = function(id, newid, addr)
    assert(id == Env.gate.lfd)
    Env.gate:add_conn(newid, addr)
end

-- SKYNET_SOCKET_TYPE_DATA = 1
socket_message[1] = function(id, size, data)
    if not Env.gate:push_data(id, data, size) then
        Driver.close(id)
    end
end

-- SKYNET_SOCKET_TYPE_CLOSE = 3
socket_message[3] = function(id)
    Env.gate:close_conn(id)
end

-- SKYNET_SOCKET_TYPE_ERROR = 5
socket_message[5] = function(id)
    if id == Env.gate.lfd then
        Env.gate:close()
    else
        Env.gate:close_conn(id)
    end
end

Skynet.register_protocol {
    name = "socket",
    id = Skynet.PTYPE_SOCKET,
    unpack = Driver.unpack,
    dispatch = function(_,_,t, n1, n2, data)
        socket_message[t](n1,n2,data)
    end
}

-----------------------------Env.gate

local command = {}

-- for new connection, must call forward before start
function command.forward(id, agent)
    Env.gate:forward_conn(id, agent)
end

function command.start(id)
    Env.gate:start_conn(id)
end

function command.kick(id)
    Env.gate:kick_conn(id)
end

function command.close()
    Env.gate:close()
end


Skynet.register_protocol(Protocol[Protocol.PTYPE_GATE_NAME])

local function __init__()
    Env.gate = Gate.newgate(header, watchdog, listen_addrs, watchdog_ptype, max)
    Env.gate:listen()

    Skynet.dispatch(Protocol.PTYPE_GATE_NAME, function(session, addr, cmd, ...)
        local f = assert(command[cmd], cmd)
        f(...)
    end)
end



Skynet.start(__init__)

