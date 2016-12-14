local Jita = Apollo.GetAddon("Jita")
local ChatWindow = Jita:Extend("ChatWindow")

local Utils = Jita.Utils
local Consts = Jita.Consts

--

function ChatWindow:AutoExpandChatInput(text)
--/- what a mess

	if not Jita.UserSettings.ChatWindow_AutoExpandChatInput then
		return
	end

	-- default offsets
	local dciTop    = -47
	local ducBottom = -52
	local denHeight = 18

	-- because chat pane scrollbar will reset when parent is resized or moved,
	-- we need to keep track of it to properly restore the range
	local vScrollPos = self.ChatMessagesPane:GetVScrollPos()
	local isAtBottom = vScrollPos == self.ChatMessagesPane:GetVScrollRange()

	local nLeft, nTop, nRight, nBottom = self.ChatInputContainer:GetAnchorOffsets()
	
	text = text or ''

	-- because prompt doesn't work on multiline, we'll keep flipping type as a workaround
	if text:len() < 36 then -- as far as it goes
		if self.ChatInputMultiLine == true then
			self.ChatInputEditBox:SetStyleEx("MultiLine", false)
			self.ChatInputMultiLine = false

			self:HideSuggestedMenu()
		end
	else
		if self.ChatInputMultiLine == false then
			self.ChatInputEditBox:SetStyleEx("MultiLine", true)
			self.ChatInputMultiLine = true
		end
	end

	-- set ui controls to default size
	if text == "" then
		if nTop == dciTop then return end -- nothing to do.

		self.ChatInputContainer:SetAnchorOffsets(nLeft, dciTop, nRight, nBottom)
		self.ChatInputExpandHelper:SetAML("")
		self.ChatInputExpandHelper:SetHeightToContentHeight()

			nLeft, nTop, nRight, nBottom = self.ChatMessagesContainer:GetAnchorOffsets()
			self.ChatMessagesContainer:SetAnchorOffsets(nLeft, nTop, nRight, ducBottom)

			nLeft, nTop, nRight, nBottom = self.RosterContainer:GetAnchorOffsets()
			self.RosterContainer:SetAnchorOffsets(nLeft, nTop, nRight, ducBottom)

			nLeft, nTop, nRight, nBottom = self.SidebarContainer:GetAnchorOffsets()
			self.SidebarContainer:SetAnchorOffsets(nLeft, nTop, nRight, ducBottom)
	end

	-- autofit ui controls to text size

	self.ChatInputExpandHelper:SetAML("<P Font=\"" .. self.MessageTextFont .. "\" TextColor=\"ffffffff\">" .. text .. "</P>")
	self.ChatInputExpandHelper:SetHeightToContentHeight()

	-- Keepme:
	-- local xmlLine = XmlDoc.new()
	-- xmlLine:AddLine(text, "white", self.MessageTextFont, "Left")
	-- self.ChatInputExpandHelper:SetDoc(xmlLine)
	-- self.ChatInputExpandHelper:SetHeightToContentHeight()

	nLeft, nTop, nRight, nBottom = self.MainForm:GetAnchorOffsets()
	local maxHeight = math.floor((nBottom - nTop) / 2) + 1

	nLeft, nTop, nRight, nBottom = self.ChatInputExpandHelper:GetAnchorOffsets()
	local nHeight = nBottom - nTop

	nLeft, nTop, nRight, nBottom = self.ChatInputContainer:GetAnchorOffsets()
	local bHeight = nBottom - nTop 

	local dHeight = nHeight - bHeight

	if not self.nLastdHeight then
		self.nLastdHeight = dHeight
	end

	if dHeight ~= self.nLastdHeight then
		nLeft, nTop, nRight, nBottom = self.ChatInputContainer:GetAnchorOffsets()
		
		local cTop = nTop - dHeight - 2

		if cTop > dciTop      then cTop = dciTop      end
		if cTop < - maxHeight then cTop = - maxHeight end

		self.ChatInputContainer:SetAnchorOffsets(nLeft, cTop, nRight, nBottom)

			nLeft, nTop, nRight, nBottom = self.ChatMessagesContainer:GetAnchorOffsets()
			self.ChatMessagesContainer:SetAnchorOffsets(nLeft, nTop, nRight, cTop - 5)

			nLeft, nTop, nRight, nBottom = self.RosterContainer:GetAnchorOffsets()
			self.RosterContainer:SetAnchorOffsets(nLeft, nTop, nRight, cTop - 5)

			nLeft, nTop, nRight, nBottom = self.SidebarContainer:GetAnchorOffsets()
			self.SidebarContainer:SetAnchorOffsets(nLeft, nTop, nRight, cTop - 5)

		self.nLastdHeight = dHeight
	end 

	if isAtBottom then
		self.ChatMessagesPane:SetVScrollPos(self.ChatMessagesPane:GetVScrollRange())
	else
		self.ChatMessagesPane:SetVScrollPos(vScrollPos) 
	end
