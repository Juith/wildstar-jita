local Jita = Apollo.GetAddon("Jita")
local ChatWindow = Jita:Extend("ChatWindow")

local Consts = Jita.Consts
local Utils = Jita.Utils

--

function ChatWindow:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self

	o.IsChatWindow       = true
	o.IsClone            = false
	o.GhostMode          = false 
	o.ShowRoster         = true 
	o.SelectedStream     = nil
	o.MessageTextFont    = nil 
	o.MessageDisplayMode = nil 
	o.MainFormLastWidth  = nil 
	o.MainFormLocation   = nil 

	o.MainForm           = nil
	o.HasFocus           = false

	return o
end

function ChatWindow:Init()
	self.SelectedStream       = Jita.UserSettings.DefaultStream
	self.GhostMode            = Jita.UserSettings.ChatWindow_GhostMode
	self.MessageTextFont      = Jita.UserSettings.ChatWindow_MessageTextFont
	self.MessageDisplayMode   = Jita.UserSettings.ChatWindow_MessageDisplay

	self.Links = {}
	self.NextLinkIndex = 1 
	self.ItemTooltipWindows = {} 

	-- Keepme:
	-- might get used for any possible key-bindings
	-- Apollo.RegisterEventHandler("SystemKeyDown", "OnSystemKeyDown", self)
end

function ChatWindow:Tick()
	if not self.MainForm or not self.MainForm:IsValid() then
		return
	end

	-- there should be a better way to handle this.
	if self.MainForm:ContainsMouse() then
		self:OnMainFormMouseEnter()
	else
		self:OnMainFormMouseExit()
	end

	-- Todo:
	-- dirty trick to fit chat input to text size and to get prompt to reset.
	-- need to investigate an alternative
	self:ValidateChatInput()

	if Jita.Timestamp % Jita.CoreSettings.RosterRefreshInterval == 0 then
		self:GenerateRoster()
	end

	if not self.IsClone and not self.IsPlayerModelLoaded then
		self:LoadedPlayerModel()
	end

	if #Jita.Client.Notifications > 0 then
		self.MainForm:FindChild('NotificationButton'):Show(true)
	else
		self.MainForm:FindChild('NotificationButton'):Show(false)
	end
end

function ChatWindow:GetState()
	local state = {
		IsClone            = self.IsClone,
		SelectedStream     = self.SelectedStream,
		GhostMode          = self.GhostMode,
		ShowRoster         = self.ShowRoster,
		MessageTextFont    = self.MessageTextFont,
		MessageDisplayMode = self.MessageDisplayMode,
		MainFormLastWidth  = self.MainFormLastWidth,
		MainFormLocation   = self.MainForm:GetLocation():ToTable(),
	}

	return state
end

function ChatWindow:RestoreSavedState(state)
	if not state then
		return
	end

	self.IsClone            = state.IsClone
	self.GhostMode          = state.GhostMode          or false
	self.ShowRoster         = state.ShowRoster         or false
	self.MessageTextFont    = state.MessageTextFont    or Jita.UserSettings.ChatWindow_MessageTextFont
	self.MessageDisplayMode = state.MessageDisplayMode or Jita.UserSettings.ChatWindow_MessageDisplay
	self.MainFormLastWidth  = state.MainFormLastWidth
	self.MainFormLocation   = state.MainFormLocation

	if self.IsClone then
		self.SelectedStream = state.SelectedStream

		self:SelectChatTab(self.SelectedStream) 
	end

	self:SetRosterVisibility()

	if self.GhostMode == true then
		self.MainForm:SetStyle("RequireMetaKeyToMove", true)
	else
		self.MainForm:SetStyle("RequireMetaKeyToMove", false)
	end

	self:GenerateRoster()
	self:GenerateChatTabs()

	self.MainForm:MoveToLocation(WindowLocation.new(self.MainFormLocation))
end

