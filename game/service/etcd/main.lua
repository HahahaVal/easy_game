local Skynet = require "znet"
local Env = require "global"
local Command = require "command"
local EtcdClient = require "etcd_v3api"
local util = require "util"

local serverid = assert(Skynet.getenv("serverid"))
local login_port = assert(Skynet.getenv("login_port"))
local root = 'root/'
local etcd_ttl = 10									--etcd的TTL

local function __init__()
    Skynet.dispatch("lua", function(session, address, cmd, ...)
        local f = assert(Command[cmd], cmd)
        f(...)
    end)
    Skynet.register "etcd"

    local hosts = {"127.0.0.1:2379",}
    Env.etcd_client = EtcdClient.new(hosts, root)

    local node_data = {
		cid = serverid,
        login_port = login_port,
	}
	Env.etcd_client:set(serverid, node_data)

    local data = Env.etcd_client:get(serverid)
    util.Table.print(data or {})

    local reader = Env.etcd_client:watch(serverid)
    while true do
        local data = reader()
        if not data then
            break
        else
            util.Table.print(data or {})
        end
    end
end

Skynet.start(__init__)