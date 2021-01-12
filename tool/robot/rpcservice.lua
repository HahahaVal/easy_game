local SprotoLoader = require "sprotoloader"
local Socket = require "levent.socket"
local Levent = require "levent.levent"
local Queue = require "levent.queue"

local file =  "../../build/sproto/sproto.spb"
SprotoLoader.save(io.input(file):read("a"), 1)
local client_proto = SprotoLoader.load(1)
local client = client_proto:host "base.pack"
local client_request = client:attach(client_proto)

local MAX_PACKET_LEN = 0xffff

local mt = {}
mt.__index = mt



function mt:_read()
    local left = ""
    while true do
        data = self.sock:recv(2048)
        if not data or #data == 0 then
            self.running = false
            return
        end
        left = left .. data
        while true do
            if #left < 2 then
                break
            end

            data_len, _ = string.unpack(">H", left:sub(1, 2))
            if (data_len + 2) > #left then
                break
            end

            data = left:sub(3, data_len+2)
            left = left:sub(data_len+3)

            self.read_queue:put(data)
        end
    end
end

function mt:_write()
    while true do
        if not self.running then
            return
        end

        local ok, data = pcall(self.write_queue.get, self.write_queue, 5)
        if ok then
            self.sock:sendall(data)
        end
    end
end

function mt:_send_chunk(chunk)
    assert(#chunk <= MAX_PACKET_LEN, #chunk)
    local data = string.pack(">s2", chunk)
    self.write_queue:put(data)
end


function mt:send(type_name, param)
    local chunk = self.client_request(type_name, param, nil, os.time())
    self:_send_chunk(chunk)
end

function mt:next_session()
    if self.cur_session > 100000000 then
        self.cur_session = 1
    end
    local n = self.cur_session
    self.cur_session = self.cur_session + 1
    return n
end

function mt:call(type_name, param, expire_sec)
    local session = self:next_session()
    local chunk = self.client_request(type_name, param, session, os.time())

    self:_send_chunk(chunk)

    local pending = Queue.queue()
    self.sessions[session] = pending

    local ok, err = pcall(pending.get, pending, expire_sec)
    if ok then
        response = err
    else
        error("call timeout")
    end

    self.sessions[session] = nil
    return response
end

function mt:response_to_caller(name, response_cb, result)
    -- take care of send
    if not response_cb then
        return
    end
    local response = response_cb(result)

    self:_send_chunk(response)
end

function mt:_dispatch()
    while true do
        if not self.running then
            return
        end

        local ok, data = pcall(self.read_queue.get, self.read_queue, 5)
        if not ok then
            goto CONTINUE
        end

        local msg_type, name, request, response_cb = self.client:dispatch(data)

        if msg_type == "RESPONSE" then
            local session = name
            local result = request
            local pending = self.sessions[session]
            if pending then
                pending:put(result)
            end
        else
            -- request
            assert("msg_type is request")
        end

        ::CONTINUE::
    end
end

function mt:start()
    local sock, errcode = Socket.socket(Socket.AF_INET, Socket.SOCK_STREAM)
    assert(sock, errcode)
    self.sock = sock
    assert(self.sock:connect(self.host, self.port))

    Levent.spawn(self._read, self)
    Levent.spawn(self._write, self)
    Levent.spawn(self._dispatch, self)
end

function mt:exit()
    self.running = false
    self.sock:close()
    Levent.exit()
end

local M = {}
function M.new(host, port, ud)
    local obj = {
        host = host,
        port = port,
        write_queue = Queue.queue(),
        read_queue = Queue.queue(),
        sessions = {},
        cur_session = 1,
        sock = nil,
        ud = ud,
        running = true,

        time_diff = 0,
        cbs = {},
    }

    obj.client = client
    obj.client_request = client_request

    setmetatable(obj, mt)
    obj:start()
    return obj
end

return M