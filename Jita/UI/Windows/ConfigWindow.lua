local Jita = Apollo.GetAddon("Jita")
local ConfigWindow = Jita:Extend("ConfigWindow")

local Utils = Jita.Utils
local Consts = Jita.Consts

--

function ConfigWindow:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self

	o.IsConfigWindow = true
	
	o.MainForm = nil

	return o
end

function ConfigWindow:Init()
end

function ConfigWindow:LoadForms()
	self.MainForm = Apollo.LoadForm(Jita.XmlDoc, "JCC_ConfigWindow", nil, self) 

	self.OptsForm = Apollo.LoadForm(Jita.XmlDoc, "OptionsSettingsContent", self.MainForm:FindChild("OptionsSettingsContainer"), self) 

	self.MainForm:FindChild("FooterContainer"):FindChild("Version"):SetText("Jita 0." .. Jita:GetAddonVersion())

	-- these tooltips needs extra formatting 
	self.MainForm:FindChild("InfoButtonTextFloater"):SetTooltip("Relevant messages, according to my objectively superior opinion, are those of:\n \nSystem channel,\nSay and Emotes below 32 meters range,\nWhispers and account whispers,\n\tMessages containing character's name or keywords.\n \nThe Overlay Mode is automatically enabled when main chat window is closed. TextFloater messages are set to be visible for 5.2 seconds and will not be overlapped for the duration.")
	self.MainForm:FindChild("InfoButtonLootFilter"):SetTooltip("When enabled, Jita will attempt to filter out loot messages to:\n \nOmnibits,\nItems of Superb quality or above,\nIn game currency equal or superior to One platinum,\nBuy, sell and repair notices.\n \nNote that other loot messages may still get by due to technicalities.")

	-- Main chat window defines these sets for global use
	-- propagated instead of instant because of laziness
	local mcw = Jita.WindowManager:GetWindow("MainChatWindow")

	if mcw then
		if mcw.GhostMode          ~= nil then Jita.UserSettings.ChatWindow_GhostMode        = mcw.GhostMode          end
		if mcw.ShowRoster         ~= nil then Jita.UserSettings.ChatWindow_ShowRoster       = mcw.ShowRoster         end
		if mcw.MessageDisplayMode ~= nil then Jita.UserSettings.ChatWindow_MessageDisplay   = mcw.MessageDisplayMode end
		if mcw.MessageTextFont    ~= nil then Jita.UserSettings.ChatWindow_MessageTextFont  = mcw.MessageTextFont    end
	end

	local settings = Jita.UserSettings

	local profile = Jita.Player.Profile

	--/- Bio

		if profile then
			local bio = profile.Bio or ""
			local count = 1024 - bio:len()

			self.OptsForm:FindChild("BioEditBox"):SetText(bio)

			self.OptsForm:FindChild("BioCharCount"):SetText(count)

			if count <= 0 then
				self.OptsForm:FindChild("BioCharCount"):SetTextColor("AddonError")
			else
				self.OptsForm:FindChild("BioCharCount"):SetTextColor("gray")
			end

		-- Todo:
		-- else something wrongie did occur
		end

	--/- DefaultStream

		self.OptsForm:FindChild("DefaultStream_General"):SetCheck(settings.DefaultStream == "Default::General")
		self.OptsForm:FindChild("DefaultStream_Local"  ):SetCheck(settings.DefaultStream == "Default::Local"  )

	--/- WindowsTheme

		self.OptsForm:FindChild("WindowsTheme_TealDark" ):SetCheck(settings.WindowsTheme == "TealDark" )
		self.OptsForm:FindChild("WindowsTheme_Viking"   ):SetCheck(settings.WindowsTheme == "Viking"   )
		self.OptsForm:FindChild("WindowsTheme_ForgeDark"):SetCheck(settings.WindowsTheme == "ForgeDark")
		self.OptsForm:FindChild("WindowsTheme_HoloLight"):SetCheck(settings.WindowsTheme == "HoloLight")

	--/- MessageDisplay

		self.OptsForm:FindChild("ChatWindow_MessageDisplay_Block" ):SetCheck(settings.ChatWindow_MessageDisplay == "Block" )
		self.OptsForm:FindChild("ChatWindow_MessageDisplay_Inline"):SetCheck(settings.ChatWindow_MessageDisplay == "Inline")

	--/- MessageText style

		self.OptsForm:FindChild("ChatWindow_MessageTextFont"):SetText(settings.ChatWindow_MessageTextFont)

	--/- ChatWindow_Opacity

		self.OptsForm:FindChild("ChatWindow_Opacity"):FindChild("Slider"    ):SetValue(settings.ChatWindow_Opacity * 100)
		self.OptsForm:FindChild("ChatWindow_Opacity"):FindChild("Slider"    ):SetData("ChatWindow_Opacity")
		self.OptsForm:FindChild("ChatWindow_Opacity"):FindChild("SliderText"):SetText(settings.ChatWindow_Opacity * 100)

	--/- Generic

		self.OptsForm:FindChild("AutoHideChatLogWindows"               ):SetCheck(settings.AutoHideChatLogWindows)
		self.OptsForm:FindChild("ChatWindow_ShowHeader"                ):SetCheck(settings.ChatWindow_ShowHeader)
		self.OptsForm:FindChild("ChatWindow_GhostMode"                 ):SetCheck(settings.ChatWindow_GhostMode)
		self.OptsForm:FindChild("ChatWindow_AutoHideChatTabs"          ):SetCheck(settings.ChatWindow_AutoHideChatTabs)
		self.OptsForm:FindChild("ChatWindow_ShowRoster"                ):SetCheck(settings.ChatWindow_ShowRoster)
		self.OptsForm:FindChild("ChatWindow_RosterLeftClickInfo"       ):SetCheck(settings.ChatWindow_RosterLeftClickInfo)
		self.OptsForm:FindChild("ChatWindow_AutoExpandChatInput"       ):SetCheck(settings.ChatWindow_AutoExpandChatInput)
		self.OptsForm:FindChild("ChatWindow_MessageDetectURLs"         ):SetCheck(settings.ChatWindow_MessageDetectURLs)
		self.OptsForm:FindChild("ChatWindow_MessageShowTimestamp"      ):SetCheck(settings.ChatWindow_MessageShowTimestamp)
		self.OptsForm:FindChild("ChatWindow_MessageShowChannelName"    ):SetCheck(settings.ChatWindow_MessageShowChannelName)
		self.OptsForm:FindChild("ChatWindow_MessageUseChannelAbbr"     ):SetCheck(settings.ChatWindow_MessageUseChannelAbbr)
		self.OptsForm:FindChild("ChatWindow_MessageShowPlayerRange"    ):SetCheck(settings.ChatWindow_MessageShowPlayerRange)
		self.OptsForm:FindChild("ChatWindow_MessageAlertPlayerInRange" ):SetCheck(settings.ChatWindow_MessageAlertPlayerInRange)
		self.OptsForm:FindChild("ChatWindow_MessageShowBubble"         ):SetCheck(settings.ChatWindow_MessageShowBubble)
		self.OptsForm:FindChild("ChatWindow_MessageShowTextFloater"    ):SetCheck(settings.ChatWindow_MessageShowTextFloater)
		self.OptsForm:FindChild("ChatWindow_MessageShowLastViewed"     ):SetCheck(settings.ChatWindow_MessageShowLastViewed)
		self.OptsForm:FindChild("ChatWindow_MessageFilterProfanity"    ):SetCheck(settings.ChatWindow_MessageFilterProfanity)
		self.OptsForm:FindChild("ChatWindow_ChatInputAutoSetFocus"     ):SetCheck(settings.ChatWindow_ChatInputAutoSetFocus)
		self.OptsForm:FindChild("ChatWindow_UseCustomBackgroundPicture"):SetCheck(settings.ChatWindow_UseCustomBackgroundPicture)
		self.OptsForm:FindChild("IIComm_ShareLocation"                 ):SetCheck(settings.IIComm_ShareLocation)
		self.OptsForm:FindChild("EnableLootFilter"                     ):SetCheck(settings.EnableLootFilter)

	--/- limits

		self.OptsForm:FindChild("ChatWindow_MaxChatLines"):FindChild("Slider"    ):SetValue(settings.ChatWindow_MaxChatLines)
		self.OptsForm:FindChild("ChatWindow_MaxChatLines"):FindChild("Slider"    ):SetData("ChatWindow_MaxChatLines")
		self.OptsForm:FindChild("ChatWindow_MaxChatLines"):FindChild("SliderText"):SetText(settings.ChatWindow_MaxChatLines)

		self.OptsForm:FindChild("ChatWindow_MaxChatMembers"):FindChild("Slider"    ):SetValue(settings.ChatWindow_MaxChatMembers)
		self.OptsForm:FindChild("ChatWindow_MaxChatMembers"):FindChild("Slider"    ):SetData("ChatWindow_MaxChatMembers")
		self.OptsForm:FindChild("ChatWindow_MaxChatMembers"):FindChild("SliderText"):SetText(settings.ChatWindow_MaxChatMembers)

		self.OptsForm:FindChild("ChatWindow_SayEmoteRange"):FindChild("Slider"    ):SetValue(settings.ChatWindow_SayEmoteRange)
		self.OptsForm:FindChild("ChatWindow_SayEmoteRange"):FindChild("Slider"    ):SetData("ChatWindow_SayEmoteRange")
		self.OptsForm:FindChild("ChatWindow_SayEmoteRange"):FindChild("SliderText"):SetText(settings.ChatWindow_SayEmoteRange)

	--/- RP

		self.OptsForm:FindChild("ChatWindow_MessageHighlightRolePlay" ):SetCheck(settings.ChatWindow_MessageHighlightRolePlay)
		self.OptsForm:FindChild("ChatWindow_MessageAlienateOutOfRange"):SetCheck(settings.ChatWindow_MessageAlienateOutOfRange)

	--/- keywords

		self.OptsForm:FindChild("ChatWindow_MessageKeywordAlert"    ):SetCheck(settings.ChatWindow_MessageKeywordAlert)
		self.OptsForm:FindChild("ChatWindow_MessageKeywordPlaySound"):SetCheck(settings.ChatWindow_MessageKeywordPlaySound)
		self.OptsForm:FindChild("ChatWindow_MessageKeywordList"     ):SetText(settings.ChatWindow_MessageKeywordList)

	--/- Text Color thing

	if not self.GeminiColor then
		self.GeminiColor = Apollo.GetPackage("GeminiColor").tPackage
	end

	self:PopulateColorPalette()
	
	--/- 

	self.MainForm:Show(true, true)

	-- Keepme:
	-- self.MainForm:FindChild("BioEditBox"):SetFocus()
