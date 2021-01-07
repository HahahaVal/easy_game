local Sharenv = require "sharenv"
local Global = Sharenv.init()

Global.gate = nil
Global.agent_pool = nil
Global.timers = nil

return Sharenv.fini(Global)
