local M = {}

local mt = {}
mt.__index = mt

local floor = math.floor

local function min_priority(a, b)
    return a < b
end

function mt:_get_priority_func()
    if self.priority_func then
        return self.priority_func
    end
    return min_priority
end

function mt:_swap(from, to)
    local index2priority = self.index2priority
    index2priority[from], index2priority[to] = index2priority[to], index2priority[from]

    local index2obj = self.index2obj
    index2obj[from], index2obj[to] = index2obj[to], index2obj[from]

    local obj2index = self.obj2index
    obj2index[index2obj[from]], obj2index[index2obj[to]] = from, to
end

function mt:_swim(index)
    local priority_func = self:_get_priority_func()
    local index2priority = self.index2priority
    local parent = floor(index/2)

    while index > 1 and priority_func(index2priority[index], index2priority[parent]) do
        self:_swap(index, parent)
        index = parent
        parent = floor(index/2)
    end

    return index
end

function mt:_sink(index)
    local priority_func = self:_get_priority_func()
    local index2priority = self.index2priority
    local size = self.size
    local left = index * 2
    local right = left + 1

    while left <= size do
        local smaller = left
        if right <= size and priority_func(index2priority[right], index2priority[left]) then
            smaller = right
        end
        if priority_func(index2priority[smaller], index2priority[index]) then
            self:_swap(index, smaller)
        else
            break
        end
        index = smaller
        left = index * 2
        right = left + 1
    end
end

function mt:enqueue(obj, priority)
    if self.obj2index[obj] then
        error("obj already in the queue")
    end

    local size = self.size + 1
	self.size = size

    self.index2priority[size] = priority

    self.index2obj[size] = obj
    self.obj2index[obj] = size

    self:_swim(size)
end

function mt:remove(obj)
    local size = self.size
    local index2priority = self.index2priority
    local index2obj = self.index2obj
    local obj2index = self.obj2index

    local index = obj2index[obj]
    if not index then
        return false
    end

    if size == index then
        index2priority[index] = nil
        index2obj[index] = nil
        obj2index[obj] = nil
        self.size = size - 1
    else
        self:_swap(index, size)

        index2priority[size] = nil
        index2obj[size] = nil
        obj2index[obj] = nil
        self.size = size - 1
        if self.size > 1 then
            self:_sink(index)
        end
    end
    return true
end

function mt:update(obj, priority)
	local ret = self:remove(obj)
    if not ret then
        return false
    end

	self:enqueue(obj, priority)
	return true
end

function mt:dequeue()
	local size = self.size
    if size <= 0 then
        return false
    end

	local obj = self.index2obj[1]
	self:remove(obj)
	return obj
end

function mt:peek()
	return self.index2obj[1], self.index2priority[1]
end

function mt:empty()
	return self.size <= 0
end

function M.new(priority_func)
    local obj = {
        priority_func = priority_func,
        index2priority = {},
        index2obj = {},
        obj2index = {},
        size = 0,
    }
    return setmetatable(obj, mt)
end

return M