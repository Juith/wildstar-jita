local Jita = Apollo.GetAddon("Jita")
local ChatWindow = Jita:Extend("ChatWindow")

local Utils = Jita.Utils
local Consts = Jita.Consts

--

function ChatWindow:GenerateSidebar()
	local stream = Jita.Client:GetStream(self.SelectedStream)

	if not stream then
		return
	end

	if stream.Closeable then
		self.MainForm:FindChild("CloseChatTabButton"):Enable(true)
		self.MainForm:FindChild("CloseAndIgnoreChatTabButton"):Enable(true)

		self.MainForm:FindChild("CloseChatTabButton"):SetTooltip("Close current chat")
		self.MainForm:FindChild("CloseAndIgnoreChatTabButton"):SetTooltip("Close current tab and ignore any incoming new messages.")
	else
		self.MainForm:FindChild("CloseChatTabButton"):Enable(false)
		self.MainForm:FindChild("CloseAndIgnoreChatTabButton"):Enable(false)

		self.MainForm:FindChild("CloseChatTabButton"):SetTooltip("Default chat tab is not closable.")
		self.MainForm:FindChild("CloseAndIgnoreChatTabButton"):SetTooltip("Default chat tab is not closable.")
	end

	self.SidebarStreamsListPane:DestroyChildren() 

	for id, data in ipairs(Jita.Client.Streams) do
		self:GenerateChatTabButton(data, { Wnd = self.SidebarStreamsListPane, Align = "Left", Untruncated = true })
	end

	for _, button in ipairs(self.SidebarStreamsListPane:GetChildren()) do  
		local name = button:GetData()

		if name then
			local nLeft, nTop, nRight, nBottom = button:GetAnchorOffsets()
	 
			local nw = 210

			button:SetAnchorOffsets(nLeft, nTop, nw, nBottom)

			local buttonBG = button:FindChild("Background")
			
			if buttonBG then
				buttonBG:SetAnchorOffsets(nLeft, nTop, nw, nBottom)
			end
		end 
	end 

	self.SidebarStreamsListPane:ArrangeChildrenVert(0)
	self.SidebarStreamsListPane:SetVScrollPos(0)
	
	--

	self.SidebarContainer:FindChild("SidebarBackground"):Show(true)

	if self.StreamType == Jita.Client.EnumStreamsTypes.AGGREGATED then
		self.ChannelsSelectorListPane:DestroyChildren() 
		
		local userChannels = ChatSystemLib.GetChannels()

		for _, uChannel in ipairs(userChannels) do
			if  uChannel:GetType() ~= ChatSystemLib.ChatChannel_Combat then
				local button = Apollo.LoadForm(Jita.XmlDoc, "ChannelSelectorControl", self.ChannelsSelectorListPane, self)

				button:FindChild("CheckButton"):SetData(uChannel:GetType() .. "::" .. uChannel:GetName())
				button:FindChild("ChannelName"):SetText(uChannel:GetName())

				for _, sChannelId in ipairs(stream.Channels) do
					if string.lower(uChannel:GetType() .. "::" .. uChannel:GetName()) == string.lower(sChannelId) then
						button:FindChild("CheckButton"):SetCheck(true)
					end
				end
			end
		end

		self.ChannelsSelectorListPane:ArrangeChildrenTiles(0)
		self.ChannelsSelectorListPane:SetVScrollPos(0)

		self.ChannelsSelectorContainer:Show(true)
	else
		self.ChannelsSelectorContainer:Show(false)

		if self.ShowRoster then
			self.RosterContainer:Show(false)

			self.SidebarContainer:FindChild("SidebarBackground"):Show(false)
		end
	end

	--

	self.SidebarContainer:Show(true)
end

function ChatWindow:HideSidebar()
	self.SidebarContainer:Show(false)
	self.ChannelsSelectorContainer:Show(false)

	if self.ShowRoster then
		self.RosterContainer:Show(true)
	end
