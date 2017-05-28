local Jita = Apollo.GetAddon("Jita")
local Client = Jita:Extend("Client")

local Utils = Jita.Utils
local Consts = Jita.Consts

--

function Client:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self 

	o.ChatLogEnabled = nil -- indicate whether ChatLog is enabled, we need this because Jita is made to coexist with it.

	-- aggregated streams are where players get to pick and choose what channels to follow
	-- segregated streams are the exact opposite
	o.EnumStreamsTypes = {  -- might be as well be a boolean, but when
		AGGREGATED = 1, -- you make one exception, expect to make 
		SEGREGATED = 2, -- another. I hate to deal with exceptions.
	}

	o.Streams           = {} -- streams are groups of chat channels, and they encapsulate their metadata, channels, messages and members
	o.Channels          = {} -- list of known chat channels
	o.MembersProfiles   = {} -- a member can have only one profile across all channels/streams
	o.PrivateNotes      = {} -- private notes on players are stored realm wide
	o.LocalPlayers      = {} -- they come and go, thus we keep them on a separate scope
	o.PartyPlayers      = {} -- they kind of important, we also keep them on a separate scope
	o.PlayersOfInterest = {} -- a cache of players with notes, had mentioned a keyword, etc.
	o.Notifications     = {}
	o.LastWhisper       = {}

	return o
end

function Client:Init(core)
	Apollo.LinkAddon(core, self)

	self:InitStandardStreams()

	--

	Apollo.RegisterEventHandler("ChatMessage"    , "OnChatMessage"   , self) -- Fires when a message is sent on a chat channel.
	Apollo.RegisterEventHandler("ChatResult"     , "OnChatResult"    , self) -- Fires when there is an error with a chat message that the player tried to send.
	Apollo.RegisterEventHandler("ChatJoin"       , "OnChatJoin"      , self) -- Fires when the player joins a chat channel.
	Apollo.RegisterEventHandler("ChatJoinResult" , "OnChatJoinResult", self) -- Fires whenever the player fails to join a channel.
	Apollo.RegisterEventHandler("ChatLeave"      , "OnChatLeave"     , self) -- Fires when the player leaves or is kicked from a chat channel.
	Apollo.RegisterEventHandler("ChatAction"     , "OnChatAction"    , self) -- Fires whenever an action is taken on a custom chat channel. (eg passing the ownership, mod status).

	Apollo.RegisterEventHandler("Event_EngageAccountWhisper" , "OnEngageAccountWhisper", self)
	Apollo.RegisterEventHandler("Event_EngageWhisper"        , "OnEngageWhisper", self)
	Apollo.RegisterEventHandler("GenericEvent_ChatLogWhisper", "OnEngageWhisper", self)

	Apollo.RegisterEventHandler("ChatTellFailed"       , "OnChatTellFailed"       , self) -- Fires whenever the player makes an unsuccessful tell
	Apollo.RegisterEventHandler("ChatAccountTellFailed", "OnChatAccountTellFailed", self) -- Fires whenever the player makes an unsuccessful tell

	Apollo.RegisterEventHandler("ChatReply", "OnReplyKeybind" , self) -- Fires when the player uses the ChatReply keybinding.

	Apollo.RegisterEventHandler("ChatList"    , "OnChatList"  , self) -- Result of custom channel request members
	Apollo.RegisterEventHandler("GuildRoster", "OnGuildRoster", self) -- Result of guild and circles channel request members

	--

	Apollo.RegisterEventHandler("UnitCreated"    , "OnUnitCreated"   , self)
	Apollo.RegisterEventHandler("UnitDestroyed"  , "OnUnitDestroyed" , self)
	Apollo.RegisterEventHandler("ChangeWorld"    , "OnChangeWorld"   , self)
	Apollo.RegisterEventHandler("SubZoneChanged" , "OnSubZoneChanged", self)
	Apollo.RegisterEventHandler("WhoResponse"    , "OnWhoResponse"   , self)

	-- Events ported straight from ChatLog. Most do nothing of use, just spam chat with notifs and such

	Apollo.RegisterEventHandler("GenericEvent_LootChannelMessage"  , "OnGenericEvent_LootChannelMessage"  , self)
	Apollo.RegisterEventHandler("GenericEvent_SystemChannelMessage", "OnGenericEvent_SystemChannelMessage", self)

	Apollo.RegisterEventHandler("LuaChatLogMessage"       , "OnLuaChatLogMessage"      , self)
	Apollo.RegisterEventHandler("PlayedTime"              , "OnPlayedtime"             , self)
	Apollo.RegisterEventHandler("ItemSentToCrate"         , "OnItemSentToCrate"        , self)
	Apollo.RegisterEventHandler("HarvestItemsSentToOwner" , "OnHarvestItemsSentToOwner", self)
	Apollo.RegisterEventHandler("ChannelUpdate_Loot"      , "OnChannelUpdate_Loot"     , self)
	Apollo.RegisterEventHandler("ChannelUpdate_Crafting"  , "OnChannelUpdate_Crafting" , self)
	Apollo.RegisterEventHandler("ChannelUpdate_Progress"  , "OnChannelUpdate_Progress" , self)
	Apollo.RegisterEventHandler("TradeSkillSigilResult"   , "OnTradeSkillSigilResult"  , self)
	Apollo.RegisterEventHandler("AccountCurrencyChanged"  , "OnAccountCurrencyChanged" , self)

	Apollo.RegisterEventHandler("AccountSupportTicketResult", "OnAccountSupportTicketResult", self)
