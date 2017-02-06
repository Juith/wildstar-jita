local Jita = Apollo.GetAddon("Jita")
local ChatWindow = Jita:Extend("ChatWindow")

--

function ChatWindow:GenerateRoster()
	if not self.ShowRoster then
		return
	end

	self.MainForm:FindChild("RosterIcoLoading"):Show(false)
	self.MainForm:FindChild("RosterIcoLoading"):SetTooltip("")

	self.MainForm:FindChild("RosterIcoLocked"):Show(false)
	self.MainForm:FindChild("RosterIcoLocked"):SetTooltip("")

	self.MainForm:FindChild("RosterIcoTruncated"):Show(false)
	self.MainForm:FindChild("RosterIcoTruncated"):SetTooltip("")

	local unitPlayer     = Jita.Player.Unit
	local friendList     = FriendshipLib.GetList() or {}
	local accountFriends = FriendshipLib.GetAccountList() or {}

	local vScrollPos = self.RosterPane:GetVScrollPos()

	self.RosterPane:DestroyChildren()
	self.RosterPane:SetVScrollPos(0)

	local stream = Jita.Client:GetStream(self.SelectedStream)

	if not stream then
		return
	end

	table.sort(stream.Members, function(a, b) return a.Name < b.Name end)

	-- lazy way to sort table, eh?
	local count = 0
	for _, member in ipairs(stream.Members) do
		if member.IsChannelOwner then
			self:GenerateRosterMemberButton(member, friendList, accountFriends)
			count = count + 1
		end
	end
	for _, member in ipairs(stream.Members) do
		if member.IsModerator then
			self:GenerateRosterMemberButton(member, friendList, accountFriends)
			count = count + 1
		end
	end
	for _, member in ipairs(stream.Members) do
		if not member.IsChannelOwner and not member.IsModerator and count <= Jita.UserSettings.ChatWindow_MaxChatMembers then
			self:GenerateRosterMemberButton(member, friendList, accountFriends)
			count = count + 1
		end
	end

	if #stream.Members > Jita.UserSettings.ChatWindow_MaxChatMembers then
		self.MainForm:FindChild("RosterIcoTruncated"):Show(true)
		self.MainForm:FindChild("RosterIcoTruncated"):SetTooltip("Only " .. Jita.UserSettings.ChatWindow_MaxChatMembers
			.. " out of " .. #stream.Members .. " players are shown. You may increase this limit on the advanced chat"
			.. " options and settings")

	elseif not stream.CanRequestMembersList then
		self.MainForm:FindChild("RosterIcoLocked"):Show(true)
		self.MainForm:FindChild("RosterIcoLocked"):SetTooltip("Jita doesn't have permission to retrieve"
			.. " the players list for this stream. Roster will be generated based on activity instead.")

	elseif #stream.Members == 0 then
		self.MainForm:FindChild("RosterIcoLoading"):Show(true)
		self.MainForm:FindChild("RosterIcoLoading"):SetTooltip("Retrieving players list.")
	end

	-- laziness.
	if #stream.Channels == 1
	and (stream.Channels[1] == ChatSystemLib.ChatChannel_Whisper
	or stream.Channels[1] == ChatSystemLib.ChatChannel_AccountWhisper
	or stream.Channels[1] == ChatSystemLib.ChatChannel_GuildOfficer)
	then
		self.MainForm:FindChild("RosterIcoLoading"):Show(false)
		self.MainForm:FindChild("RosterIcoTruncated"):Show(false)

		self.MainForm:FindChild("RosterIcoLocked"):Show(true)
		self.MainForm:FindChild("RosterIcoLocked"):SetTooltip("")
	end

	self:ArrangeRosterPane(self.RosterPane, vScrollPos)
end

function ChatWindow:GenerateRosterMemberButton(member, friendList, accountFriends, groupMembers)
end

