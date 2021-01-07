local Skynet = require "znet"

local M = {}

function M.launch(port, max_agent, tag)
    local gate = assert(
        Skynet.launch("gate", "S", Skynet.address(Skynet.self()), port, tag, max_agent), 
    "launch gate failed")
    return gate
end

function M.start(fd)
    Skynet.send(Env.gate, "text", "start", fd)
end

function M.close()
    Skynet.send(Env.gate, "text", "close")
end

function M.forward(fd, agent, client)
    Skynet.send(Env.gate, "text", "forward", fd, Skynet.address(agent), Skynet.address(client))
end

function M.kick(fd)
    Skynet.send(Env.gate, "text", "kick", fd)
end

return M

