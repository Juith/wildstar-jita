local Jita = Apollo.GetAddon("Jita")
local ChatWindow = Jita:Extend("ChatWindow")

local Consts = Jita.Consts

--

function ChatWindow:GenerateChatTabs()
	if self.IsClone then
		return
	end

	local cp = 0

	self.TabsContainer:DestroyChildren()

	for id, data in ipairs(Jita.Client.Streams) do
		if data.Closed == false then
			self:GenerateChatTabButton(data, { Wnd = self.TabsContainer, Align = "Center", Untruncated = false })

			cp = cp + 1
		end
	end

	-- bleh

	local w = self.MainForm:GetWidth() - 96
	local ws = w / cp
	if ws < 26 then ws  = 26 end 
	if ws > 101 then ws = 101 end

	for i, button in ipairs(self.TabsContainer:GetChildren()) do
		local data = button:GetData()

		if data.IsChatTab == true then
			local nLeft, nTop, nRight, nBottom = button:GetAnchorOffsets()

			button:SetAnchorOffsets(nLeft, nTop, ws, nBottom)

			local buttonBG = button:FindChild("Background")
			
			if buttonBG then
				buttonBG:SetAnchorOffsets(nLeft, nTop, ws, nBottom)
			end
		end
	end

	--

	self.TabsContainer:ArrangeChildrenHorz(0) 
end

function ChatWindow:GenerateChatTabButton(stream, params)
	if not stream then
		return
	end

	local button = Apollo.LoadForm(Jita.XmlDoc, "GenericTabButtonControl", params.Wnd, self)
	local buttonBG = button:FindChild("Background")

	local bGSprite  = ''
	local bGBGColor = '0'
	local color     = "UI_BtnTextGoldListNormal"
	local tooltip   = stream.DisplayName

	if stream.Closed == true then
		color = "gray"
		
		if not stream.Ignored then
			tooltip = tooltip .. "\nClosed" 
		end
	end

	if stream.Ignored == true then
		color = "vdarkgray"

		tooltip = tooltip .. "\nClosed and Ignored" 
	end

	if stream.UnreadMessages == true then
		color = "ChatNexus"
		
		tooltip = tooltip .. "\nUnread messages" 

		bGSprite  = 'BasicSprites:WhiteFill'
		bGBGColor = '22000000'
	end

	if stream.Name == self.SelectedStream then
		tooltip = tooltip .. "\nSelected" 

		bGSprite  = 'BasicSprites:WhiteFill'
		bGBGColor = 'aa000000'

		button:SetCheck(true)
	end

	local padding = "  "

	if params.Align == "Center" then
		padding = ""

		button:SetTextFlags("DT_CENTER", true)
	end

	if params.Align ~= "Center"
	or self:NormalizeChatTabName(stream.Name, true) ~= self:NormalizeChatTabName(stream.Name)
	then
		button:SetTooltip(tooltip)
	end

	buttonBG:SetSprite(bGSprite)
	buttonBG:SetBGColor(bGBGColor) 

	button:SetText(padding .. self:NormalizeChatTabName(stream.Name, params.Untruncated))
	button:SetNormalTextColor(color)
	button:SetPressedTextColor("white")

	-- Keepme:
	-- button:SetPressedFlybyTextColor(stream.CommandColor)
	-- button:SetFlybyTextColor(stream.CommandColor)

	local data = {
		IsChatTab  = true,
		StreamName = stream.Name
	}

	button:SetData(data)
	button:AddEventHandler('ButtonCheck'  , 'OnChatTabClick')
	button:AddEventHandler('ButtonUncheck', 'OnChatTabClick')
end

--

function ChatWindow:UpdateChatTabs()
	for _, button in ipairs(self.TabsContainer:GetChildren()) do
		self:UpdateChatTabButton(button)
	end

	for _, button in ipairs(self.SidebarStreamsListPane:GetChildren()) do
		self:UpdateChatTabButton(button)
	end
end

function ChatWindow:UpdateChatTabButton(button)
	if not button then
		return
	end

	local data = button:GetData()

	if not data then
		return
	end

	if not data.IsChatTab or not data.StreamName then
		return
	end

	local stream = Jita.Client:GetStream(data.StreamName)

	if not stream then
		return
	end

	--

	local buttonBG = button:FindChild("Background")

	local color = "UI_BtnTextGoldListNormal"

	local bGSprite  = ''
	local bGBGColor = '0'

	if stream.UnreadMessages == true then
		color = "ChatNexus"

		bGSprite  = 'BasicSprites:WhiteFill'
		bGBGColor = '22000000'
	end

	if data.StreamName == self.SelectedStream then
		bGSprite  = 'BasicSprites:WhiteFill'
		bGBGColor = 'aa000000'
	end

	if stream.Closed == true then
		color = "gray"
	end

	if stream.Ignored == true then
		color = "vdarkgray"
	end

	buttonBG:SetSprite(bGSprite)
	buttonBG:SetBGColor(bGBGColor) 

	button:SetNormalTextColor(color)
	button:SetPressedTextColor("white")