end

function ChatWindow:ValidateChatInput()
	self:AutoExpandChatInput(self.ChatInputEditBox:GetText())
end

function ChatWindow:OnChatInputEditBoxReturn(wndHandler, wndControl, text)
	if self:IsSuggestedMenuShown() 
	and self.SuggestedMenuEntires 
	and self.SuggestedMenuEntires[self.SuggestedMenuSelectedEntryPosition] 
	then
		self:SelectSuggestedMenuEntry(self.SuggestedMenuEntires[self.SuggestedMenuSelectedEntryPosition])

		return
	end

	text = text .. "\n"

	self:OnChatInputEditBoxChanged(wndHandler, wndControl, text)
end

function ChatWindow:OnChatInputEditBoxChanged(wndHandler, wndControl, text)
	text = self:ReplaceLinksInInput(text, wndControl:GetAllLinks())

	if string.sub(text, 1, 1) ~= "/" then
		wndControl:SetTextColor(self.StreamDefaultCommandColor)
	else
		wndControl:SetTextColor("gray")
	end

	if string.find(text, "\n", 1) then  -- sneaky sneaky
		self:HandleChatInputEditBoxReturn(wndHandler, wndControl, text)

		text = ""
	end

	self:AutoExpandChatInput(text)

	--

	self:ShowSuggestedMenu(text)
end

function ChatWindow:HandleChatInputEditBoxCommandChanged(wndHandler, wndControl, text)
	if not text or string.sub(text, 1, 1) ~= "/" then
		return
	end

	local parsed = ChatSystemLib.SplitInput(text)

	if not parsed then
		return
	end

	local channel = parsed.channelCommand

	if not channel then
		return
	end

	local channelName    = channel:GetName()
	local channelType    = channel:GetType()
	local channelCommand = channel:GetCommand()

	if not channelCommand or channelCommand == '' then
		return
	end

	local defaultCommand = wndControl:GetData()

	local textColor = Consts.ChatMessagesColors[channelType] or ApolloColor.new("gray")
	local command = "/" .. channel:GetCommand()

	if channelType == ChatSystemLib.ChatChannel_Whisper
	or channelType == ChatSystemLib.ChatChannel_AccountWhisper
	then
		--use last whispered as the target
		if Jita.Client.LastWhisper
		and Jita.Client.LastWhisper.Command
		and Jita.Client.LastWhisper.Command ~= ""
		and Jita.Client.LastWhisper.Channel
		and Jita.Client.LastWhisper.Channel == channelType
		then
			command = Jita.Client.LastWhisper.Command

		--updating last whispered for next messages
		else
			local strSend = parsed.strMessage

			local strPattern = "" --using regex pattern

			if channelType == ChatSystemLib.ChatChannel_Whisper then
				--find a space, any number of alphabet characters, and then another space
				strPattern = "%s%a*%s-"
			elseif channelType == ChatSystemLib.ChatChannel_AccountWhisper then
				--since account names only are one word, find a space
				strPattern = "%s"
			end

			local nPlaceHolder, nSubstringStop = string.find(strSend, strPattern)

			--Occurs when not typing a message, just ending with sender name.
			if not nSubstringStop then
				nSubstringStop = Apollo.StringLength(strSend) 
			end

			if strPattern and strPattern ~= "" then
				local target = string.sub(strSend, 0, nSubstringStop)--gets the name of the target

				if target and target ~= "" then
					command = command .. ' ' .. target
				end
			end
		end
	end

	if channel:CanSend() then
		wndControl:SetPrompt(command)
		wndControl:SetData(command)
		self.StreamDefaultCommandColor = textColor
		wndControl:SetTextColor(textColor)
		wndControl:SetPromptColor(textColor)

		if self.StreamType == Jita.Client.EnumStreamsTypes.AGGREGATED then
			local stream = Jita.Client:GetStream(self.SelectedStream)

			if stream then
				stream.Command = command
				stream.CommandColor = channelType
			end
		end
	end
