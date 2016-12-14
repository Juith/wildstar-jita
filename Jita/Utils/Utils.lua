--[[
	Number of functional utilities mostly copied over the Internet.

	Attribution often given, although hardly anyone would care to check.
]]--

local Jita = Apollo.GetAddon("Jita")
local Utils = Jita.Utils

--

function Utils:EscapeHTML(str)
--/- (a) drafto_LuaUtils.lua

	local subst = {
		["&"] = "&amp;";
		['"'] = "&quot;";
		["'"] = "&apos;";
		["<"] = "&lt;";
		[">"] = "&gt;";
	}

	return tostring(str):gsub("[&\"'<>\n]", subst)
end

function Utils:Round(num, idp)
-- (a) http://lua-users.org/

	return tonumber(string.format("%." .. (idp or 0) .. "f", num))
end

function Utils:Trim(text)
-- (a) http://lua-users.org/

	if type(text) ~= 'string' then
		return ""
	end

	text = string.gsub(text, "^%s*(.-)%s*$", "%1")

	return text or ""
end

function Utils:LTrim(text)
-- (a) http://lua-users.org/

	if type(text) ~= 'string' then
		return ""
	end

	return (text:gsub("^%s*", ""))
end

function Utils:RTrim(text)
-- (a) http://lua-users.org/

	if type(text) ~= 'string' then
		return ""
	end

	local n = #text
	while n > 0 and text:find("^%s", n) do n = n - 1 end
	return text:sub(1, n)
end

function Utils:StringStarts(text, start)
	if type(text) ~= 'string' then
		return false
	end

	return string.sub(text, 1, string.len(start)) == start
end

function Utils:StringEmpty(text)
	if type(text) ~= 'string' then
		return false
	end

	local strFirstChar
	local bHasText = false

	strFirstChar = string.find(text, "%S")

	bHasText = strFirstChar ~= nil and Apollo.StringLength(strFirstChar) > 0

	return bHasText
end 

function Utils:If(cond, ret1, ret2)
	if cond then
		return ret1
	end

	return ret2
end

function Utils:KeyByVal(t, v)
	if #t > 0 then
		for k, __ in ipairs(t) do
			if __ == v then
				return k
			end
		end

		return
	end

	for k, __ in pairs(t) do
		if __ == v then
			return k
		end
	end
end

function Utils:Exists(t, k)
	if #t > 0 then
		for _, __ in ipairs(t) do
			if _ == k then
				return true
			end
		end
	end

	for _, __ in pairs(t) do
		if _ == k then
			return true
		end
	end
end

function Utils:Foreach(t, f)
	if #t > 0 then
		for _, v in ipairs(t) do
			f(v)
		end

		return
	end

	for k, v in pairs(t) do
		f(k, v)
	end
end

function Utils:Map(array, func)
	local new_array = {}

	for i,v in ipairs(array) do
		new_array[i] = func(v)
	end

	return new_array
end

function Utils:SplitString(str, delimiter)
	local result = {}
	local from  = 1
	local delim_from, delim_to = string.find(str, delimiter, from)
	
	while delim_from do
		table.insert(result, string.sub(str, from , delim_from-1))
		from  = delim_to + 1
		delim_from, delim_to = string.find(str, delimiter, from)
	end
	
	table.insert(result, string.sub(str, from))

	return result
end

function Utils:Filter(tbl, func)
	local newtbl= {}

	for i,v in pairs(tbl) do
		if func(v) then
			newtbl[i]=v
		end
	end

	return newtbl
end

function Utils:RemoveIf(arr, func)
	local new_array = {}

	for k,v in ipairs(arr) do
		if not func(v) then 
			table.insert(new_array, v)
		end
	end

	return new_array
end

function Utils:DistanceToUnit(unitPlayer, unitTarget)
	if not unitPlayer then return end
	if not unitTarget then return end

	local loc1 = unitPlayer:GetPosition()
	local loc2 = unitTarget:GetPosition()

	if not loc1 then return end
	if not loc2 then return end

	local tVec = {}

	for axis, value in pairs(loc1) do
		tVec[axis] = loc1[axis] - loc2[axis]
	end

	local vVec = Vector3.New(tVec['x'], tVec['y'], tVec['z'])

	return math.floor(vVec:Length()) + 1
end

function Utils:Copy(base)
	local object = {}

	for _, __ in pairs(base) do
		if type(__) == 'table' then
			object[_] = self:Copy(__)
		else
			object[_] = __
		end
	end

	return object
end

function Utils:Overwrite(what, by)
	local object = {}

	by = by or {}
	what = what or {}

	for _, __ in pairs(what) do
		if type(__) == 'table' then
			object[_] = self:Overwrite(__)
		else
			object[_] = __
		end
	end

	for _, __ in pairs(by) do
		if type(__) == 'table' then
			object[_] = self:Overwrite(__)
		else
			object[_] = __
		end
	end

	return object
end

function Utils:Count(t)
	if type(t) ~= 'table' then
		return
	end

	if #t > 0 then
		return #t
	end

	local count = 0

	for _ in pairs(t) do
		count = count + 1
	end

	return count
end

function Utils:GetFormatedTimeString()
-- (a) ChatLog, NCSoft

	local nTimeDisplay = Apollo.GetConsoleVariable("hud.TimeDisplay")
	
	local tTime = GameLib.GetLocalTime()
	local strTime = (string.format("%02d:%02d", tostring(tTime.nHour), tostring(tTime.nMinute)))
	
	if nTimeDisplay == 2 then --Local 12hr am/pm
		local nHour = tTime.nHour > 12 and tTime.nHour - 12 or tTime.nHour == 0 and 12 or tTime.nHour
	
		strTime = (string.format("%02d:%02d", tostring(nHour), tostring(tTime.nMinute)))
	elseif nTimeDisplay == 3 then --Server 24hr
		tTime = GameLib.GetServerTime()
	
		strTime = (string.format("%02d:%02d", tostring(tTime.nHour), tostring(tTime.nMinute)))
	elseif nTimeDisplay == 4 then --Server 12hr am/pm
		tTime = GameLib.GetServerTime()
		local nHour = tTime.nHour > 12 and tTime.nHour - 12 or tTime.nHour == 0 and 12 or tTime.nHour
	
		strTime = (string.format("%02d:%02d", tostring(nHour), tostring(tTime.nMinute)))
	end
	
	return strTime
end

function Utils:Chunk(text, size, pmax)
	local s = {}
	local p = 0

	for i=1, #text, size do
		p = #s + 1

		if p == pmax then
			s[p] = text:sub(i)

			return s
		end

		s[p] = text:sub(i ,i + size - 1)
	end

	return s
end

function Utils:Random(f, t)
	if not self.Randomseed then
		self.Randomseed = os.time()

		math.randomseed(self.Randomseed)
		math.random()
		math.random()
		math.random()
	end

	return math.random(f, t)
end
