local Jita = Apollo.GetAddon("Jita")
local ChatWindow = Jita:Extend("ChatWindow")

local Utils = Jita.Utils
local Consts = Jita.Consts

--

function ChatWindow:GenerateChatMessagesPane()
	self.ChatMessagesPane:DestroyChildren()
	self.ChatMessagesPane:SetVScrollPos(0)

	self.LastSender = ""

	local stream = Jita.Client:GetStream(self.SelectedStream)

	if not stream then
		return
	end

	for _, message in ipairs(stream.Messages) do
		if message.ID > #stream.Messages - Jita.UserSettings.ChatWindow_MaxChatLines then
			if message.Type == "aml" then
				self:GenerateChatMessageDecorated(message)
			elseif message.Type == "plain" then
				self:GenerateChatMessagePlain(message.Content, self.MessageTextFont)
			else
				self:GenerateChatMessage(message)
			end

			if Jita.UserSettings.ChatWindow_MessageShowLastViewed == true and message.IsLastViewed == true then
				local marker = Apollo.LoadForm(Jita.XmlDoc, "ChatMessageLastViewedMarkerControl", self.ChatMessagesPane, self)
				marker:SetOpacity(0.36, 10.0)
				self.LastSender = "-"
			end
		end
	end

	self:ArrangeChatMessagesPane()
end

--

function ChatWindow:GenerateChatMessage(message)
	if not message or not message.Channel or not message.Content then
		return
	end

	if not Jita.Client.Channels then
		return
	end

	local channel = Jita.Client.Channels[message.Channel]

	if not channel
	or not channel:GetType()
	or not channel:GetName()
	then
		return
	end -- of discussion

	-- drop local messages if OOR
	if message.Range ~= nil
	and message.Range >= Jita.UserSettings.ChatWindow_SayEmoteRange
	and Jita.UserSettings.ChatWindow_MessageAlienateOutOfRange ~= true
	then
		return
	end

	local children = self.ChatMessagesPane:GetChildren()

	if children and #children >= Jita.UserSettings.ChatWindow_MaxChatLines then
		self:RemoveChatMessage(1)
	end

	-- generate and display message

	if self.MessageDisplayMode == 'Inline' then
		local result = self:GenerateChatMessageInline(message)

		return result
	end

	-- if self.MessageDisplayMode == 'Block' then
	local result = self:GenerateChatMessageBlock(message)
	
	return result	
end

function ChatWindow:GenerateChatMessageInline(message)
	local result = self:GenerateChatMessageGeneric(message)

	if not result or not result.XmlLine then
		return
	end

	local wndChatLine = Apollo.LoadForm(Jita.XmlDoc, "ChatMessageInlineControl", self.ChatMessagesPane, self)

	wndChatLine:SetData(message)

	wndChatLine:SetDoc(result.XmlLine)

	wndChatLine:SetHeightToContentHeight()

	local nLeft, nTop, nRight, nBottom = wndChatLine:GetAnchorOffsets()
	wndChatLine:SetAnchorOffsets(nLeft, nTop + 2 , nRight, nTop + nBottom + 4)

	return result
end

