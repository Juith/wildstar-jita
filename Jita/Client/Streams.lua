local Jita = Apollo.GetAddon("Jita")
local Client = Jita:Extend("Client")

-- 

function Client:AddStream(stream)
	if not stream then
		return
	end

	local exists = self:GetStream(stream.Name)

	if not exists then
		table.insert(self.Streams, stream)
	end
end

function Client:GetStream(name)
	if not name then
		return
	end

	for _, __ in ipairs(self.Streams) do
		if __.Name == name then
			return __
		end
	end 
end

--

function Client:InitStandardStreams()
	local stream = Jita:Yield("Stream")

	stream.Name                    = "Default::General"
	stream.DisplayName             = "General"
	stream.Type                    = self.EnumStreamsTypes.AGGREGATED
	stream.Channels                = {}
	stream.CanRequestMembersList   = false
	stream.IsRequestingMembersList = false
	stream.Closed                  = false
	stream.Closeable               = true
	stream.Command                 = "/say"
	stream.CommandColor            = ChatSystemLib.ChatChannel_Say

	self:AddStream(stream)

	--

	stream = Jita:Yield("Stream")

	stream.Name                    = "Default::Local"
	stream.DisplayName             = "Local"
	stream.Type                    = self.EnumStreamsTypes.SEGREGATED
	stream.Channels                = 
	{
		ChatSystemLib.ChatChannel_System,
		ChatSystemLib.ChatChannel_Realm,
		ChatSystemLib.ChatChannel_Support,

		ChatSystemLib.ChatChannel_Say,
		ChatSystemLib.ChatChannel_Yell,
		ChatSystemLib.ChatChannel_Emote,
		ChatSystemLib.ChatChannel_AnimatedEmote,
	}
	stream.CanRequestMembersList   = true
	stream.IsRequestingMembersList = true
	stream.Closed                  = false
	stream.Closeable               = true
	stream.Command                 = "/say"
	stream.CommandColor            = ChatSystemLib.ChatChannel_Say

	self:AddStream(stream)

	--

	stream = Jita:Yield("Stream")

	stream.Name                    = "Default::Zone"
	stream.DisplayName             = "Zone"
	stream.Type                    = self.EnumStreamsTypes.SEGREGATED
	stream.Channels                = 
	{
		ChatSystemLib.ChatChannel_Zone,
	}
	stream.CanRequestMembersList   = false
	stream.IsRequestingMembersList = false
	stream.Closed                  = false
	stream.Closeable               = true
	stream.Command                 = "/zone"
	stream.CommandColor            = ChatSystemLib.ChatChannel_Zone

	self:AddStream(stream)

	--

	stream = Jita:Yield("Stream")

	stream.Name                    = "Default::Nexus"
	stream.DisplayName             = "Nexus"
	stream.Type                    = self.EnumStreamsTypes.SEGREGATED
	stream.Channels                = 
	{
		ChatSystemLib.ChatChannel_Nexus,
	}
	stream.CanRequestMembersList   = false
	stream.IsRequestingMembersList = false
	stream.Closed                  = false
	stream.Closeable               = true
	stream.Command                 = "/nexus"
	stream.CommandColor            = ChatSystemLib.ChatChannel_Nexus

	self:AddStream(stream)

	--

	stream = Jita:Yield("Stream")

	stream.Name                    = "Default::Guild"
	stream.DisplayName             = "Guild"
	stream.Type                    = self.EnumStreamsTypes.SEGREGATED
	stream.Channels                = 
	{
		ChatSystemLib.ChatChannel_Guild,
	}
	stream.CanRequestMembersList   = true
	stream.IsRequestingMembersList = true
	stream.Closed                  = false
	stream.Closeable               = true
	stream.Command                 = "/guild"
	stream.CommandColor            = ChatSystemLib.ChatChannel_Guild

	self:AddStream(stream)

	--

	stream = Jita:Yield("Stream")

	stream.Name                    = "Default::Guild Officer"
	stream.DisplayName             = "Guild Officer"
	stream.Type                    = self.EnumStreamsTypes.SEGREGATED
	stream.Channels                = 
	{
		ChatSystemLib.ChatChannel_GuildOfficer,
	}
	stream.CanRequestMembersList   = false
	stream.IsRequestingMembersList = false
	stream.Closed                  = true
	stream.Closeable               = true
	stream.Command                 = "/gofficer"
	stream.CommandColor            = ChatSystemLib.ChatChannel_GuildOfficer

	self:AddStream(stream)

	--

	stream = Jita:Yield("Stream")

	stream.Name                    = "Default::Party"
	stream.DisplayName             = "Party"
	stream.Type                    = self.EnumStreamsTypes.SEGREGATED
	stream.Channels                = 
	{
		ChatSystemLib.ChatChannel_Party, 
	}
	stream.CanRequestMembersList   = true
	stream.IsRequestingMembersList = true
	stream.Closed                  = true
	stream.Closeable               = true
	stream.Color                   = true
	stream.Command                 = "/party"
	stream.CommandColor            = ChatSystemLib.ChatChannel_Party

	self:AddStream(stream)

	--
	
	stream = Jita:Yield("Stream")

	stream.Name                    = "Default::Instance"
	stream.DisplayName             = "Instance"
	stream.Type                    = self.EnumStreamsTypes.SEGREGATED
	stream.Channels                = 
	{
		ChatSystemLib.ChatChannel_Instance, 
	}
	stream.CanRequestMembersList   = false
	stream.IsRequestingMembersList = false
	stream.Closed                  = true
	stream.Closeable               = true
	stream.Command                 = "/instance"
	stream.CommandColor            = ChatSystemLib.ChatChannel_Instance

	self:AddStream(stream)

	--

	stream = Jita:Yield("Stream")

	stream.Name                    = "Default::PvP"
	stream.DisplayName             = "PvP"
	stream.Type                    = self.EnumStreamsTypes.SEGREGATED
	stream.Channels                = 
	{
		ChatSystemLib.ChatChannel_ZonePvP, 
	}
	stream.CanRequestMembersList   = false
	stream.IsRequestingMembersList = false
	stream.Closed                  = true
	stream.Closeable               = true
	stream.Command                 = "/pvp"
	stream.CommandColor            = ChatSystemLib.ChatChannel_ZonePvP

	self:AddStream(stream)

	--

	stream = Jita:Yield("Stream")

	stream.Name                    = "Default::Loot"
	stream.DisplayName             = "Loot"
	stream.Type                    = self.EnumStreamsTypes.SEGREGATED
	stream.Channels                = 
	{
		ChatSystemLib.ChatChannel_Loot, 
	}
	stream.CanRequestMembersList   = false
	stream.IsRequestingMembersList = false
	stream.Ignored                 = true
	stream.Closed                  = true
	stream.Closeable               = true
	stream.Command                 = "/say"
	stream.CommandColor            = ChatSystemLib.ChatChannel_Say

	self:AddStream(stream)

	--
	
	stream = Jita:Yield("Stream")

	stream.Name                    = "Default::Debug"
	stream.DisplayName             = "Debug"
	stream.Type                    = self.EnumStreamsTypes.SEGREGATED
	stream.Channels                = 
	{
		ChatSystemLib.ChatChannel_Debug, 
	}
	stream.CanRequestMembersList   = false
	stream.IsRequestingMembersList = false
	stream.Ignored                 = true
	stream.Closed                  = true
	stream.Closeable               = true
	stream.Command                 = "/say"
	stream.CommandColor            = ChatSystemLib.ChatChannel_Say

	self:AddStream(stream)
