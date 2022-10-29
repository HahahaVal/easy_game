local M = {}
local command = {}

local Skynet = nil

function command.EXIT()
    local cb = M.get_exit_cb()
    if cb then
        cb()
    end
    Skynet.exit()
end

function M.atexit(func)
    M.exit_cb = func
end

function M.get_exit_cb()
    return M.exit_cb
end

function M.REG(_Skynet)
    Skynet = _Skynet
	Skynet.register_protocol {
        name = 'sys',
        id = 13,
        unpack = Skynet.unpack,
        pack = Skynet.pack,
        dispatch = function(session, address, cmd, ...)
            local f = assert(command[cmd], cmd)
            f(...)
        end,
    }
end

return M