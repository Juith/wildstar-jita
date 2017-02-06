local Jita = Apollo.GetAddon("Jita")
local Client = Jita:Extend("Client")

local Utils = Jita.Utils
local Consts = Jita.Consts

--

function Client:DoChatMessage(command, text)
--/- Thing that actually post stuff to chat

	if not text then
		return
	end

	-- remove trailing
	text = string.gsub(text, "\n", "")

	-- substitute macros
	text = self:SubstituteJitaMacros(text)

	if not text or Utils:Trim(text) == '' then
		return
	end

	-- append command if any
	if command then
		text = command .. " " .. text
	end

	-- validation
	local parsed = ChatSystemLib.SplitInput(text)

	if not parsed then
		ChatSystemLib.Command(text)

		return
	end

	--

	if parsed.bValidCommand and parsed.channelCommand then -- obviously at this point
		local channelType = parsed.channelCommand:GetType()

		-- slash command
		if channelType == ChatSystemLib.ChatChannel_Command then
			ChatSystemLib.Command(text)

			return
		end

		-- will deal with these on another day - prolly,
		if channelType == ChatSystemLib.ChatChannel_Whisper
		or channelType == ChatSystemLib.ChatChannel_AccountWhisper
		then
			ChatSystemLib.Command(text)

			return
		end
	end

	--

	if string.len(text) <= 500 then
		ChatSystemLib.Command(text)

		return
	end

	-- 

	command = parsed.strCommand

	local pattern = "%s*[^%s]+%s*"
	local chunks  = {}
	local chunk   = ""
	local length  = 0

	for word in string.gmatch(parsed.strMessage, pattern) do
		length = length + string.len(word)

		if length > 480 then
			table.insert(chunks, chunk)

			chunk  = "(cont.) "
			length = 0
		end

		chunk = chunk .. word
	end

	table.insert(chunks, chunk)

	for _, _chunk in ipairs(chunks) do
		ChatSystemLib.Command("/" .. command .. " " .. _chunk)
	end
end

function Client:DoChatAction(streamName, playerName, action)
--/- Execute actions on custom channels

	local stream = self:GetStream(streamName)

	if not stream then
		return
	end

	local gChannels = ChatSystemLib.GetChannels()

	for _, gChannel in ipairs(gChannels) do
		for __, sChannelId in ipairs(stream.Channels) do
			if gChannel:GetUniqueId() == sChannelId then
				if action == "PassOwner" then
					gChannel:PassOwner(playerName) 
				end

				if action == "SetModerator" then
					gChannel:SetModerator(playerName, 1)
				end

				if action == "RemoveModerator" then
					gChannel:SetModerator(playerName, 0)
				end

				if action == "Mute" then
					gChannel:SetMute(playerName, 1)
				end

				if action == "Unmute" then
					gChannel:SetMute(playerName, 0)
				end

				if action == "Kick" then
					gChannel:Kick(playerName)
				end
			end
		end
	end
end

--

function Client:OnChatMessage(channel, message)
--/- Hooks on incoming messages
--/- One hell of an #if chain cause lua too stronk