end

--

function ChatWindow:SelectChatTab(streamName, button)
	self.SelectedStream = streamName

	self.LastSender = ""

	self.ChatInputEditBox:SetData("")
	self.ChatInputEditBox:SetText("")
	self.ChatInputEditBox:SetPrompt("X")
	self.ChatInputEditBox:SetPromptColor("AddonError")
	self.ChatInputEditBox:ClearHistoryStrings()

	--

	local stream = Jita.Client:GetStream(self.SelectedStream)

	if not stream then
		return
	end

	if button then
		button:SetCheck(true)
	end

	stream.Closed = false 
	stream.Ignored = false 
	stream.UnreadMessages = false

	self.StreamType = stream.Type

	local color = Consts.ChatMessagesColors[stream.CommandColor] or ApolloColor.new("white")

	self.StreamDefaultCommandColor = color:GetColorString()

	self.ChatInputEditBox:SetData(stream.Command .. " ")
	self.ChatInputEditBox:SetFont(self.MessageTextFont)
	self.ChatInputEditBox:SetTextColor(self.StreamDefaultCommandColor)

	self.ChatInputEditBox:SetStyleEx("MultiLine", false)
	self.ChatInputEditBox:SetPrompt(stream.Command)
	self.ChatInputEditBox:SetPromptColor(self.StreamDefaultCommandColor)

	--

	self:HideSidebar()

	--

	if self.IsClone then
		local title = self:NormalizeChatTabName(self.SelectedStream, true)

		self.TabsContainer:SetText("  " .. title)
	end

	self:GenerateChatTabs()
	self:GenerateRoster()
	self.RosterPane:SetVScrollPos(0)
	self:GenerateChatMessagesPane()
	self:ValidateChatInput()

	Jita.Client:UpdateLastChatMessageViewed(streamName)
end

function ChatWindow:CloseChatTab(streamName, button)
	local stream = Jita.Client:GetStream(streamName)

	if not stream then
		return
	end

	if stream.Closeable == true then
		stream.Closed = true
		stream.UnreadMessages = false

		self.ChatInputEditBox:SetData("")
		self.ChatInputEditBox:SetText("")
		self.ChatInputEditBox:SetPrompt("X")
		self.ChatInputEditBox:SetPromptColor("AddonError")

		if button then
			button:SetCheck(false)
		end

		self:SelectChatTab(Jita.UserSettings.DefaultStream)
	else
		stream.Closed  = false
		stream.Ignored = false

		self:GenerateChatMessagePlain("Default chat tab is not closable.")
	end
end

--

function ChatWindow:OnChatTabClick(wndHandler, wndControl, eMouseButton)
	local LeftButton   = eMouseButton == GameLib.CodeEnumInputMouse.Left
	local MiddleButton = eMouseButton == GameLib.CodeEnumInputMouse.Middle
	local RightButton  = eMouseButton == GameLib.CodeEnumInputMouse.Right

	local data = wndControl:GetData()

	if not data.IsChatTab then
		return
	end

	local streamName = data.StreamName

	if LeftButton then
		self:SelectChatTab(streamName, wndControl)

	elseif MiddleButton then
		self:CloseChatTab(streamName, wndControl)

	elseif RightButton then
		local clone = Jita.WindowManager:CloneChatWindow(self)

		if clone then
			clone:SelectChatTab(streamName)

			clone.MainForm:Show(true, true)
		end

		-- Game's client colors tabButton as selected
		self:GenerateChatTabs()
	end
end

--

function ChatWindow:NormalizeChatTabName(name, untruncated)
	local out = name

	local stream = Jita.Client:GetStream(name)

	if stream and stream.DisplayName then
		out = stream.DisplayName
	else
		out = string.gsub(out, "Default::" , "")
		out = string.gsub(out, "Custom::"  , "")
		out = string.gsub(out, "Society::" , "")
		out = string.gsub(out, "AWhisper::", "")
		out = string.gsub(out, "Whisper::" , "")
	end

	if untruncated then 
		return out
	end

	-- looks fugly because it is

	local cp = 0

	for id, data in ipairs(Jita.Client.Streams) do
		if data.Closed == false then
			cp = cp + 1
		end
	end

	local w = self.MainForm:GetWidth() - 96
	local ws = w / cp
	if ws < 26 then ws  = 26 end 
	if ws > 101 then ws = 101 end

	local slen = ws / 13 + 1

	if ws < 27 then slen = 1 end 

	--

	out = string.sub(out, 1, slen)

	--

	return out
end
