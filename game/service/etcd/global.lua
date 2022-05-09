local Sharenv = require("sharenv")

local GLOBAL = Sharenv.init()

GLOBAL.nodes = nil
GLOBAL.etcd_client = nil
GLOBAL.timers = nil

return Sharenv.fini(GLOBAL)