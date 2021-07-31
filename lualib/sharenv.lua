--[[
全局共享表遵循如下规则:
1. key值不得是数字
2. 初始化阶段必须初始化所有可能的key, 初始化完成后不得增加key
2. 首字母大写的key值只能访问不能修改 65-90
]]

local share_env = {}

function share_env.init()
    local t = {}    --t[0]为true表示已fini
    _keys = {}      --value为0表示不能修改
    _t = {}         --index只读表
    local mt = {
        __index = function(_,k)
            return _t[k]
        end,
        __newindex = function(t,k,v)
            assert(type(k) ~= "number")
            if rawget(t,0) then
                if _keys[k] ~= 1 then
                    error(string.format("key %s dont exist or cant modify", tostring(k)), 2)
                end

                rawset(t,k,v)
            else
                local c = string.byte(k)
                if c >= 65 and c <= 90 then
				    _keys[k] = 0
                    _t[k] = v
			    else
				    _keys[k] = 1
                    rawset(t,k,v)
                end
            end
        end,
    }
    setmetatable(t, mt)
    return t
end

function share_env.fini(t)
    rawset(t, 0, true)
    return t
end

return share_env

