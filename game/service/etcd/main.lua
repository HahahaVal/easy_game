local Skynet = require "znet"
local Env = require "global"
local Command = require "command"
local EtcdClient = require "etcd_v3api"
local util = require "util"

local serverid = assert(Skynet.getenv("serverid"))
local login_port = assert(Skynet.getenv("login_port"))
local root = '/root'
local prefix = '/'
local etcd_ttl = 10									--etcd的TTL

local function __init__()
    Skynet.dispatch("lua", function(session, address, cmd, ...)
        local f = assert(Command[cmd], cmd)
        f(...)
    end)

    local hosts = {"127.0.0.1:2379",}
    Env.etcd_client = EtcdClient.new(hosts, root)

    local node_data = {
		cid = serverid,
        login_port = login_port,
	}
	Env.etcd_client:set(prefix..serverid, node_data)
    util.Table.print(Env.etcd_client:get(prefix..serverid))

    Skynet.register "etcd"
end

Skynet.start(__init__)