function ChatWindow:GenerateChatMessageBlock(message)
	local channel = Jita.Client.Channels[message.Channel]
	
	local channelType = channel:GetType()
	local channelName = channel:GetName()
	local content     = message.Content

	local result = self:GenerateChatMessageGeneric(message)

	if not result or not result.XmlLine then
		return
	end

	local wndChatLine = Apollo.LoadForm(Jita.XmlDoc, "ChatMessageBlockControl", self.ChatMessagesPane, self)

	wndChatLine:SetData(message)

	wndChatLine:FindChild("Message"):SetDoc(result.XmlLine)

	wndChatLine:FindChild("Message"):SetHeightToContentHeight()

	wndChatLine:FindChild("Time"):SetText(message.StrTime)
	wndChatLine:FindChild("Time"):SetFont(self.MessageTextFont)

	local curSender = ""

	-- Player message
	if content.strDisplayName and content.strDisplayName ~= "" and result.XmlPlayerName then
		wndChatLine:FindChild("Sender"):SetDoc(result.XmlPlayerName)

		curSender = content.strDisplayName

	-- Channel message (system, debug, realm, etc.)
	elseif channelName then
		local crChannel = Consts.ChatMessagesColors[channelType] or ApolloColor.new("white")
		crChannel = crChannel:GetColorString()

		wndChatLine:FindChild("Sender"):SetAML("<P TextColor=\"" .. crChannel .. "\" Font=\"" .. self.MessageTextFont .. "\">" .. channelName .. "</P>")

		curSender = channelName
	end

	wndChatLine:FindChild("Header"):SetAML("<P TextColor=\"0\" Font=\"" .. self.MessageTextFont .. "\" VAlign=\"Center\">.</P>")
	wndChatLine:FindChild("Header"):SetHeightToContentHeight()

	local tPad = 10
	if self.LastSender == nil or self.LastSender == "" then tPad = 0 end
	if self.LastSender == curSender then tPad = 0 end

	local nLeft, nTop, nRight, nBottom = wndChatLine:FindChild("Header"):GetAnchorOffsets()
	local hHeight = nBottom - nTop + 4
	if self.LastSender == curSender then hHeight = 0 end
	wndChatLine:FindChild("Header"):SetAnchorOffsets(nLeft, nTop + tPad, nRight, nTop + tPad + hHeight)

		nLeft, nTop, nRight, nBottom = wndChatLine:FindChild("Sender"):GetAnchorOffsets()
		wndChatLine:FindChild("Sender"):SetAnchorOffsets(nLeft, nTop, nRight, nTop + hHeight)

		nLeft, nTop, nRight, nBottom = wndChatLine:FindChild("Time"):GetAnchorOffsets()
		wndChatLine:FindChild("Time"):SetAnchorOffsets(nLeft, nTop, nRight, nTop + hHeight)

	nLeft, nTop, nRight, nBottom = wndChatLine:FindChild("Message"):GetAnchorOffsets()
	local mHeight = nBottom - nTop + 4
	wndChatLine:FindChild("Message"):SetAnchorOffsets(nLeft, nTop + tPad + hHeight, nRight, nBottom + tPad + hHeight)

	nLeft, nTop, nRight, nBottom = wndChatLine:GetAnchorOffsets()
	wndChatLine:SetAnchorOffsets(nLeft, nTop, nRight, nBottom + tPad + hHeight + mHeight)

	self.LastSender = curSender

	return result
end