function ChatWindow:LoadForms()
	self.MainForm = Apollo.LoadForm(Jita.XmlDoc, "JCC_ChatWindow", nil, self) 

	--

	self.LoadingContainer                         = self.MainForm:FindChild("LoadingContainer")

	self.HeaderContainer                          = self.MainForm:FindChild("HeaderContainer")

	self.BodyContainer                            = self.MainForm:FindChild("BodyContainer")
		self.TabsContainer                    = self.BodyContainer:FindChild("TabsContainer")
		self.ChatTabsOptsContainer            = self.BodyContainer:FindChild("ChatTabsOptsContainer")

		self.ChatMessagesContainer            = self.BodyContainer:FindChild("ChatMessagesContainer") 
			self.ChatMessagesPane         = self.ChatMessagesContainer:FindChild("ChatMessagesPane") 

		self.ChannelsSelectorContainer        = self.BodyContainer:FindChild("ChannelsSelectorContainer")
			self.ChannelsSelectorListPane = self.ChannelsSelectorContainer:FindChild("ChannelsSelectorListPane")

		self.RosterContainer                  = self.BodyContainer:FindChild("RosterContainer")
			self.RosterPane               = self.RosterContainer:FindChild("RosterPane")
			self.RosterIcoLoading         = self.RosterContainer:FindChild("RosterIcoLoading")
			self.RosterIcoLocked          = self.RosterContainer:FindChild("RosterIcoLocked")
			self.RosterIcoTruncated       = self.RosterContainer:FindChild("RosterIcoTruncated")

		self.SidebarContainer                 = self.BodyContainer:FindChild("SidebarContainer")
			self.SidebarStreamsListPane   = self.SidebarContainer:FindChild("SidebarStreamsListPane")

		self.ChannelsSelectorContainer        = self.MainForm:FindChild("ChannelsSelectorContainer")
			self.ChannelsSelectorListPane = self.ChannelsSelectorContainer:FindChild("ChannelsSelectorListPane")

		self.ChatInputContainer               = self.BodyContainer:FindChild("ChatInputContainer")
			self.ChatInputBackground      = self.ChatInputContainer:FindChild("ChatInputBackground")
			self.ChatInputExpandHelper    = self.ChatInputContainer:FindChild("ChatInputExpandHelper")
			self.ChatInputSpellingHelper  = self.ChatInputContainer:FindChild("ChatInputSpellingHelper")
			self.ChatInputEditBox         = self.ChatInputContainer:FindChild("ChatInputEditBox")

	--

	self.PlayerPortrait = self.MainForm:FindChild("PlayerPortrait")
	self.TestPortrait   = self.MainForm:FindChild("TestPortrait")

	--

	self:SetHeaderContainerVisibity()

	self.MainForm:Show(false, true)

	Jita.WindowManager.Themes:ApplyCurrentThemeToWindow(self)

	if Jita.UserSettings.ChatWindow_UseCustomBackgroundPicture == true then 
		self:ApplyCustomBackgroundToChatWindows()

		-- Will give it one second to load before we double tab
		if not self.CustomBackgroundTimer then
			self.CustomBackgroundTimer = ApolloTimer.Create(1.0, false, "ApplyCustomBackgroundToChatWindows", self)
		end
	end

	self.ChatInputMultiLine = false

	self.ChatInputEditBox:SetFont(self.MessageTextFont) 

	self:CreateSuggestedMenu(self.ChatInputEditBox)

	self:SetWindowOpacity(Jita.UserSettings.ChatWindow_Opacity)

	-- Events hook related to UI

	Apollo.RegisterEventHandler("GenericEvent_LinkItemToChat"    , "OnLinkItemToChat", self)
	Apollo.RegisterEventHandler("GenericEvent_QuestLink"         , "OnQuestLink"     , self)
	Apollo.RegisterEventHandler("GenericEvent_ArchiveArticleLink", "OnArticleLink"   , self)
end

--

function ChatWindow:SetWindowOpacity(opacity)
	local rate = 5

	self.MainForm:SetNCOpacity(opacity, rate)
	self.MainForm:SetBGOpacity(opacity, rate)

	self.BodyContainer:SetNCOpacity(opacity, rate)
	self.BodyContainer:SetBGOpacity(opacity, rate)

		self.TabsContainer:SetNCOpacity(opacity, rate)
		self.TabsContainer:SetBGOpacity(opacity, rate)

		self.ChatTabsOptsContainer:SetNCOpacity(opacity, rate)
		self.ChatTabsOptsContainer:SetBGOpacity(opacity, rate)

		self.ChatMessagesContainer:SetNCOpacity(opacity, rate)
		self.ChatMessagesContainer:SetBGOpacity(opacity, rate)

			self.ChatMessagesPane:SetNCOpacity(opacity, rate) -- sets scroll bar opacity

		self.RosterContainer:SetNCOpacity(opacity, rate)
		self.RosterContainer:SetBGOpacity(opacity, rate)

			self.RosterPane:SetNCOpacity(opacity, rate) -- sets scroll bar opacity

		self.ChatInputContainer:SetNCOpacity(opacity, rate)
		self.ChatInputContainer:SetBGOpacity(opacity, rate)
end

function ChatWindow:OnSystemKeyDown(key)
--/- unimplemented

end

function ChatWindow:OnWindowKeyEscape()
--/- unimplemented

end

function ChatWindow:OnWindowGainedFocus()
	self.HasFocus = true
end

function ChatWindow:OnWindowLostFocus()
	self.HasFocus = false
end

function ChatWindow:OnWindowToFront(wndHandler, wndControl)
	if Jita.UserSettings.ChatWindow_ChatInputAutoSetFocus == false then
		return true
	end

	self.ChatInputEditBox:SetFocus()

	self.HasFocus = true

	return true
