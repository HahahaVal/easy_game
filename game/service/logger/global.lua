local Sharenv = require("sharenv")

local GLOBAL = Sharenv.init()
GLOBAL.file = nil

return Sharenv.fini(GLOBAL)