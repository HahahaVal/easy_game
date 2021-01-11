local Skynet = require "skynet"
local Env    = require "global"

local M = {}

local function get_cache(uid, roleid)
    local key = string.format('%d_%d', uid, roleid)
    local role = Env.roles[key]
    if role then
        return role
    end

    local data = Env.role_db:findOne({uid=uid, roleid=roleid}, {_id=false})

    --double check
    role = Env.roles[key]
    if role then
        return role
    elseif not data then
        return nil
    else
        Env.roles[key] = data
        return Env.roles[key]
    end
end

local function update_cache(role)
    if not role then
        return
    end
    Env.roles[key] = role
end

function M.get(uid, roleid)
    assert(uid, "uid is nil")
    local role = get_cache(uid, roleid)
    Skynet.retpack(role)
end

function M.add(obj)
    local ok, err = Env.role_db:ack_insert(obj)
    if not ok then
        print("roleid create role failed: ", obj.roleid, err)
        return Skynet.retpack(false)
    end
    return Skynet.retpack(true)
end

local function save_data(uid, data)
    if not data then
        return
    end
    local roleid = data.roleid
    local ok, err = Env.role_db:ack_update({roleid=roleid}, data)
    if not ok then
        print("update roleid failed: ", roleid, err)
        return
    end
    print("save uid", uid)
end

function M.update(uid, role)
    assert(uid, "uid is nil")
    assert(role, "role is nil")

    local cache = get_cache(uid, role.roleid)
    if not cache then
        print("no role:", uid)
        return Skynet.retpack(false)
    end

    update_cache(role)
    save_data(uid, role)
    return Skynet.retpack(true)
end

return M
