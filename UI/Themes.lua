local Jita = Apollo.GetAddon("Jita")
local Themes = Jita:Extend("Themes")

--

function Themes:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self

	o.CurrentTheme = {
		MainForm_Sprite = "",
		MainForm_BGColor = "",

		HeaderContainer_Sprite = "",
		HeaderContainer_BGColor = "",

		BodyContainer_Sprite = "",
		BodyContainer_BGColor = "",

		TabsContainer_Sprite = "",
		TabsContainer_BGColor = "",

		ChatTabsOptsContainer_Sprite = "",
		ChatTabsOptsContainer_BGColor = "",

		ChatMessagesContainer_Sprite = "",
		ChatMessagesContainer_BGColor = "",

		RosterContainer_Sprite = "",
		RosterContainer_BGColor = "",

		ChatInputContainer_Sprite = "",
		ChatInputContainer_BGColor = "",

		SidebarContainer_Sprite = "",
		SidebarContainer_BGColor = "",
	}

	o.PresetThemes = {
		{
			Name = "TealDark",

			MainForm_Sprite = "",
			MainForm_BGColor = "",

			HeaderContainer_Sprite = "BasicSprites:WhiteFill",
			HeaderContainer_BGColor = "ff004444",

			BodyContainer_Sprite = "BasicSprites:WhiteFill",
			BodyContainer_BGColor = "xkcdDarkTeal", 

			TabsContainer_Sprite = "BasicSprites:WhiteFill",
			TabsContainer_BGColor = "xkcdDeepTeal",

			ChatTabsOptsContainer_Sprite = "",
			ChatTabsOptsContainer_BGColor = "",

			ChatMessagesContainer_Sprite = "CRB_UIKitSprites:spr_scrollHologramBack",
			ChatMessagesContainer_BGColor = "UI_WindowBGDefault",

			RosterContainer_Sprite = "CRB_UIKitSprites:spr_scrollHologramBack",
			RosterContainer_BGColor = "UI_WindowBGDefault",

			ChatInputContainer_Sprite = "CRB_UIKitSprites:spr_scrollHologramBack",
			ChatInputContainer_BGColor = "UI_WindowBGDefault",

			SidebarContainer_Sprite = "BasicSprites:WhiteFill",
			SidebarContainer_BGColor = "xkcdDeepTeal",

			SidebarBackground_Sprite = "",
			SidebarBackground_BGColor = "",

			SidebarPadding_Sprite = "BasicSprites:WhiteFill",
			SidebarPadding_BGColor = "xkcdDarkTeal", 
		}, 
		{
			Name = "Viking",

			MainForm_Sprite = "",
			MainForm_BGColor = "",

			HeaderContainer_Sprite = "BasicSprites:WhiteFill",
			HeaderContainer_BGColor = "99120f1e",

			BodyContainer_Sprite = "BasicSprites:WhiteFill",
			BodyContainer_BGColor = "ff141122",

			TabsContainer_Sprite = "BasicSprites:WhiteFill",
			TabsContainer_BGColor = "99141122",

			ChatTabsOptsContainer_Sprite = "",
			ChatTabsOptsContainer_BGColor = "",

			ChatMessagesContainer_Sprite = "",
			ChatMessagesContainer_BGColor = "ffffffff",

			RosterContainer_Sprite = "",
			RosterContainer_BGColor = "ffffffff",

			ChatInputContainer_Sprite = "BasicSprites:WhiteFill",
			ChatInputContainer_BGColor = "99120f1e",

			SidebarContainer_Sprite = "BasicSprites:WhiteFill",
			SidebarContainer_BGColor = "99141122",

			SidebarBackground_Sprite = "BasicSprites:WhiteFill",
			SidebarBackground_BGColor = "fa000000",

			SidebarPadding_Sprite = "BasicSprites:WhiteFill",
			SidebarPadding_BGColor = "99141122", 
		},
		{
			Name = "ForgeDark",

			MainForm_Sprite = "",
			MainForm_BGColor = "",

			HeaderContainer_Sprite = "BasicSprites:WhiteFill",
			HeaderContainer_BGColor = "99181818",

			BodyContainer_Sprite = "BasicSprites:WhiteFill",
			BodyContainer_BGColor = "ff181818",

			TabsContainer_Sprite = "BasicSprites:WhiteFill",
			TabsContainer_BGColor = "99151515",

			ChatTabsOptsContainer_Sprite = "",
			ChatTabsOptsContainer_BGColor = "",

			ChatMessagesContainer_Sprite = "",
			ChatMessagesContainer_BGColor = "ffffffff",

			RosterContainer_Sprite = "",
			RosterContainer_BGColor = "ffffffff",

			ChatInputContainer_Sprite = "BasicSprites:WhiteFill",
			ChatInputContainer_BGColor = "99151515",

			SidebarContainer_Sprite = "BasicSprites:WhiteFill",
			SidebarContainer_BGColor = "99181818",

			SidebarBackground_Sprite = "BasicSprites:WhiteFill",
			SidebarBackground_BGColor = "fa000000",

			SidebarPadding_Sprite = "BasicSprites:WhiteFill",
			SidebarPadding_BGColor = "99101010",  
		},
		{
			Name = "HoloLight",

			MainForm_Sprite = "HologramSprites:HoloHorzDivider",
			MainForm_BGColor = "xkcdDeepTeal",

			BodyContainer_Sprite = "",
			BodyContainer_BGColor = "xkcdDarkTeal",

			HeaderContainer_Sprite = "CRB_UIKitSprites:spr_scrollHologramBack",
			HeaderContainer_BGColor = "ff004c4c",

			TabsContainer_Sprite = "",
			TabsContainer_BGColor = "xkcdDeepTeal",

			ChatTabsOptsContainer_Sprite = "",
			ChatTabsOptsContainer_BGColor = "xkcdDeepTeal",

			ChatMessagesContainer_Sprite = "CRB_UIKitSprites:spr_scrollHologramBack",
			ChatMessagesContainer_BGColor = "UI_WindowBGDefault",

			RosterContainer_Sprite = "CRB_UIKitSprites:spr_scrollHologramBack",
			RosterContainer_BGColor = "UI_WindowBGDefault",

			ChatInputContainer_Sprite = "CRB_UIKitSprites:spr_scrollHologramBack",
			ChatInputContainer_BGColor = "UI_WindowBGDefault",

			SidebarContainer_Sprite = "BasicSprites:WhiteFill",
			SidebarContainer_BGColor = "fa000000",

			SidebarBackground_Sprite = "",
			SidebarBackground_BGColor = "",

			SidebarPadding_Sprite = "BasicSprites:WhiteFill",
			SidebarPadding_BGColor = "ff181818",
		},
	}

	return o