--[[
  ChatMessage
  Fires when a message is sent on a chat channel
  
  Params
    channelSource (ChatChannel) - The channel where the message should be displa
    tMessageInfo (Table) - 
      bAutoResponse (Boolean) - Whether or not the message is an auto respons
      bGM (Boolean) - Whether the message was sent by a GM or not. 
      bSelf (Boolean) - Whether the message was sent by the player or not. 
      strSender (String) - The name of the source of the message. 
      strRealmName (String) - The name of the sender's home realm. 
      nPresenceState (Integer) - The sender's status. This value lines up with t
      arMessageSegments (Table) - This is currently using the incorrect prefix. 
        bAlien (Boolean) - Whether or not the text is flagged to show alien font
        bProfanity (Boolean) - Whether or not the text contains profanity. 
        bRoleplay (Boolean) - Whether or not the text is flagged as Role Play te
        strText (String) - The text that is displayed. 
      unitSource (Unit) - The unit that sent the message. This variable does not
      bShowChatBubble (Boolean) - Whether or not a chat bubble should be shown a
      bCrossFaction (Boolean) - Whether or not the message came from a character
      nReportId (Integer) - The id that corresponds with the message. This value
]]--

	local channelId   = channel:GetUniqueId()
	local channelName = channel:GetName()
	local channelType = channel:GetType()
	local senderName  = message.strSender
	local senderRealm = message.strRealmName

	self.Channels[channelId] = channel

	local generateTabs = false

	-- Piss off.
	if channelType == ChatSystemLib.ChatChannel_Combat then
		return
	end

	-- Keepme:
	-- Need this to avoid recursive calls to print when debugging.
	-- if channelType == ChatSystemLib.ChatChannel_Debug then
		-- return
	-- end

	-- Check if incoming whisper
	if channelType == ChatSystemLib.ChatChannel_Whisper then
		local stream = self:GetStream("Whisper::" .. senderName)

		if not stream then
			self:OnIncomingWhisper(senderName)

			generateTabs = true
		end

		self.LastWhisper = {
			Peer    = senderName,
			Stream  = "Whisper::" .. senderName,
			Channel = ChatSystemLib.ChatChannel_Whisper,
			Command = "/whisper " .. senderName,
		}
	end

	-- Check if incoming account whisper
	local AW_PeerAccountName    = ""
	local AW_PeerCharacterName  = "" 
	local AW_PeerCharacterRealm = "" 
	local AW_PeerIsCrossfaction = false

	if channelType == ChatSystemLib.ChatChannel_AccountWhisper then
		local accountFriends = FriendshipLib.GetAccountList()

		for _, account in pairs(accountFriends) do
			if account.arCharacters ~= nil then
				for _, character in pairs(account.arCharacters) do
					if character.strCharacterName == senderName 
					and (senderRealm:len() == 0 
					or character.strRealm == senderRealm)
					then
						AW_PeerAccountName    = account.strCharacterName
						AW_PeerCharacterName  = character.strCharacterName
						AW_PeerCharacterRealm = character.strRealm 
						AW_PeerIsCrossfaction = not (character.nFactionId == Jita.Player.Unit:GetFaction())
					end
				end
			end
		end

		local stream = self:GetStream("AWhisper::" .. AW_PeerAccountName)

		if not stream then
			self:OnIncomingAccountWhisper(
				AW_PeerAccountName, 
				AW_PeerCharacterName, 
				AW_PeerCharacterRealm
			)

			generateTabs = true
		end

		self.LastWhisper = {
			Peer    = AW_PeerAccountName,
			Stream  = "AWhisper::" .. AW_PeerAccountName,
			Channel = ChatSystemLib.ChatChannel_AccountWhisper,
			Command = "/AWhisper " .. AW_PeerAccountName,
		}
	end

	-- Add a new field to message table to properly format display names
	-- Because ChatLog got this backward on whispers and message.strSender
	-- has the same name regardless of who's sending.
	-- defaults to verbatim sender's name
	message.strDisplayName = message.strSender

	-- display names of incoming messages from different realm (as if this still a thing)
	if senderRealm:len() > 0 
	and channelType ~= ChatSystemLib.ChatChannel_AccountWhisper
	then
		message.strDisplayName = message.strDisplayName .. "@" .. senderRealm
	end

	-- display names of account whispers
	if channelType == ChatSystemLib.ChatChannel_AccountWhisper then
		-- extra info on AW peer
		message.strAWPeerAccountName    = AW_PeerAccountName
		message.strAWPeerCharacterName  = AW_PeerCharacterName
		message.strAWPeerDisplayName    = AW_PeerAccountName .. " (" .. AW_PeerCharacterName .. ")"
		message.bAWPeerIsCrossfaction   = AW_PeerIsCrossfaction

		-- If message received
		if not message.bSelf then
			message.strDisplayName = message.strAWPeerDisplayName
		end
	end

	if channelType == ChatSystemLib.ChatChannel_Whisper
	or channelType == ChatSystemLib.ChatChannel_AccountWhisper
	then
		-- If message sent
		if message.bSelf then
			message.strDisplayName = Jita.Player.Name
		end

		-- play whisper sound in Chatlog stead
		if self.ChatLogEnabled == false then
			self:PlaySound(self.EnumSounds.Whisper)
		end
	end

	local insertedMessage = nil -- normalized message data structure

	for id, stream in ipairs(self.Streams) do
		local newMessage = false -- whether message is part of iterated stream

		-- Segregated streams identify channels in two different ways :
		-- 1. standard channels are identified by their TYPE except for whispers and account whispers
		-- cause those are tricky multiplexed channels.
		-- 2. custom, circles and whispers have their own streams and thus identified by stream name
		if stream.Type == self.EnumStreamsTypes.SEGREGATED then
			for _, streamChannelType in ipairs(stream.Channels) do
				-- standard channels matches by type
				if (
					channelType == streamChannelType 
					and channelType ~= ChatSystemLib.ChatChannel_Whisper 
					and channelType ~= ChatSystemLib.ChatChannel_AccountWhisper
				)

				-- whispers, account whispers, customs, circles: simply look up by stream name 
				or (channelType == ChatSystemLib.ChatChannel_Whisper        and stream.Name ==  "Whisper::" .. senderName        )
				or (channelType == ChatSystemLib.ChatChannel_AccountWhisper and stream.Name == "AWhisper::" .. AW_PeerAccountName)
				or (channelType == ChatSystemLib.ChatChannel_Custom         and stream.Name ==   "Custom::" .. channel:GetName() )
				or (channelType == ChatSystemLib.ChatChannel_Society        and stream.Name ==  "Society::" .. channel:GetName() )
				then
					newMessage = true
				end
			end

		-- Aggregated streams identify channels by their type and name (cause again, Channel's UniqueId may randomly change by server for reasons)
		elseif stream.Type == self.EnumStreamsTypes.AGGREGATED then
			for _, streamChannelId in ipairs(stream.Channels) do
				if string.lower(streamChannelId) == string.lower(channelType .. "::" .. channelName) then
					newMessage = true
				end
			end
		end

		if newMessage and stream.Ignored == false then
			insertedMessage = stream:AddMessage({
				Channel = channel,
				Message = message,
			})

			if (stream.Type == self.EnumStreamsTypes.SEGREGATED
			and #stream.Messages > Jita.CoreSettings.Stream_Segregated_MaxMessages)
			or (stream.Type == self.EnumStreamsTypes.AGGREGATED
			and #stream.Messages > Jita.CoreSettings.Stream_Aggregated_MaxMessages)
			then
				stream:RemoveMessage()
			end

			if stream.Closed then
				stream.Closed = false
				generateTabs = true

				-- keep debug, loot, guild, circles and zone pvp chat tabs closed if spam
				if (
					channelType == ChatSystemLib.ChatChannel_Debug
					or channelType == ChatSystemLib.ChatChannel_Loot
					or channelType == ChatSystemLib.ChatChannel_Guild
					or channelType == ChatSystemLib.ChatChannel_Society
					or channelType == ChatSystemLib.ChatChannel_ZonePvP
				)
				and (
					senderName:len() == 0 
					or senderName == Apollo.GetString("GuildInfo_MessageOfTheDay")
				)
				then
					stream.Closed = true
					generateTabs = false
				end
			end

			if senderName ~= Apollo.GetString("GuildInfo_MessageOfTheDay") -- this on Carbino.
			then
				if channelType
				== ChatSystemLib.ChatChannel_AccountWhisper then
					if not message.bSelf then
						self:AddStreamMember(stream, senderName, {
							IsCrossfaction = message.bAWPeerIsCrossfaction,
							NickName       = message.strAWPeerDisplayName,
						})
					end
				else
					self:AddStreamMember(stream, senderName, {
						IsCrossfaction = message.bCrossFaction 
					})
				end

				self:AddPlayerProfile(senderName)
			end

			self:PushMessageToChatWindows(stream, insertedMessage)
		end
	end

	-- nag about command outputs which is often used to communicate errors/chat actions to player
	if channelType == ChatSystemLib.ChatChannel_Command then
		self:PushMessageToSelectedStreamsInChatWindows({
			Channel = channel,
			Message = message,
		})
	end

	-- cause generating tabs for each message would make clicking them clunky
	if generateTabs then
		self:GenerateChatWindowsTabs()
	end

	local hasKeyword, hasMention = self:CheckForNotifications(senderName, insertedMessage)

	self:PushMessageToTextFloater(insertedMessage, hasKeyword, hasMention)

	self:NotifiyOverlayWindow(channelType)
end

function Client:OnChatAction(channelSource, eAction, strActor, strActedOn)
	for id, stream in ipairs(self.Streams) do
		for _, channelId in ipairs(stream.Channels) do
			-- segregated and aggregated the same because actions only happens on custom
			-- channels which are identified by ids
			if channelSource:GetUniqueId() == channelId then
				local actor   = stream:GetMember(strActor)
				local actedOn = stream:GetMember(strActedOn)

				if actor and actedOn then
					if eAction == ChatSystemLib.ChatChannelAction_PassOwner then
						actor.IsChannelOwner   = false
						actor.IsModerator      = true -- old owner seems to get automod rights
						actedOn.IsChannelOwner = true
					end

					if eAction == ChatSystemLib.ChatChannelAction_AddModerator then
						actedOn.IsModerator = true
					end

					if eAction == ChatSystemLib.ChatChannelAction_RemoveModerator then
						actedOn.IsModerator = false 
					end

					if eAction == ChatSystemLib.ChatChannelAction_Muted then
						actedOn.IsMuted = true 
					end

					if eAction == ChatSystemLib.ChatChannelAction_Unmuted then
						actedOn.IsMuted = false 
					end

					if eAction == ChatSystemLib.ChatChannelAction_Kicked then
						stream:RemoveMember(strActedOn)
					end
				end
			end
		end
	end

	-- Fixme:
	-- Only regenerate roster for selected stream/window
	self:GenerateChatWindowsTabs()
	self:GenerateChatWindowsRoster()

	-- If ChatLog is enabled then cut it short
	if self.ChatLogEnabled == true then
		return
	end

	-- Copy pasta from ChatLog code
	local strMessage = ""
	local strChanName = ""

	if channelSource == nil or channelSource:GetName() == "" then
		strChanName = Apollo.GetString("Unknown_Unit")
	else
		strChanName = channelSource:GetName()
	end

	if Consts.ktChatActionOutputStrings[eAction] then
		strMessage = String_GetWeaselString(
			Consts.ktChatActionOutputStrings[eAction],
			strChanName,
			strActor,
			strActedOn
		)
	else
		strMessage = String_GetWeaselString(
			Apollo.GetString("ChatLog_UndefinedMessage"),
			Apollo.GetString("CombatFloaterType_Error"),
			eAction,
			strChanName
		)
	end

	if strMessage then
		ChatSystemLib.PostOnChannel(
			ChatSystemLib.ChatChannel_Command, 
			strMessage, 
			""
		)
	end
end

function Client:OnIncomingAccountWhisper(accountName, characterName, realmName)
	if not accountName 
	or type(accountName) ~= 'string'
	or accountName:len() == 0
	then
		return
	end

	--

	local streamName = "AWhisper::" .. accountName
	
	local stream = Jita:Yield("Stream")

	stream.Name         = streamName
	stream.DisplayName  = "@" .. accountName
	stream.Type         = self.EnumStreamsTypes.SEGREGATED
	stream.Channels     = { ChatSystemLib.ChatChannel_AccountWhisper }
	stream.Command      = "/AWhisper " .. accountName
	stream.CommandColor = ChatSystemLib.ChatChannel_AccountWhisper

	-- NickName will have different formatting to identify account friends
	local nickName = accountName .. " (" .. characterName .. "@" 
		.. realmName .. ")"

	local isCrossfaction = false
	
	local accountFriends = FriendshipLib.GetAccountList()

	for _, account in pairs(accountFriends) do
		if account.arCharacters ~= nil then
			for _, character in pairs(account.arCharacters) do
				if account.strCharacterName == accountName 
				and character.strCharacterName == characterName 
				then
					isCrossfaction = 
						not (character.nFactionId 
						== Jita.Player.Unit:GetFaction())
				end
			end
		end
	end

	self:AddStreamMember(stream, characterName, { 
		NickName = nickName, 
		IsCrossfaction = isCrossfaction 
	})

	self:AddStreamMember(stream, Jita.Player.Name)

	self:AddPlayerProfile(characterName)

	self:AddStream(stream)  
end

function Client:OnIncomingWhisper(characterName)
	if not characterName 
	or type(characterName) ~= 'string'
	or characterName:len() == 0
	then
		return
	end

	--

	local streamName = "Whisper::" .. characterName

	local stream = Jita:Yield("Stream")

	stream.Name         = streamName
	stream.DisplayName  = "@" .. characterName
	stream.Type         = self.EnumStreamsTypes.SEGREGATED
	stream.Channels     = { ChatSystemLib.ChatChannel_Whisper }
	stream.Command      = "/whisper " .. characterName
	stream.CommandColor = ChatSystemLib.ChatChannel_Whisper

	self:AddStreamMember(stream, characterName)
	self:AddStreamMember(stream, Jita.Player.Name)

	self:AddPlayerProfile(characterName)

	self:AddStream(stream)
end

function Client:OnEngageAccountWhisper(accountName, characterName, realmName)
--/- OnEngageAccountWhisper has same logic as OnIncomingAccountWhisper
--/- in addition we auto select the stream tab

	self:OnIncomingAccountWhisper(accountName, characterName, realmName)

	local streamName = "AWhisper::" .. accountName

	local stream = self:GetStream(streamName)

	if not stream then
		return
	end

	self:SelectChatTabOnMainChatWindow(streamName)
end

function Client:OnEngageWhisper(characterName)
--/- OnEngageWhisper has same logic as OnIncomingWhisper
--/- in addition we auto select the stream tab

	self:OnIncomingWhisper(characterName)

	local streamName = "Whisper::" .. characterName

	local stream = self:GetStream(streamName)

	if not stream then
		return
	end

	self:SelectChatTabOnMainChatWindow(streamName)
end

function Client:OnChatList(channel)
--/- process requested channel members

	if not channel then
		return
	end

	local channelName = channel:GetName()

	local stream = self:GetStream("Custom::" .. channelName)

	if not stream or stream.Ignored then
		return
	end

	local members = channel:GetMembers()

	if not members then
		return
	end

	local slang

	-- Keepme:
	-- if Jita.LibCRC32 and channelName then
		-- local crc = Jita.LibCRC32.Hash(string.lower(channelName))
		-- slang = Consts.ChatChannelsSlangs[crc]
	-- end

	stream.Members = {}

	for _, member in ipairs(members) do
		local name = member['strMemberName']

		local info = {}

		info.IsChannelOwner = member['bIsChannelOwner']
		info.IsModerator    = member['bIsModerator']
		info.IsMuted        = member['bIsMuted']

		self:AddStreamMember(stream, name, info)

		local profile = self:AddPlayerProfile(name)

		if profile and slang then
			profile.Slang = slang
		end
	end

	self:AddCurrentPlayerToStreamsMembers()

	stream.IsRequestingMembersList = false
end

function Client:OnReplyKeybind()
	if not self.LastWhisper
	or not self.LastWhisper.Stream
	or not self.LastWhisper.Channel
	or not self.LastWhisper.Command
	then
		return
	end

	self:SelectChatTabOnMainChatWindow(self.LastWhisper.Stream, { SetFocus = true })
end

function Client:OnChatResult(channelSender, eResult)
	-- Yield it to ChatLog if enabled
	if self.ChatLogEnabled == true then
		return
	end

	-- Copy pasta from ChatLog code
	local strMessage = Apollo.GetString("CombatFloaterType_Error")
	local strChanName = ""

	if channelSender == nil or channelSender:GetName() == "" then
		strChanName = Apollo.GetString("Unknown_Unit")
	else
		strChanName = channelSender:GetName()
	end

	if Consts.ktChatResultOutputStrings[eResult] then
		if eResult == ChatSystemLib.ChatChannelResult_NotInGroup
		and GroupLib.InGroup()
		and GroupLib.InInstance()
		then
			strMessage = Apollo.GetString("ChatLog_UseInstanceChannel")
		else
			strMessage = String_GetWeaselString(
				Consts.ktChatResultOutputStrings[eResult],
				strMessage,
				strChanName
			)
		end
	else
		strMessage = String_GetWeaselString(
			Apollo.GetString("ChatLog_UndefinedMessage"),
			strMessage,
			eResult,
			strChanName
		)
	end

	ChatSystemLib.PostOnChannel(
		ChatSystemLib.ChatChannel_Command,
		strMessage,
		""
	)
end

function Client:OnChatJoin(channelJoined)
	-- Yield it to ChatLog if enabled
	if self.ChatLogEnabled == false then
		ChatSystemLib.PostOnChannel(
			ChatSystemLib.ChatChannel_Command,
			String_GetWeaselString(
				Apollo.GetString("ChatLog_JoinChannel"),
				channelJoined:GetName()
			),
			"" 
		)
	end

	--

	-- because joining channels is asynchronous on server side, we need
	-- to ignore any delayed ChatJoin event when a character logs in.
	if Jita.Timestamp < 2 then
		return
	end

	self:AddChannelToAggregatedStreams(channelJoined)

	self:SyncPlayerStreams(false)

	--

	self:GenerateChatWindowsControls()
end

function Client:OnChatJoinResult(strChanName, eResult)
	-- Yield it to ChatLog if enabled
	if self.ChatLogEnabled == true then
		return
	end

	-- Copy pasta from ChatLog code
	local strMessage = Apollo.GetString("CombatFloaterType_Error")

	if strChanName == nil or strChanName == "" then
		strChanName = Apollo.GetString("Unknown_Unit")
	end

	if Consts.ktChatJoinOutputStrings[eResult] then
		strMessage = String_GetWeaselString(
			Consts.ktChatJoinOutputStrings[eResult], 
			strMessage, 
			strChanName
		)
	else
		strMessage = String_GetWeaselString(
			Apollo.GetString("ChatLog_UndefinedMessage"), 
			strMessage, 
			eResult, 
			strChanName
		)
	end

	if strMessage then
		ChatSystemLib.PostOnChannel(
			ChatSystemLib.ChatChannel_Command,
			strMessage,
			""
		)
	end
end

function Client:OnChatLeave(channelLeft, bKicked, bBanned)
	-- Keepme:
	-- Because ChatLeave auto fires for some channels (circles and guild it seems) before logging off a character,
	-- we need to know whether it's the case to save players channels correctly on our end.
	-- So these lines are skipped until I find a workaround 
	-- self:RemoveChannelFromAggregatedStreams(channelLeft)
	-- local channelStream = self:CloseStreamByChannel(channelLeft)
	-- if channelStream then
		-- self:RemoveStreamFromChatWindows(channelStream) 
	-- end

	-- Yield the rest to ChatLog if enabled
	if self.ChatLogEnabled == true then
		return
	end

	--

	if(bBanned) then
		ChatSystemLib.PostOnChannel(
			ChatSystemLib.ChatChannel_Command,
			String_GetWeaselString(
			Apollo.GetString("ChatLog_BannedFromChannel"),
			channelLeft:GetName()),
			""
		)
	elseif(bKicked) then
		ChatSystemLib.PostOnChannel(
			ChatSystemLib.ChatChannel_Command, 
			String_GetWeaselString(
			Apollo.GetString("ChatLog_KickedFromChannel"),
			channelLeft:GetName()), 
			""
		)
	else
		ChatSystemLib.PostOnChannel(
			ChatSystemLib.ChatChannel_Command,
			String_GetWeaselString(
			Apollo.GetString("ChatLog_LeftChannel"),
			channelLeft:GetName()),
			""
		)
	end
end

--
-- Events ported from ChatLog as it is. They do nothing of use, just spam chat with messages, .. well maybe few are actually important.
--

function Client:OnChatTellFailed(channel, strCharacterTo)
	-- Yield it to ChatLog if enabled
	if self.ChatLogEnabled == true then
		return
	end
	
	--

	local strMessage = String_GetWeaselString(
		Apollo.GetString("CRB_Whisper_Error"),
		Apollo.GetString("CombatFloaterType_Error"),
		strCharacterTo, Apollo.GetString("CRB_Whisper_Error_Reason")
	)

	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Command, strMessage, "")
end

function Client:OnChatAccountTellFailed(channel, strCharacterTo)
	-- Yield it to ChatLog if enabled
	if self.ChatLogEnabled == true then
		return
	end
	
	--

	local strMessage = String_GetWeaselString(
		Apollo.GetString("CRB_Whisper_Error"),
		Apollo.GetString("CombatFloaterType_Error"),
		strCharacterTo, Apollo.GetString("CRB_Account_Whisper_Error_Reason")
	)

	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Command, strMessage, "")
end

function Client:OnAccountSupportTicketResult(channelSource, bSuccess)
	-- Yield it to ChatLog if enabled
	if self.ChatLogEnabled == true then
		return
	end

	--

	if(bSuccess) then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_System, Apollo.GetString("PlayerTicket_TicketSent"), "")
	else
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_System, Apollo.GetString("PlayerTicket_TicketFailed"), "")
	end
