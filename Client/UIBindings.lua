local Jita = Apollo.GetAddon("Jita")
local Client = Jita:Extend("Client")

local Utils = Jita.Utils
local Consts = Jita.Consts

--

function Client:PushMessageToChatWindows(stream, message)
	if not stream or not message then
		return
	end

	stream.UnreadMessages = true

	for _, window in pairs(Jita.WindowManager.Windows) do
		if window.IsChatWindow
		and window.SelectedStream == stream.Name
		then
			stream.UnreadMessages = false

			self:UpdateLastChatMessageViewed(stream.Name)

			window:GenerateChatMessage(message)

			window:ArrangeChatMessagesPane()

			if not stream.CanRequestMembersList then
				window:GenerateRoster()
			end
		end

		if window.IsChatWindow then
			window:UpdateChatTabs()
		end
	end

	if not message.XmlObj
	or not message.XmlObj.XmlBubble
	then
		return
	end

	if message.Content and message.Content.unitSource then
		message.Content.unitSource:AddTextBubble(message.XmlObj.XmlBubble)
		
		message.Content.unitSource = nil
	end

	message.XmlObj.XmlBubble = nil
end

function Client:PushMessageToSelectedStreamsInChatWindows(data)
	if not data then
		return
	end

	for _, window in pairs(Jita.WindowManager.Windows) do
		if window.IsChatWindow 
		and window.SelectedStream
		then
			local stream = self:GetStream(window.SelectedStream)

			if stream 
			and stream.Type ~= self.EnumStreamsTypes.AGGREGATED
			then
				local insertedMessage = stream:AddMessage(data)

				if insertedMessage then
					window:GenerateChatMessage(insertedMessage)

					window:ArrangeChatMessagesPane()
				end
			end
		end
	end
end

function Client:PushMessageToTextFloater(message, hasKeyword, hasMention)
	if not message or not message.Channel or not message.Content then
		return
	end

	if Jita.WindowManager:GetWindow("MainChatWindow") then
		return
	end

	if not Jita.UserSettings.ChatWindow_MessageShowTextFloater then
		return
	end

	if Jita.Timestamp < 1 then
		return
	end

	if message.Content.bSelf then
		return
	end

	local channel = self.Channels[message.Channel]

	if not channel then
		return
	end

	local channelType = channel:GetType()

	if not channelType then
		return
	end

	--

	local continue = false

	if hasKeyword or hasMention then
		continue = true
	end

	if message.Range and message.Range <= 32 then
		continue = true
	end	

	if channelType == ChatSystemLib.ChatChannel_System
	or channelType == ChatSystemLib.ChatChannel_Whisper
	or channelType == ChatSystemLib.ChatChannel_AccountWhisper
	then
		continue = true
	end

	if channelType == ChatSystemLib.ChatChannel_Debug
	and Jita.CoreSettings.EnableIICommDebug
	then
		continue = true
	end

	if not continue then
		return
	end
	
	--

	local text = ""

	if message.Content.strSender and message.Content.strSender ~= '' then
		text = message.Content.strSender
		text = text .. ":\n"
	end

	for _, tSegment in ipairs(message.Content.arMessageSegments) do
		text = text .. tSegment.strText
	end

	--

	pcall(Client.RequestShowTextFloater, channel, channelType, text)
end

function Client.RequestShowTextFloater(channel, channelType, text)
--/- to invoke via pcall

	if not text or text == '' then
		return
	end

	local pattern = "%s*[^%s]+%s*"
	local chunks  = {}
	local chunk   = ""
	local length  = 0

	for word in string.gmatch(text, pattern) do
		length = length + string.len(word)

		if length > 100 then
			chunk = Utils:Trim(chunk)
			table.insert(chunks, chunk)

			chunk  = "\n"
			length = 0
		end

		chunk = chunk .. word
	end

	table.insert(chunks, chunk)

	text = table.concat(chunks) or ""
	text = Utils:Trim(text)

	if string.len(text) > 512 then
		text = string.sub(text, 1, 512) .. "..."
	end

	--

	local FloatText = Apollo.GetAddon("FloatText")
	
	if not FloatText then
		return
	end

	local tTextOption = FloatText:GetDefaultTextOption()

	tTextOption.bUseScreenPos = true
	tTextOption.fOffset       = -280
	tTextOption.nColor        = 0xffffff
	tTextOption.strFontFace   = "CRB_HeaderLarge_O"
	tTextOption.bShowOnTop    = false
	tTextOption.arFrames      =
	{
		[1] = {fTime = 0,   fAlpha = 0  },
		[2] = {fTime = 0.6, fAlpha = 1.0},
		[3] = {fTime = 4.6, fAlpha = 1.0},
		[4] = {fTime = 5.2, fAlpha = 0  },
	}

	if channel and channelType then
		local color = Consts.ChatMessagesColors[channelType] or ApolloColor.new("white")
		color = color:GetColorString()
		color = string.sub(color, 3)
		color = tonumber(color, 16)

		if color then
			tTextOption.nColor = color
		end
	end

	FloatText:RequestShowTextFloater(LuaEnumMessageType.ZoneName, GameLib.GetControlledUnit(), text, tTextOption)
end

function Client:GenerateChatWindowsControls(stream)
	for idw, window in pairs(Jita.WindowManager.Windows) do
		if window.IsChatWindow then
			window:GenerateRoster()
			window:GenerateChatTabs()

			if window.SidebarContainer:IsShown() then
				window:GenerateSidebar()
			end

			if stream and stream.Name == window.SelectedStream then
				window:GenerateChatMessagesPane()
			end
		end
	end
end

function Client:GenerateChatWindowsTabs()
	for _, window in pairs(Jita.WindowManager.Windows) do
		if window.IsChatWindow and not window.IsClone then
			window:GenerateChatTabs()
		end
	end
end

function Client:GenerateChatWindowsRoster()
	for _, window in pairs(Jita.WindowManager.Windows) do
		if window.IsChatWindow then
			window:GenerateRoster()
		end
	end
end

function Client:NotifiyOverlayWindow(channelType)
	local overlay = Jita.WindowManager:GetWindow("OverlayWindow")

	if overlay then
		overlay:OnChatMessage(channelType)
	end
end

function Client:SelectChatTabOnMainChatWindow(streamName, options)
	local window = Jita.WindowManager:GetWindow("MainChatWindow")

	if window then
		window:SelectChatTab(streamName)

		if options then
			if options.SetFocus 
			and window.ChatInputEditBox
			then
				window.ChatInputEditBox:SetFocus()
			end
		end
	end
end

function Client:RemoveStreamFromChatWindows(stream)
	if not stream then
		return
	end	

	for _, window in pairs(Jita.WindowManager.Windows) do
		if window.IsChatWindow then
			if not window.IsClone then
				window:CloseChatTab(stream.Name)

			elseif window.SelectedStream == stream.Name then
				window:OnCloseButtonClick()
			end
		end
	end
end
