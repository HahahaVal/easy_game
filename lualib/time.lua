local Skynet = require "znet"

local TZ = Skynet.getenv("TZ") or 8
local secondsPerMinute = 60
local secondsPerHour   = 60 * 60
local secondsPerDay    = 24 * secondsPerHour
local secondsPerWeek   = 7 * secondsPerDay
local daysPer400Years  = 365*400 + 97
local daysPer100Years  = 365*100 + 24
local daysPer4Years    = 365*4 + 1

--把 unix 时间转化为内部的绝对时间，即计算从公元元年到 unix 起始时间所经历的秒数
local unixBase = (1969*365 + 1969//4 - 1969//100 + 1969//400) * secondsPerDay

local daysBefore = {
    0,
    31,
    31 + 28,
    31 + 28 + 31,
    31 + 28 + 31 + 30,
    31 + 28 + 31 + 30 + 31,
    31 + 28 + 31 + 30 + 31 + 30,
    31 + 28 + 31 + 30 + 31 + 30 + 31,
    31 + 28 + 31 + 30 + 31 + 30 + 31 + 31,
    31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30,
    31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31,
    31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31 + 30,
    31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31 + 30 + 31,
}

local January   = 1
local February  = 2
local March     = 3
local April     = 4
local May       = 5
local June      = 6
local July      = 7
local August    = 8
local September = 9
local October   = 10
local November  = 11
local December  = 12

local function absTimestamp(ts)
    return ts + unixBase
end

local function isLeap(year)
    return year%4 == 0 and (year%100 ~= 0 or year%400 == 0)
end

local function absWeekday(abs)
    -- January 1 of the absolute year, like January 1 of 2001, was a Monday.
    local sec = (abs+1*secondsPerDay) % secondsPerWeek
    return (sec // secondsPerDay) + 1
end

-- convert timestamp to year, month, day, yday
local function absDate(abs)
    local day = abs // secondsPerDay

    local n, y
    -- Account for 400 year cycles.
    n = day // daysPer400Years
    y = 400 * n
    day = day - daysPer400Years * n

    -- Cut off 100-year cycles.
    -- The last cycle has one extra leap year, so on the last day
    -- of that year, day / daysPer100Years will be 4 instead of 3.
    -- Cut it back down to 3 by subtracting n>>2.
    n = day // daysPer100Years
    n = n - (n >> 2)
    y = y + 100 *n
    day = day - daysPer100Years * n

    -- Cut off 4-year cycles.
    -- The last cycle has a missing leap year, which does not
    -- affect the computation.
    n = day // daysPer4Years
    y = y + 4 * n
    day = day - daysPer4Years * n

    -- Cut off years within a 4-year cycle.
    -- The last year is a leap year, so on the last day of that year,
    -- day / 365 will be 4 instead of 3. Cut it back down to 3
    -- by subtracting n>>2.
    n = day // 365
    n = n - (n >> 2)
    y = y + n
    day = day - 365 * n

    local year = y + 1
    local yday = day + 1

    if isLeap(year) then
        -- Leap year
        if day > 31+29-1 then
            -- After leap day; pretend it wasn't there.
            day = day - 1
        elseif day == 31+29-1 then
            return year, February, 29, yday
        end
    end

    -- Estimate month on assumption that every month has 31 days.
    -- The estimate may be too low by at most one month, so adjust.
    local month = (day // 31) + 1
    local monthDayEnd = daysBefore[month + 1]
    local monthDayBegin

    if day >= monthDayEnd then
        month = month + 1
        monthDayBegin = monthDayEnd
    else
        monthDayBegin = daysBefore[month]
    end

    day = day - monthDayBegin + 1
    return year, month, day, yday
end

local function absDayFromDate(t)
    local y = assert(t.year, "year") - 1
    local day = y*365 + y//4 - y//100 + y//400

    if t.yday then
        day = day + t.yday - 1
    else
        local m = assert(t.month, "month")
        local d = assert(t.day, "day")

        day = day + daysBefore[m]
        if isLeap(t.year) and m >= March then
            -- February 29
            day = day + 1
        end

        -- Add in days before today.
        day = day + d - 1
    end
    return day
end

local M = {}

-- table格式转成时间戳
function M.time(t)
    local day = absDayFromDate(t)
    local timestamp = day * secondsPerDay
    if t.hour then
        timestamp = timestamp + t.hour * secondsPerHour + t.min * secondsPerMinute + t.sec
    end
    return timestamp - unixBase
end

-- 指定时区的table格式转成时间戳
function M.utctime(t)
    return M.time(t) - TZ * secondsPerHour
end

-- 时间戳转换成table格式
function M.date(sec)
    assert(sec)
    local abs = absTimestamp(sec)
    local t = {}
    t.year, t.month, t.day, t.yday = absDate(abs)
    t.wday = absWeekday(abs)

    local seconds = abs % secondsPerDay
    t.hour = seconds // secondsPerHour
    seconds = seconds - (t.hour * secondsPerHour)
    t.min = seconds // secondsPerMinute
    t.sec = seconds - (t.min * secondsPerMinute)
    return t
end

-- 指定时区的时间戳转换成table格式
function M.localdate(sec)
    return M.date(sec + TZ * secondsPerHour)
end

return M