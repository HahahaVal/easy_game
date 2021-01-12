local Skynet = require "skynet"
local Env    = require "global"
local Log = require "log_api"

local M = {}

function M.register(address, catalog)
    if Env.is_shutdown then
        return Skynet.retpack(false)
    end
    if Env.addr_catalog[address] then
        return Skynet.retpack(false)
    end
    Env.addr_catalog[address] = catalog
    table.insert(Env.addr_list, address)
    return Skynet.retpack(true)
end

function M.unregister(address)
    local catalog = Env.addr_catalog[address]
    if not catalog then
        return
    end

    Env.addr_catalog[address] = nil
    for i=#Env.addr_list, 1, -1 do
        if Env.addr_list[i] == address then
            table.remove(Env.addr_list, i)
        end
    end
end

function M.start_info(ok, errmsg)
    local file_path = assert(Skynet.getenv("start_msg"))
    local file = io.open(file_path, "w+")
    assert(file)
    local msg = ok and "_start_ok_" or errmsg
    file:write(os.date(), " ", msg, "\n")
    file:flush()
    return Skynet.retpack(true)
end

-- 先注册的服务后关闭
function M.shutdown()
    Log.info("system begin shutdown")
    Env.is_shutdown = true

    for i=#Env.addr_list, 1, -1 do
        local address = Env.addr_list[i]
        Log.info("shutdown service, catalog:%s,address:%s ", Env.addr_catalog[address], address)
        Skynet.send(address, "sys", "EXIT")
    end
    local waitcount = 0
    while true do
        if #Env.addr_list > 0 then
            if waitcount <= 0 then
                Log.info("waiting all service exit left:%s", #Env.addr_list)                
                waitcount = 100
            end            
            waitcount = waitcount - 1
            Skynet.sleep(1)
        else
            break
        end
    end

    Skynet.abort()
end

return M
