--[[

   Logic borrowed from Lui_SpamFilter,
   Them thanks Andrej for code and so do I.

]]--

local Jita = Apollo.GetAddon("Jita")
local ChatWindow = Jita:Extend("ChatWindow")

--

function ChatWindow:OnContextMenuPlayer(selectedMember, selectedStream)
	self.menu = Apollo.GetAddon("ContextMenuPlayer")

	if not self.menu then
		return
	end

	local stream = Jita.Client:GetStream(self.SelectedStream)

	local currentPlayer = stream:GetMember(Jita.Player.Name)

	-- because some times shit happens
	if not currentPlayer then 
		currentPlayer = { 
			Name = Jita.Player.Name,
			IsChannelOwner = false,
			IsModerator = false,
		}
	end

	if currentPlayer.Name == selectedMember.Name then
		return
	end

	self.ContextMenuPlayerMutex      = 1
	self.ContextMenuPlayerMemberData = selectedMember
	self.ContextMenuPlayerSelfData   = currentPlayer
	self.ContextMenuPlayerStreamName = selectedStream

	-- Add an extra button to the player context menu
	local oldRedrawAll = self.menu.RedrawAll

	self.menu.RedrawAll = function(context)
		if (self.menu.unitTarget == nil or self.menu.unitTarget ~= GameLib.GetPlayerUnit()) then
			if self.menu.wndMain ~= nil then
				if self.ContextMenuPlayerMutex and self.ContextMenuPlayerMutex == 1 then
					local wndButtonList = self.menu.wndMain:FindChild("ButtonList")

					if wndButtonList ~= nil then
						-- profile
						local BtnJitaViewProfile = Apollo.LoadForm(self.menu.xmlDoc, "BtnRegularContainer", wndButtonList, self.menu)
						BtnJitaViewProfile:SetData("BtnJitaViewProfile")
						BtnJitaViewProfile:FindChild("BtnText"):SetText("View Profile")

						-- mod options
						if self.ContextMenuPlayerSelfData
						and (self.ContextMenuPlayerSelfData.IsChannelOwner == true or self.ContextMenuPlayerSelfData.IsModerator == true)
						then
							local BtnJitaChanModPassOwner = Apollo.LoadForm(self.menu.xmlDoc, "BtnRegularContainer", wndButtonList, self.menu)
							BtnJitaChanModPassOwner:SetData("BtnJitaChanModPassOwner")
							BtnJitaChanModPassOwner:FindChild("BtnText"):SetText("Pass Ownership")

							local BtnJitaChanModSetModerator = Apollo.LoadForm(self.menu.xmlDoc, "BtnRegularContainer", wndButtonList, self.menu)
							BtnJitaChanModSetModerator:SetData("BtnJitaChanModSetModerator")
							BtnJitaChanModSetModerator:FindChild("BtnText"):SetText("Set Moderator")

							local BtnJitaChanModRemoveModerator = Apollo.LoadForm(self.menu.xmlDoc, "BtnRegularContainer", wndButtonList, self.menu)
							BtnJitaChanModRemoveModerator:SetData("BtnJitaChanModRemoveModerator")
							BtnJitaChanModRemoveModerator:FindChild("BtnText"):SetText("Remove Moderator")

							local BtnJitaChanModMute = Apollo.LoadForm(self.menu.xmlDoc, "BtnRegularContainer", wndButtonList, self.menu)
							BtnJitaChanModMute:SetData("BtnJitaChanModMute")
							BtnJitaChanModMute:FindChild("BtnText"):SetText("Mute Player")

							local BtnJitaChanModUnmute = Apollo.LoadForm(self.menu.xmlDoc, "BtnRegularContainer", wndButtonList, self.menu)
							BtnJitaChanModUnmute:SetData("BtnJitaChanModUnmute")
							BtnJitaChanModUnmute:FindChild("BtnText"):SetText("Unmute Player")

							local BtnJitaChanModKick = Apollo.LoadForm(self.menu.xmlDoc, "BtnRegularContainer", wndButtonList, self.menu)
							BtnJitaChanModKick:SetData("BtnJitaChanModKick")
							BtnJitaChanModKick:FindChild("BtnText"):SetText("Kick Player")
						end

						self.ContextMenuPlayerMutex = 2
					end
				end
			end
		end

		oldRedrawAll(context)
	end

	-- Add an extra button to the friend context menu
	local oldRedrawAllFriend = self.menu.RedrawAllFriend

	self.menu.RedrawAllFriend = function(context)
		if self.menu.wndMain ~= nil then
			if self.ContextMenuPlayerMutex and self.ContextMenuPlayerMutex == 1 then
				local wndButtonList = self.menu.wndMain:FindChild("ButtonList")

				if wndButtonList ~= nil then
					-- profile
					local BtnJitaViewProfile = Apollo.LoadForm(self.menu.xmlDoc, "BtnRegularContainer", wndButtonList, self.menu)
					BtnJitaViewProfile:SetData("BtnJitaViewProfile")
					BtnJitaViewProfile:FindChild("BtnText"):SetText("View Profile")

					-- mod options
					if self.ContextMenuPlayerSelfData
					and (self.ContextMenuPlayerSelfData.IsChannelOwner == true or self.ContextMenuPlayerSelfData.IsModerator == true)
					then
						local BtnJitaChanModPassOwner = Apollo.LoadForm(self.menu.xmlDoc, "BtnRegularContainer", wndButtonList, self.menu)
						BtnJitaChanModPassOwner:SetData("BtnJitaChanModPassOwner")
						BtnJitaChanModPassOwner:FindChild("BtnText"):SetText("Pass Ownership")

						local BtnJitaChanModSetModerator = Apollo.LoadForm(self.menu.xmlDoc, "BtnRegularContainer", wndButtonList, self.menu)
						BtnJitaChanModSetModerator:SetData("BtnJitaChanModSetModerator")
						BtnJitaChanModSetModerator:FindChild("BtnText"):SetText("Set Moderator")

						local BtnJitaChanModRemoveModerator = Apollo.LoadForm(self.menu.xmlDoc, "BtnRegularContainer", wndButtonList, self.menu)
						BtnJitaChanModRemoveModerator:SetData("BtnJitaChanModRemoveModerator")
						BtnJitaChanModRemoveModerator:FindChild("BtnText"):SetText("Remove Moderator")

						local BtnJitaChanModMute = Apollo.LoadForm(self.menu.xmlDoc, "BtnRegularContainer", wndButtonList, self.menu)
						BtnJitaChanModMute:SetData("BtnJitaChanModMute")
						BtnJitaChanModMute:FindChild("BtnText"):SetText("Mute Player")

						local BtnJitaChanModUnmute = Apollo.LoadForm(self.menu.xmlDoc, "BtnRegularContainer", wndButtonList, self.menu)
						BtnJitaChanModUnmute:SetData("BtnJitaChanModUnmute")
						BtnJitaChanModUnmute:FindChild("BtnText"):SetText("Unmute Player")

						local BtnJitaChanModKick = Apollo.LoadForm(self.menu.xmlDoc, "BtnRegularContainer", wndButtonList, self.menu)
						BtnJitaChanModKick:SetData("BtnJitaChanModKick")
						BtnJitaChanModKick:FindChild("BtnText"):SetText("Kick Player")
					end
				end

				self.ContextMenuPlayerMutex = 2
			end
		end

		oldRedrawAllFriend(context)
	end

	-- catch the event fired when the player clicks the context menu
	local oldContextClick = self.menu.ProcessContextClick

	self.menu.ProcessContextClick = function(context, eButtonType)
		-- profile
		if eButtonType == "BtnJitaViewProfile" then
			if self.ContextMenuPlayerMutex and self.ContextMenuPlayerMutex == 2 then
				if Jita and Jita.WindowManager then
					if Jita.WindowManager:LoadWindow("ProfileWindow") then
						Jita.WindowManager:GetWindow("ProfileWindow"):ShowCharacterProfile(self.ContextMenuPlayerMemberData)
					end
				end
	
				self.ContextMenuPlayerMutex = 0
			end

		-- mod options
		elseif eButtonType == "BtnJitaChanModPassOwner"
		or eButtonType     == "BtnJitaChanModSetModerator"
		or eButtonType     == "BtnJitaChanModRemoveModerator"
		or eButtonType     == "BtnJitaChanModMute"
		or eButtonType     == "BtnJitaChanModUnmute"
		or eButtonType     == "BtnJitaChanModKick"
		then
			if self.ContextMenuPlayerMutex and self.ContextMenuPlayerMutex == 2 then
				local action = string.gsub(eButtonType, "BtnJitaChanMod", "")

				self:StreamModAction(self.ContextMenuPlayerStreamName, action, self.ContextMenuPlayerMemberData.Name)

				self.ContextMenuPlayerMutex = 0
			end  

		-- inherit
		else
			oldContextClick(context, eButtonType)
		end
	end