end

function ConfigWindow:OnShiftChatFontLeftButtonClick()  
	if not self.MessageTextFontIndex then
		self.MessageTextFontIndex = Utils:KeyByVal(Consts.ChatMessagesFonts, self.OptsForm:FindChild("ChatWindow_MessageTextFont" ):GetText()) or 1
	end

	self.MessageTextFontIndex = self.MessageTextFontIndex - 1

	if self.MessageTextFontIndex < 1 then self.MessageTextFontIndex = #Consts.ChatMessagesFonts end

	local font = Consts.ChatMessagesFonts[self.MessageTextFontIndex]

	if not font then
		return
	end

	self.OptsForm:FindChild("ChatWindow_MessageTextFont"):SetText(font) 
end

function ConfigWindow:OnShiftChatFontRightButtonClick()

	if not self.MessageTextFontIndex then
		self.MessageTextFontIndex = Utils:KeyByVal(Consts.ChatMessagesFonts, self.OptsForm:FindChild("ChatWindow_MessageTextFont" ):GetText()) or 1
	end

	self.MessageTextFontIndex = self.MessageTextFontIndex + 1

	if self.MessageTextFontIndex > #Consts.ChatMessagesFonts then self.MessageTextFontIndex = 1 end

	local font = Consts.ChatMessagesFonts[self.MessageTextFontIndex]
	
	if not font then
		return
	end

	self.OptsForm:FindChild("ChatWindow_MessageTextFont"):SetText(font)
