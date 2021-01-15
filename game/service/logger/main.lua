local Skynet = require "znet"
local Env = require "global"
local Command = require "command"

local log_path  = Skynet.getenv("log_path")

local function _file_path(date)
	return string.format("%s%04d-%02d-%02d-%02d.log", log_path, date.year, date.month, date.day, date.hour)
end

local function _open_file(date)
	local f, e = io.open(_file_path(date), "w+")
	if not f then
		print("logger error:", tostring(e))
		return
	end
	return f
end

local function __init__()
    Skynet.dispatch("lua", function(session, source, cmd, ...)
		local f = assert(Command[cmd], cmd .. " not found")
		f(source, ...)
	end)

	os.execute("mkdir -p ".. log_path)
	local date = os.date("*t")
	Env.file = _open_file(date)

    Skynet.register("logger")
end


Skynet.start(__init__)