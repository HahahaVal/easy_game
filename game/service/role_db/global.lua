local Sharenv = require("sharenv")

local GLOBAL = Sharenv.init()

GLOBAL.role_db = nil
GLOBAL.roles = {}

return Sharenv.fini(GLOBAL)