function ChatWindow:GenerateChatMessageGeneric(message)
	if message.XmlObj then
		return message.XmlObj
	end

	local channel = Jita.Client.Channels[message.Channel]

	local channelType    = channel:GetType()
	local channelName    = channel:GetName()
	local channelCommand = channel:GetCommand()
	local channelAbbr    = channel:GetAbbreviation()
	local content        = message.Content

	channelAbbr = Consts.ChatChannelsAbbreviations[channelType] or channelAbbr

	local xmlPlayerName = XmlDoc.new()
	local xmlLine       = XmlDoc.new()

	local crText    = Consts.ChatMessagesColors[channelType] or ApolloColor.new("white")
	local crChannel = Consts.ChatMessagesColors[channelType] or ApolloColor.new("white")

	local crPlayerName = ApolloColor.new("ChatPlayerName")

	if content.bCrossFaction then
		crPlayerName = ApolloColor.new("ChatPlayerNameHostile")
	end

	local strCharacterName       = content.strSender
	local strDisplayName         = content.strDisplayName 

	local strAWPeerCharacterName = content.strAWPeerCharacterName
	local strAWPeerDisplayName   = content.strAWPeerDisplayName

	local source = {
		strCharacterName = strCharacterName,
		nReportId        = content.nReportId,
		strCrossFaction  = content.bCrossFaction and "true" or "false" 
	}

	if content.bSelf 
	and self.StreamType == Jita.Client.EnumStreamsTypes.SEGREGATED
	and Jita.Player.Name
	then
		source.strCharacterName = Jita.Player.Name
		source.nReportId        = nil
		source.strCrossFaction  = "false" 
	end

	--

	xmlLine:AddLine("", crChannel, self.MessageTextFont, "Left")
	xmlPlayerName:AddLine("", crPlayerName, self.MessageTextFont, "Left")

	-- Keepme:
	-- xmlLine:AppendText("#" .. message.ID .. " ", crChannel, self.MessageTextFont, "Left")

	local strTime = ""

	if self.MessageDisplayMode == 'Inline' and Jita.UserSettings.ChatWindow_MessageShowTimestamp == true then
		strTime = message.StrTime

		if self.StreamType == Jita.Client.EnumStreamsTypes.SEGREGATED then
			strTime = "[" .. message.StrTime .. "]"
		end

		xmlLine:AppendText(strTime .. " ", crChannel, self.MessageTextFont, "Left")
	end

	if Jita.UserSettings.ChatWindow_MessageShowPlayerRange == true
	and not content.bSelf
	and message.Range
	and message.Range > 0
	then
		xmlLine:AppendText("[" .. message.Range .. "m] ", "ChatEmote", "CRB_Pixel", "Left")
	end

	if self.MessageDisplayMode == 'Block' then
		xmlPlayerName:AppendText(strDisplayName, crPlayerName, self.MessageTextFont, source, "Source")

		if content.bGM then
			xmlPlayerName:AppendText(" ")
			xmlPlayerName:AppendImage(Consts.kstrGMIcon, 20, 19)
		end
	end

	-- emote channels gets special formatting
	if channelType == ChatSystemLib.ChatChannel_Emote 
	or channelType == ChatSystemLib.ChatChannel_AnimatedEmote
	then
		if strDisplayName:len() > 0 then
			if content.bGM and self.MessageDisplayMode == 'Inline' then
				xmlPlayerName:AppendImage(Consts.kstrGMIcon, 16, 16)
				xmlPlayerName:AppendText(" ")
			end

			-- only non-animated emotes get player name appended 
			if channelType == ChatSystemLib.ChatChannel_Emote then
				xmlLine:AppendText(strDisplayName, crPlayerName, self.MessageTextFont, source, "Source")
				xmlLine:AppendText(" ")
			end
		end
	else
		local strChannel = ""

		if channelType == ChatSystemLib.ChatChannel_Society
		or channelType == ChatSystemLib.ChatChannel_Custom
		then
			if Jita.UserSettings.ChatWindow_MessageUseChannelAbbr == true then
				strChannel = (string.format("%s ", String_GetWeaselString(Apollo.GetString("ChatLog_GuildCommand"), string.upper(string.sub(channelName, 1, 1)) , channelCommand)))
			else
				strChannel = (string.format("%s ", String_GetWeaselString(Apollo.GetString("ChatLog_GuildCommand"), channelName, channelCommand)))
			end
		else
			if Jita.UserSettings.ChatWindow_MessageUseChannelAbbr == true
			and channelAbbr ~= ''
			then
				strChannel = String_GetWeaselString(Apollo.GetString("CRB_Brackets_Space"), string.upper(channelAbbr))
			else
				strChannel = String_GetWeaselString(Apollo.GetString("CRB_Brackets_Space"), channelName)
			end
		end

		if Jita.UserSettings.ChatWindow_MessageShowChannelName == true
		or self.StreamType == Jita.Client.EnumStreamsTypes.AGGREGATED -- on aggregated mode we show channel because "the obs"
		then
			xmlPlayerName:AppendText(" @ ", "ChatEmote", self.MessageTextFont, "Left")
			xmlPlayerName:AppendText(strChannel, crChannel, self.MessageTextFont, "Left")

			if self.MessageDisplayMode == 'Inline' then
				xmlLine:AppendText(strChannel, crChannel, self.MessageTextFont, "Left")
			end
		end

		local strPresenceState = ""

		if content.bAutoResponse then
			strPresenceState = '('..Apollo.GetString("AutoResponse_Prefix")..')'
		end

		if content.nPresenceState == FriendshipLib.AccountPresenceState_Away then
			strPresenceState = '<'..Apollo.GetString("Command_Friendship_AwayFromKeyboard")..'>'
		elseif content.nPresenceState == FriendshipLib.AccountPresenceState_Busy then
			strPresenceState = '<'..Apollo.GetString("Command_Friendship_DoNotDisturb")..'>'
		end

		if strDisplayName:len() > 0 then
			if self.MessageDisplayMode == 'Inline' then
				if content.bGM then
					xmlLine:AppendImage(Consts.kstrGMIcon, 20, 19)
					xmlLine:AppendText(" ")
				end

				if self.StreamType == Jita.Client.EnumStreamsTypes.AGGREGATED 
				and (channelType == ChatSystemLib.ChatChannel_Whisper or channelType == ChatSystemLib.ChatChannel_AccountWhisper)
				and content.bSelf
				and content.strSender
				then
					xmlLine:AppendText(Apollo.GetString("ChatLog_To"), crChannel, self.MessageTextFont, "Left")

					if channelType == ChatSystemLib.ChatChannel_AccountWhisper
					and strAWPeerDisplayName
					and strAWPeerDisplayName:len() > 0
					then
						xmlLine:AppendText(strAWPeerDisplayName, crPlayerName, self.MessageTextFont, source, "Source")
					else
						xmlLine:AppendText(content.strSender, crPlayerName, self.MessageTextFont, source, "Source")
					end
				else
					xmlLine:AppendText(strDisplayName, crPlayerName, self.MessageTextFont, source, "Source")
				end

				xmlLine:AppendText(strPresenceState .. Apollo.GetString("Chat_ColonBreak"), crChannel, self.MessageTextFont, "Left")
			end
		end
	end

	local xmlBubble = nil

	if Jita.UserSettings.ChatWindow_MessageShowBubble == true then
		xmlBubble = XmlDoc.new()

		xmlBubble:AddLine("", crChannel, self.MessageTextFont, "Center")
	end

	--

	local bHasVisibleText = false

	for idx, tSegment in ipairs(content.arMessageSegments) do
		local strText       = tSegment.strText 
		local bAlien        = tSegment.bAlien
		local bShow         = false

		if Jita.UserSettings.ChatWindow_MessageHighlightRolePlay == true
		and strText and strText:len() > 0
		then
			strText = string.gsub(strText, "  "    , " ")
			strText = string.gsub(strText, "%-%-"  , "—")
			strText = string.gsub(strText, "%. "   , ".  ")
			strText = string.gsub(strText, "%! "   , "!  ")
			strText = string.gsub(strText, "%? "   , "?  ")
			strText = string.gsub(strText, "%.%.%.", "…")
		end

		if self.eRoleplayOption == 3 then
			bShow = not tSegment.bRolePlay
		elseif self.eRoleplayOption == 2 then
			bShow = tSegment.bRolePlay
		else
			bShow = true;
		end

		if bShow then
			local crChatText = crText;
			local crBubbleText = Consts.kstrColorChatRegular
			local strChatFont = self.MessageTextFont
			local strBubbleFont = Consts.kstrBubbleFont
			local tLink = {}

			if tSegment.uItem ~= nil then -- item link
				-- replace me with correct colors
				strText = String_GetWeaselString(Apollo.GetString("CRB_Brackets"), tSegment.uItem:GetName())
				crChatText = Consts.karEvalColors[tSegment.uItem:GetItemQuality()]
				crBubbleText = ApolloColor.new("white")

				tLink.strText = strText
				tLink.uItem = tSegment.uItem

			elseif tSegment.uQuest ~= nil then -- quest link
				-- replace me with correct colors
				strText = String_GetWeaselString(Apollo.GetString("CRB_Brackets"), tSegment.uQuest:GetTitle())
				crChatText = ApolloColor.new("green")
				crBubbleText = ApolloColor.new("green")

				tLink.strText = strText
				tLink.uQuest = tSegment.uQuest

			elseif tSegment.uArchiveArticle ~= nil then -- archive article
				-- replace me with correct colors
				strText = String_GetWeaselString(Apollo.GetString("CRB_Brackets"), tSegment.uArchiveArticle:GetTitle())
				crChatText = ApolloColor.new("ffb7a767")
				crBubbleText = ApolloColor.new("ffb7a767")

				tLink.strText = strText
				tLink.uArchiveArticle = tSegment.uArchiveArticle

			elseif tSegment.tNavPoint ~= nil then
				-- replace me with correct colors
				strText = String_GetWeaselString(Apollo.GetString("CRB_Brackets"), "NavPoint")
				crChatText = ApolloColor.new("ffb7a767")
				crBubbleText = ApolloColor.new("ffb7a767")

				tLink.strText = strText
				tLink.tNavPoint = tSegment.tNavPoint

			else
				if tSegment.bRolePlay then
					crBubbleText  = Consts.kstrColorChatRoleplay
					strChatFont   = self.MessageTextFont
					strBubbleFont = Consts.kstrDialogFontRP
				end

				if bAlien or tSegment.bProfanity then -- Weak filter. Note only profanity is scrambled.
					strChatFont   = "CRB_AlienMedium"
					strBubbleFont = "CRB_AlienMedium"
				end

				if message.Range ~= nil
				and message.Range > Jita.UserSettings.ChatWindow_SayEmoteRange
				and Jita.UserSettings.ChatWindow_MessageAlienateOutOfRange == true
				then
					strChatFont   = "CRB_AlienMedium"
					strBubbleFont = "CRB_AlienMedium"
				end
			end

			if next(tLink) == nil then 
				local highlights = self:HighlightChatMessageContent(strText, channelType)

				if highlights then
					for _, part in ipairs(highlights) do
						local hText  = part[1]
						local hColor = Consts.ChatMessagesColors[part[2]] or crChatText
						local hType  = part[3]

						if hType and hType == "URL" then
							xmlLine:AppendText(hText, hColor, strChatFont, {URL = hText}, "URL")
						else
							xmlLine:AppendText(hText, hColor, strChatFont)
						end
					end
				else
					xmlLine:AppendText(strText, crChatText, strChatFont)
				end
			else
				local strLinkIndex = tostring(self:HelperSaveLink(tLink))

				xmlLine:AppendText(strText, crChatText, strChatFont, {strIndex = strLinkIndex}, "Link")
			end

			if xmlBubble then
				xmlBubble:AppendText(strText, crBubbleText, strBubbleFont) -- Format for bubble; regular
			end

			bHasVisibleText = bHasVisibleText or Utils:StringEmpty(strText)
		end
	end

	message.XmlObj = 
	{
		XmlPlayerName  = xmlPlayerName  ,
		XmlLine        = xmlLine        ,
		XmlBubble      = xmlBubble      ,
		HasVisibleText = bHasVisibleText
	}

	return message.XmlObj