end

--

function ChatWindow:OnQuickChatOptionsButtonClick()
	if self.SidebarContainer:IsShown() == true then
		self:HideSidebar()
		
		return
	end

	self:GenerateSidebar() 
end

--

function ChatWindow:OnShiftChatFontLeftButtonClick(wndHandler, wndControl)  
	if not self.MessageTextFontIndex then
		self.MessageTextFontIndex = Utils:KeyByVal(Consts.ChatMessagesFonts, self.MessageTextFont) or 1
	end

	self.MessageTextFontIndex = self.MessageTextFontIndex - 1

	if self.MessageTextFontIndex < 1 then self.MessageTextFontIndex = #Consts.ChatMessagesFonts end

	self.MessageTextFont = Consts.ChatMessagesFonts[self.MessageTextFontIndex]

	self.ChatInputEditBox:SetFont(self.MessageTextFont)

	for _, stream in ipairs(Jita.Client.Streams) do
		for _, message in ipairs(stream.Messages) do
			message.XmlObj = nil
		end
	end

	self:GenerateChatMessagesPane()
	self:ValidateChatInput()
end

function ChatWindow:OnShiftChatFontRightButtonClick(wndHandler, wndControl)
	if not self.MessageTextFontIndex then
		self.MessageTextFontIndex = Utils:KeyByVal(Consts.ChatMessagesFonts, self.MessageTextFont) or 1
	end

	self.MessageTextFontIndex = self.MessageTextFontIndex + 1

	if self.MessageTextFontIndex > #Consts.ChatMessagesFonts then self.MessageTextFontIndex = 1 end

	self.MessageTextFont = Consts.ChatMessagesFonts[self.MessageTextFontIndex]

	self.ChatInputEditBox:SetFont(self.MessageTextFont)

	for _, stream in ipairs(Jita.Client.Streams) do
		for _, message in ipairs(stream.Messages) do
			message.XmlObj = nil
		end
	end

	self:GenerateChatMessagesPane() 
	self:ValidateChatInput()
end

function ChatWindow:OnShowTranscriptButtonButtonClick()
	self:HideSidebar()

	Jita.WindowManager:LoadWindow("TranscriptWindow"):ShowStreamTranscript(self.SelectedStream)
end

function ChatWindow:OnMembersListButtonClick() 
	self:HideSidebar()

	self.ShowRoster = not self.ShowRoster

	self:SetRosterVisibility() 
end

function ChatWindow:OnCloneCurrentChatTabButtonClick()
	local clone = Jita.WindowManager:CloneChatWindow(self)

	if clone then
		clone.MainForm:Show(true, true)
	end

	self:HideSidebar() 
end

function ChatWindow:OnCloseChatTabButtonClick()
	local stream = Jita.Client:GetStream(self.SelectedStream)

	self:CloseChatTab(stream.Name)

	self:HideSidebar() 
end

function ChatWindow:OnCloseAndIgnoreChatTabButtonClick()
	local stream = Jita.Client:GetStream(self.SelectedStream)

	stream.Ignored = true

	self:CloseChatTab(stream.Name)
	
	self:HideSidebar() 
end

function ChatWindow:OnManageChannlesButtonClick()
	Jita.WindowManager:LoadWindow("ChannelsManagerWindow", { LoadForms = true})

	self:HideSidebar()
end

--

