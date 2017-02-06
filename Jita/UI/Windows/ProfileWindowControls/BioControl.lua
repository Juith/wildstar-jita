local Jita = Apollo.GetAddon("Jita")
local ProfileWindow = Jita:Extend("ProfileWindow")

local Utils = Jita.Utils
local Consts = Jita.Consts

--

function ProfileWindow:GenerateBio(profile)
	local nLeft, nTop, nRight, nBottom = self.MainForm:FindChild("BioPane"):GetAnchorOffsets()
	local initialHeight = nBottom - nTop

	local bio = profile.Bio or ""
	bio = Utils:Trim(bio)

	if profile.Name == Jita.Player.Name then
		self.MainForm:FindChild("EditBioButton"):Show(true)
	end

	if bio == "" then
		self.MainForm:FindChild("HasNoBio"):Show(true)

		return
	end

	local xmlDoc      = XmlDoc.new()
	local highlights  = self:HighlightBioContent(bio)
	
	local crChatText  = "UI_WindowTextDefault"
	local strChatFont = "CRB_Interface11"
	
	xmlDoc:AddLine("", crChatText, strChatFont, "Left")

	if highlights then
		for _, part in ipairs(highlights) do
			local hText  = part[1]
			local hColor = Consts.ChatMessagesColors[part[2]] or crChatText
			local hType  = part[3]

			if hType and hType == "URL" then
				xmlDoc:AppendText(hText, hColor, strChatFont, {URL = hText}, "URL")
			else
				xmlDoc:AppendText(hText, hColor, strChatFont)
			end
		end
	else
		xmlDoc:AppendText(bio, crChatText, strChatFont)
	end

	self.MainForm:FindChild("BioPane"):SetDoc(xmlDoc)
	self.MainForm:FindChild("BioPane"):SetHeightToContentHeight()

	nLeft, nTop, nRight, nBottom = self.MainForm:FindChild("BioPane"):GetAnchorOffsets()
	local stretchedHeight = nBottom - nTop

	local deltaHeight = stretchedHeight - initialHeight

	if deltaHeight > 0 then
		nLeft, nTop, nRight, nBottom  = self.MainForm:FindChild("BodyContainer"):GetAnchorOffsets()
		nBottom = nBottom + deltaHeight

		if nBottom > 507 then
			nBottom = 507
		end

		self.MainForm:FindChild("BodyContainer"):SetAnchorOffsets(nLeft, nTop, nRight, nBottom)

		self.MainForm:FindChild("BioPane"):SetAnchorPoints(0, 0, 1, 1)

		nLeft, nTop, nRight, nBottom = self.MainForm:FindChild("BioPane"):GetAnchorOffsets()
		self.MainForm:FindChild("BioPane"):SetAnchorOffsets(nLeft, nTop, -6,  -6)
		self.MainForm:FindChild("BioPane"):SetVScrollPos(0)
	else
		deltaHeight = 0
	end

	local location = self.MainForm:GetLocation():ToTable()
	location.nOffsets[4] = location.nOffsets[4] + deltaHeight
	self.MainForm:MoveToLocation(WindowLocation.new(location))
end

function ProfileWindow:OnMLNodeClick(wndHandler, wndControl, strNode, tAttributes, eMouseButton)
	if strNode == "URL"
	and tAttributes.URL
	then
		self:OnCopyCloseButton()
		
		self.CopyWindow = Apollo.LoadForm(Jita.XmlDoc, "JCC_CopyWindow", nil, self) 

		if self.CopyWindow then
			self.CopyWindow:FindChild("ContentEditBox"):SetText(tAttributes.URL)
			self.CopyWindow:FindChild("ContentEditBox"):SetFocus()
			
			self.CopyWindow:Show(true, true)
		end
	end
end

function ProfileWindow:OnCopyCloseButton(wndHandler, wndControl)
	if self.CopyWindow and self.CopyWindow:IsValid() then
		self.CopyWindow:Close()
		self.CopyWindow:Destroy()
	end
end

function ProfileWindow:HighlightBioContent(strText)
	if not strText or strText:len() == 0 then
		return false
	end

	--

	strText = string.gsub(strText, "  "    , " ")
	strText = string.gsub(strText, "%-%-"  , "—")
	strText = string.gsub(strText, "%. "   , ".  ")
	strText = string.gsub(strText, "%! "   , "!  ")
	strText = string.gsub(strText, "%? "   , "?  ")
	strText = string.gsub(strText, "%.%.%.", "…")

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

	index = 1
	for url in strText:gmatch("[%a0-9_%-]+[%.@/:]+[%a0-9_@%-]+%.%S+") do
		first, last = strText:find(url, index, true)
		
		if first and last then
			urls[first] = last
			index = last + 1
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

function ProfileWindow:OnEditBioButtonClick()
	Jita.WindowManager:LoadWindow("ConfigWindow", { LoadForms = true})
end
