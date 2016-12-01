local Jita = Apollo.GetAddon("Jita")
local TranscriptWindow = Jita:Extend("TranscriptWindow")

local Utils = Jita.Utils
local Consts = Jita.Consts

--

function TranscriptWindow:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self

	o.MainForm = nil

	return o
end

function TranscriptWindow:Init()
end

function TranscriptWindow:LoadForms()
	self.MainForm = Apollo.LoadForm(Jita.XmlDoc, "JCC_TranscriptWindow", nil, self)

	Jita.WindowManager.Themes:ApplyCurrentThemeToWindow(self)

	self.MainForm:FindChild("BodyContainer"):SetBGOpacity(.9)
	self.MainForm:FindChild("BodyContainer"):SetNCOpacity(.9)

	self.MainForm:Show(true, true)
end

function TranscriptWindow:ShowStreamTranscript(streamName)
	self.SelectedStream = streamName
	
	self.MainFormLastLocation = nil

	if self.MainForm and self.MainForm:IsValid() then
		self.MainFormLastLocation = self.MainForm:GetLocation()

		self.MainForm:Destroy()
	end

	self:LoadForms()

	if self.MainFormLastLocation then
		self.MainFormLastLocation = self.MainFormLastLocation:ToTable() 
		self.MainForm:MoveToLocation(WindowLocation.new(self.MainFormLastLocation))
	end

	--
	
	self.MainForm:FindChild("MainFormTitle"):SetText("  Chat Transcript — " .. self:NormalizeChatTabName(self.SelectedStream))

	self.ChatTranscriptPane = self.MainForm:FindChild("ChatTranscriptPane")

	local stream = Jita.Client:GetStream(self.SelectedStream)

	self:GenerateChatTranscript(stream)

	local transcript = self:GetTextChatTranscript(stream)

	transcript = Jita:GetAddonName() .. " " .. Jita:GetAddonVersion() .. " - Transcript export:\r\n\r\n" .. transcript 
	transcript = transcript .. "\r\n<eof>"

	self.MainForm:FindChild("CopyToClipboardButton"):SetActionData(GameLib.CodeEnumConfirmButtonType.CopyToClipboard, transcript)

	--/-

	self.MainForm:Show(true)
	self.MainForm:ToFront()
end

function TranscriptWindow:GenerateChatTranscript(stream)
	if stream and #stream.Messages >= 0 then
		for idx, message in ipairs(stream.Messages) do
			if not message.Type then
				local channel = Jita.Client.Channels[message.Channel]

				if channel and channel:GetType() and channel:GetName() then
					local text = ""
					local xmlLine = XmlDoc.new()

					local crChannel = Consts.ChatMessagesColors[channel:GetType()] or ApolloColor.new("white") 

					local crPlayer = ApolloColor.new("ChatPlayerName")

					if message.Content.bCrossFaction then
						crPlayer = ApolloColor.new("ChatPlayerNameHostile")
					end

					xmlLine:AddLine(text, crChannel, Jita.UserSettings.ChatWindow_MessageTextFont, "Left")
				
					if message.Content then 
						text = message.StrTime .. " " 

						xmlLine:AppendText(text, crChannel, Jita.UserSettings.ChatWindow_MessageTextFont, "Left")

						if message.Content.strDisplayName then
							local channelName = "" 
							local senderName  = message.Content.strDisplayName

							if channel:GetType() ==  ChatSystemLib.ChatChannel_AnimatedEmote then
								channelName = "[AnimatedEmote] " 

								-- emote contains user ref
								senderName = ""

							elseif channel:GetType() ==  ChatSystemLib.ChatChannel_Emote then
								channelName = "[Emote] "

							else
								channelName = "[" .. channel:GetName() .. "] "
							end

							xmlLine:AppendText(channelName, crChannel, Jita.UserSettings.ChatWindow_MessageTextFont, "Left")
							xmlLine:AppendText(senderName, crPlayer, Jita.UserSettings.ChatWindow_MessageTextFont, "Left")
						end

						if message.Content.arMessageSegments then
							text = ": "

							for idz, tSegment in ipairs(message.Content.arMessageSegments) do
								text = text .. tSegment.strText
							end
			
							xmlLine:AppendText(text, crChannel, Jita.UserSettings.ChatWindow_MessageTextFont, "Left")
						end
					end

					--

					local wndChatLine = Apollo.LoadForm(Jita.XmlDoc, "ChatMessageInlineControl", self.ChatTranscriptPane, self)

					wndChatLine:SetDoc(xmlLine)

					wndChatLine:SetHeightToContentHeight()

					local nLeft, nTop, nRight, nBottom = wndChatLine:GetAnchorOffsets()
					wndChatLine:SetAnchorOffsets(nLeft, nTop + 2 , nRight, nTop + nBottom + 4)
				end
			end
		end

		self.ChatTranscriptPane:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
		
		self.ChatTranscriptPane:SetVScrollPos(self.ChatTranscriptPane:GetVScrollRange()) 
	end
end 

function TranscriptWindow:GetTextChatTranscript(stream)
	local transcript = ""

	if stream and #stream.Messages >= 0 then
		for _, message in ipairs(stream.Messages) do
			if not message.Type then
				local text = ""

				if message.Content then 
					text = "[" .. message.StrTime .. "]" 
					
					local channel = Jita.Client.Channels[message.Channel]

					if channel and channel:GetType() and channel:GetName() then
						if message.Content.strDisplayName then
							if channel:GetType() ==  ChatSystemLib.ChatChannel_AnimatedEmote then
								text = text  .. " " -- emote contains user ref

							elseif channel:GetType() ==  ChatSystemLib.ChatChannel_Emote then
								text = text  .. " " .. message.Content.strDisplayName .. " "

							elseif channel:GetType() ==  ChatSystemLib.ChatChannel_Say then
								text = text  .. " " .. message.Content.strDisplayName .. " says: "

							elseif channel:GetType() ==  ChatSystemLib.ChatChannel_Yell then
								text = text  .. " " .. message.Content.strDisplayName .. " yells: "

							else
								text = text  .. " " .. "[" .. channel:GetName() .. "]" 
								text = text  .. " " .. message.Content.strDisplayName .. ": "
							end
						end

						if message.Content.arMessageSegments then
							for _, tSegment in ipairs(message.Content.arMessageSegments) do
								text = text .. tSegment.strText
							end
						end
					end
				end

				if text ~= "" then
					transcript = transcript .. text .. "\r\n"
				end
			end
		end
	end

	if transcript == "" then
		transcript = "Naught messages found.\r\n"
	end

	return transcript
end 

function TranscriptWindow:NormalizeChatTabName(name) 
	local out = name

	out = string.gsub(out, "Default::", "")
	out = string.gsub(out, "Custom::" , "")
	out = string.gsub(out, "Society::", "")
	out = string.gsub(out, "AWhisper::", "")
	out = string.gsub(out, "Whisper::", "")

	return out
end

function TranscriptWindow:OnCloseButtonClick()
	self.MainForm:Destroy()

	Jita.WindowManager:RemoveWindow("TranscriptWindow")
end
