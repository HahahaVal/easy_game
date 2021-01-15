local Skynet = require "znet"
local Env = require "global"
local Command = require "command"
local MongoEx = require "mongo_ex"
local LruCache = require "lru_cache"


local function __init__()
    Skynet.dispatch("lua", function(session, address, cmd, ...)
        local f = assert(Command[cmd], cmd)
        f(...)
    end)

    Env.role_db = MongoEx.get_game_collection("role")
    Env.roles = LruCache.new(300, 60)
    Skynet.register "role_db"
end

Skynet.start(__init__)