end

function ConfigWindow:OnSliderBarChanged(wndHandler, wndControl)
	local sliderName = wndControl:GetData()
	
	if not sliderName then
		return
	end

	self.OptsForm:FindChild(sliderName):FindChild("SliderText"):SetText(
		tonumber(self.OptsForm:FindChild(sliderName):FindChild("Slider"):GetValue())
	)
end

function ConfigWindow:OnApplyButtonClick()
	local satuts = self.MainForm:FindChild("FooterContainer"):FindChild("Status")

	satuts:SetText("Updating chat options and settings.")
	satuts:SetTextColor("UI_TextMetalGoldHighlight")
	satuts:SetFont("CRB_Interface10")

	--/- Bio

		local bio = self.OptsForm:FindChild("BioEditBox"):GetText()
		
		local profile = Jita.Player.Profile

		if profile then
			profile:Update("Bio", bio)
		end

	--/- DefaultStream

		local defaultStream = Jita.Client:GetStream(Jita.UserSettings.DefaultStream)

		if defaultStream then
			defaultStream.Closeable = true
		end

		if self.OptsForm:FindChild("DefaultStream_General"):IsChecked() then Jita.UserSettings.DefaultStream = "Default::General" end
		if self.OptsForm:FindChild("DefaultStream_Local"  ):IsChecked() then Jita.UserSettings.DefaultStream = "Default::Local"   end

		defaultStream = Jita.Client:GetStream(Jita.UserSettings.DefaultStream)

		if defaultStream then
			defaultStream.Closed    = false
			defaultStream.Closeable = false
			defaultStream.Ignored   = false
		end

	--/- WindowsTheme

		if self.OptsForm:FindChild("WindowsTheme_TealDark" ):IsChecked() then Jita.UserSettings.WindowsTheme = "TealDark"  end
		if self.OptsForm:FindChild("WindowsTheme_Viking"   ):IsChecked() then Jita.UserSettings.WindowsTheme = "Viking"    end
		if self.OptsForm:FindChild("WindowsTheme_ForgeDark"):IsChecked() then Jita.UserSettings.WindowsTheme = "ForgeDark" end
		if self.OptsForm:FindChild("WindowsTheme_HoloLight"):IsChecked() then Jita.UserSettings.WindowsTheme = "HoloLight" end

	--/- MessageDisplay

		if self.OptsForm:FindChild("ChatWindow_MessageDisplay_Block" ):IsChecked() then Jita.UserSettings.ChatWindow_MessageDisplay = "Block"  end
		if self.OptsForm:FindChild("ChatWindow_MessageDisplay_Inline"):IsChecked() then Jita.UserSettings.ChatWindow_MessageDisplay = "Inline" end

	--/- MessageText style

		Jita.UserSettings.ChatWindow_MessageTextFont  = self.OptsForm:FindChild("ChatWindow_MessageTextFont" ):GetText()

		if self.ColorPalette then
			for idx, color in pairs(self.ColorPalette) do
				Consts.ChatMessagesColors[idx] = ApolloColor.new(color)
			end
		end

		for _, stream in ipairs(Jita.Client.Streams) do
			for _, message in ipairs(stream.Messages) do
				message.XmlObj = nil
			end
		end

	--/- ChatWindow_Opacity

		Jita.UserSettings.ChatWindow_Opacity = tonumber(self.OptsForm:FindChild("ChatWindow_Opacity"):FindChild("Slider"):GetValue()) / 100

	--/- Generic

		Jita.UserSettings.AutoHideChatLogWindows                = false
	        Jita.UserSettings.ChatWindow_ShowHeader                 = false
	        Jita.UserSettings.ChatWindow_GhostMode                  = false
	        Jita.UserSettings.ChatWindow_AutoHideChatTabs           = false
	        Jita.UserSettings.ChatWindow_ShowRoster                 = false
	        Jita.UserSettings.ChatWindow_RosterLeftClickInfo        = false
	        Jita.UserSettings.ChatWindow_AutoExpandChatInput        = false
	        Jita.UserSettings.ChatWindow_MessageDetectURLs          = false
	        Jita.UserSettings.ChatWindow_MessageShowTimestamp       = false
	        Jita.UserSettings.ChatWindow_MessageShowChannelName     = false
	        Jita.UserSettings.ChatWindow_MessageUseChannelAbbr      = false
	        Jita.UserSettings.ChatWindow_MessageShowPlayerRange     = false
	        Jita.UserSettings.ChatWindow_MessageAlertPlayerInRange  = false
	        Jita.UserSettings.ChatWindow_MessageShowBubble          = false
	        Jita.UserSettings.ChatWindow_MessageShowTextFloater     = false
	        Jita.UserSettings.ChatWindow_MessageShowLastViewed      = false
	        Jita.UserSettings.ChatWindow_MessageFilterProfanity     = false
	        Jita.UserSettings.ChatWindow_ChatInputAutoSetFocus      = false
	        Jita.UserSettings.ChatWindow_UseCustomBackgroundPicture = false
	        Jita.UserSettings.IIComm_ShareLocation                  = false
	        Jita.UserSettings.EnableLootFilter                      = false

		if self.OptsForm:FindChild("AutoHideChatLogWindows"               ):IsChecked() then Jita.UserSettings.AutoHideChatLogWindows                = true end
		if self.OptsForm:FindChild("ChatWindow_ShowHeader"                ):IsChecked() then Jita.UserSettings.ChatWindow_ShowHeader                 = true end
		if self.OptsForm:FindChild("ChatWindow_GhostMode"                 ):IsChecked() then Jita.UserSettings.ChatWindow_GhostMode                  = true end
		if self.OptsForm:FindChild("ChatWindow_AutoHideChatTabs"          ):IsChecked() then Jita.UserSettings.ChatWindow_AutoHideChatTabs           = true end
		if self.OptsForm:FindChild("ChatWindow_ShowRoster"                ):IsChecked() then Jita.UserSettings.ChatWindow_ShowRoster                 = true end
		if self.OptsForm:FindChild("ChatWindow_RosterLeftClickInfo"       ):IsChecked() then Jita.UserSettings.ChatWindow_RosterLeftClickInfo        = true end
		if self.OptsForm:FindChild("ChatWindow_AutoExpandChatInput"       ):IsChecked() then Jita.UserSettings.ChatWindow_AutoExpandChatInput        = true end
		if self.OptsForm:FindChild("ChatWindow_MessageDetectURLs"         ):IsChecked() then Jita.UserSettings.ChatWindow_MessageDetectURLs          = true end
		if self.OptsForm:FindChild("ChatWindow_MessageShowTimestamp"      ):IsChecked() then Jita.UserSettings.ChatWindow_MessageShowTimestamp       = true end
		if self.OptsForm:FindChild("ChatWindow_MessageShowChannelName"    ):IsChecked() then Jita.UserSettings.ChatWindow_MessageShowChannelName     = true end
		if self.OptsForm:FindChild("ChatWindow_MessageUseChannelAbbr"     ):IsChecked() then Jita.UserSettings.ChatWindow_MessageUseChannelAbbr      = true end
		if self.OptsForm:FindChild("ChatWindow_MessageShowPlayerRange"    ):IsChecked() then Jita.UserSettings.ChatWindow_MessageShowPlayerRange     = true end
		if self.OptsForm:FindChild("ChatWindow_MessageAlertPlayerInRange" ):IsChecked() then Jita.UserSettings.ChatWindow_MessageAlertPlayerInRange  = true end
		if self.OptsForm:FindChild("ChatWindow_MessageShowBubble"         ):IsChecked() then Jita.UserSettings.ChatWindow_MessageShowBubble          = true end
		if self.OptsForm:FindChild("ChatWindow_MessageShowTextFloater"    ):IsChecked() then Jita.UserSettings.ChatWindow_MessageShowTextFloater     = true end
		if self.OptsForm:FindChild("ChatWindow_MessageShowLastViewed"     ):IsChecked() then Jita.UserSettings.ChatWindow_MessageShowLastViewed      = true end
		if self.OptsForm:FindChild("ChatWindow_MessageFilterProfanity"    ):IsChecked() then Jita.UserSettings.ChatWindow_MessageFilterProfanity     = true end
		if self.OptsForm:FindChild("ChatWindow_ChatInputAutoSetFocus"     ):IsChecked() then Jita.UserSettings.ChatWindow_ChatInputAutoSetFocus      = true end
		if self.OptsForm:FindChild("ChatWindow_UseCustomBackgroundPicture"):IsChecked() then Jita.UserSettings.ChatWindow_UseCustomBackgroundPicture = true end
		if self.OptsForm:FindChild("IIComm_ShareLocation"                 ):IsChecked() then Jita.UserSettings.IIComm_ShareLocation                  = true end
		if self.OptsForm:FindChild("EnableLootFilter"                     ):IsChecked() then Jita.UserSettings.EnableLootFilter                      = true end

	--/- limits

		Jita.UserSettings.ChatWindow_MaxChatLines   = tonumber(self.OptsForm:FindChild("ChatWindow_MaxChatLines"  ):FindChild("Slider"):GetValue())
		Jita.UserSettings.ChatWindow_MaxChatMembers = tonumber(self.OptsForm:FindChild("ChatWindow_MaxChatMembers"):FindChild("Slider"):GetValue())
		Jita.UserSettings.ChatWindow_SayEmoteRange  = tonumber(self.OptsForm:FindChild("ChatWindow_SayEmoteRange" ):FindChild("Slider"):GetValue())

		if not Jita.UserSettings.ChatWindow_MaxChatLines
		or Jita.UserSettings.ChatWindow_MaxChatLines > Jita.CoreSettings.ChatWindow_MaxChatLines then
			Jita.UserSettings.ChatWindow_MaxChatLines = Jita.CoreSettings.ChatWindow_MaxChatLines
		end

		if not Jita.UserSettings.ChatWindow_MaxChatMembers
		or Jita.UserSettings.ChatWindow_MaxChatMembers > Jita.CoreSettings.ChatWindow_MaxChatMembers then
			Jita.UserSettings.ChatWindow_MaxChatMembers = Jita.CoreSettings.ChatWindow_MaxChatMembers
		end

		if not Jita.UserSettings.ChatWindow_SayEmoteRange
		or Jita.UserSettings.ChatWindow_SayEmoteRange > Jita.CoreSettings.ChatWindow_SayEmoteRange then
			Jita.UserSettings.ChatWindow_SayEmoteRange = Jita.CoreSettings.ChatWindow_SayEmoteRange
		end

		if Jita.UserSettings.EnableLootFilter == true then
			Jita.UserSettings.LootFilter_MinCoppers = 1000000
			Jita.UserSettings.LootFilter_MinQuality = Item.CodeEnumItemQuality.Superb
		else
			Jita.UserSettings.EnableLootFilter      = false
			Jita.UserSettings.LootFilter_MinCoppers = 0
			Jita.UserSettings.LootFilter_MinQuality = 0
		end

	--/- RP
	        Jita.UserSettings.ChatWindow_MessageHighlightRolePlay  = false
	        Jita.UserSettings.ChatWindow_MessageAlienateOutOfRange = false

		if self.OptsForm:FindChild("ChatWindow_MessageHighlightRolePlay" ):IsChecked() then Jita.UserSettings.ChatWindow_MessageHighlightRolePlay  = true end
		if self.OptsForm:FindChild("ChatWindow_MessageAlienateOutOfRange"):IsChecked() then Jita.UserSettings.ChatWindow_MessageAlienateOutOfRange = true end

	--/- keywords

	        Jita.UserSettings.ChatWindow_MessageKeywordAlert     = false
	        Jita.UserSettings.ChatWindow_MessageKeywordPlaySound = false
	        Jita.UserSettings.ChatWindow_MessageKeywordList      = ""

		if self.OptsForm:FindChild("ChatWindow_MessageKeywordAlert"     ):IsChecked() then Jita.UserSettings.ChatWindow_MessageKeywordAlert     = true end
		if self.OptsForm:FindChild("ChatWindow_MessageKeywordPlaySound" ):IsChecked() then Jita.UserSettings.ChatWindow_MessageKeywordPlaySound = true end

		Jita.UserSettings.ChatWindow_MessageKeywordList = tostring(self.OptsForm:FindChild("ChatWindow_MessageKeywordList"):GetText())

	--/- Apply

		Jita.Client:SetConsoleVariables()

		--

		if Jita.UserSettings.ChatWindow_UseCustomBackgroundPicture
		and not Apollo.IsSpriteLoaded("Jita_ChatWindow_Background")
		then
			Apollo.LoadSprites("Views/Sprites.xml")
		end

		--

		Jita.WindowManager.Themes:SelectPresetThemeByName(Jita.UserSettings.WindowsTheme)

		for _, window in pairs(Jita.WindowManager.Windows) do
			if window.MainForm and window.MainForm:IsValid() and not window.IsConfigWindow then
				Jita.WindowManager.Themes:ApplyCurrentThemeToWindow(window)

				if window.IsChatWindow
				and Jita.UserSettings.ChatWindow_UseCustomBackgroundPicture
				then
					window:ApplyCustomBackgroundToChatWindows()
				end
			end
		end

		--

		for _, window in pairs(Jita.WindowManager.Windows) do
			if window.MainForm and window.MainForm:IsValid() and window.IsChatWindow then
				window.MentionsAndKeywords = nil

				window:HideSidebar()
				window:GenerateChatTabs()

				window:SetWindowOpacity(Jita.UserSettings.ChatWindow_Opacity)

				if Jita.UserSettings.ChatWindow_AutoHideChatTabs == true then
					window.MainForm:FindChild("TabsContainer"):SetOpacity(0)
				else
					window.MainForm:FindChild("TabsContainer"):SetOpacity(1)
				end

				if Jita.UserSettings.ChatWindow_GhostMode == false then
					window.MainForm:FindChild("TabsContainer"):SetOpacity(1)
				end
			end
		end

		--

		for _, window in pairs(Jita.WindowManager.Windows) do
			if window.MainForm and window.MainForm:IsValid() and window.IsChatWindow then
				window.MessageTextFont    = Jita.UserSettings.ChatWindow_MessageTextFont
				window.MessageDisplayMode = Jita.UserSettings.ChatWindow_MessageDisplay 

				-- bleh
				window:SelectChatTab(window.SelectedStream)
			end
		end

		--

		local chatLogWindow = Apollo.FindWindowByName("ChatWindow")

		if chatLogWindow and chatLogWindow:IsValid() then
			chatLogWindow:Show(not Jita.UserSettings.AutoHideChatLogWindows)
		end

		--

		if Jita.WindowManager:GetWindow("MainChatWindow") then
			Jita.WindowManager:GetWindow("MainChatWindow"):SetHeaderContainerVisibity()
		end

		--

		for _, window in pairs(Jita.WindowManager.Windows) do
			if window.IsChatWindow then
				window.GhostMode  = Jita.UserSettings.ChatWindow_GhostMode
				window.ShowRoster = Jita.UserSettings.ChatWindow_ShowRoster

				window:SetRosterVisibility()
			end
		end

	--/-

	satuts:SetText("Options and settings updated.")
