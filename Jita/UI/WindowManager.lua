local Jita = Apollo.GetAddon("Jita")
local WindowManager = Jita:Extend("WindowManager")

local Utils = Jita.Utils

--

function WindowManager:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self 

	o.Themes  = nil
	o.Windows = {}

	return o
end

function WindowManager:Init(core)
	self.Themes = Jita:Yield("Themes")
end

function WindowManager:Tick()
	for name, window in pairs(self.Windows) do
		if window.IsChatWindow then
			window:Tick() 
		end
	end

	if Jita.CoreSettings.EnableDebugWindow
	and Jita.Timestamp % 2 == 0
	and self:GetWindow("DebugWindow")
	then
		self:GetWindow("DebugWindow"):Tick()
	end
end

function WindowManager:GetState()
	local state = {}
	local hasMainChatWindow = false
	
	for name, window in pairs(self.Windows) do
		if window.IsChatWindow then
			state[ name ] = window:GetState()

			if not window.IsClone then
				hasMainChatWindow = true
			end
		end
	end

	-- one silly tick, but that's one window we don't want mess with - amap
	if not hasMainChatWindow
	and self.MainChatWindowStateCache
	then
		state["MainChatWindow"] = self.MainChatWindowStateCache
	end

	return state
end

function WindowManager:RestoreSavedState()
	self.Themes:SelectPresetThemeByName(Jita.UserSettings.WindowsTheme)

	for name, window in pairs(self.Windows) do
		if window.IsChatWindow then
			self.Themes:ApplyCurrentThemeToWindow(window)
		end
	end

	if not Jita.SaveData
	or not Jita.SaveData.Character
	or not Jita.SaveData.Character.WindowManagerState
	then
		return
	end

	-- main chat window
	local mainChatWindow = self:GetWindow("MainChatWindow")

	if mainChatWindow then
		if Jita.SaveData.Character.WindowManagerState
		and Jita.SaveData.Character.WindowManagerState.MainChatWindow
		then
			mainChatWindow:RestoreSavedState(
				Jita.SaveData.Character.WindowManagerState.MainChatWindow
			)
		end
	else
		return -- already something fucked up
	end

	-- clones
	for _, state in pairs(Jita.SaveData.Character.WindowManagerState) do
		if state.IsClone and state.IsClone == true then
			local stream = Jita.Client:GetStream(state.SelectedStream)

			-- stream must exist
			if stream then
				-- Fixme:
				-- kind of a rare recurring bug where clone offsets are
				-- are reset to 0 all around, needs to investigate.
				if state.MainFormLocation.nOffsets[1]
				~= state.MainFormLocation.nOffsets[3]
				then
					local window = self:CloneChatWindow(mainChatWindow)

					if window then
						window:RestoreSavedState(state)
					end
				end
			end
		end
	end
end

--

function WindowManager:AddWindow(name, window) 
	window.Name = name

	self.Windows[name] = window

	return window
end

function WindowManager:GetWindow(name) 
	return self.Windows[name]
end

function WindowManager:LoadWindow(name, options)
	if self:GetWindow(name) then
		return self:GetWindow(name)
	end

	local window = Jita:Yield(name)

	-- if window need to have a different name for identification
	if options and options.Name then
		window.Name = options.Name
	else
		window.Name = name
	end

	window:Init(Jita)

	-- whether it needs to load its forms in memory or stay as moot ref
	if options and options.LoadForms == true then
		window:LoadForms()
	end

	-- most windows do it themselves so this flag get rarely used
	if options and options.ApplyCurrentTheme == true then
		self.Themes:ApplyCurrentThemeToWindow(window)
	end

	self:AddWindow(window.Name, window)

	-- Keepme:
	-- Apollo.LinkAddon(Jita, window)

	return window
end

function WindowManager:RemoveWindow(name)
	local window = self:GetWindow(name)

	if window
	and window.MainForm
	and window.MainForm:IsValid() 
	then
		window.MainForm:Destroy()
	end

	Apollo.UnlinkAddon(Jita, window)

	self.Windows[name] = nil
end

-- Chat windows specifics,

function WindowManager:InvokeChatWindows()
	for _, window in pairs(self.Windows) do
		if window.IsChatWindow then
			window:SelectChatTab(window.SelectedStream)

			window:GenerateRoster()
			window:GenerateChatTabs()

			window.MainForm:Show(true)

			if window.MainForm:ContainsMouse() then
				window:OnMainFormMouseEnter()
			else
				window:OnMainFormMouseExit()
			end

			window.MainForm:ClearFocus()
		end
	end

	if self:GetWindow("OverlayWindow") then
		self:GetWindow("OverlayWindow"):Close()
	end
end

function WindowManager:CloneChatWindow(parent)
	if not parent then
		return
	end

	-- something is fishy
	if Utils:Count(self.Windows) 
	> Jita.CoreSettings.WindowManager_MaxClonesWindows then
		return
	end

	local clone = Jita:Clone(parent)

	local name = "CloneChatWindow_" .. Utils:Random(1, 10000000) --/- meh

	clone.Name = name
	clone.IsClone = true
	clone:Init(Jita)

	clone:LoadForms()

	clone.SelectedStream     = parent.SelectedStream
	clone.ShowRoster         = parent.ShowRoster
	clone.GhostMode          = false
	clone.MessageTextFont    = parent.MessageTextFont
	clone.MessageDisplayMode = parent.MessageDisplayMode  
	clone.MainFormLastWidth  = parent.MainForm:GetWidth()
	clone.MainFormLocation   = parent.MainForm:GetLocation():ToTable()

	clone.MainFormLocation.nOffsets[1] = clone.MainFormLocation.nOffsets[1] + 20
	clone.MainFormLocation.nOffsets[2] = clone.MainFormLocation.nOffsets[2] + 20
	clone.MainFormLocation.nOffsets[3] = clone.MainFormLocation.nOffsets[3] + 20
	clone.MainFormLocation.nOffsets[4] = clone.MainFormLocation.nOffsets[4] + 20

	if Jita.UserSettings.ChatWindow_UseCustomBackgroundPicture == true then
		clone:ApplyCustomBackgroundToChatWindows()
	end

	clone:SetRosterVisibility()
	clone.MainForm:MoveToLocation(WindowLocation.new(clone.MainFormLocation))

	clone:SelectChatTab(clone.SelectedStream)

	self:AddWindow(name, clone)

	return clone
end