end

function ChatWindow:GenerateChatMessagePlain(text, font)
	-- This is to display a _plain_ text message to chat pane

	if not font then
		font = self.MessageTextFont
	end

	local wndChatLine = Apollo.LoadForm(Jita.XmlDoc, "ChatMessageInlineControl", self.ChatMessagesPane, self)

	wndChatLine:SetAML("<P TextColor=\"gray\" Font=\"" .. font .. "\">" .. Utils:EscapeHTML(text) .. "</P>")

	wndChatLine:SetHeightToContentHeight()

	local nLeft, nTop, nRight, nBottom = wndChatLine:GetAnchorOffsets()
	wndChatLine:SetAnchorOffsets(nLeft, nTop + 2, nRight, nTop + nBottom + 4)

	self:ArrangeChatMessagesPane()
end

function ChatWindow:GenerateChatMessageDecorated(message)
	if not message.Content then
		return
	end

	local wndChatLine = Apollo.LoadForm(Jita.XmlDoc, "ChatMessageDecorateControl", self.ChatMessagesPane, self)

	wndChatLine:SetData(message)

	local wndMessage = wndChatLine:FindChild("Message")
	local nHeight = 0

	for _, line in pairs(message.Content) do
		local wndLine = Apollo.LoadForm(Jita.XmlDoc, "ChatMessageInlineControl", wndMessage, self)

		wndLine:SetAML(line)
		wndLine:SetHeightToContentHeight()
		
		local nLeft, nTop, nRight, nBottom = wndLine:GetAnchorOffsets()

		nHeight = nHeight + nBottom - nTop
	end

	wndMessage:ArrangeChildrenVert()
	wndMessage:SetHeightToContentHeight()

	local nLeft, nTop, nRight, nBottom = wndChatLine:GetAnchorOffsets()
	wndChatLine:SetAnchorOffsets(nLeft, nTop, nRight, nHeight + 12)

	self:ArrangeChatMessagesPane()
