--[[--
	Behold the spaghetti code;
	Public Domain desu, 2016.
	Names are ephemeral.

	~

	Quick notes on the layout of the project to whomever was bored enough to
	want to check out this organised mess:

	Core:
		This same file. A shallow skeleton devoid of any meaningful logic
		and serves as an entry point for the game client and to link
		different components of the add-on.

	Models:
		Contains definitions of users profiles, streams, chat members,
		normalized chat messages and current player data.
		A stream simply mean a group of chat channels.

		Other data structures weren't important enough to warrant both 
		shape and container.

	Client:
		Where most of the communication with servers lays, chunked into
		multitude of files to simplify managing concerns.

	ICComm:
		Used to share players basic info, characters models and profile 
		biographies between Jita users.

		It implements a bleh attempt at managing nodes bandwidth by making
		them exchange data over windows of time while taking rate limits 
		and throttle into account, thus making sharing a global channel
		a bit more reliable. Well, probably.

	UI:
		Mostly user interaction: what button does what, what window goes
		where, that kind of stuff.

		Parts of UI are still a cluster-fuck that I'm not happy about and
		needs re-factoring, hopefully that gets done before the game shuts
		down; or I totally lose interest.

	Utils:
		A dumpster for otherwise common code. External libraries are to 
		reside there as well.

	Views:
		You guessed it. That's where xml forms and whatever sprites goes.

	As a last notes:

		Jita goes far beyond the scope of a chat add-on for I wrote it 
		for fun and necessity to be my one-stop place for a number of
		things, and if they end serving someone else's needs, it's but
		a coincidence and not my goal.

		I absolutely despise Hungarian notation and I drop them whenever
		possible. Types are inferred from context, that's it.

--]]--

require "Apollo"
require "Window"
require "Unit"
require "GameLib"
require "GroupLib"
require "HousingLib"
require "ChatSystemLib"
require "ChatChannelLib"
require "FriendshipLib"
require "AccountItemLib"

local Jita = {}

local ADDON_VERSION    = 5.9                -- Major being 0 for if it _ever_ hit 1, it'd be time for me to move on.
local ADDON_NAME       = 'Jita Chat Client' -- I couldn't come with a better name.
local WINDOW_NAMESPACE = 'JCC_'             -- prefix used to identify top windows in stratum.
local ICCOMM_VERSION   = 1                  -- not that I'm planning to peruse working on new versions any time soon.

--

