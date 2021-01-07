local Sharenv = require "sharenv"
local Global = Sharenv.init()

Global.gate = nil
Global.conns = nil

return Sharenv.fini(Global)
