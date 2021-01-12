package.cpath = "../levent/?.so;" .. "../../build/clualib/?.so;" .. package.cpath
package.path  = "../levent/?.lua;" .. "../levent/?/init.lua;" .. "../../lualib/?.lua;" .. "../../skynet/lualib/?.lua;" .. package.path

local Levent = require "levent.levent"
local Conf = require "conf"
local Player = require "player"

local function main()
    Levent.spawn(Player.new, Conf.host, Conf.port, Conf.uid, Conf.roleid, Conf.script)
end

Levent.start(main)