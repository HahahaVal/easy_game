local Log = require "log_api"
local Coroutine = require "skynet.coroutine"
local coroutine_resume = Coroutine.resume
local coroutine_yield = Coroutine.yield
local coroutine_create = Coroutine.create

local BT_INVALID = "BT_INVALID"
local BT_SUCCESS = "BT_SUCCESS"
local BT_FAILURE = "BT_FAILURE"
local BT_RUNNING = "BT_RUNNING"
local DEX_BT_STOP = "DEX_BT_STOP"

local CHECK_RET = {
	[BT_INVALID] = true,
	[BT_SUCCESS] = true,
	[BT_FAILURE] = true,
	[BT_RUNNING] = true,
	[DEX_BT_STOP] = true,
}

local OPER_TYPE = {
	["Equal"] = function(lhs, rhs)
		return lhs==rhs and BT_SUCCESS or BT_FAILURE
	end,
	["NotEqual"] = function(lhs, rhs)
		return lhs~=rhs and BT_SUCCESS or BT_FAILURE
	end,
	["Greater"] = function(lhs, rhs)
		return lhs>rhs and BT_SUCCESS or BT_FAILURE
	end,
	["GreaterEqual"] = function(lhs, rhs)
		return lhs>=rhs and BT_SUCCESS or BT_FAILURE
	end,
	["Less"] = function(lhs, rhs)
		return lhs<rhs and BT_SUCCESS or BT_FAILURE
	end,
	["LessEqual"] = function(lhs, rhs)
		return lhs<=rhs and BT_SUCCESS or BT_FAILURE
	end,
}

local function run_func(funcName, ai_obj, entity, params)
	return ai_obj[funcName](ai_obj, entity, params)
end

local function op_ret_handler(ai_obj, entity, op_config)
	--1：值 2：带参函数 3：无参函数
	local op_type = op_config.type
	if op_type == 1 then
		return op_config.value
	elseif op_type == 2 then
		return run_func(op_config.value, ai_obj, entity, op_config.params)
	else
		return ai_obj[op_config.value]
	end
end

local function bt_yield(...)
	local signal = coroutine_yield(BT_RUNNING, ...)
	if signal == "EXIT" then
		error(DEX_BT_STOP)
	end
end

local _cor_cache = setmetatable({},{__mode="k"})

local function create_cor(func)
	local co = next(_cor_cache)
	if co then
		_cor_cache[co] = nil
		return co
	end
	co = coroutine_create(function(ai_obj, entity, bt_config)
		xpcall(func, debug.traceback, ai_obj, entity, bt_config)
		while true do
			_cor_cache[co] = true
			ai_obj, entity, bt_config = coroutine_yield()
			xpcall(func, debug.traceback, ai_obj, entity, bt_config)
		end
	end)
	return co
end

--前置节点处理
local function iter_precondition(ai_obj, entity, c_preconditions)
	local binary_op = true
	local ret
	for i, c_precondition in ipairs(c_preconditions) do
		local oper_func = OPER_TYPE[c_precondition.Operator]
		local op1_ret = op_ret_handler(ai_obj, entity, c_precondition.Opl)
		local op2_ret = op_ret_handler(ai_obj, entity, c_precondition.Opr2)
		if oper_func(op1_ret, op2_ret) == BT_SUCCESS then
			ret = true
		else
			ret = false
		end
		--第一个节点的BinaryOperator必然是And
		if c_precondition.BinaryOperator == "And" then
			binary_op = ret and binary_op
		else
			binary_op = ret or binary_op
		end
	end
	return binary_op
end

local NODE_TYPE = {}
local function iter_node(ai_obj, entity, node_config)
	local type = node_config.type
	local node_func = NODE_TYPE[type]

	if not node_func then
		Log.error("iter_node", type, "is not support")
		return BT_FAILURE
	end

	local cal_ret, bt_status = xpcall(node_func, debug.traceback, ai_obj, entity, node_config)
	if not cal_ret then
		bt_status = BT_FAILURE
	end
	return bt_status
end

