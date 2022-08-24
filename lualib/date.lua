local Skynet = require "znet"
local Time = require "time"

local M = {}

local SECONDS_HOUR = 3600
local SECONDS_DAY = 24 * SECONDS_HOUR
local SECONDS_WEEK = 7 * SECONDS_DAY
local TZ = Skynet.getenv("TZ") or 8
local TD = TZ * SECONDS_HOUR


function M.in_same_day(t1, t2)
    return (t1+TD)//SECONDS_DAY == (t2+TD)//SECONDS_DAY
end

--指定某个小时作为一天的分界线
function M.in_logical_day(t1, t2, hour)
    return M.in_same_day(t1-hour*SECONDS_HOUR, t2-hour*SECONDS_HOUR)
end

local ORIGIN_TIMESTAMP = 1640966400     --2022-01-01 00:00:00
function M.in_same_week(t1, t2)
    local week1 = math.floor((t1 + TD - ORIGIN_TIMESTAMP) / SECONDS_WEEK)
    local week2 = math.floor((t2 + TD - ORIGIN_TIMESTAMP) / SECONDS_WEEK)
    return week1 == week2
end

--指定某天和某个小时作为一周的分界线
function M.in_logical_week(t1, t2, wday, hour)
    assert(wday and wday >= 1 and wday <= 7, "wday invalid")
    assert(hour and hour >= 0 and hour <= 24, "hour invalid")
    local tw = SECONDS_DAY * (wday - 1)
    return M.in_same_week(t1-hour*SECONDS_HOUR-tw, t2-hour*SECONDS_HOUR-tw)
end

--指定时间的当天零点
function M.get_day_begin_time(time)
    local d = Time.localdate(time)
    return Time.utctime({day=d.day, month=d.month, year=d.year, hour=nil})
end

return M