function Jita:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self 

	o.UserSettings = { -- User settings are mutable
		DefaultStream                         = "Default::General",
		WindowsTheme                          = "Viking",
		AutoHideChatLogWindows                = false,

		JitaCustomChannel                     = "Jita",
		AutojoinJitaCustomChannel             = true,

		--

		ChatWindow_ShowHeader                 = false,
		ChatWindow_GhostMode                  = false,
		ChatWindow_AutoHideChatTabs           = false,
		ChatWindow_ShowRoster                 = true,
		ChatWindow_AutoExpandChatInput        = true,
		ChatWindow_RosterLeftClickInfo        = true,
		ChatWindow_Opacity                    = 0.69,
		ChatWindow_ChatInputAutoSetFocus      = false,

		ChatWindow_MessageDisplay             = "Inline",   -- "Block" or "Inline"
		ChatWindow_MessageTextFont            = "CRB_Interface10",
		ChatWindow_MessageTextColors          = {},
		ChatWindow_MessageHighlightRolePlay   = false,
		ChatWindow_MessageDetectURLs          = true,
		ChatWindow_MessageKeywordAlert        = false,
		ChatWindow_MessageKeywordPlaySound    = false,
		ChatWindow_MessageKeywordList         = "",
		ChatWindow_MessageShowTimestamp       = true,
		ChatWindow_MessageShowChannelName     = false,
		ChatWindow_MessageUseChannelAbbr      = false,
		ChatWindow_MessageShowPlayerRange     = false,
		ChatWindow_MessageAlertPlayerInRange  = false,
		ChatWindow_MessageShowBubble          = true,
		ChatWindow_MessageShowTextFloater     = true,
		ChatWindow_MessageShowLastViewed      = true,
		ChatWindow_MessageFadeLines           = true, -- Unused (Just to look pretty for now. May get implemented, or not.)
		ChatWindow_MessageFilterProfanity     = false,
		ChatWindow_MessageAlienateOutOfRange  = true,
		ChatWindow_UseCustomBackgroundPicture = false,

		ChatWindow_MaxChatMembers             = 32,  -- max members to display by default
		ChatWindow_MaxChatLines               = 64,  -- max lines to display to user by default
		ChatWindow_SayEmoteRange              = 512, -- usually around 250, but server may send random things at times.

		--

		EnableIIComm                          = true,
		IIComm_ShareInfo                      = true,
		IIComm_ShareModel                     = true,
		IIComm_ShareBio                       = true,
		IIComm_ShareLocation                  = true,
		IIComm_ShareInterests                 = true,
		IIComm_SharePlayersChannels           = true,

		--

		EnableLootFilter                      = false,
		LootFilter_MinCoppers                 = 10000,
		LootFilter_MinQuality                 = 1,
	}

	o.CoreSettings = { -- thou probably shalt not change these.
		ChatWindow_MaxChatMembers      = 64,  -- max items to render
		ChatWindow_MaxChatLines        = 128, --
		ChatWindow_SayEmoteRange       = 512, --

		WindowManager_MaxClonesWindows = 32,

		Stream_Segregated_MaxMessages  = 256, -- max messages per stream to keep in memory
		Stream_Segregated_MaxMembers   = 64,  -- max members to keep in memory per stream. (server may send up to 50 members cap per channel.)

		Stream_Aggregated_MaxMessages  = 128, -- aggregated get lower memory space because of flood-gates effect.
		Stream_Aggregated_MaxMembers   = 32,  -- cause, again, aggregated streams are flood-y.

		Client_MaxNotifications        = 32,
		Client_MaxLocalPlayers         = 32,
		Client_MaxProfiles             = 256, -- we only keep a bunch on a queue at any time, and they will be created then populated as needed replacing oldest.

		PingChatLogDelay               = 2,
		PingChatLogInterval            = 15,
		PullLocalPlayersInterval       = 30,
		PullPartyMembersInterval       = 30,
		RequestStreamsMembersDelay     = 30,
		RequestStreamsMembersInterval  = 300,
		ValidateProfilesInterval       = 30,
		RosterRefreshInterval          = 60,

		IIComm_Channel                 = "___JCC" .. self:GetICCommVersion(), -- new protocol, new channel.
		IIComm_KeepAlive               = true,

		EnableDebugWindow              = false, -- Note: turning this thing on may add up to 1.2ms/frame and 5kb mem.
		EnableIICommDebug              = false,
	}

	o.Factory = {} -- where "classes" are defined
	o.Utils   = {} -- redundant chucks of codes
	o.Consts  = {} -- things I don't want to see hanging on top of scripts

	o.Client        = {} -- server stuff
	o.WindowManager = {} -- ui stuff
	o.ICCommNode    = {} -- p2p stuff

	o.Player = {} -- Current player data, kept on "global" scope for ease of access

	o.Seconds   = 0
	o.Timestamp = 0

	o.SaveData = {}

	return o
end

function Jita:Init()
--/- calls a function that calls another function who calls yet other functions

	Apollo.RegisterAddon(self, true, Jita:GetAddonName(), {})
end

function Jita:OnLoad()
--/- and hop

	self.XmlDoc = XmlDoc.CreateFromFile("Views/Forms.xml")
	self.XmlDoc:RegisterCallback("OnDocLoaded", self)

	self.Client        = self:Yield("Client")
	self.WindowManager = self:Yield("WindowManager")
	self.ICCommNode    = self:Yield("ICCommNode")
	self.Player        = self:Yield("Player")

	self.Client:Init(self)
	self.WindowManager:Init(self)
	self.ICCommNode:Init(self) 
end

function Jita:OnDocLoaded()
--/- one more to go

	if self.XmlDoc == nil then
		return
	end

	self.DelayTimer = ApolloTimer.Create(0.2, true, "OnPlayerUnitLoaded", self)
end

function Jita:OnPlayerUnitLoaded()
--/- unless player unit is loaded, we won't bother to start.

	if not GameLib.GetPlayerUnit() then
		return
	end

	if self.DelayTimer then
		self.DelayTimer:Stop()
	end

	self.Player:Init()

	self:RestoreUserSettings()

	if self.UserSettings.ChatWindow_UseCustomBackgroundPicture then
		Apollo.LoadSprites("Views/Sprites.xml")
	end

	Apollo.RegisterSlashCommand("jita", "OnSlashCommand", self)

	self.Client:SetConsoleVariables()
	self.Client:SuppressChatLog()
	self.Client:JoinJitaCustomChannel()
	self.Client:SyncPlayerStreams()
	self.Client:RestoreSavedState()

	self.Client:PullLocalMembers()
	self.Client:PullPartyMembers()

	self.WindowManager:LoadWindow("ChatWindow", {LoadForms = true, Name = "MainChatWindow"})

	self.WindowManager:RestoreSavedState()
	self.WindowManager:InvokeChatWindows()

	if not self.SaveData.Realm and not self.SaveData.Character then
		self.WindowManager:LoadWindow("HelpWindow", {LoadForms = true})
	end

	if self.CoreSettings.EnableDebugWindow then
		self.WindowManager:LoadWindow("DebugWindow", {LoadForms = true})
	end

	self.TickTimer  = ApolloTimer.Create(1 , true , "Tick" , self)
	self.DeferTimer = ApolloTimer.Create(15, false, "Defer", self)