--效果处理节点。
local function iter_effector(ai_obj, entity, c_effectors, bt_status)
	local ret = (bt_status == "BT_SUCCESS")
	for i, c_effector in ipairs(c_effectors) do
		local phase = c_effector.Phase
		if ( phase == "Success" and ret) or (phase == "Failure" and not ret) or (phase == "Both") then
			op_ret_handler(ai_obj, entity, c_effector.Opl)
		end
	end
end

local function iter_bt_node(ai_obj, entity, node_config)
	local c_preconditions = node_config.preconditionList
	if c_preconditions then
		if not iter_precondition(ai_obj, entity, c_preconditions) then
			return BT_FAILURE
		end
	end

	local bt_status = iter_node(ai_obj, entity, node_config)

	local c_effectors = node_config.effectorList
	if c_effectors then
		iter_effector(ai_obj, entity, c_effectors, bt_status)
	end

	return bt_status
end

local function Sequence(ai_obj, entity, node_config)
	local bt_status
	for i, child_node_config in ipairs(node_config.nodeList) do
		repeat
			bt_status = iter_node(ai_obj, entity, child_node_config)
			if bt_status == BT_SUCCESS then
				break
			elseif bt_status == BT_FAILURE then
				return BT_FAILURE
			end
			bt_yield()
		until bt_status ~= BT_RUNNING
	end
	return BT_SUCCESS
end

local function Selector(ai_obj, entity, node_config)
	local bt_status
	for i, child_node_config in ipairs(node_config.nodeList) do
		repeat
			bt_status = iter_node(ai_obj, entity, child_node_config)
			if bt_status == BT_SUCCESS then
				return BT_SUCCESS
			elseif bt_status == BT_FAILURE then
				break
			end
			bt_yield()
		until bt_status ~= BT_RUNNING
	end
	return BT_FAILURE
end

local function Condition(ai_obj, entity, node_config)
	local oper_func = OPER_TYPE[node_config.Operator]
	return oper_func(
		op_ret_handler(ai_obj, entity, node_config.Opl),
		op_ret_handler(ai_obj, entity, node_config.Opr)
	)
end

local function Action(ai_obj, entity, node_config)
	local bt_status = run_func(node_config.Method, ai_obj, entity, node_config.params)
	local resultOption = node_config.ResultOption

	if resultOption == BT_INVALID then
		return bt_status
	end
	return resultOption
end

local function parallel_child_node(ai_obj, entity, node_config)
	local bt_status
	repeat
		bt_status = iter_node(ai_obj, entity, node_config)
		if bt_status == BT_RUNNING then
			bt_yield()
		end
	until bt_status ~= BT_RUNNING
	return bt_status
end

local function Parallel(ai_obj, entity, node_config)
	local sawSuccess = false
	local sawFail = false
	local sawRunning = false
	local sawAllFails = false
	local sawAllSuccess = false

	local bt_status
	for i, childNodeConfig in ipairs(node_config.nodeList) do
		local cor = ai_obj:get_node_cor(i)
		if not cor then
			cor = create_cor(parallel_child_node)
		end
		local corState, ret = coroutine_resume(cor, ai_obj, entity, childNodeConfig)

		if ret == BT_FAILURE then
			sawFail = true
            sawAllSuccess = false
			ai_obj:reset_node_cor(i)
		elseif ret == BT_SUCCESS then
			sawSuccess = true
			sawAllFails = false
			ai_obj:reset_node_cor(i)
		elseif ret == BT_RUNNING then
			sawRunning = true;
            sawAllFails = false;
            sawAllSuccess = false;
			ai_obj:set_node_cor(i, cor)
		end
	end

	bt_status = sawRunning and BT_RUNNING or BT_FAILURE

	local failurePolicy = node_config.FailurePolicy
	local successPolicy = node_config.SuccessPolicy
	if ( failurePolicy == "FAIL_ON_ALL" and sawAllFails) or (failurePolicy == "FAIL_ON_ONE" and sawFail) then
		bt_status = BT_FAILURE
	elseif (successPolicy == "SUCCEED_ON_ALL" and sawAllSuccess) or (successPolicy == "SUCCEED_ON_ONE" and sawSuccess) then
		bt_status = BT_SUCCESS
	end

	return bt_status