end

function ChatWindow:StreamModAction(streamName, action, member)
	if self.ConfirmForm and self.ConfirmForm:IsValid() then
		self.ConfirmForm:Close()
		self.ConfirmForm:Destroy()
	end

	self.ConfirmForm = Apollo.LoadForm(Jita.XmlDoc, "JCC_ConfirmWindow", nil, self) 

	self.ConfirmForm:FindChild("TitleText"):SetText("Are your sure you want to execute this command?")
	self.ConfirmForm:FindChild("BodyText"):SetText(action .. " \"" ..  member .. "\" on " .. self:NormalizeChatTabName(streamName, true))

	local data = {
		StreamName = streamName,
		MemberName = member,
		Action     = action,
	}

	self.ConfirmForm:FindChild("YesButton"):SetData(data)

	self.ConfirmForm:Show(true, true)
end

function ChatWindow:OnConfirmYesButton(wndHandler, wndControl)
	local data = wndControl:GetData()

	if not data then
		return
	end

	if self.ConfirmForm and self.ConfirmForm:IsValid() then
		self.ConfirmForm:Close()
		self.ConfirmForm:Destroy()
	end

	Jita.Client:DoChatAction(data.StreamName, data.MemberName, data.Action)
end

function ChatWindow:OnConfirmNoButton(wndHandler, wndControl)
	if self.ConfirmForm and self.ConfirmForm:IsValid() then
		self.ConfirmForm:Close()
		self.ConfirmForm:Destroy()
	end
end
