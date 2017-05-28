local Jita = Apollo.GetAddon("Jita")
local ProfileWindow = Jita:Extend("ProfileWindow")

local Utils = Jita.Utils
local Consts = Jita.Consts

--

function ProfileWindow:GenerateBioTabs(idSelectedTab)
	local mainFormTitle = self.MainForm:FindChild("MainFormTitle")
	local tabsContainer = self.MainForm:FindChild("TabsContainer")

	tabsContainer:DestroyChildren()

	self:GenerateBioTabButton("JITA", "  Character Information", "", tabsContainer, 180, (idSelectedTab == "JITA"))
	
	local profile = Jita.Client:GetPlayerProfile(self.Metadata.Name)

	if profile then
		local tabColor = nil

		if Jita.Client.PrivateNotes[self.Metadata.Name] then
			tabColor = 'ChatNexus'
		end
		
		self:GenerateBioTabButton("NOTES", "  Notes", "Private Notes", tabsContainer, 69, (idSelectedTab == "NOTES"), tabColor)

		if profile.ExternalBios then
			tabColor = 'ChatNexus'

			if profile.ExternalBios.TIM then
				self:GenerateBioTabButton("TIM" , "  TIM", "This Is Me Biography", tabsContainer, 56, (idSelectedTab == "TIM"), tabColor)
			end

			if profile.ExternalBios.KRP then
				self:GenerateBioTabButton("KRP" , "  KRP", "Katia Plot RP Finder", tabsContainer, 56, (idSelectedTab == "KRP"), tabColor)
			end
		end

		if Jita.CoreSettings.EnableDebugWindow
		or Jita.CoreSettings.EnableIICommDebug
		then
			self:GenerateBioTabButton("DEBUG", "  Debug", "Profile Data", tabsContainer, 72, (idSelectedTab == "DEBUG"))
		end
	end

	tabsContainer:ArrangeChildrenHorz(0) 

	mainFormTitle:Show(false)
	tabsContainer:Show(true)
end

function ProfileWindow:GenerateBioTabButton(idTab, name, tooltip, wndParent, width, selected, color)
	local btn = Apollo.LoadForm(Jita.XmlDoc, "GenericTabButtonControl", wndParent, self)

	if not color then
		color = "UI_BtnTextGoldListNormal"
	end

	btn:SetText(name)
	btn:SetNormalTextColor(color)
	btn:SetPressedTextColor("UI_BtnTextGoldListNormal")
	btn:SetFont("CRB_HeaderSmall")

	if tooltip and tooltip ~= '' then
		btn:SetTooltip(tooltip)
	end

	local btnBG = btn:FindChild("Background")

	btnBG:SetSprite("")
	btnBG:SetBGColor("0") 

	if selected then
		btn:SetNormalTextColor("white")
		btn:SetPressedTextColor("white")

		btnBG:SetSprite("WhiteFill")
		btnBG:SetBGColor("aa000000")
	end
	
	local nLeft, nTop, nRight, nBottom = btn:GetAnchorOffsets()
	btn:SetAnchorOffsets(nLeft, nTop, width, nBottom)
	btnBG:SetAnchorOffsets(nLeft, nTop, width, nBottom)

	btn:SetData(idTab)
	btn:AddEventHandler('ButtonCheck'  , 'OnBioTabClick')
	btn:AddEventHandler('ButtonUncheck', 'OnBioTabClick')
end

function ProfileWindow:OnBioTabClick(wndHandler, wndControl, eMouseButton)
	local idTab = wndControl:GetData()

	if not idTab then
		return
	end

	self:GenerateBioTabs(idTab)

	local profile = Jita.Client:AddPlayerProfile(self.Metadata.Name)

	if not profile then
		return
	end

	self.EditBoxNotes = false
	self.MainForm:FindChild("ExtendBioPane"):Show(false)
	self.MainForm:FindChild("ExtendEditBoxPane"):Show(false)

	if idTab == "JITA" then
		self.MainForm:FindChild("ExtendProfileContainer"):Show(false)

	elseif idTab == "NOTES"  then
		self.EditBoxNotes = true
		
		self.MainForm:FindChild("ExtendProfileContainer"):Show(true)

		local text = Jita.Client.PrivateNotes[self.Metadata.Name] or ''

		text = Utils:Trim(text) or ''

		self.MainForm:FindChild("ExtendEditBoxPane"):Show(true)
		self.MainForm:FindChild("ExtendEditBoxPane"):FindChild("EditBox"):SetText(text)

	elseif idTab == "DEBUG" then
		self.MainForm:FindChild("ExtendProfileContainer"):Show(true)

		local text = 'Awaiting LibJSON..'

		if Jita.LibJSON then
			local status, json = pcall(Jita.LibJSON.encode, profile)

			if status and type(json) == "string" then
				text = json
			end
		end

		self.MainForm:FindChild("ExtendEditBoxPane"):Show(true)
		self.MainForm:FindChild("ExtendEditBoxPane"):FindChild("EditBox"):SetText(text)

	elseif idTab == "TIM"  then
		self.MainForm:FindChild("ExtendProfileContainer"):Show(true)

		local text = Utils:Trim(profile.ExternalBios.TIM) or ''

		text = Utils:EscapeHTML(text)
		text = "<P TextColor=\"UI_WindowTextDefault\" Font=\"CRB_Interface11\">" .. text .. "</P>"

		self.MainForm:FindChild("ExtendBioPane"):Show(true)
		self.MainForm:FindChild("ExtendBioPane"):SetAML(text)
		self.MainForm:FindChild("ExtendBioPane"):SetVScrollPos(0)

	elseif idTab == "KRP" then
		self.MainForm:FindChild("ExtendProfileContainer"):Show(true)

		local text = Utils:Trim(profile.ExternalBios.KRP) or ''

		text = Utils:EscapeHTML(text)
		text = "<P TextColor=\"UI_WindowTextDefault\" Font=\"CRB_Interface11\">" .. text .. "</P>"

		self.MainForm:FindChild("ExtendBioPane"):Show(true)
		self.MainForm:FindChild("ExtendBioPane"):SetAML(text)
		self.MainForm:FindChild("ExtendBioPane"):SetVScrollPos(0)
	end
end

function ProfileWindow:OnExtendProfileNoteEditBoxChanged(wndHandler, wndControl, text)
	if not self.EditBoxNotes then
		return
	end

	text = Utils:Trim(text)

	if text and text ~= '' then
		Jita.Client.PrivateNotes[self.Metadata.Name] = text
		return
	end

	Jita.Client.PrivateNotes[self.Metadata.Name] = nil
end
