local Skynet = require "znet"
local Node = require "lualib.agent_node"
local mt = {}
mt.__index = mt

function mt:_choose_node()
    assert(#self.nodes > 0, "no Available node")
    local apt_node = self.nodes[1]
    for i=1, #self.nodes, 1 do
        local node = self.nodes[i]
        if apt_node:get_count() > node:get_count() then
            apt_node = node
        end
    end
    assert(apt_node, "choose node failed")
    return apt_node
end

function mt:get(key)
    assert(not self.key_node[key], "get node failed, key duplicated:".. key)
    local node = self:_choose_node()
    node:apply()
    self.key_node[key] = node
    return node:get_addr()
end

function mt:put(key)
    local node = assert(self.key_node[key], "put node failed, key not found:"..key)
    node:freed()
    self.key_node[key] = nil
end


function mt:_retire_node(i)
    table.insert(self.retired_nodes, self.nodes[i])
    local node = Node.new()
    node:init()
    self.nodes[i] = node
end

function mt:reset_nodes()
    for i=1, self.count do
        self:_retire_node(i)
    end
end

function mt:check_retire_nodes()
    for i in ipairs(self.nodes) do
        local node = self.nodes[i]
        if node:get_work_times() >= self.threshold then
            self:_retire_node(i)
        end
    end
end

function mt:del_nodes()
    for i=#self.retired_nodes, 1, -1 do
        local node = self.retired_nodes[i]
        if node:get_count() == 0 then
            node:fini()
            table.remove(self.retired_nodes, i)
        end
    end
end

function mt:update()
    self:check_retire_nodes()
    self:del_nodes()
end

local M = {}

function M.new(count, threshold)
    local obj = {
        nodes = {},
        retired_nodes = {},
        key_node = {},
        threshold = threshold,
        count = count,
    }
    return setmetatable(obj, mt)
end

return M