local RpcService = require "rpcservice"

local mt = {}
mt.__index = mt


function mt:init()
    local cator = {
        uid = self.uid,
        roleid = self.roleid,
    }
    local ret = self:call("login.login_game", {cator=cator})
    if ret.errcode ~= 0 then
        print("login_game fail")
        return false
    end
    if ret.roleid == 0 then
        ret = self:call("login.create_role", {name="guojin"})
        if ret.errcode ~= 0 then
            print("create_role fail")
            return false
        end
        self.roleid = assert(ret.roleid)
    else
        self.roleid = ret.roleid
    end

    local resp = self:call("login.enter_game", {})
    if resp.errcode ~= 0 then
        print("enter_game fail")
        return false
    end
    print("robot enter game success")
    return true
end

function mt:call(typename, params, expire_sec)
    expire_sec = expire_sec or 1
    local ret = self.service:call(typename, params, expire_sec)
    return ret
end

function mt:send(typename, params)
    self.service:send(typename, params)
end


local function test(testfunc)
    local fails = 0
    for _, f in ipairs(testfunc) do
        local ret, error_info = xpcall(f, debug.traceback)
        if not ret then
            fails = fails + 1
            print("error:",error_info)
        end
    end
    print("test fail :", fails)
end

function mt:run_script(script)
    if not script then
        return
    end
    local env = setmetatable(
        {
            player = self,
            test = test,
        },
        {__index = _ENV}
    )
    local func = loadfile(script, "bt", env)
    assert(func, script)
    func()
end

function mt:start()
    if self:init() then
        local ok, errmsg = xpcall(self.run_script, debug.traceback, self, self.script)
        if not ok then
            print("error :", errmsg)
        end
    end
end

function mt:destroy()
    self:leave_game()
end

function mt:stop()
    self:destroy()
    self.service:exit()
end

local M = {}
function M.new(host, port, uid, roleid, script)
    local obj = {}
    obj.host = host
    obj.port = port
    obj.uid = uid
    obj.roleid = roleid
    obj.script = script

    obj.service = RpcService.new(host, port, obj)
    setmetatable(obj, mt)
    obj:start()
    return obj
end
return M
