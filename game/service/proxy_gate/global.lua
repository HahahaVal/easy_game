local Sharenv = require "sharenv"
local Global = Sharenv.init()

Global.gate = nil

return Sharenv.fini(Global)
