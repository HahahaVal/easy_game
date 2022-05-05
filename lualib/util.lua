local srep = string.rep
local tconcat = table.concat
local tinsert = table.insert

local util = {
    Table = {},
}

local function _repr(T,CR)
    assert(type(T) == "table")

	CR = CR or '\r\n'
	local cache = {  [T] = "." }
	local function _dump(t,space,name)
		local temp = {}
		for k,v in next,t do
			local key = tostring(k)
			if cache[v] then
				tinsert(temp,"+" .. key .. " {" .. cache[v].."}")
			elseif type(v) == "table" then
				local new_key = name .. "." .. key
				cache[v] = new_key
				tinsert(temp,"+" .. key .. _dump(v,space .. (next(t,k) and "|" or " " ).. srep(" ",#key),new_key))
			else
				tinsert(temp,"+" .. key .. " [" .. tostring(v).."]")
			end
		end
		return tconcat(temp,CR..space)
	end

    return _dump(T, "","")
end

function util.Table.repr(T, CR)
    return _repr(T, CR)
end

function util.Table.print(T, CR)
	print(_repr(T, CR))
end

return util