end

function Jita:Tick()
--/- like NextFrame but times slower. 

	self.Timestamp = self.Timestamp + 1
	self.Seconds   = self.Timestamp % 60 + 1

	self.Client:Tick()

	self.WindowManager:Tick()

	self.ICCommNode:Tick()
end

function Jita:Defer()
--/- like OnLoad but seconds later. 

	if not self.LibJSON then
		self.LibJSON = Apollo.GetPackage("Lib:dkJSON-2.5").tPackage
	end

	if not self.LibCRC32 then
		self.LibCRC32 = Apollo.GetPackage("Lib:CRC32").tPackage
	end

	self.Player:UpdateLocation()

	if self.UserSettings.EnableIIComm == true then
		self.ICCommNode:Connect(
			self.CoreSettings.IIComm_Channel,
			ICCommLib.CodeEnumICCommChannelType.Global
		)
	end

	self.DelayTimer = nil
	self.DeferTimer = nil
end

-- Roaming

function Jita:OnSave(level)
--/- You know, la routine.

	if self.SkipOnSave then
		return {}
	end

	if level == GameLib.CodeEnumAddonSaveLevel.Realm then
		if -- something fucked up, royally.
		not self.TickTimer 
		and (self.SaveData and self.SaveData.Realm)
		then
			return self.SaveData.Realm
		end

		local data = {}

		data['AddonVersion']  = self:GetAddonVersion()
		data['ICCommVersion'] = self:GetICCommVersion()
		data['NewAddonVersionDetected'] = self.NewAddonVersionDetected

		data['PrivateNotes'] = self.Client.PrivateNotes or {}

		return data
	end

	if level == GameLib.CodeEnumAddonSaveLevel.Character then
		if not self.TickTimer 
		and (self.SaveData and self.SaveData.Character)
		then
			return self.SaveData.Character
		end

		--

		self.UserSettings.ChatWindow_MessageTextColors = {}

		for _, __ in pairs(self.Consts.ChatMessagesColors) do
			self.UserSettings.ChatWindow_MessageTextColors[_] = 
				__:GetColorString()
		end

		--

		local data = {}

		data['UserSettings'] = self.UserSettings
		data['ClientState']  = self.Client:GetState()
		data['WindowManagerState'] = self.WindowManager:GetState()

		data['PlayersProfiles'] = { 
			Current = self.Player.Profile
		}

		return data
	end
end

function Jita:OnRestore(level, data)
--/- we'll simply dump it to scope to whom may ask

	if level == GameLib.CodeEnumAddonSaveLevel.Realm then
		self.SaveData.Realm = data
	end

	if level == GameLib.CodeEnumAddonSaveLevel.Character then
		self.SaveData.Character = data
	end
end

function Jita:RestoreUserSettings()
	if not self.SaveData 
	or not self.SaveData.Character
	or not self.SaveData.Character.UserSettings
	then
		return
	end

	self.UserSettings = self.Utils:Overwrite(
		self.UserSettings,
		self.SaveData.Character.UserSettings
	)
end

function Jita:OnSlashCommand(command, args)
--/- fancy slash commands; who use them

	args = args and args:lower() or ""

	if args == "hide" then
		local window = self.WindowManager:GetWindow("MainChatWindow")

		if window then
			window:OnCloseButtonClick()
		end

		return
	end

	if args == "reset" then
		self.SkipOnSave = true

		RequestReloadUI()

		return
	end

	self.WindowManager:InvokeChatWindows()
end

function Jita:OnConfigure()
--/- because every add-on has one of these

	self.WindowManager:LoadWindow("ConfigWindow", {LoadForms = true})
end

-- OOP-ish

function Jita:Extend(name)
--/- create or extend the definition of a "class"

	self.Factory[name] = self.Factory[name] or {}

	return self.Factory[name]
end

function Jita:Yield(name)
--/- not that one, this produce an instance of a "class"

	local object = self.Factory[name]:new()

	return object
end

function Jita:Clone(base, clone)
--/- does what you think it does.

	if type(base) ~= "table" then
		return clone or base 
	end

	clone = clone or {}
	clone.__index = base

	return setmetatable(clone, clone)
end

-- Getters

function Jita:GetAddonName()
	return ADDON_NAME
end

function Jita:GetAddonVersion()
	return ADDON_VERSION
end

function Jita:GetICCommVersion()
	return ICCOMM_VERSION
end

function Jita:GetWindowNamespace()
	return WINDOW_NAMESPACE
end

-- Entry point

local instance = Jita:new()
instance:Init()