end

function Client:OnGenericEvent_LootChannelMessage(strMessage)	
	-- Yield it to ChatLog if enabled
	if self.ChatLogEnabled == true then
		return
	end

	--

	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Loot, strMessage, "")
end

function Client:OnGenericEvent_SystemChannelMessage(strMessage)
	-- Yield it to ChatLog if enabled
	if self.ChatLogEnabled == true then
		return
	end

	--

	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_System, strMessage, "")
end

function Client:OnLuaChatLogMessage(strArgMessage, tArgFlags)
	-- Yield it to ChatLog if enabled
	if self.ChatLogEnabled == true then
		return
	end

	--

	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Debug, strArgMessage, "")
end

function Client:OnPlayedtime(strCreationDate, strPlayedTime, strPlayedLevelTime, strPlayedSessionTime, dateCreation, nSecondsPlayed, nSecondsLevel, nSecondsSession)
	-- Yield it to ChatLog if enabled
	if self.ChatLogEnabled == true then
		return
	end

	--

	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_System, strCreationDate, "")
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_System, strPlayedTime, "")
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_System, strPlayedLevelTime, "")
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_System, strPlayedSessionTime, "")
end

function Client:OnItemSentToCrate(itemSentToCrate, nCount)
	-- Yield it to ChatLog if enabled
	if self.ChatLogEnabled == true then
		return
	end

	if Jita.UserSettings.EnableLootFilter == true then
		return
	end

	--

	if itemSentToCrate == nil or nCount == 0 then
		return
	end
	local tFlags = {ChatFlags_Loot=true}
	local strMessage = String_GetWeaselString(Apollo.GetString("ChatLog_ToHousingCrate"), {["count"] = nCount, ["name"] = itemSentToCrate:GetName()})
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Loot, strMessage, "")
end

