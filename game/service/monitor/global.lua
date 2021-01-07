local Sharenv = require("sharenv")

local GLOBAL = Sharenv.init()

GLOBAL.is_shutdown = false
GLOBAL.addr_list = {}
GLOBAL.addr_catalog = {} 

return Sharenv.fini(GLOBAL)