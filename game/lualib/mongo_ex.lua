local Skynet = require "znet"
local MongoObj = require "mongo_obj"

local function get_db(name)
    local serverid = assert(Skynet.getenv("serverid"))
    local realname = string.format("%s_%s", name, serverid)
    return MongoObj.new(realname)
end

local M = {}
function M.get_game_db()
    return get_db("game")
end

function M.get_game_collection(name)
    return M.get_game_db():get_collection(name)
end

return M