function Client:OnHarvestItemsSentToOwner(arSentToOwner)
	-- Yield it to ChatLog if enabled
	if self.ChatLogEnabled == true then
		return
	end

	if Jita.UserSettings.EnableLootFilter == true then
		return
	end

	--

	for _, tSent in ipairs(arSentToOwner) do
		if tSent.item then
			local strMessage = String_GetWeaselString(Apollo.GetString("Housing_HarvestingLoot"), {["count"] = tSent.nCount, ["name"] = tSent.item:GetName()})
			ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Loot, strMessage, "")
		end
	end
end

function Client:OnChannelUpdate_Loot(eType, tEventArgs)
	-- Yield it to ChatLog if enabled
	if self.ChatLogEnabled == true then
		return
	end

	--

	local strResult = nil
	
	if eType == GameLib.ChannelUpdateLootType.Currency and tEventArgs.monNew then

		if tEventArgs.monNew:GetAccountCurrencyType() == AccountItemLib.CodeEnumAccountCurrency.Omnibits then
			local tOmniBitInfo = GameLib.GetOmnibitsBonusInfo()

			if tOmniBitInfo then
				-- Keepme:
				-- Commented line below was a never reached instruction on ChatLog. It seems like it was meant to show extra info on Omnibits drops, however the arguments used here ain't valid (exp tEventArgs.nBonusAmount no longer exist) which I simply set to ZERO just to make things work.
				-- strResult = String_GetWeaselString(Apollo.GetString("ChatLog_OmniBits_Gained"), tEventArgs.nOmnibitsGained, tEventArgs.nBonusAmount, tOmniBitInfo.nWeeklyBonusEarned, tOmniBitInfo.nWeeklyBonusTotal)

				strResult = String_GetWeaselString(Apollo.GetString("ChatLog_OmniBits_Gained"), tEventArgs.monNew:GetAmount(), 0, tOmniBitInfo.nWeeklyBonusEarned, tOmniBitInfo.nWeeklyBonusMax)
			else
				strResult = String_GetWeaselString(Apollo.GetString("CombatLog_LootReceived"), tEventArgs.monNew:GetMoneyString())
			end
		else
			strResult = String_GetWeaselString(Apollo.GetString("CombatLog_LootReceived"), tEventArgs.monNew:GetMoneyString())

			--

			if Jita.UserSettings.EnableLootFilter == true
			and tEventArgs.monNew:GetAmount() < Jita.UserSettings.LootFilter_MinCoppers
			then
				strResult = nil
			end
		end

	elseif eType == GameLib.ChannelUpdateLootType.Item and tEventArgs.itemNew then

		local strItem = tEventArgs.itemNew:GetChatLinkString()
		if tEventArgs.nCount > 1 then
			strItem = String_GetWeaselString(Apollo.GetString("CombatLog_MultiItem"), tEventArgs.nCount, strItem)
		end
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_LootReceived"), strItem)

		--

		if Jita.UserSettings.EnableLootFilter == true
		and tEventArgs.itemNew:GetItemQuality() < Jita.UserSettings.LootFilter_MinQuality
		then
			strResult = nil
		end

	elseif eType == GameLib.ChannelUpdateLootType.ItemDestroy and tEventArgs.itemDestroyed then

		strResult = String_GetWeaselString(Apollo.GetString("ChatLog_DestroyItem"), tEventArgs.itemDestroyed:GetChatLinkString())

		--

		if Jita.UserSettings.EnableLootFilter == true
		and tEventArgs.itemDestroyed:GetItemQuality() < Jita.UserSettings.LootFilter_MinQuality
		then
			strResult = nil
		end

	end

	if strResult ~= nil then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Loot, strResult, "")
	end
