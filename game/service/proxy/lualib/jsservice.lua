
local Skynet = require "znet"
local Json   = require "lualib.json"
local Driver = require "skynet.socketdriver"

local MAX_RESP_LEN = 0x10000000

local jservice = {}
local cbs      = {}

jservice.PTYPE_JSON_NAME = "Json"
jservice.PTYPE_JSON      = 28


---------------------------------------register

local function gen_unpack_f(f)
	local nparam = debug.getinfo(f,"u").nparams
	local src = {}
	for i=1,nparam do
		local arg_name = debug.getlocal(f,i)
		if arg_name == "_all" then
			table.insert(src , "param")
		elseif arg_name == "_addr" then
			table.insert(src , "addr")
		else
			table.insert(src , "param."..arg_name)
        end
	end
	return assert(load("return function(param, addr) return " .. table.concat(src,",") .. " end"))()
end

local function make_callback(f)
    local unpack_f = gen_unpack_f(f)
    return function(param, addr)
        local reply = f(unpack_f(param, addr))
        return reply
    end
end

function jservice.enable(command)
    for k,func in pairs(command) do
        assert(not cbs[k] and type(func) == "function", k)
        cbs[k] = make_callback(func)
    end
end


---------------------------------------dispatch


local function unknown_request(session, address, data)
    error(string.format("unknown session:%d from %x, data:%s", session, address, data))
end

local function _check_request(t) 
    if type(t) ~= "table" or type(t.cmd) ~= "string" or type(t.data) ~= "table" then
        return false
    end

    if t.session ~= nil and type(t.session) ~= "number" then
        return false
    end
    return true
end

local function _send_chunk(address, chunk)
    local len = #chunk
    assert(len <= MAX_RESP_LEN, len)
    Driver.send(address, string.pack(">I4", len))
    Driver.send(address, chunk)
end

local function response_to_caller(address, req, data)
    if not req.session or req.session == 0 then
        assert(not data, req.cmd)
        return
    end

    local resp = {}
    resp.session = req.session
    resp.data = data
    local chunk = Json.encode(resp)
    _send_chunk(address, chunk)
end

function jservice.dispatch(session, address, msg, sz)
    local chunk = Skynet.tostring(msg, sz)
    local req   = Json.decode(chunk)

    if not _check_request(req) then
        unknown_request(session, address, chunk)
        return
    end

    local cb = cbs[req.cmd]
    if not cb then
        unknown_request(session, address, chunk)
        return
    end
    response_to_caller(address, req, cb(req.data, address))
end


---------------------------------------send data


Skynet.register_protocol {
    name = jservice.PTYPE_JSON_NAME,
    id   = jservice.PTYPE_JSON,
    pack = function(...) return ... end,
    unpack = function(...) return ... end,
    dispatch = jservice.dispatch
}


return jservice

