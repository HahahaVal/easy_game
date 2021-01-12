local Env      = require "global"
local Errcode  = require "errcode"
local M = {}

function M.login_game(cator,  _addr)
    if not cator.uid or not cator.roleid then
        return {errcode = Errcode.FALSE}
    end
    local session = Env.sessions:get_session(_addr)
    if not session or session:get_user() then
        return {errcode = Errcode.FALSE}
    end
    local user = session:attach_user(cator.uid, cator.roleid)
    if not user then
        return {errcode = Errcode.FALSE}
    end

    local role = user:get_role()
    if not role then
        return {errcode = Errcode.SUCCESS, roleid = 0}
    else
        return {errcode = Errcode.SUCCESS, roleid = role.roleid}
    end
end

function M.create_role(name, _addr)
    local session = Env.sessions:get_session(_addr)
    if not session then
        return {errcode = Errcode.FALSE}
    end
    local user = session:get_user()
    if not user then
        return {errcode = Errcode.FALSE}
    end

    local roleid = user:create_role(name)
    if roleid then
        return {errcode = Errcode.SUCCESS, roleid = roleid}
    else
        return {errcode = Errcode.FALSE}
    end
end

function M.enter_game(_addr)
    local session = Env.sessions:get_session(_addr)
    if not session then
        return {errcode = Errcode.FALSE}
    end
    local user = session:get_user()
    if not user or not user:get_role() or user:get_agent() then
        return {errcode = Errcode.FALSE}
    end

    local ret = user:enter_game()
    if ret then
        return {errcode = Errcode.SUCCESS}
    else
        return {errcode = Errcode.FALSE}
    end
end

function M.leave_game(_addr)
    Connection.kick(_addr)
end


return M