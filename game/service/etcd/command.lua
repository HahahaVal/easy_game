local Env    = require "global"

local M = {}

function M.get_node(cid)
    return Env.nodes[cid]
end

return M
