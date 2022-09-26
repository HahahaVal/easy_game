local Env = require "global"
local Date = require "date"

local function _log_time(date)
	return string.format("%02d:%02d:%02d.%02d", date.hour, date.min, date.sec, 
		math.floor(Date.time()*100%100))
end

local M = {}

function M.logging(source, type, str)
	local date = os.date("*t")
	str = string.format("[:%08x][%s][%s]%s", source, type, _log_time(date), str)
	Env.file:write(str .. '\n')
	Env.file:flush()
	print(str)
end

return M