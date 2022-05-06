local Skynet = require "skynet"
local Sys = require "sys"
require "skynet.manager"

math.randomseed(math.floor(Skynet.time()))


--注册c服务的函数处理
Skynet.register_protocol {
    name = "text",
    id = Skynet.PTYPE_TEXT,
    pack = function (...)
        local n = select ("#" , ...)
        if n == 0 then
            return ""
        elseif n == 1 then
            return tostring(...)
        else
            return table.concat({...}," ")
        end
    end,
    unpack = Skynet.tostring
}

Sys.REG(Skynet)

return Skynet