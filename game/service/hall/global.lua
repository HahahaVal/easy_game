local Sharenv = require "sharenv"
local Global = Sharenv.init()

Global.gate = nil
Global.agent_pool = nil

Global.timers = nil
Global.sessions = nil
Global.users = nil
Global.allocator = nil

return Sharenv.fini(Global)
