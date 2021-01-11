local Skynet       = require "znet"
local Socket       = require "skynet.socket"
local SprotoLoader = require "sprotoloader"
local SprotoDef    = require "sproto_list"

local MAX_PACKET_LEN = 0xffff

local service = {}
local cbs = {}
local filter_table = {}

service.PTYPE_SPROTO_NAME = "sproto"
service.PTYPE_SPROTO      = 100


local file = assert(Skynet.getenv("protopath"))
SprotoLoader.save(io.input(file):read("a"), 1)
local client_proto = SprotoLoader.load(1)
local client = client_proto:host "base.pack"
local client_request = client:attach(client_proto)


local function gen_unpack_f(f)
	local nparam = debug.getinfo(f,"u").nparams
	local src = {}
	for i=1,nparam do
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
        local reply = f(unpack_f(param, addr, timestamp))
        return reply
    end
end


function service.decode(name, msg)
    return client_proto:decode(name, msg)
end


function service.encode(name, param)
    return client_proto:encode(name, param)
end


local function _write_chunk(address, chunk)
    return Socket.write(address, chunk)
end


local function _pack_chunk(chunk)
    assert(#chunk <= MAX_PACKET_LEN, #chunk)
    local data = string.pack(">s2", chunk)
    return data
end


local function _send_chunk(address, chunk, name)
    local data = _pack_chunk(chunk)
    if not _write_chunk(address, data) then
        print("send proto[%s] to address[%s] failed", name, address)
        return false
    end
    return true
end


function service.send(conn, name, parm)
    local chunk = client_request(name, parm)
    return _send_chunk(conn, chunk, name)
end


function service.enable(command, filter)
    for k,v in pairs(command) do
        if type(v) == "function" then
            local f = make_callback(v)
            service.register(k, f, filter)
        end
    end
end


function service.register(name, func, filter)
    assert(not cbs[name], name)
    if filter then
        filter_table[name] = filter
    end
    cbs[name] = func
end


function service.check_required_parameter(name, request)
    local protocol = assert(SprotoDef.protocol[name], name)
    if not protocol.request then
        return true
    end
    local req_def = assert(SprotoDef.type[protocol.request], name)
    for _,parameter in ipairs(req_def) do
        if request[parameter.name] == nil and parameter.note ~= 'optional' then
            return false, ("protocol %s need %s"):format(name, parameter.name)
        end
    end
    return true
end


local function unknown_request(session, address, name, data)
    error(string.format("unknown session:%d from %x, name:%s, data:%s", session, address, name, data))
end


local function response_to_caller(name, address, response_cb, result)
    if response_cb == nil then
        assert(result == nil, name)
        return
    end
    local protocol = assert(SprotoDef.protocol[name], name)
    if not protocol.response then
        return
    end
    local ok, response = xpcall(response_cb, debug.traceback, result)
    if not ok then
        print("in proto[%s] traceback:%s", name, response)
        return
    end
    _send_chunk(address, response, name)
end


local function sproto_dispatch(session, address, ...)
    Skynet.ignoreret()-- session is fd, don't call skynet.ret
    local type, name, request, response_cb, ud = ...
    if type == "REQUEST" then
        local timestamp = ud or 0
        local filter = filter_table[name]
        if filter and not filter(address, name, timestamp, request) then
            return
        end

        local cb = cbs[name]
        if not cb then
            unknown_request(session, address, name, request)
        else
            response_to_caller(name, address, response_cb, cb(request, address, timestamp))
        end
    else 
        assert(false, "doesn't support type client")
    end
end


Skynet.register_protocol {
    name = service.PTYPE_SPROTO_NAME,
    id   = service.PTYPE_SPROTO,
    pack = function(...) return ... end,
    unpack = function(msg, sz) return client:dispatch(msg, sz) end,
    dispatch = sproto_dispatch,
}


return service