end

function Client:SyncPlayerStreams(closed)
	local channels = ChatSystemLib.GetChannels()

	if not channels then
		return
	end

	if closed == nil then
		closed = true
	end

	table.sort(channels, function(a, b) return a:GetName() < b:GetName() end)

	for _, channel in ipairs(channels) do
		-- customs
		if channel:GetType() == ChatSystemLib.ChatChannel_Custom then
			local stream = Jita:Yield("Stream")

			stream.Name         = "Custom::" .. channel:GetName()
			stream.DisplayName  = channel:GetName()
			stream.Type         = self.EnumStreamsTypes.SEGREGATED
			stream.Closeable    = true
			stream.Closed       = closed
			stream.Command      = "/" .. channel:GetCommand()
			stream.CommandColor = ChatSystemLib.ChatChannel_Custom

			stream.CanRequestMembersList   = true
			stream.IsRequestingMembersList = true 

			stream:AddChannel(channel:GetUniqueId())

			self:AddStream(stream)
		end

		-- circles
		if channel:GetType() == ChatSystemLib.ChatChannel_Society then
			local stream = Jita:Yield("Stream")

			stream.Name         = "Society::" .. channel:GetName()
			stream.DisplayName  = channel:GetName()
			stream.Type         = self.EnumStreamsTypes.SEGREGATED
			stream.Closeable    = true
			stream.Closed       = closed 
			stream.Command      = "/" .. channel:GetCommand()
			stream.CommandColor = ChatSystemLib.ChatChannel_Society

			stream.CanRequestMembersList   = true
			stream.IsRequestingMembersList = true 

			stream:AddChannel(channel:GetUniqueId())

			self:AddStream(stream)
		end
	end
end

function Client:InitAggregatedStreamChannles(stream)
	if not stream then
		return
	end

	if stream.Type ~= self.EnumStreamsTypes.AGGREGATED then
		return
	end

	local channels = ChatSystemLib.GetChannels()

	for _, channel in ipairs(channels) do
		if channel:GetType() ~= ChatSystemLib.ChatChannel_Combat -- combat logs are thrown out
		then
			stream:AddChannel(channel:GetType() .. "::" .. channel:GetName())
		end
	end
end

function Client:AddChannelToAggregatedStreams(channel)
	if not channel then
		return
	end

	for _, stream in ipairs(self.Streams) do
		if stream.Type == self.EnumStreamsTypes.AGGREGATED then
			stream:AddChannel(channel:GetType() .. "::" .. channel:GetName())
		end
	end