end

--Keepme:
function ChatWindow:GenerateChatMessageDecoratedXMLDoc(message)
	if not message.Content then
		return
	end

	local wndChatLine = Apollo.LoadForm(Jita.XmlDoc, "ChatMessageDecorateControl", self.ChatMessagesPane, self)

	local xmlLine = XmlDoc.new()
	local crText = ApolloColor.new("white")

	for _, line in pairs(message.Content) do
		xmlLine:AddLine(line, crText, self.MessageTextFont, "Left")
	end

	wndChatLine:FindChild("Message"):SetDoc(xmlLine)
	wndChatLine:FindChild("Message"):SetHeightToContentHeight()

	local nLeft, nTop, nRight, nBottom = wndChatLine:GetAnchorOffsets()
	local wLeft, wTop, wRight, wBottom = wndChatLine:FindChild("Message"):GetAnchorOffsets()
	wndChatLine:SetAnchorOffsets(nLeft, nTop, nRight, nTop + wBottom + 12)

	self:ArrangeChatMessagesPane()
end

function ChatWindow:HighlightChatMessageContent(strText, channelType)
--/- Analyse messages for rp, mentions, links and whatnot, and highlight any relevant parts
--/- Parts of this are total knock off of Killroy and ChatSplitter

	if not strText or strText:len() == 0 then
		return false
	end

	if not channelType
	or not (
		   channelType == ChatSystemLib.ChatChannel_Say 
		or channelType == ChatSystemLib.ChatChannel_Yell
		or channelType == ChatSystemLib.ChatChannel_Emote 
		or channelType == ChatSystemLib.ChatChannel_AnimatedEmote

		or channelType == ChatSystemLib.ChatChannel_Whisper
		or channelType == ChatSystemLib.ChatChannel_AccountWhisper

		or channelType == ChatSystemLib.ChatChannel_Party
		or channelType == ChatSystemLib.ChatChannel_Instance
		or channelType == ChatSystemLib.ChatChannel_Zone
		or channelType == ChatSystemLib.ChatChannel_Nexus
		or channelType == ChatSystemLib.ChatChannel_Guild
		or channelType == ChatSystemLib.ChatChannel_Society
		or channelType == ChatSystemLib.ChatChannel_Custom
	)
	then
		return false
	end

	--

	local crChatText = nil
	local parsedText = {}

	local oocs     = {}
	local emotes   = {}
	local quotes   = {}
	local keywords = {}
	local urls     = {}

	local index    = 1
	local first    = 0
	local last     = 0

	if Jita.UserSettings.ChatWindow_MessageHighlightRolePlay == true then
		for emote in strText:gmatch("%b**") do
			first, last = strText:find(emote, index, true)

			if first and last then
				emotes[first] = last
				index = last + 1
			end
		end

		index = 1
		for quote in strText:gmatch("%b\"\"") do
			first, last = strText:find(quote, index, true)
			
			if first and last then
				quotes[first] = last
				index = last + 1
			end
		end

		index = 1
		for ooc in strText:gmatch("%(%(.*%)%)") do
			first, last = strText:find(ooc, index, true)
			
			if first and last then
				oocs[first] = last
				index = last + 1
			end
		end
	end

	if Jita.UserSettings.ChatWindow_MessageDetectURLs == true then
		index = 1
		for url in strText:gmatch("[%a0-9_%-]+[%.@/:]+[%a0-9_@%-]+%.%S+") do
			first, last = strText:find(url, index, true)
			
			if first and last then
				urls[first] = last
				index = last + 1
			end
		end
	end

	-- cache player's name and keywords
	if not self.MentionsAndKeywords then
		self.MentionsAndKeywords = {}
		local mentionsAndKeywords = ''

		-- skip names if shorter than 3 characters
		for word in string.gmatch(Jita.Player.Name, "%w+") do
			word = string.lower(Utils:Trim(word))

			if word and word:len() >= 3 then
				mentionsAndKeywords = mentionsAndKeywords .. " " .. word
			end
		end

		if Jita.UserSettings.ChatWindow_MessageKeywordAlert == true
		and string.len(Jita.UserSettings.ChatWindow_MessageKeywordList) > 1
		then
			mentionsAndKeywords = mentionsAndKeywords 
				.. ' ' 
				.. Jita.UserSettings.ChatWindow_MessageKeywordList
		end

		if mentionsAndKeywords and mentionsAndKeywords:len() > 1 then
			for word in string.gmatch(mentionsAndKeywords, "%w+") do
				word = string.lower(Utils:Trim(word))

				if word and word ~= '' then
					self.MentionsAndKeywords[word] = word
				end
			end
		end
	end

	local strTextLower = string.lower(strText)

	if strTextLower
	and strTextLower:len() > 1
	and self.MentionsAndKeywords
	then
		index = 1
		for word in strTextLower:gmatch('%w+') do
			for _, keyword in pairs(self.MentionsAndKeywords) do
				if keyword == word then
					first, last = strTextLower:find(keyword, index, true) -- not the most perfect way, but works, kinda.

					if first and last then
						keywords[first] = last
						index = last + 1
					end
				end
			end
		end
	end

	--

	local buffer = ""
	index = 1
	local highlight = false

	while index <= strText:len() do
		if oocs[index] then
			if buffer then
				table.insert(parsedText, {buffer, crChatText})
				buffer = ""
			end
			table.insert(parsedText, {strText:sub(index, oocs[index]), "O"})
			index = oocs[index] + 1
			highlight = true

		elseif emotes[index] then
			if buffer then
				table.insert(parsedText, {buffer, crChatText})
				buffer = ""
			end
			table.insert(parsedText, {strText:sub(index, emotes[index]), "A"})
			index = emotes[index] + 1
			highlight = true

		elseif quotes[index] then
			if buffer then
				table.insert(parsedText, {buffer, crChatText})
				buffer = ""
			end
			table.insert(parsedText, {strText:sub(index, quotes[index]), "Q"})
			index = quotes[index] + 1
			highlight = true

		elseif urls[index] then
			if buffer then
				table.insert(parsedText, {buffer, crChatText})
				buffer = ""
			end
			table.insert(parsedText, {strText:sub(index, urls[index]), "U", "URL"})
			index = urls[index] + 1
			highlight = true

		elseif keywords[index] then
			if buffer then
				table.insert(parsedText, {buffer, crChatText})
				buffer = ""
			end
			table.insert(parsedText, {strText:sub(index, keywords[index]), "K"})
			index = keywords[index] + 1
			highlight = true

		else
			buffer = buffer .. strText:sub(index, index)
			index = index + 1
		end
	end

	if not highlight then
		return false
	end

	if buffer ~= "" then
		table.insert(parsedText, {buffer, crChatText})
	end

	return parsedText
