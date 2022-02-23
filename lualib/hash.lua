local tinsert = table.insert
local tremove = table.remove
local tsort = table.sort

local mt = {}
mt.__index = mt

local FNV_32_INIT = 2166136261
local FNV_32_PRIME = 16777619
local Bit32 = 0xffffffff

--FNV32 HASH
local function _get_hash(str)
    local p = FNV_32_PRIME
    local hash = FNV_32_INIT & Bit32
    local str_len = string.len(str)
    for i=1, str_len, 1 do
        hash = ((hash ~ string.byte(str, i)) * p) & Bit32
    end
    hash = (hash + (hash << 13) & Bit32 ) & Bit32
    hash = (hash ~ (hash >> 7) & Bit32 ) & Bit32
    hash = (hash + (hash << 3) & Bit32 ) & Bit32
    hash = (hash ~ (hash >> 17) & Bit32) & Bit32
    hash = (hash + (hash << 5) & Bit32) & Bit32
    hash = math.abs(hash)
    return hash
end

function mt:init(servers)
    for _, server in ipairs(servers) do
        local hash = _get_hash(server)
        self.server_map[hash] = server
        tinsert(self.server_hash_list, hash)
    end
    tsort(self.server_hash_list)
end

function mt:add_server_node(server)
    local hash = _get_hash(server)
    self.server_map[hash] = server
    tinsert(self.server_hash_list, hash)
    tsort(self.server_hash_list)
end

function mt:del_server_node(server)
    local hash = _get_hash(server)
    self.server_map[hash] = nil

    local server_hash_list = self.server_hash_list
    for i=#server_hash_list, 1, -1 do
        if hash == server_hash_list[i] then
            tremove(server_hash_list, i)
            return
        end
    end
end

function mt:select_server_node(key)
    local server_hash = self.server_hash_list[1]
    local hash = _get_hash(key)
    for _, sh in ipairs(self.server_hash_list) do
        if sh >= hash then
            server_hash = sh
            break
        end
    end
    return self.server_map[server_hash]
end

local M = {}

function M.new()
    local obj = {
        server_map = {},        --加入hash环的服务器列表
        server_hash_list = {}   --服务器hash有序数组
    }
    return setmetatable(obj, mt)
end

return M