end

function Client:Tick()
	-- Basically we keep this flag updated to check if Carbine's ChatLog is
	-- enabled in order to prevent doubles messages, notifications and such.
	-- Will give it few seconds to load then keep pinging for status
	if Jita.Timestamp == Jita.CoreSettings.PingChatLogDelay
	or Jita.Timestamp  % Jita.CoreSettings.PingChatLogInterval == 0
	then
		self.ChatLogEnabled = false

		if Apollo.GetAddon("ChatLog") then
			self.ChatLogEnabled = true
		end
	end

	-- Pulling nearby players has small computation cost, but we still keep refresh rate low 
	if Jita.Timestamp % Jita.CoreSettings.PullLocalPlayersInterval == 0 then
		self:PullLocalMembers()
	end

	-- same goes for party members 
	if Jita.Timestamp % Jita.CoreSettings.PullPartyMembersInterval == 0 then
		self:PullPartyMembers()
	end

	-- Carbine's cheesy with their bandwidth, so members lists gets updated only so often
	if Jita.Timestamp == Jita.CoreSettings.RequestStreamsMembersDelay
	or Jita.Timestamp  % Jita.CoreSettings.RequestStreamsMembersInterval == 0 then
		self:RequestCustomChannelsMembers()
		self:RequestGuildAndCirclesMembers() 
	end

	-- Validate current player identity and remove unused profile of other members
	if Jita.Timestamp % Jita.CoreSettings.ValidateProfilesInterval == 0 then
		self:ValidatePlayersProfiles()
	end

	-- alert players in close chat range. Scales down on populated areas, or that's the plan.
	if Jita.UserSettings.ChatWindow_MessageAlertPlayerInRange == true
	and Jita.Timestamp % (math.floor(math.log10(Utils:Count(self.LocalPlayers)) * 2) + 1) == 0
	then
		self:AlertPlayerInRange(20)
	end
end

function Client:GetState()
	local state = {
		Streams = {},
		History = {}
	}

	for _, stream in ipairs(self.Streams) do
		table.insert(state.Streams, {
			Name        = stream.Name       ,
			DisplayName = stream.DisplayName,
			Type        = stream.Type       ,
			Channels    = stream.Channels   ,
			Ignored     = stream.Ignored    ,
			Closed      = stream.Closed     ,
			Command     = stream.Command    ,
		})
	end

	return state
end

function Client:RestoreSavedState()
	self:InitGreetings()

	-- restore private notes
	if Jita.SaveData and Jita.SaveData.Realm then
		self.PrivateNotes = Jita.SaveData.Realm.PrivateNotes or {}
	end

	-- if new toon, one pass on aggregated streams to populate channels list
	if not Jita.SaveData
	or not Jita.SaveData.Character
	or not Jita.SaveData.Character.ClientState
	then
		for _, stream in ipairs(self.Streams) do
			if stream.Type == self.EnumStreamsTypes.AGGREGATED then
				self:InitAggregatedStreamChannles(stream)
			end
		end

		-- set default chat tab to not closeable
		local stream = self:GetStream(Jita.UserSettings.DefaultStream)

		if stream then
			stream.Closeable = false
		end

		return
	end

	-- restore streams state
	local state = Jita.SaveData.Character.ClientState

	if state and state.Streams then
		for _, dStream in ipairs(state.Streams) do
			for _, sStream in ipairs(self.Streams) do
				-- Fixme:
				-- backward compatibility thing..
				local isgeneral = dStream.Name == "Default::Custom" and sStream.Name == "Default::General"

				if string.lower(dStream.Name) == string.lower(sStream.Name) 
				or isgeneral
				then
					sStream.Closed      = dStream.Closed or false
					sStream.Ignored     = dStream.Ignored or false
					sStream.DisplayName = dStream.DisplayName or sStream.DisplayName

					-- Fixme:
					if isgeneral then
						sStream.DisplayName = "General"
					end

					-- if aggregated we also restore channels which is tricky 
					-- because there's no easy way to identify channels 
					-- (even unique id is not really unique and can get randomly reset by server)
					if  dStream.Type
					and dStream.Channels
					and dStream.Type == self.EnumStreamsTypes.AGGREGATED
					then
						sStream.Channels = dStream.Channels or {}

						if Jita.Player then
							self:AddStreamMember(sStream, Jita.Player.Name)
						end
					end
				end
			end
		end
	end

	-- set default chat tab to not closeable
	local stream = self:GetStream(Jita.UserSettings.DefaultStream)

	if stream then
		stream.Closeable = false
	end

	-- restore current player profile
	local profiles = Jita.SaveData.Character.PlayersProfiles

	if profiles and profiles.Current then
		Jita.Player:RestoreProfile(profiles.Current)
	end
end

function Client:JoinJitaCustomChannel()
	if not Jita.UserSettings.AutojoinJitaCustomChannel == true
	or not Jita.UserSettings.JitaCustomChannel
	then
		return
	end

	local channels = ChatSystemLib.GetChannels()
	local member = false
	
	for _, item in ipairs(channels) do
		if item:GetType()  == ChatSystemLib.ChatChannel_Custom
		and item:GetName() == Jita.UserSettings.JitaCustomChannel
		then
			member = true
		end
	end

	if not member then 
		ChatSystemLib.JoinChannel(Jita.UserSettings.JitaCustomChannel)

		Jita.UserSettings.AutojoinJitaCustomChannel = false
	end
end