end

function Client:OnChannelUpdate_Crafting(eType, tEventArgs)
	-- Yield it to ChatLog if enabled
	if self.ChatLogEnabled == true then
		return
	end

	if Jita.UserSettings.EnableLootFilter == true
	and tEventArgs.itemNew:GetItemQuality() < Jita.UserSettings.LootFilter_MinQuality
	then
		return
	end

	--

	local strResult = nil

	if eType == GameLib.ChannelUpdateCraftingType.Item and tEventArgs.itemNew then
		strResult = String_GetWeaselString(Apollo.GetString("ChatLog_CraftItem"), tEventArgs.itemNew:GetChatLinkString())
	end

	--

	if strResult ~= nil then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Loot, strResult, "")
	end
end

function Client:OnChannelUpdate_Progress(eType, tEventArgs)
	-- Yield it to ChatLog if enabled
	if self.ChatLogEnabled == true then
		return
	end

	if Jita.UserSettings.EnableLootFilter == true then
		return
	end

	--

	local strResult = nil

	if eType == GameLib.ChannelUpdateProgressType.RewardPoints and tEventArgs.rtCurr then
		if tEventArgs.rtCurr:GetType() == RewardTrackLib.CodeEnumRewardTrackType.Challenge then
			strResult = String_GetWeaselString(Apollo.GetString("ChatLog_Progress_Challenge"), tEventArgs.rtCurr:GetName(), tEventArgs.nGain)
		end
	elseif eType == GameLib.ChannelUpdateProgressType.Experience then
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_XPGain"), tEventArgs.nGain)
	elseif eType == GameLib.ChannelUpdateProgressType.RestExperience then
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_RestXPGain"), tEventArgs.nGain)
	elseif eType == GameLib.ChannelUpdateProgressType.ElderPoints then
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_ElderPointsGained"), tEventArgs.nGain)
	elseif eType == GameLib.ChannelUpdateProgressType.RestElderPoints then
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_RestEPGain"), tEventArgs.nGain)
	elseif eType == GameLib.ChannelUpdateProgressType.SignatureExperience then
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_SignatureXPGain"), tEventArgs.nGain)
	elseif eType == GameLib.ChannelUpdateProgressType.SignatureElderPoints then
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_SignatureEPGain"), tEventArgs.nGain)
	end
	
	if strResult ~= nil then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Loot, strResult, "")
	end
