local Jita = Apollo.GetAddon("Jita")
local ChatWindow = Jita:Extend("ChatWindow")

local Consts = Jita.Consts
local Utils = Jita.Utils

--

function ChatWindow:OnNotificationButtonClick()
	Jita.WindowManager:LoadWindow("NotificationWindow", { LoadForms = true})
end

function ChatWindow:OnGhostModeButtonClick()
	if self.GhostMode == false then
		self.GhostMode = true

		if self.MainForm:ContainsMouse() then
			self:OnMainFormMouseEnter()
		else
			self:OnMainFormMouseExit()
		end

		self.MainForm:SetStyle("RequireMetaKeyToMove", true)
	else
		self.GhostMode = false
		
		self.MainForm:SetStyle("RequireMetaKeyToMove", false)
	end
end

function ChatWindow:OnConfigButtonClick()
	Jita.WindowManager:LoadWindow("ConfigWindow", { LoadForms = true})

	self:HideSidebar()
end

function ChatWindow:OnDebugButtonClick()
	if Jita.CoreSettings.EnableDebugWindow then
		return
	end

	Jita.WindowManager:LoadWindow("DebugWindow", { LoadForms = true})

	Jita.CoreSettings.EnableDebugWindow = true
end

function ChatWindow:OnCloseButtonClick()
	-- if main chat window we store state in a kind of cache so it doesn't
	-- reset to default when opening window again
	if not self.IsClone then
		Jita.WindowManager.MainChatWindowStateCache = self:GetState()
	end

	self.MainForm:Close()
	self.MainForm:Destroy()

	Jita.WindowManager:RemoveWindow(self.Name)

	if not self.IsClone then
		if not  Jita.WindowManager:GetWindow("OverlayWindow") then
			Jita.WindowManager:LoadWindow("OverlayWindow", { LoadForms = true })
		end

		Jita.WindowManager:GetWindow("OverlayWindow"):Invoke()
	end
end

--

function ChatWindow:SetHeaderContainerVisibity()
	if Jita.UserSettings.ChatWindow_ShowHeader == true then
		self.PlayerPortrait:Show(true)
		self.HeaderContainer:Show(true)

		local nLeft, nTop, nRight, nBottom = self.BodyContainer:GetAnchorOffsets()
		self.BodyContainer:SetAnchorOffsets(nLeft, 26, nRight, nBottom)

		self.HeaderContainer:FindChild("MainFormTitle"):SetText(Jita:GetAddonName())
	elseif self.HeaderContainer:IsShown() then
		self.PlayerPortrait:Show(false)
		self.HeaderContainer:Show(false)

		local nLeft, nTop, nRight, nBottom = self.BodyContainer:GetAnchorOffsets()
		self.BodyContainer:SetAnchorOffsets(nLeft, 0, nRight, nBottom)
	end
end

function ChatWindow:ToggleScrollbars()
	local bottom = false
	local pos = self.ChatMessagesPane:GetVScrollPos()

	if pos == self.ChatMessagesPane:GetVScrollRange() then
		bottom = true
	end

	if self.MainForm:ContainsMouse() then 
		self.ChatMessagesPane:SetNCOpacity(1)
		self.RosterPane:SetNCOpacity(1) 

		return
	end

	if bottom then
		self.ChatMessagesPane:SetNCOpacity(0) 
	end

	self.RosterPane:SetNCOpacity(0) 
end

function ChatWindow:ToggleTabsOptsContainer()
	if self.MainForm:ContainsMouse() then
		self.ChatTabsOptsContainer:SetOpacity(1)
	
		return
	end

	self.ChatTabsOptsContainer:SetOpacity(0)
end

function ChatWindow:LoadedPlayerModel()
	if not Jita.Player.Unit then 
		return
	end

	if self.IsPlayerModelLoading then 
		return
	end

	if self.IsPlayerModelLoaded then 
		return
	end

	self.PlayerPortrait:SetCostume(Jita.Player.Unit)
	self.TestPortrait:SetCostume(Jita.Player.Unit)

	self.IsPlayerModelLoading = true
end

function ChatWindow:OnTestPortraitLoaded(wndHandler, wndControl)
	Jita.Player:Init()

	if Jita.Player.Profile then 
		Jita.Player.Profile:PullDataFromUnit(Jita.Player.Unit)
		Jita.Player.Profile:PullDataFromPortrait(self.TestPortrait)
	end

	self.IsPlayerModelLoaded  = true
	self.IsPlayerModelLoading = nil

	wndControl:Destroy()
end