function ChatWindow:GenerateRosterMemberButton(member, friendList, accountFriends, groupMembers)
	if not member then
		return
	end

	--

	local profile = Jita.Client:GetPlayerProfile(member.Name)

	-- probably was removed due to reaching max profiles cap,
	-- selected stream users gets priority, so we push it again
	if not profile then
		profile = Jita.Client:AddPlayerProfile(member.Name)
	end

	friendList     = friendList or {}
	accountFriends = accountFriends or {}

	local strColor = "ChatPlayerName"
	local nickname = member.NickName or member.Name
	local toolTipText = nickname .. "\n"

	if member.IsCrossfaction == true then
		strColor = "ChatPlayerNameHostile" 

		toolTipText = toolTipText .. "Hostile Faction\n"
	end

	if member.IsMuted == true then
		strColor = "darkgray"
		
		toolTipText = toolTipText .. "Muted\n"
	end

	if member.IsModerator == true then
		strColor = "xkcdFrogGreen" 
		
		toolTipText = toolTipText .. "Moderator\n"
	end

	if member.IsChannelOwner == true then 
		strColor = "xkcdGolden"
		
		toolTipText = toolTipText .. "Channel Owner\n"
	end

	if profile and profile.Slang then
		strColor = tostring(profile.Slang)
	end

	nickname = string.sub(nickname, 1,  20)

	local button = Apollo.LoadForm(Jita.XmlDoc, 'RosterLineControl', self.RosterPane, self)

	if not button then
		return
	end

	local buttonPlayerName       = button:FindChild('PlayerName')
	local buttonPlayerIcon       = button:FindChild('PlayerIcon')
	local buttonPlayerNearbyIcon = button:FindChild('PlayerNearbyIcon')

	if not buttonPlayerName or not buttonPlayerIcon or not buttonPlayerNearbyIcon then
		return
	end

	buttonPlayerIcon:SetSprite('')
	buttonPlayerIcon:Show(false)
	buttonPlayerNearbyIcon:Show(false)

	buttonPlayerName:SetAML("<P TextColor=\"" .. strColor .. "\">" .. nickname .. "</P>")

	local isInFriendList = false

	for _, player in pairs(friendList) do
		if player.strCharacterName == member.Name then
			if player.bFriend then
				buttonPlayerIcon:SetSprite("IconSprites:Icon_Windows_UI_CRB_Friend")
				buttonPlayerIcon:Show(true)
				toolTipText = toolTipText .. "Friend\n"

			elseif player.bRival then
				buttonPlayerIcon:SetSprite("IconSprites:Icon_Windows_UI_CRB_Rival")
				buttonPlayerIcon:Show(true)
				toolTipText = toolTipText .. "Rival\n"

			elseif player.bIgnore then
				buttonPlayerIcon:SetSprite("BK3:UI_BK3_StoryPanelAlert_Icon")
				buttonPlayerIcon:Show(true)
				toolTipText = toolTipText .. "Ignored\n"
			end

			isInFriendList = true
		end
	end

	for _, account in pairs(accountFriends) do
		if account.arCharacters ~= nil then
			for _, character in pairs(account.arCharacters) do
				local strCharacterName = account.strCharacterName .. " (" .. character.strCharacterName .. "@" .. character.strRealm .. ")"

				if strCharacterName == member.Name or member.Name == character.strCharacterName then
					buttonPlayerIcon:SetSprite("IconSprites:Icon_Windows_UI_CRB_Friend")
					buttonPlayerIcon:Show(true)
					toolTipText = toolTipText .. "Account Friend\n"

					isInFriendList = true
				end
			end
		end
	end

	local isInGroupMembers = false

	if Jita.Player.Name ~= member.Name then
		if Jita.Client.PartyPlayers[member.Name] then
			buttonPlayerIcon:SetSprite("achievements:sprAchievements_Icon_Group")
			buttonPlayerIcon:Show(true)
			toolTipText = toolTipText .. "In Group\n"

			isInGroupMembers = true
		end

		if Jita.Client.LocalPlayers[member.Name] ~= nil then
			if not isInFriendList and not isInGroupMembers then
				buttonPlayerNearbyIcon:Show(true)
			end

			toolTipText = toolTipText .. "Has Been Seen Nearby\n"
		end

		if Jita.Client.PrivateNotes[member.Name] ~= nil then
			if not isInFriendList and not isInGroupMembers then
				buttonPlayerIcon:SetSprite("IconSprites:Icon_Mission_Scientist_ScanMineral")
				buttonPlayerIcon:Show(true)
			end

			toolTipText = toolTipText .. "Has Private Notes\n"
		end
	end

	if profile and profile.ExternalBios then
		if not isInFriendList and not isInGroupMembers then
			buttonPlayerIcon:SetSprite("IconSprites:Icon_Mission_Scientist_ScanMineral")
			buttonPlayerIcon:Show(true)
		end

		if profile.ExternalBios.KRP then
			toolTipText = toolTipText .. "Has a Listed KRP Plot\n"
		end

		if profile.ExternalBios.TIM then
			toolTipText = toolTipText .. "Has \"This Is Me' Biography\n"
		end
	end

	if profile and profile.JitaUser == true then
		if not isInFriendList and not isInGroupMembers then
			buttonPlayerIcon:SetSprite("BK3:sprHolo_Friends_Single")
			buttonPlayerIcon:Show(true)
		end

		toolTipText = toolTipText .. "Jita User\n"
	end

	button:SetTooltip(toolTipText)

	button:SetData(member)