end

function Client:OnTradeSkillSigilResult(eResult)
	-- Yield it to ChatLog if enabled
	if self.ChatLogEnabled == true then
		return
	end

	if Jita.UserSettings.EnableLootFilter == true then
		return
	end

	--

	local tEnumTable = CraftingLib.CodeEnumTradeskillResult
	local kstrTradeskillResultTable =
	{
		[tEnumTable.Success] = Apollo.GetString("EngravingStation_Success"),
		[tEnumTable.InsufficentFund] = Apollo.GetString("EngravingStation_NeedMoreMoney"),
		[tEnumTable.InvalidItem] = Apollo.GetString("EngravingStation_InvalidItem"),
		[tEnumTable.InvalidSlot] = Apollo.GetString("EngravingStation_InvalidSlot"),
		[tEnumTable.MissingEngravingStation] = Apollo.GetString("EngravingStation_StationTooFar"),
		[tEnumTable.Unlocked] = Apollo.GetString("EngravingStation_UnlockSuccessfull"),
		[tEnumTable.UnknownError] = Apollo.GetString("EngravingStation_Failure"),
		[tEnumTable.RuneExists] = Apollo.GetString("EngravingStation_ExistingRune"),
		[tEnumTable.MissingRune] = Apollo.GetString("EngravingStation_RuneMissing"),
		[tEnumTable.DuplicateRune] = Apollo.GetString("EngravingStation_DuplicateRune"),
		[tEnumTable.AttemptFailed] = Apollo.GetString("EngravingStation_Failure"),
		[tEnumTable.RuneSlotLimit] = Apollo.GetString("EngravingStation_SlotLimitReached"),
	}

	Event_FireGenericEvent("GenericEvent_LootChannelMessage", kstrTradeskillResultTable[eResult])