end

function ConfigWindow:OnBioEditBoxChanged(wndHandler, wndControl, text)
	local count = 1024 - text:len()

	self.OptsForm:FindChild("BioCharCount"):SetText(count)

	if count <= 0 then
		self.OptsForm:FindChild("BioCharCount"):SetTextColor("AddonError")
	else
		self.OptsForm:FindChild("BioCharCount"):SetTextColor("gray")
	end
end

function ConfigWindow:OnCloseButtonClick()
	self.MainForm:Destroy() 

	Jita.WindowManager:RemoveWindow("ConfigWindow")
end

--

function ConfigWindow:PopulateColorPalette()
	self.MainForm:FindChild("PalettePaneInfoButtonMain"):SetTooltip(
		"Main chat channels color scheme.\nHover over cells for channels names. Click to invoke Color Picker."
	)

	self.MainForm:FindChild("PalettePaneInfoButtonSub"):SetTooltip(
		"Role play and special highlighting.\nHover over cells for details. Click to invoke Color Picker."
	)
	
	self.ColorPalette = {}

	for var, val in pairs(ChatSystemLib) do
		if string.match(var, 'ChatChannel_') then
			self:PopulateColorPaletteCell(var, val)
		end
	end

	self:PopulateColorPaletteCell("Highlight_OOC"     , "O", "OOC comments.\nApplies when \"Highlight Roleplay Messages and Emotes\" is enabled.")
	self:PopulateColorPaletteCell("Highlight_Emote"   , "A", "Inline emotes (asterisks and ltgt).\nApplies when \"Highlight Roleplay Messages and Emotes\" is enabled.")
	self:PopulateColorPaletteCell("Highlight_Quote"   , "Q", "Quotes.\nApplies when \"Highlight Roleplay Messages and Emotes\" is enabled.")
	self:PopulateColorPaletteCell("Highlight_Keyword" , "K", "Keywords.\nApplies when \"Enable Keyword Notifications\" is enabled.")
	self:PopulateColorPaletteCell("Highlight_URL"     , "U", "Links.\nApplies when \"Make URLs Clickable\" is enabled.")
