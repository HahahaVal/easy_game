local Skynet = require "znet"
local Env = require "global"
local Command = require "command"
local EtcdClient = require "etcd_v3api"
local util = require "util"
local TimerObj = require "timer_obj"

local serverid = assert(Skynet.getenv("serverid"))
local login_port = assert(Skynet.getenv("login_port"))
local root = '/nodes'
local prefix = '/'
local etcd_ttl = 10									--etcd的TTL

local function __init__()
    Skynet.dispatch("lua", function(session, address, cmd, ...)
        local f = assert(Command[cmd], cmd)
        f(...)
    end)
    Skynet.register "etcd"

    --注册
    local hosts = {"127.0.0.1:2379",}
    Env.etcd_client = EtcdClient.new(hosts, root)

    local grant = Env.etcd_client:grant(etcd_ttl, 0)
    local grant_id = grant.ID

    local node_data = {
		cid = serverid,
        login_port = login_port,
	}
    local attr = {
        lease = grant_id
    }
	Env.etcd_client:set(prefix..serverid, node_data, attr)

    --续约
    local time_interval = etcd_ttl/2-1
    Env.timers = TimerObj.new(time_interval)
    Env.timers:add_timer(time_interval, function()
        Env.etcd_client:keepalive(grant_id)
    end)
    Env.timers:start()

    --监听
    Skynet.fork(function ()
        local version
        local function reset_watch()
            local opts = {
                start_revision = version
            }
            local reader, stream = Env.etcd_client:watchdir(prefix, opts)
            if not reader then
                return false
            end
            while true do
                local data = reader()
                if data.error then
                    break
                else
                    util.Table.print(data or {})
                    version = data.result.header.revision + 1
                end
            end
            --连接异常
            Env.etcd_client:watchcancel(stream)
        end

        while true do
            reset_watch()
            Skynet.sleep(500)
        end
    end)
end

Skynet.start(__init__)