end

local function False()
	return BT_FAILURE
end

local function True()
	return BT_SUCCESS
end

local function Or(ai_obj, entity, node_config)
	local nodeList = node_config.nodeList
	local ret1 = iter_node(ai_obj, entity, nodeList[1])
	local ret2 = iter_node(ai_obj, entity, nodeList[2])
	if ret1 or ret2 then
		return BT_SUCCESS
	end
	return BT_FAILURE
end

local function And(ai_obj, entity, node_config)
	local node_list = node_config.nodeList
	local ret1 = iter_node(ai_obj, entity, node_list[1])
	local ret2 = iter_node(ai_obj, entity, node_list[2])
	if ret1 and ret2 then
		return BT_SUCCESS
	end
	return BT_FAILURE
end

local function IfElse(ai_obj, entity, node_config)
	local node_list = node_config.nodeList
	local b_ret = iter_node(ai_obj, entity, node_list[1])
	if b_ret then
		return iter_node(ai_obj, entity, node_list[2])
	else
		return iter_node(ai_obj, entity, node_list[3])
	end
end

local function DecoratorLoop(ai_obj, entity, node_config)
	--Count小于1表示无限循环
	local count = node_config.Count
	local maxCountPreframe = 100
	local inOneFrame = node_config.DoneWithinFrame
	local loopNode = node_config.nodeList[1]
	local bt_status
	repeat
		maxCountPreframe = maxCountPreframe - 1
		if maxCountPreframe <= 0 then
			bt_yield()--限制最大只会执行100次每次
			maxCountPreframe = 100
		end
		--循环只会有一个子节点。
		bt_status = iter_node(ai_obj, entity, loopNode)
		if bt_status == BT_FAILURE then
			return bt_status
		end
		if not inOneFrame then
			bt_yield()
		end
		count = count - 1
	until count == 0
	return BT_SUCCESS
end

local function End(ai_obj, entity, node_config)
	error(DEX_BT_STOP)
end

NODE_TYPE = {
	["Sequence"] = Sequence,
	["Selector"] = Selector,
	["Condition"] = Condition,
	["Action"] = Action,
	["False"] = False,
	["True"] = True,
	["Or"] = Or,
	["And"] = And,
	["Parallel"] = Parallel,
	["IfElse"] = IfElse,
	["DecoratorLoop"] = DecoratorLoop,
	["End"] = End
}

-----------------------------------------------------mt----------------------------------------------

local mt = {}
mt.__index = mt

local function _run_ai(ai_obj, entity, bt_config)
	return iter_bt_node(ai_obj, entity, bt_config[1])
end

function mt:set_node_cor(node_index, core)
	self.node_cor[node_index] = core
end

function mt:reset_node_cor(node_index)
	self.node_cor[node_index] = false
end

function mt:get_node_cor(node_index)
	return self.node_cor[node_index]
end

--每帧反复调用
function mt:run_ai()
	local cor = self.cor
	if not cor then
		cor = create_cor(_run_ai)
	end
	local _, ret = coroutine_resume(cor, self, self.entity, self.bt_config)

	if ret then
		if ret == BT_RUNNING then
			self.cor = cor
		else
			self.cor = false
		end
		if not CHECK_RET[ret] then
			Log.error("run_ai return a wrong ret type, ret:",ret)
		end
	else
		self.cor = false
	end
end

--停止行为树
function mt:stop_ai()
	if self.cor then
		coroutine_resume(self.cor, "EXIT")
		self.cor = nil
	end
end

local M = {}
function M.new(entity, bt_config)
	local obj = {
		entity = entity,
		bt_config = bt_config,
		cor = false, --用于记录上一帧ai操作的协程
		node_cor = {},	--记录并行挂起的节点协程
	}
    setmetatable(obj, mt)
    return obj
end
return M