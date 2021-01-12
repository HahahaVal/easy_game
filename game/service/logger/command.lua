local Skynet = require "znet"

local log_path  = Skynet.getenv("log_path")
os.execute("mkdir ".. log_path)

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

local function _log_time(date)
	return string.format("%02d:%02d:%02d.%02d", date.hour, date.min, date.sec, 
		math.floor(Skynet.time()*100%100))
end

local M = {}

function M.logging(source, type, str)
	local date = os.date("*t")
	str = string.format("[:%08x][%s][%s]%s", source, type, _log_time(date), str)

	local log_file = _open_file(date)
	log_file:write(str .. '\n')
	log_file:flush()
	
	print(str)
end

return M