end

function ChatWindow:OnMainFormMove()
	if self.ResizeMainFormTimer then
		self.ResizeMainFormTimer:Stop()
	end

	self.ResizeMainFormTimer = ApolloTimer.Create(0.2, false, "OnResizeMainFormTimer", self)

	-- keepme:
	-- if self.ResizeMainFormReTimer then
		-- self.ResizeMainFormTimer:Stop()
	-- end
	-- self.LoadingContainer:Show(true)
	-- self.LoadingContainer:SetStyle("AutoFade", true)
	-- self.ResizeMainFormTimer   = ApolloTimer.Create(0.5, false, "OnResizeMainFormTimer"  , self)
	-- self.ResizeMainFormReTimer = ApolloTimer.Create(1.0, false, "OnResizeMainFormReTimer", self)
end

function ChatWindow:OnResizeMainFormTimer()
	if self.MainForm:GetWidth() ~= self.MainFormLastWidth then
		self:GenerateChatTabs()
		self:GenerateChatMessagesPane()
		self:ValidateChatInput()
		self.MainFormLastWidth = self.MainForm:GetWidth()
	end
end

function ChatWindow:OnResizeMainFormReTimer()
	if self.MainForm:GetWidth() == self.MainFormLastWidth then
		self.ChatMessagesPane:SetVScrollPos(999999)
		self.LoadingContainer:SetStyle("AutoFade", false)
		self.LoadingContainer:Show(false)
	end
end

function ChatWindow:OnMainFormMouseEnter() 
	self:ToggleTabsOptsContainer()
	self:ToggleScrollbars()

	if self.GhostMode == false then
		return
	else
		if self.MainForm:ContainsMouse() == false then
			return
		end
	end

	--

	local currentTheme = Jita.WindowManager.Themes:GetCurrentTheme()

	if Jita.UserSettings.ChatWindow_AutoHideChatTabs == true then
		self.TabsContainer:SetOpacity(1)
	end

	self.RosterIcoLoading:SetOpacity(1) 
	self.RosterIcoLocked:SetOpacity(1) 
	self.RosterIcoTruncated:SetOpacity(1) 

	self.MainForm:SetSprite(currentTheme.MainForm_Sprite)
	self.HeaderContainer:SetSprite(currentTheme.HeaderContainer_Sprite)
	self.BodyContainer:SetSprite(currentTheme.BodyContainer_Sprite)
	self.TabsContainer:SetSprite(currentTheme.TabsContainer_Sprite)
	self.ChatTabsOptsContainer:SetSprite(currentTheme.ChatTabsOptsContainer_Sprite)
	self.ChatMessagesContainer:SetSprite(currentTheme.ChatMessagesContainer_Sprite)
	self.RosterContainer:SetSprite(currentTheme.RosterContainer_Sprite) 
	self.ChatInputContainer:SetSprite(currentTheme.ChatInputContainer_Sprite)

	self:SetWindowOpacity(Jita.UserSettings.ChatWindow_Opacity)

	if Jita.UserSettings.ChatWindow_UseCustomBackgroundPicture == true then
		self:ApplyCustomBackgroundToChatWindows()
	end
end

function ChatWindow:OnMainFormMouseExit() 
	self:ToggleTabsOptsContainer() 
	self:ToggleScrollbars() 

	if self.GhostMode == false then 

		return
	else
		if self.MainForm:ContainsMouse() == true then
			return
		else
			self:HideSidebar()
		end
	end

	--

	if Jita.UserSettings.ChatWindow_AutoHideChatTabs == true then
		self.TabsContainer:SetOpacity(0) 
	end

	self.RosterIcoLoading:SetOpacity(0) 
	self.RosterIcoLocked:SetOpacity(0) 
	self.RosterIcoTruncated:SetOpacity(0) 

	self.MainForm:SetSprite("")
	self.HeaderContainer:SetSprite("")
	self.BodyContainer:SetSprite("")
	self.TabsContainer:SetSprite("")
	self.ChatTabsOptsContainer:SetSprite("")
	self.ChatMessagesContainer:SetSprite("")
	self.RosterContainer:SetSprite("")

	self:SetWindowOpacity(0) 

	self.ChatInputContainer:SetSprite()
	self.ChatInputContainer:SetBGOpacity(0)

	-- Keepme:
	-- make it obvious that input is still on focus
	-- if self.HasFocus == true then
		-- self.ChatInputContainer:SetBGOpacity(.6)
	-- end
end

--

function ChatWindow:ApplyCustomBackgroundToChatWindows()
	self.MainForm:SetSprite("Jita_ChatWindow_Background")
	self.MainForm:SetBGColor("ffffffff")
end