end

function ConfigWindow:PopulateColorPaletteCell(ctrlName, colorIdx, tooltip)
	local ctrl = self.MainForm:FindChild("PalettePane"):FindChild(ctrlName)

	if not ctrl then
		return
	end

	local color = Consts.ChatMessagesColors[ colorIdx ]

	if not color then
		return
	end

	local argb = color:GetColorString()

	if not argb then
		return
	end

	if tooltip then
		ctrl:SetTooltip(tooltip)
	end

	ctrl:SetData({Idx = colorIdx, Color = argb})
	ctrl:FindChild("BG"):SetBGColor(argb)
	ctrl:FindChild("ColorBtn"):SetData("RGB")

	self.ColorPalette[colorIdx] = argb
end

function ConfigWindow:OnBtnChooseColor(wndHandler, wndControl)
-- (a) LUI addons

	if not self.GeminiColor then
		return
	end

	local setting = wndControl:GetParent():GetData()

	if not setting then
		return
	end

	self.GeminiColor:ShowColorPicker(self, {
		callback        = "OnColorPicker",
		strInitialColor = setting.Color,
		bCustomColor    = true,
		bAlpha          = false,
	}, wndControl)
end

function ConfigWindow:OnColorPicker(wndHandler, wndControl)
-- (a) LUI addons

	if not wndHandler then
		return
	end

	local setting = wndControl:GetParent():GetData()

	if not setting then
		return
	end

	local argb

	if type(wndHandler) == "string" then
		argb = wndHandler
	end

	if not argb or string.len(argb) ~= 8 then
		return
	end

	wndControl:GetParent():FindChild("BG"):SetBGColor(argb)
	wndControl:GetParent():GetParent():SetData(argb)

	self.ColorPalette[setting.Idx] = argb
end