end

function ChatWindow:OnRosterMemberButtonClick(wndHandler, wndControl, eMouseButton)
	local LeftButton   = eMouseButton == GameLib.CodeEnumInputMouse.Left
	local MiddleButton = eMouseButton == GameLib.CodeEnumInputMouse.Middle
	local RightButton  = eMouseButton == GameLib.CodeEnumInputMouse.Right

	local selectedMember = wndControl:GetData()

	if not selectedMember then 
		return
	end

	if LeftButton then 
		if not Jita.UserSettings.ChatWindow_RosterLeftClickInfo then
			return
		end

		Jita.WindowManager:LoadWindow("ProfileWindow"):ShowCharacterProfile(selectedMember)
	elseif MiddleButton then 
		local unit = GameLib.GetPlayerUnitByName(selectedMember.Name)
		
		if unit ~= nil then
			unit:ShowHintArrow()
		end
	elseif RightButton then
		self:OnContextMenuPlayer(selectedMember, self.SelectedStream)

		if selectedMember.IsCrossfaction == true then
			Event_FireGenericEvent("GenericEvent_NewContextMenuPlayer", wndHandler, selectedMember.Name, nil, { bCrossFaction = "true" })
		else
			Event_FireGenericEvent("GenericEvent_NewContextMenuPlayer", wndHandler, selectedMember.Name, nil, {})
		end
	end
end

function ChatWindow:ArrangeRosterPane(wndRosterList, vScrollPos) 
	if not wndRosterList then
		return
	end

	wndRosterList:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)

	if vScrollPos then
		wndRosterList:SetVScrollPos(vScrollPos)
	end
end

function ChatWindow:SetRosterVisibility()
	local nLeft, nTop, nRight, nBottom = self.ChatMessagesContainer:GetAnchorOffsets()
	
	if self.ShowRoster == true then
		self.ChatMessagesContainer:SetAnchorOffsets(nLeft, nTop, -169, nBottom)
	else
		self.ChatMessagesContainer:SetAnchorOffsets(nLeft, nTop, -6, nBottom)
	end

	self.RosterContainer:Show(self.ShowRoster)

	if self.StreamType then
		self:GenerateChatMessagesPane()
	end

	self:GenerateRoster()
end

function ChatWindow:ToggleRosterVisible()
	local nLeft, nTop, nRight, nBottom = self.ChatMessagesContainer:GetAnchorOffsets()
	self.ChatMessagesContainer:SetAnchorOffsets(nLeft, nTop, -6, nBottom)

	self.RosterContainer:Show(false)
end

function ChatWindow:ToggleRosterHidden()
	local nLeft, nTop, nRight, nBottom = self.ChatMessagesContainer:GetAnchorOffsets()
	self.ChatMessagesContainer:SetAnchorOffsets(nLeft, nTop, -169, nBottom)

	self.RosterContainer:Show(false)
end
