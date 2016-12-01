local Jita = Apollo.GetAddon("Jita")
local Stream = Jita:Extend("Stream")

local Utils = Jita.Utils

--

function Stream:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self

	o.Name                    = "Default::Blank"
	o.DisplayName             = "Default"
	o.Type                    = nil
	o.Channels                = {}
	o.Messages                = {}
	o.Members                 = {}
	o.UnreadMessages          = false
	o.CanRequestMembersList   = false
	o.IsRequestingMembersList = false
	o.Closeable               = true
	o.Closed                  = false
	o.Ignored                 = false
	o.Command                 = "/say"
	o.CommandColor            = nil

	return o
end

--

function Stream:AddChannel(refrence)
	if not refrence then 
		return false
	end

	-- exists
	if self:GetChannel(refrence) then
		return false
	end

	table.insert(self.Channels, refrence)
end

function Stream:GetChannel(refrence)
	for _, channel in ipairs(self.Channels) do
		if channel == refrence then
			return channel
		end
	end
end

function Stream:RemoveChannel(refrence) 
	for _, channel in ipairs(self.Channels) do
		if channel == refrence then
			table.remove(self.Channels, _)
		end
	end
end

--

function Stream:AddMember(name, info)
	if name == nil or name == "" then 
		return false
	end

	-- unique
	if self:GetMember(name) then
		return false
	end

	info = info or {}

	local member = Jita:Yield("Member")

	member.Name           = name
	member.NickName       = info.NickName
	member.IsChannelOwner = info.IsChannelOwner
	member.IsModerator    = info.IsModerator
	member.IsMuted        = info.IsMuted
	member.IsCrossfaction = info.IsCrossfaction

	table.insert(self.Members, member)

	return true
end

function Stream:GetMember(name)
	for _, member in ipairs(self.Members) do
		if member.Name == name then
			return member
		end
	end
end

function Stream:RemoveMember(name)
	for id, member in ipairs(self.Members) do
		if member.Name == name then
			table.remove(self.Members, id)
		end
	end
end

--

function Stream:AddMessage(info)
	local message = Jita:Yield("Message")

	message.ID           = #self.Messages + 1
	message.Type         = info.Type
	message.Channel      = info.Channel and info.Channel:GetUniqueId() or nil
	message.Content      = info.Content or {}
	message.IsLastViewed = info.IsLastViewed
	message.IsOfInterest = info.IsOfInterest
	message.Range        = info.Range
	message.StrTime      = Utils:GetFormatedTimeString()

	-- if chat message, we shrink down its footprint by removing implicit data.
	if info.Message then
		message.Content = Utils:Overwrite(message.Content, info.Message)

		if not message.Content.bAutoResponse then message.Content.bAutoResponse = nil end
		if not message.Content.bGM           then message.Content.bGM           = nil end
		if not message.Content.bSelf         then message.Content.bSelf         = nil end
		if not message.Content.bCrossFaction then message.Content.bCrossFaction = nil end

		if not message.Content.strRealmName   or message.Content.strRealmName  == '' then message.Content.strRealmName   = nil end
		if not message.Content.nPresenceState or message.Content.nPresenceState == 0 then message.Content.nPresenceState = nil end

		message.Content.bShowChatBubble = nil
		message.Content.nPremiumTier    = nil

		local segments = message.Content.arMessageSegments or {}

		for _, segment in ipairs(segments) do
			segment.bAlien     = segment.bAlien     and segment.bAlien     or nil
			segment.bProfanity = segment.bProfanity and segment.bProfanity or nil
			segment.bRolePlay  = segment.bRolePlay  and segment.bRolePlay  or nil
		end
	end

	-- calculate range if emitter's in vicinity
	if not message.Range 
	and info.Channel
	and message.Content.unitSource
	then
		if info.Channel:GetType() == ChatSystemLib.ChatChannel_Say
		or info.Channel:GetType() == ChatSystemLib.ChatChannel_Emote
		or info.Channel:GetType() == ChatSystemLib.ChatChannel_AnimatedEmote
		then
			local player = GameLib.GetPlayerUnit()
			local target = message.Content.unitSource

			message.Range = Utils:DistanceToUnit(player, target)

			-- go figure
			if message.Range and message.Range > 512 then
				message.Range = nil
			end
		end
	end

	table.insert(self.Messages, message)

	return message
end

function Stream:RemoveMessage(id)
	if id == nil then
		table.remove(self.Messages, 1)

		return
	end
	
	for _, message in ipairs(self.Messages) do
		if message.ID == id then
			table.remove(self.Messages, id)
		end
	end
end
