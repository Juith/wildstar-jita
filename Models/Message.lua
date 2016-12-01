local Jita = Apollo.GetAddon("Jita")
local Message = Jita:Extend("Message")

--

function Message:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self

	o.ID           = nil
	o.Type         = nil
	o.Channel      = nil
	o.Content      = nil
	o.IsLastViewed = nil
	o.IsOfInterest = nil
	o.Range        = nil
	o.StrTime      = nil

	return o
end