end

function Client:RemoveChannelFromAggregatedStreams(channel)
	if not channel then
		return
	end

	for _, stream in ipairs(self.Streams) do
		if stream.Type == self.EnumStreamsTypes.AGGREGATED then
			stream:RemoveChannel(channel:GetType() .. "::" .. channel:GetName())
		end
	end
end

function Client:CloseStreamByChannel(channel)
--/- close stream and keep it memory in case player want to check messages

	if not channel then
		return
	end

	self:SyncPlayerStreams()

	local channelStream = nil

	for _, stream in ipairs(self.Streams) do
		if stream.Type == self.EnumStreamsTypes.SEGREGATED then
			for _, channelId in ipairs(stream.Channels) do
				if channelId == channel:GetUniqueId() then
					stream.Closed  = true

					channelStream = stream
				end
			end
		end
	end

	return channelStream
end

--

function Client:GetStreamMember(name)
	if not name then
		return
	end

	for _, __ in ipairs(self.Streams) do
		for ___, ____ in ipairs(self.Streams[_].Members) do
			if ____.Name == name then
				return ____
			end
		end 
	end 
end

function Client:PullLocalMembers()
	Jita.Player:Init()

	local unitPlayer = Jita.Player.Unit

	if not unitPlayer then return end

	local stream = self:GetStream("Default::Local")

	if not stream then
		return
	end

	stream.Members = {}

	for name, unit in pairs(self.LocalPlayers) do 
		local info = {}

		info.IsCrossfaction = false

		if unit:GetDispositionTo(unitPlayer) 
		== Unit.CodeEnumDisposition.Hostile then
			info.IsCrossfaction = true
		end

		self:AddStreamMember(stream, name, info)

		self:AddPlayerProfile(name)
	end

	self:AddStreamMember(stream, Jita.Player.Name)

	stream.IsRequestingMembersList = false
end

function Client:PullPartyMembers()
	self.PartyPlayers = {}

	for cp = 1, GroupLib.GetMemberCount() do
		local member = GroupLib.GetGroupMember(cp)

		if member
		and member.strCharacterName
		then
			self.PartyPlayers[member.strCharacterName] = member
		end
	end

	local stream = self:GetStream("Default::Party")

	if not stream then
		return
	end

	stream.Members = {}

	for name, player in pairs(self.PartyPlayers) do
		self:AddStreamMember(stream, name)

		self:AddPlayerProfile(name)
	end

	self:AddStreamMember(stream, Jita.Player.Name)

	stream.IsRequestingMembersList = false
end

function Client:RequestCustomChannelsMembers()
	local channels = ChatSystemLib.GetChannels()

	if not channels then
		return
	end

	for _, channel in ipairs(channels) do
		if channel:GetType() == ChatSystemLib.ChatChannel_Custom then
			self:RequestCustomChannelMembers(channel)
		end
	end
end

function Client:RequestCustomChannelMembers(channel)
	if not channel then
		return
	end

	local stream = self:GetStream("Custom::" .. channel:GetName())

	if not stream or stream.Closed or stream.Ignored then
		return
	end

	if  #stream.Members   >= 1
	and #stream.Messages  <= 1
	and math.random(1, 2) == 2
	then
		return
	end

	channel:RequestMembers()

	stream.IsRequestingMembersList = true
end

function Client:RequestGuildAndCirclesMembers()
	local guilds = GuildLib.GetGuilds() or {}

	if not guilds then
		return
	end

	for _, guild in pairs(guilds) do
		if guild:GetType() == GuildLib.GuildType_Circle
		or guild:GetType() == GuildLib.GuildType_Guild
		then
			guild:RequestMembers()
		end
	end
end

--

function Client:AddStreamMember(stream, name, info)
--/- had to wrap this method to enforce limits

	if not stream or not name then
		return
	end

	stream:AddMember(name, info)

	if stream.Type == self.EnumStreamsTypes.SEGREGATED
	and #stream.Members > Jita.CoreSettings.Stream_Segregated_MaxMembers then
		table.remove(stream.Members, 1)
	end

	if stream.Type == self.EnumStreamsTypes.AGGREGATED
	and #stream.Members > Jita.CoreSettings.Stream_Aggregated_MaxMembers then
		table.remove(stream.Members, 1)
	end
end

function Client:AddCurrentPlayerToStreamsMembers()
--/- be sneaky and add current player to standard streams

	for _, stream in ipairs(self.Streams) do
		if stream.CanRequestMembersList == false then
			self:AddStreamMember(stream, Jita.Player.Name)
		end
	end
end

--

function Client:UpdateLastChatMessageViewed(name)
	if not Jita.UserSettings.ChatWindow_MessageShowLastViewed then
		return
	end

	local stream = self:GetStream(name)

	if not stream then
		return
	end

	for _, message in ipairs(stream.Messages) do
		if message then
			message.IsLastViewed = nil
		end
	end

	if #stream.Messages > 0 then
		stream.Messages[#stream.Messages].IsLastViewed = true
	end
end