function ChatWindow:OnExpandChatTabListButtonClick()
--/- hard coded desu

	local epTop    = 0
	local epbottom = 28
	local elTop    = 28

	self.SidebarContainer:FindChild('SidebarPaddingFonts'):Show(false)
	self.SidebarContainer:FindChild('ShiftChatFontLeftButton'):Show(false)
	self.SidebarContainer:FindChild('ShiftChatFontRightButton'):Show(false)
	self.SidebarContainer:FindChild('ShowTranscriptButton'):Show(false)
	self.SidebarContainer:FindChild('MembersListButton'):Show(false)
	self.SidebarContainer:FindChild('CloseChatTabButton'):Show(false)
	self.SidebarContainer:FindChild('CloseAndIgnoreChatTabButton'):Show(false)
	self.SidebarContainer:FindChild('ManageChannlesButton'):Show(false)
	self.SidebarContainer:FindChild('AdvancedOptionsButton'):Show(false)

	local nLeft, nTop, nRight, nBottom = self.SidebarContainer:FindChild('SidebarPaddingStreams'):GetAnchorOffsets()
	self.SidebarContainer:FindChild('SidebarPaddingStreams'):SetAnchorOffsets(nLeft, epTop, nRight, epbottom)
	
	nLeft, nTop, nRight, nBottom = self.SidebarContainer:FindChild('SidebarStreamsListPane'):GetAnchorOffsets()
	self.SidebarContainer:FindChild('SidebarStreamsListPane'):SetAnchorOffsets(nLeft, elTop, nRight, nBottom)

	self.SidebarContainer:FindChild('ExpandChatTabListButton'):Show(false)
	self.SidebarContainer:FindChild('CollapseChatTabListButton'):Show(true)

	self.SidebarStreamsListPane:SetVScrollPos(0)
end

function ChatWindow:OnCollapseChatTabListButtonClick()
--/- hard coded desu

	local cpTop    = 180 -- 150
	local cpbottom = 204 -- 179
	local clTop    = 205 -- 180

	self.SidebarContainer:FindChild('SidebarPaddingFonts'):Show(true)
	self.SidebarContainer:FindChild('ShiftChatFontLeftButton'):Show(true)
	self.SidebarContainer:FindChild('ShiftChatFontRightButton'):Show(true)
	self.SidebarContainer:FindChild('ShowTranscriptButton'):Show(true)
	self.SidebarContainer:FindChild('MembersListButton'):Show(true)
	self.SidebarContainer:FindChild('CloseChatTabButton'):Show(true)
	self.SidebarContainer:FindChild('CloseAndIgnoreChatTabButton'):Show(true)
	self.SidebarContainer:FindChild('ManageChannlesButton'):Show(true)
	self.SidebarContainer:FindChild('AdvancedOptionsButton'):Show(true)

	local nLeft, nTop, nRight, nBottom = self.SidebarContainer:FindChild('SidebarPaddingStreams'):GetAnchorOffsets()
	self.SidebarContainer:FindChild('SidebarPaddingStreams'):SetAnchorOffsets(nLeft, cpTop, nRight, cpbottom)
	
	nLeft, nTop, nRight, nBottom = self.SidebarContainer:FindChild('SidebarStreamsListPane'):GetAnchorOffsets()
	self.SidebarContainer:FindChild('SidebarStreamsListPane'):SetAnchorOffsets(nLeft, clTop, nRight, nBottom)

	self.SidebarContainer:FindChild('ExpandChatTabListButton'):Show(true)
	self.SidebarContainer:FindChild('CollapseChatTabListButton'):Show(false)

	self.SidebarStreamsListPane:SetVScrollPos(0)
end

--

function ChatWindow:OnChannelSelectorCheck(wndHandler, wndControl, eMouseButton)
	local channelId = wndControl:GetData()

	if not channelId then
		return
	end

	-- also good to check type
	if self.StreamType ~= Jita.Client.EnumStreamsTypes.AGGREGATED then
		return
	end

	local stream = Jita.Client:GetStream(self.SelectedStream)
	
	stream:AddChannel(channelId)
end

function ChatWindow:OnChannelSelectorUncheck(wndHandler, wndControl, eMouseButton)
	local channelId = wndControl:GetData()

	if not channelId then
		return
	end

	-- also good to check type
	if self.StreamType ~= Jita.Client.EnumStreamsTypes.AGGREGATED then
		return
	end

	local stream = Jita.Client:GetStream(self.SelectedStream)

	stream:RemoveChannel(channelId)
end