end

function ChatWindow:ArrangeChatMessagesPane()
	local bAtBottom = false
	local nPos = self.ChatMessagesPane:GetVScrollPos()

	if nPos == self.ChatMessagesPane:GetVScrollRange() then
		bAtBottom = true
	end

	self.ChatMessagesPane:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)

	if bAtBottom then
		self.ChatMessagesPane:SetVScrollPos(self.ChatMessagesPane:GetVScrollRange()) 
	end
end

function ChatWindow:RemoveChatMessage(line)
	local children = self.ChatMessagesPane:GetChildren()

	if not children then
		return
	end

	for order, wndChatLine in ipairs(children) do
		if order == line then
			local message = wndChatLine:GetData()

			if message and message.XmlObj then
				message.XmlObj = nil
			end

			wndChatLine:Destroy()
		end
	end

	-- If in block display mode, we need to restore last message header
	if self.MessageDisplayMode ~= 'Block' then
		return
	end

	for order, wndChatLine in ipairs(children) do
		if order == line + 1 then
			wndChatLine:FindChild("Header"):SetHeightToContentHeight()

			local nLeft, nTop, nRight, nBottom = wndChatLine:FindChild("Header"):GetAnchorOffsets()
			local nHeight = nBottom - nTop

			nLeft, nTop, nRight, nBottom = wndChatLine:FindChild("Sender"):GetAnchorOffsets()
			wndChatLine:FindChild("Sender"):SetAnchorOffsets(nLeft, nTop, nRight, nTop + nHeight)

			nLeft, nTop, nRight, nBottom = wndChatLine:FindChild("Time"):GetAnchorOffsets()
			wndChatLine:FindChild("Time"):SetAnchorOffsets(nLeft, nTop, nRight, nTop + nHeight)

			nLeft, nTop, nRight, nBottom = wndChatLine:GetAnchorOffsets()
			wndChatLine:SetAnchorOffsets(nLeft, nTop, nRight, nBottom + nHeight)

			nLeft, nTop, nRight, nBottom = wndChatLine:FindChild("Message"):GetAnchorOffsets()
			wndChatLine:FindChild("Message"):SetAnchorOffsets(nLeft, nTop + nHeight, nRight, nBottom + nHeight)

			return
		end
	end
