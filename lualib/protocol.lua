local Skynet = require "znet"

local M = {}

M.PTYPE_GATE_NAME = "lua-gate"
M["lua-gate"] = {
    name = M.PTYPE_GATE_NAME,
    id = 29,
    pack = Skynet.pack,
    unpack = Skynet.unpack
}

return M