end

function Themes:GetCurrentTheme()
	return self.CurrentTheme
end

function Themes:SelectPresetThemeByName(name)
	for _, __ in ipairs(self.PresetThemes) do
		if __.Name == name then
			self.CurrentTheme = __
		end
	end 
end

function Themes:ApplyCurrentThemeToWindow(window)
	local form = window.MainForm

	if window.UseCustomBackground and self.CustomBackgroundTimer then
		self.CustomBackgroundTimer:Stop()
	end

	if form:FindChild("JCC_CharacterProfileWindow") then
		form:FindChild("JCC_CharacterProfileWindow"):SetSprite(self.CurrentTheme.MainForm_Sprite)
		form:FindChild("JCC_CharacterProfileWindow"):SetBGColor(self.CurrentTheme.MainForm_BGColor)
	end

	if form:FindChild("JCC_ChatWindow") then
		form:FindChild("JCC_ChatWindow"):SetSprite(self.CurrentTheme.MainForm_Sprite)
		form:FindChild("JCC_ChatWindow"):SetBGColor(self.CurrentTheme.MainForm_BGColor)
	end

	if form:FindChild("HeaderContainer") then
		form:FindChild("HeaderContainer"):SetSprite(self.CurrentTheme.HeaderContainer_Sprite)
		form:FindChild("HeaderContainer"):SetBGColor(self.CurrentTheme.HeaderContainer_BGColor)
	end

	if form:FindChild("WelcomeTabContainer") then
		form:FindChild("WelcomeTabContainer"):SetSprite(self.CurrentTheme.WelcomeTabContainer_Sprite)
		form:FindChild("WelcomeTabContainer"):SetBGColor(self.CurrentTheme.WelcomeTabContainer_BGColor)
	end

	if form:FindChild("BodyContainer") then
		form:FindChild("BodyContainer"):SetSprite(self.CurrentTheme.BodyContainer_Sprite)
		form:FindChild("BodyContainer"):SetBGColor(self.CurrentTheme.BodyContainer_BGColor)
	end

		if form:FindChild("TabsContainer") then
			form:FindChild("TabsContainer"):SetSprite(self.CurrentTheme.TabsContainer_Sprite)
			form:FindChild("TabsContainer"):SetBGColor(self.CurrentTheme.TabsContainer_BGColor)
		end
		
		if form:FindChild("ChatTabsOptsContainer") then
			form:FindChild("ChatTabsOptsContainer"):SetSprite(self.CurrentTheme.ChatTabsOptsContainer_Sprite)
			form:FindChild("ChatTabsOptsContainer"):SetBGColor(self.CurrentTheme.ChatTabsOptsContainer_BGColor)
		end

		if form:FindChild("ChatMessagesContainer") then
			form:FindChild("ChatMessagesContainer"):SetSprite(self.CurrentTheme.ChatMessagesContainer_Sprite)
			form:FindChild("ChatMessagesContainer"):SetBGColor(self.CurrentTheme.ChatMessagesContainer_BGColor)
		end

		if form:FindChild("RosterContainer") then
			form:FindChild("RosterContainer"):SetSprite(self.CurrentTheme.RosterContainer_Sprite)
			form:FindChild("RosterContainer"):SetBGColor(self.CurrentTheme.RosterContainer_BGColor)
		end

		if form:FindChild("SidebarContainer") then
			form:FindChild("SidebarContainer"):SetSprite(self.CurrentTheme.SidebarContainer_Sprite)
			form:FindChild("SidebarContainer"):SetBGColor(self.CurrentTheme.SidebarContainer_BGColor)
		end

			if form:FindChild("SidebarBackground") then
				form:FindChild("SidebarBackground"):SetSprite(self.CurrentTheme.SidebarBackground_Sprite)
				form:FindChild("SidebarBackground"):SetBGColor(self.CurrentTheme.SidebarBackground_BGColor)
			end

			if form:FindChild("SidebarPaddingStreams") then
				form:FindChild("SidebarPaddingStreams"):SetSprite(self.CurrentTheme.SidebarPadding_Sprite)
				form:FindChild("SidebarPaddingStreams"):SetBGColor(self.CurrentTheme.SidebarPadding_BGColor)
			end

		if form:FindChild("ChannelsSelectorContainer") then
			form:FindChild("ChannelsSelectorContainer"):SetSprite(self.CurrentTheme.SidebarContainer_Sprite)
			form:FindChild("ChannelsSelectorContainer"):SetBGColor(self.CurrentTheme.SidebarContainer_BGColor)
		end

			if form:FindChild("ChannelsSelectorPadding") then
				form:FindChild("ChannelsSelectorPadding"):SetSprite(self.CurrentTheme.SidebarPadding_Sprite)
				form:FindChild("ChannelsSelectorPadding"):SetBGColor(self.CurrentTheme.SidebarPadding_BGColor)
			end

			if form:FindChild("ChannelsSelectorBackground") then
				form:FindChild("ChannelsSelectorBackground"):SetSprite(self.CurrentTheme.SidebarBackground_Sprite)
				form:FindChild("ChannelsSelectorBackground"):SetBGColor(self.CurrentTheme.SidebarBackground_BGColor)
			end

		if form:FindChild("ChatInputContainer") then
			form:FindChild("ChatInputContainer"):SetSprite(self.CurrentTheme.ChatInputContainer_Sprite)
			form:FindChild("ChatInputContainer"):SetBGColor(self.CurrentTheme.ChatInputContainer_BGColor)
		end
end