end

-- Events

function ChatWindow:OnMLChatlineNodeClick(wndHandler, wndControl, strNode, tAttributes, eMouseButton)
	if strNode == "URL" 
	and tAttributes.URL
	then
		if not Jita.UserSettings.ChatWindow_MessageDetectURLs then
			return
		end

 		self:OnCopyCloseButton()

		self.CopyWindow = Apollo.LoadForm(Jita.XmlDoc, "JCC_CopyWindow", nil, self) 

		if self.CopyWindow then
			self.CopyWindow:FindChild("ContentEditBox"):SetText(tAttributes.URL)
			self.CopyWindow:FindChild("ContentEditBox"):SetFocus()
			
			self.CopyWindow:Show(true, true)
		end

	elseif strNode == "Source" 
	and eMouseButton == GameLib.CodeEnumInputMouse.Left
	and tAttributes.strCharacterName
	then
		if not Jita.UserSettings.ChatWindow_RosterLeftClickInfo then
			return
		end

		local data = Jita.Client:GetStreamMember(tAttributes.strCharacterName)

		if not data then
			data = Jita.Client:AddPlayerProfile(tAttributes.strCharacterName)
		end

		if data then
			Jita.WindowManager:LoadWindow("ProfileWindow"):ShowCharacterProfile(data)
		else
			self:GenerateChatMessagePlain("[" .. tAttributes.strCharacterName .. "] has left the chat or their profile has been purged.")
		end

	elseif strNode == "Source" 
	and eMouseButton == GameLib.CodeEnumInputMouse.Right 
	and tAttributes.strCharacterName 
	and tAttributes.strCrossFaction
	then
		local bCross = tAttributes.strCrossFaction == "true"--sending boolean. -- oh thanks cabino dev for the obvious comment. quite helpful. 
		local nReportId = nil

		if tAttributes ~= nil and tAttributes.nReportId ~= nil then
			nReportId = tAttributes.nReportId
		end

		local tOptionalData = {nReportId = tAttributes.nReportId, bCrossFaction = bCross}

		Event_FireGenericEvent("GenericEvent_NewContextMenuPlayer", wndHandler, tAttributes.strCharacterName, nil, tOptionalData)

		return true
	end

	if strNode == "Link" then

		-- note, tAttributes.nLinkIndex is a string value, instead of the int we passed in because it was saved
		-- out as xml text then read back in.
		local nIndex = tonumber(tAttributes.strIndex)

		if self.Links[nIndex]
		and (self.Links[nIndex].uItem 
		or self.Links[nIndex].uQuest 
		or self.Links[nIndex].uArchiveArticle
		or self.Links[nIndex].tNavPoint)
		then
			if Apollo.IsShiftKeyDown() then
				self:AppendLinkToInput(self.ChatInputEditBox, self.Links[nIndex])
			else
				if self.Links[nIndex].uItem then

					local bWindowExists = false

					for idx, wndCur in pairs(self.ItemTooltipWindows or {}) do
						if wndCur:GetData() == self.Links[nIndex].uItem then
							bWindowExists = true
							break
						end
					end

					if bWindowExists == false then
						local wndChatItemToolTip = Apollo.LoadForm(Jita.XmlDoc, "JCC_ItemTooltipWindow", "TooltipStratum", self)
						wndChatItemToolTip:SetData(self.Links[nIndex].uItem)

						table.insert(self.ItemTooltipWindows, wndChatItemToolTip)

						local itemEquipped = self.Links[nIndex].uItem:GetEquippedItemForItemType()

						local wndLink = Tooltip.GetItemTooltipForm(self, wndControl, self.Links[nIndex].uItem, {bPermanent = true, wndParent = wndChatItemToolTip, bSelling = false, bNotEquipped = true})

						local nLeftWnd, nTopWnd, nRightWnd, nBottomWnd = wndChatItemToolTip:GetAnchorOffsets()
						local nLeft, nTop, nRight, nBottom = wndLink:GetAnchorOffsets()

						wndChatItemToolTip:SetAnchorOffsets(nLeftWnd, nTopWnd, nLeftWnd + nRight + 15, nBottom + 75)

						if itemEquipped then
							wndChatItemToolTip:SetTooltipDoc(nil)
							Tooltip.GetItemTooltipForm(self, wndChatItemToolTip, itemEquipped, {bPrimary = true, bSelling = false, bNotEquipped = false})
						end
					end

				elseif self.Links[nIndex].uQuest then
					Event_FireGenericEvent("ShowQuestLog", self.Links[nIndex].uQuest)
					Event_FireGenericEvent("GenericEvent_ShowQuestLog", self.Links[nIndex].uQuest)

				elseif self.Links[nIndex].uArchiveArticle then
					Event_FireGenericEvent("HudAlert_ToggleLoreWindow")
					Event_FireGenericEvent("GenericEvent_ShowGalacticArchive", self.Links[nIndex].uArchiveArticle)

				elseif self.Links[nIndex].tNavPoint then
					GameLib.SetNavPoint(self.Links[nIndex].tNavPoint.tPosition, self.Links[nIndex].tNavPoint.nMapZoneId)
					GameLib.ShowNavPointHintArrow()
				end
			end
		end
	end

	return false
end

function ChatWindow:OnCopyCloseButton(wndHandler, wndControl)
	if self.CopyWindow and self.CopyWindow:IsValid() then
		self.CopyWindow:Close()
		self.CopyWindow:Destroy()
	end
end

function ChatWindow:OnCloseItemTooltipForm(wndHandler, wndControl)
	local wndParent = wndControl:GetParent()
	local itemData = wndParent:GetData()

	for idx, wndCur in pairs(self.ItemTooltipWindows) do
		if wndCur:GetData() == itemData then
			table.remove(self.ItemTooltipWindows, idx)
		end
	end

	wndParent:Destroy()
end

--

function ChatWindow:HelperSaveLink(tLink)
	self.Links[self.NextLinkIndex] = tLink
	self.NextLinkIndex = self.NextLinkIndex + 1

	return self.NextLinkIndex - 1
end