end

function ChatWindow:HandleChatInputEditBoxReturn(wndHandler, wndControl, text)
	local defaultCommand = wndControl:GetData()

	wndControl:SetText("")
	wndControl:SetTextColor(self.StreamDefaultCommandColor)

	wndControl:SetPrompt(defaultCommand)
	wndControl:SetPromptColor(self.StreamDefaultCommandColor)

	if not(not defaultCommand or not text or Utils:Trim(text) == '') then
		local fc = string.sub(text, 1, 1)
		local domessage = true

		-- Wildstar slash command
		if fc == '/' then
			Jita.Client:DoChatMessage(nil, text)

			domessage = false

		-- Jita command
		elseif fc == '!' then
			local success = Jita.Client:DoJitaCommand(self, text)

			domessage = not success
		end

		-- Chat message
		if domessage then
			Jita.Client:DoChatMessage(defaultCommand, text)
		end
	end

	self:HandleChatInputEditBoxCommandChanged(wndHandler, wndControl, text)

	wndControl:AddHistoryString(string.gsub(text, "\n", "")) -- sneakier

	if Apollo.IsShiftKeyDown() then
		wndControl:SetFocus()
	else
		wndControl:ClearFocus()
	end
end

--

function ChatWindow:OnLinkItemToChat(itemLinked)
	if itemLinked == nil then
		return
	end

	local tLink = {}
	tLink.uItem = itemLinked
	tLink.strText = String_GetWeaselString(Apollo.GetString("CRB_Brackets"), itemLinked:GetName())

	self:AppendLinkToInput(self.ChatInputEditBox, tLink)
end

function ChatWindow:OnQuestLink(queLinked)
	if queLinked == nil or not Quest.is(queLinked) then
		return
	end

	local tLink = {}
	tLink.uQuest = queLinked
	tLink.strText = String_GetWeaselString(Apollo.GetString("CRB_Brackets"), queLinked:GetTitle())

	self:AppendLinkToInput(self.ChatInputEditBox, tLink)
end

function ChatWindow:OnArticleLink() 
	-- Todo:
	-- maybe not.
end

--

function ChatWindow:AppendLinkToInput(wndEdit, tLink)
	local tSelectedText = wndEdit:GetSel()

	wndEdit:AddLink(tSelectedText.cpCaret, tLink.strText, tLink)
	wndEdit:SetFocus()
end

function ChatWindow:ReplaceLinksInInput(strText, arEditLinks)
	local strReplacedText = ""

	local nCurrentIdx = 1
	local nLastIdx = strText:len()
	while nCurrentIdx <= nLastIdx do
		local nNextIdx = nCurrentIdx + 1

		local bFound = false

		for nEditIdx, tEditLink in pairs(arEditLinks) do
			if tEditLink.iMin <= nCurrentIdx and nCurrentIdx < tEditLink.iLim then
				if tEditLink.data.uItem then
					strReplacedText = strReplacedText .. tEditLink.data.uItem:GetChatLinkString()
				elseif tEditLink.data.uQuest then
					strReplacedText = strReplacedText .. tEditLink.data.uQuest:GetChatLinkString()
				elseif tEditLink.data.uArchiveArticle then
					strReplacedText = strReplacedText .. tEditLink.data.uArchiveArticle:GetChatLinkString()
				end

				if nNextIdx < tEditLink.iLim then
					nNextIdx = tEditLink.iLim
				end

				bFound = true
				break
			end
		end

		if bFound == false then
			strReplacedText = strReplacedText .. strText:sub(nCurrentIdx, nCurrentIdx)
		end

		nCurrentIdx = nNextIdx
	end

	return strReplacedText
end