end

function Client:OnAccountCurrencyChanged()
	-- Yield it to ChatLog if enabled
	if self.ChatLogEnabled == true then
		return
	end

	--

	if self.tAccountCurrencyValues == nil then
		return
	end

	local ePremiumCurrency = AccountItemLib.GetPremiumCurrency()
	local nNCoinAmount = AccountItemLib.GetAccountCurrency(ePremiumCurrency):GetAmount()
	local nOldNCoinAmount = self.tAccountCurrencyValues[ePremiumCurrency]
	
	if nOldNCoinAmount >= nNCoinAmount then
		return
	end

	self.tAccountCurrencyValues[ePremiumCurrency] = nNCoinAmount

	local tNotifications = self.ktAccountCurrencyIncreased[ePremiumCurrency]
	if tNotifications == nil then
		return
	end

	if tNotifications.strChatMessage ~= nil then
		local nDifference = nNCoinAmount - nOldNCoinAmount
		
		local monTemp = Money.new()
		monTemp:SetAccountCurrencyType(ePremiumCurrency)
		monTemp:SetAmount(nDifference)
		
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_System, String_GetWeaselString(Apollo.GetString(tNotifications.strChatMessage), monTemp:GetMoneyString()), "")
	end

	if tNotifications.eSound ~= nil then
		Sound.Play(tNotifications.eSound)
	end
end

--
--
--

function Client:SetConsoleVariables()
--/- Utility to set chat related vars
--/- May require reloadui for some reason

	Apollo.SetConsoleVariable(
		"chat.filter",
		Jita.UserSettings.ChatWindow_MessageFilterProfanity
	)
end

function Client:SuppressChatLog()
	if Jita.UserSettings.AutoHideChatLogWindows == true then
		local chatLogWindow = Apollo.FindWindowByName("ChatWindow")

		if chatLogWindow and chatLogWindow:IsShown() then
			chatLogWindow:Show(false)
		end
	end

	local ChatLog = Apollo.GetAddon("ChatLog")

	if ChatLog then
		-- ikr? I'll fix it, prolly.
		function ChatLog:OnChatList(channelSource)
			return nil
		end
	end
end
