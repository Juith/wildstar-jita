local Jita = Apollo.GetAddon("Jita")
local Member = Jita:Extend("Member")

--

function Member:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self

	o.Name           = nil
	o.NickName       = nil
	o.IsChannelOwner = nil
	o.IsModerator    = nil
	o.IsMuted        = nil
	o.IsCrossfaction = nil

	return o
end
