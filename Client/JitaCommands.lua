local Jita = Apollo.GetAddon("Jita")
local Client = Jita:Extend("Client")

local Utils = Jita.Utils
local Consts = Jita.Consts

--

function Client:DoJitaCommand(window, line)
--/- Work in progress

	if not window or not line or line == '' then
		return -- nil
	end

	local prefix = '!'

	-- remove trailing
	line = string.gsub(line, "\n", "")

	line = Utils:Trim(line)

	if prefix .. 'help' == line then
		Jita.WindowManager:LoadWindow("HelpWindow", { LoadForms = true })

		return true
	end

	if prefix .. 'channels' == line then
		Jita.WindowManager:LoadWindow("ChannelsManagerWindow", { LoadForms = true})

		return true
	end

	if prefix .. 'notifications' == line then
		Jita.WindowManager:LoadWindow("NotificationWindow", { LoadForms = true})

		return true
	end

	if prefix .. 'transcript' == line then
		window:OnShowTranscriptButtonButtonClick()

		return true
	end

	if prefix .. 'roster' == line then
		window:OnMembersListButtonClick() 

		return true
	end

	if prefix .. 'sidebar' == line then
		window:OnQuickChatOptionsButtonClick()

		return true
	end

	if prefix .. 'clear' == line then
		local stream = self:GetStream(window.SelectedStream)

		if stream then
			stream.Messages = {}

			window:GenerateChatMessagesPane()
		else
			window.ChatMessagesPane:DestroyChildren()
			window:ArrangeChatMessagesPane()
		end

		return true
	end

	if prefix .. 'config' == line then
		window:OnConfigButtonClick()

		return true
	end

	if prefix .. 'clone' == line then
		window:OnCloneCurrentChatTabButtonClick()

		return true
	end

	if prefix .. 'close' == line then
		if window.IsClone then
			window:OnCloseButtonClick()
		else
			window:CloseChatTab(window.SelectedStream)
		end

		return true
	end

	if prefix .. 'quit' == line then
		window:OnCloseButtonClick()

		return true
	end

	if prefix .. 'debug' == line then
		window:OnDebugButtonClick()

		return true
	end

	if Utils:StringStarts(line, prefix .. 'whois') then
		local name = string.sub(line, 7) or ''
		
		if not name or name:len() == 0 then
			return
		end

		local metadata = { Name = Utils:Trim(name) }

		Jita.WindowManager:LoadWindow("ProfileWindow"):ShowCharacterProfile(metadata)

		return true
	end

	if Utils:StringStarts(line, prefix .. 'opacity') then
		local value = string.sub(line, 9) or ''
		
		value = tonumber(value)

		if value and value >= 0 and value <= 100 then
			value = value / 100

			window:SetWindowOpacity(value)
		end

		return true
	end

	if prefix .. 'macros' == line then
		local font = "Courier"

		window:GenerateChatMessagePlain("[Jita] Jita macros: ", font)
		window:GenerateChatMessagePlain("   &me       : Your character name.", font)
		window:GenerateChatMessagePlain("   &faction  : Your character faction.", font)
		window:GenerateChatMessagePlain("   &race     : Your character race.", font)
		window:GenerateChatMessagePlain("   &gender   : Your character gender.", font)
		window:GenerateChatMessagePlain("   &class    : Your character class.", font)
		window:GenerateChatMessagePlain("   &path     : Your character path.", font)
		window:GenerateChatMessagePlain("   &guild    : Your character guild or circle.", font)
		window:GenerateChatMessagePlain("   &level    : Your character level.", font)
		window:GenerateChatMessagePlain("   &ilevel   : Your character items level.", font)
		window:GenerateChatMessagePlain("   &items    : List of equipped items.", font)
		window:GenerateChatMessagePlain("       &weapon   : Equipped weapon item.", font)
		window:GenerateChatMessagePlain("       &shoulder : Equipped shoulder item.", font)
		window:GenerateChatMessagePlain("       &head     : Equipped head item.", font)
		window:GenerateChatMessagePlain("       &chest    : Equipped chest item.", font)
		window:GenerateChatMessagePlain("       &hands    : Equipped hands item.", font)
		window:GenerateChatMessagePlain("       &legs     : Equipped legs item.", font)
		window:GenerateChatMessagePlain("       &feet     : Equipped feet item.", font)
		window:GenerateChatMessagePlain("       &implant  : Equipped implant item.", font)
		window:GenerateChatMessagePlain("       &shields  : Equipped shield item.", font)
		window:GenerateChatMessagePlain("       &gadget   : Equipped gadget item.", font)
		window:GenerateChatMessagePlain("   &costume    : List of equipped costume items.", font)
		window:GenerateChatMessagePlain("   &location   : Your current location.", font)
		window:GenerateChatMessagePlain("   &navpoint   : Current navigation point.", font)
		window:GenerateChatMessagePlain("   &money      : Current amount of gold.", font)
		window:GenerateChatMessagePlain("   &omnibits   : Earned omnibits and weekly cap.", font)
		window:GenerateChatMessagePlain("   &pets       : List summoned pets names.", font)
		window:GenerateChatMessagePlain("   &target     : Current target name.", font)
		window:GenerateChatMessagePlain("   &nearby     : List up to 8 nearby players.", font)
		window:GenerateChatMessagePlain("   &party      : List up to 8 players in your party.", font)
		window:GenerateChatMessagePlain("   &friendlist   : List up to 8 players in your friend list.", font)
		window:GenerateChatMessagePlain("   &ignorelist   : List up to 8 ignored players.", font)
		window:GenerateChatMessagePlain("   &neighborlist : List up to 8 neighbors.", font)
		window:GenerateChatMessagePlain("   &channels : List your players channels.", font)
		window:GenerateChatMessagePlain("   &circles  : List your circles.", font)
		window:GenerateChatMessagePlain("   &pvet3    : PvE tier three contract.", font)
		window:GenerateChatMessagePlain("   &pvpt3    : PvP tier three contract.", font)
		window:GenerateChatMessagePlain("   &time     : Current time.", font)
		window:GenerateChatMessagePlain("   &fps      : Current FPS.", font)
		window:GenerateChatMessagePlain("   &lag      : Current latency.", font)

		return true
	end

	if prefix .. 'commands' == line then
		local font = "Courier" --/ CRB_Pixel

		window:GenerateChatMessagePlain("[Jita] Jita commands: ", font)
		window:GenerateChatMessagePlain("   " .. prefix .. "help     : Display Jita's help window.", font)
		window:GenerateChatMessagePlain("   " .. prefix .. "commands : List available Jita commands.", font)
		window:GenerateChatMessagePlain("   " .. prefix .. "macros   : List supported Jita macros.", font)
		window:GenerateChatMessagePlain("   " .. prefix .. "clear    : Clear chat panes.", font)
		window:GenerateChatMessagePlain("   " .. prefix .. "clone    : Clone current tab on a new window.", font)
		window:GenerateChatMessagePlain("   " .. prefix .. "close    : Close current tab.", font)
		window:GenerateChatMessagePlain("   " .. prefix .. "quit     : Close current window.", font)
		window:GenerateChatMessagePlain("   " .. prefix .. "opacity  : Set window opacity temporally. !opacity <1-100>", font)

		window:GenerateChatMessagePlain("   " .. prefix .. "sidebar  : Toggle sidebar on and off.", font)
		window:GenerateChatMessagePlain("   " .. prefix .. "roster   : Toggle roster on and off.", font)

		window:GenerateChatMessagePlain("   " .. prefix .. "whois    : Show player profile. !whois <firstname lastname>", font)
		window:GenerateChatMessagePlain("   " .. prefix .. "config   : Invoke Advanced settings window.", font)
		window:GenerateChatMessagePlain("   " .. prefix .. "channels : Invoke Channels manger window.", font)
		window:GenerateChatMessagePlain("   " .. prefix .. "transcript : Invoke Chat transcript window.", font)
		window:GenerateChatMessagePlain("   " .. prefix .. "notifications : Invoke Notifications window.", font)

		--Keepme:
		-- window:GenerateChatMessagePlain("   " .. prefix .. "set      : Change a user setting. !set <setting> <value>", font)
		-- window:GenerateChatMessagePlain("   " .. prefix .. "reset    : Set all user settings to default and reloadui.", font)
		-- window:GenerateChatMessagePlain("   " .. prefix .. "macro    : Change or add a custom macro. !macro <example> <value>", font)
		-- window:GenerateChatMessagePlain("   " .. prefix .. "list     : List all aggregated channels on current tab.", font)
		-- window:GenerateChatMessagePlain("   " .. prefix .. "rename   : Rename current tab. !rename <example>", font)
		-- window:GenerateChatMessagePlain("   " .. prefix .. "color    : Set text color of current tab. !color <colorname|code>", font)
		-- window:GenerateChatMessagePlain("   " .. prefix .. "debug    : Turn debug mode on.", font)

		return true
	end

	-- Keepme:
	-- We ain't taking over prefix yet.
	-- If command doesn't exist, we simply dump the message to chat.
	-- window:GenerateChatMessagePlain("[Jita] Unknown Jita command. Type " .. prefix 
	--	.. "help to display the help window or " .. prefix .. "commands to list available commands.", font)
	-- window:GenerateChatMessagePlain("", font)

	return false
end
