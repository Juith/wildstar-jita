local Jita = Apollo.GetAddon("Jita")
local HelpWindow = Jita:Extend("HelpWindow")

local Utils = Jita.Utils
local Consts = Jita.Consts

--

function HelpWindow:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self

	o.MainForm = nil

	return o
end

function HelpWindow:Init()
end

function HelpWindow:LoadForms()
	self.MainForm = Apollo.LoadForm(Jita.XmlDoc, "JCC_HelpWindow", nil, self)

	Jita.WindowManager.Themes:ApplyCurrentThemeToWindow(self)

	self.MainForm:FindChild("BodyContainer"):SetBGOpacity(1)
	self.MainForm:FindChild("BodyContainer"):SetNCOpacity(1)

	self.MainForm:Show(true, true)

	self:ShowHelp()
end

function HelpWindow:ShowHelp()
	self.HelpContent = self:GetHelpContent()

	self.HelpPane = self.MainForm:FindChild("HelpPane")

	for _, text in pairs(self.HelpContent) do
		local line = Apollo.LoadForm(Jita.XmlDoc, "ChatMessageInlineControl", self.HelpPane, self)

		line:SetAML(text)
		line:SetHeightToContentHeight()
	end

	self.HelpPane:ArrangeChildrenVert()

	self.MainForm:Show(true)
	self.MainForm:ToFront()
end

function HelpWindow:GetHelpContent()
	local content = {
		"<T TextColor=\"UI_TextHoloTitle\" Font=\"CRB_Header11_O\">Chat tabs:</T>",

	"<P Font=\"CRB_Header11_O\"><T TextColor=\"0\">.</T></P>",

		"<T TextColor=\"ChatSupport\">Jita Chat Client</T> moves away from confined in-game chat logs toward a more traditional approach where, except for a few, channels and instant messages are segregated into their own tabs. By default, five main tabs are open:",

	"<P Font=\"CRB_Header11_O\"><T TextColor=\"0\">.</T></P>",

		"<T TextColor=\"0\">...</T><T TextColor=\"xkcdGreyblue\">General</T> : One snowflake-y tab made for those who can't break out of old habits. It enable players to pick and choose what channels to follow at a time.",
		"<T TextColor=\"0\">...</T><T TextColor=\"UI_TextHoloBodyHighlight\">Local</T> : Regroup system, /say, /yell and /emote channels.",
		"<T TextColor=\"0\">...</T><T TextColor=\"ChatZone\">Zone</T> : For zone chat.",
		"<T TextColor=\"0\">...</T><T TextColor=\"ChatNexus\">Nexus</T> : The global cross-faction chat channel on Nexus.",
		"<T TextColor=\"0\">...</T><T TextColor=\"ChatGuild\">Guild</T> : Home to Guild's chat.",

	"<P><T TextColor=\"0\">.</T></P>",

		"<T TextColor=\"0\">...</T><T TextColor=\"ChatGuildOfficer\">Guild Officer</T>, <T TextColor=\"ChatPvP\">Zone PvP</T>, <T TextColor=\"ChatParty\">Party</T>, <T TextColor=\"ChatInstance\">Instance</T>, <T TextColor=\"ChatCustom\">Players channels</T>, <T TextColor=\"ChatCircle2\">Circles</T>, <T TextColor=\"ChatWhisper\">Whispers</T> and <T TextColor=\"ChatAccountWisper\">Account whispers</T> chat tabs are closed by default and set to automatically open on incoming new messages. Alternatively you may access them from Quick options via the wrench icon on the top right of the interface.",

	"<P><T TextColor=\"0\">.</T></P>",

		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">Left</T> click on a tab button to select a chat.",
		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">Wheel</T> click on a tab button to quickly close the chat.",
		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">Right</T> click on a tab button to clone the chat on a new window.",

	"<P><T TextColor=\"0\">.</T></P>",

		"<T TextColor=\"0\">...</T>To filter the list of aggregated channels on <T TextColor=\"xkcdGreyblue\">General</T>, select the tab first then click on Quick options.",

	"<P><T TextColor=\"0\">.</T></P>",
	
		"<T TextColor=\"UI_TextHoloTitle\" Font=\"CRB_Header11_O\">Roster:</T>",

	"<P Font=\"CRB_Header11_O\"><T TextColor=\"0\">.</T></P>",

		"Players roster is but a mere convenience. Due to technical limitations and self imposed restrictions both to keep the add-on lightweight and Carbine's IT department happy, list will be delayed at login (and /reloadui) and refreshes once per five minutes.",

	"<P><T TextColor=\"0\">.</T></P>",

		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">Left</T> click on a player's name shall pop up their profile window.",
		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">Right</T> click will fire the player's context menu.",

	"<P><T TextColor=\"0\">.</T></P>",

		"<T TextColor=\"UI_TextHoloTitle\" Font=\"CRB_Header11_O\">Quick chat options:</T>",

	"<P Font=\"CRB_Header11_O\"><T TextColor=\"0\">.</T></P>",

		"Home to a handful of quick options like changing font faces, toggling players roster on and off, opening chat transcript, switching to different chat tab, etc.",

	"<P><T TextColor=\"0\">.</T></P>",

		"<T TextColor=\"UI_TextHoloTitle\" Font=\"CRB_Header11_O\">Chat input:</T>",

	"<P Font=\"CRB_Header11_O\"><T TextColor=\"0\">.</T></P>",

		"The chat input is multi-line and will auto-expand to a cap as you type. Except for whispers, messages over 500 characters will be split into chunks before sent to channel.",

	"<P><T TextColor=\"0\">.</T></P>",

		"All chat and slash commands works alike in Jita as in Carbine's ChatLog, except for one <T TextColor=\"ChatPvP\">major difference</T>: When selecting a tab, chat prompt will always reset to the default value.",

	"<P><T TextColor=\"0\">.</T></P>",

		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">Enter</T> will set chat input in focus.",
		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">Shift+Enter</T> will send a message and attempt to keep chat input in focus.",

	"<P><T TextColor=\"0\">.</T></P>",

		"<T TextColor=\"UI_TextHoloTitle\" Font=\"CRB_Header11_O\">Autocomplete widget:</T>",

	"<P Font=\"CRB_Header11_O\"><T TextColor=\"0\">.</T></P>",

		"<T TextColor=\"ChatSupport\">Jita</T> implements an autocomplete helper that will pop up when detecting one of these symbols at the start of a message: ",

	"<P><T TextColor=\"0\">.</T></P>",

		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">/</T> Regular slash commands.",
		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">!</T> Jita commands.",
		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">&</T> Jita macros.",
		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">@</T> Names currently listed on chat roster.",

	"<P><T TextColor=\"0\">.</T></P>",

		"<T TextColor=\"UI_TextHoloTitle\" Font=\"CRB_Header11_O\">Chat transcript:</T>",

	"<P Font=\"CRB_Header11_O\"><T TextColor=\"0\">.</T></P>",

		"Made for those moments where chunks of a conversation are important enough to warrant scrolling up the chat log for a reread, or to copy it to clipboard and save it for later. Chat transcript is accessible via Quick options.",

	"<P><T TextColor=\"0\">.</T></P>",

		"<T TextColor=\"UI_TextHoloTitle\" Font=\"CRB_Header11_O\">Channels Manager:</T>",

	"<P Font=\"CRB_Header11_O\"><T TextColor=\"0\">.</T></P>",

		"Channels Manager enables you to quickly join and leave players channels.",

	"<P><T TextColor=\"0\">.</T></P>",

		"<T TextColor=\"UI_TextHoloTitle\" Font=\"CRB_Header11_O\">Notifications:</T>",

	"<P Font=\"CRB_Header11_O\"><T TextColor=\"0\">.</T></P>",

		"When you receive a notification, a new button will shows up on top-right of chat windows. Said notifications may include friends online status, guild-mates online status, your character name mentions and set keywords.",

	"<P><T TextColor=\"0\">.</T></P>",

		"<T TextColor=\"UI_TextHoloTitle\" Font=\"CRB_Header11_O\">Players profiles:</T>",

	"<P Font=\"CRB_Header11_O\"><T TextColor=\"0\">.</T></P>",

		"Clicking on player's name will show a profile window to display their basic info such as level, class and race and their unit model preview when available. Note that <T TextColor=\"ChatSupport\">Jita</T> use the publicly available Who API to query players data, and said API has a cooldown between calls.",

	"<P Font=\"CRB_Header11_O\"><T TextColor=\"0\">.</T></P>",

		"Players may choose to attach a biography field to their profile. To this end a global IIComm channel is used as a medium for the transmission. However, it's worth noting that said IIComm channel has ridiculously low upload rates, thus biographies and characters previews are propagated on a slow basis.",

	"<P Font=\"CRB_Header11_O\"><T TextColor=\"0\">.</T></P>",

		"In addition, <T TextColor=\"ChatSupport\">Jita</T> integrate with <T TextColor=\"ChatSupport\">This Is Me</T> and <T TextColor=\"ChatSupport\">Katia Plot RP</T>. If you've one or both of those add-ons installed, players profiles may show extended sections when relevant.",

	"<P><T TextColor=\"0\">.</T></P>",

		"<T TextColor=\"UI_TextHoloTitle\" Font=\"CRB_Header11_O\">Overlay:</T>",

	"<P Font=\"CRB_Header11_O\"><T TextColor=\"0\">.</T></P>",

		"Closing the main chat window will auto-invoke the overlay which is a micro button placed on top-left of the screen that shows the count of incoming messages.",

	"<P><T TextColor=\"0\">.</T></P>",
	
		"<T TextColor=\"UI_TextHoloTitle\" Font=\"CRB_Header11_O\">Themes and display modes:</T>",

	"<P Font=\"CRB_Header11_O\"><T TextColor=\"0\">.</T></P>",

		"<T TextColor=\"ChatSupport\">Jita</T> comes with four different color schemes where each matches one of <T TextColor=\"ChatSupport\">Wildstar</T> popular themes. You can also choose between compact, irc-like chat log and a loose layout. Both settings can be found on Advanced chat options.",

	"<P Font=\"CRB_Header11_O\"><T TextColor=\"0\">.</T></P>",

		"<T TextColor=\"UI_TextHoloTitle\" Font=\"CRB_Header11_O\">Window opacity:</T>",

	"<P Font=\"CRB_Header11_O\"><T TextColor=\"0\">.</T></P>",

		"<T TextColor=\"ChatSupport\">Jita</T> offers two levels of opacity: When chat windows are opaque or semi-transparent and its value can be set to taste on the Advanced chat options. The second is Ghost mode where windows goes fully transparent when not in mice focus. Ghost mode can be toggled on and off via the ghost icon on the top right of the interface, and in addition it will also pin the window in place.",

	"<P Font=\"CRB_Header11_O\"><T TextColor=\"0\">.</T></P>",

		"<T TextColor=\"UI_TextHoloTitle\" Font=\"CRB_Header11_O\">Macros:</T>",

	"<P Font=\"CRB_Header11_O\"><T TextColor=\"0\">.</T></P>",

		"<T TextColor=\"ChatSupport\">Jita</T> has a number of built-in macros to help you save time and energy typing. They are a set of special keywords that will be substituted in your chat messages with current values if any.",

	"<P Font=\"CRB_Header11_O\"><T TextColor=\"0\">.</T></P>",

		"Example: ",

	"<P Font=\"CRB_Header11_O\"><T TextColor=\"0\">.</T></P>",

		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">" .. Utils:EscapeHTML("<&guild> absolute best guild on &faction is now seeking new cupcakes. /w &me for invite.") .. "</T>",

	"<P Font=\"CRB_Header11_O\"><T TextColor=\"0\">.</T></P>",

		"Will be sent to chat as such: ",

	"<P Font=\"CRB_Header11_O\"><T TextColor=\"0\">.</T></P>",

		"<T TextColor=\"0\">...</T>" .. Utils:EscapeHTML(Jita.Client:SubstituteJitaMacros("<&guild> absolute best guild on &faction is now seeking new cupcakes. /w &me for invites.")),

	"<P Font=\"CRB_Header11_O\"><T TextColor=\"0\">.</T></P>",

		"All macros can be used in any combination and only works through <T TextColor=\"ChatSupport\">Jita</T>.",

	"<P Font=\"CRB_Header11_O\"><T TextColor=\"0\">.</T></P>",

		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">&me</T>: Your character name.",
		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">&faction</T>: Your character faction.",
		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">&race</T>: Your character race.",
		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">&gender</T>: Your character gender.",
		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">&class</T>: Your character class.",
		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">&path</T>: Your character path.",
		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">&guild</T>: Your character guild or circle.",
		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">&level</T>: Your character level.",
		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">&ilevel</T>: Your character items level.",
		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">&items</T>: List of equipped items.",
		"<T TextColor=\"0\">...</T><T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">&weapon</T>: Equipped weapon item.",
		"<T TextColor=\"0\">...</T><T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">&shoulder</T>: Equipped shoulder item.",
		"<T TextColor=\"0\">...</T><T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">&head</T>: Equipped head item.",
		"<T TextColor=\"0\">...</T><T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">&chest</T>: Equipped chest item.",
		"<T TextColor=\"0\">...</T><T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">&hands</T>: Equipped hands item.",
		"<T TextColor=\"0\">...</T><T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">&legs</T>: Equipped legs item.",
		"<T TextColor=\"0\">...</T><T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">&feet</T>: Equipped feet item.",
		"<T TextColor=\"0\">...</T><T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">&implant</T>: Equipped implant item.",
		"<T TextColor=\"0\">...</T><T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">&shields</T>: Equipped shield item.",
		"<T TextColor=\"0\">...</T><T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">&gadget</T>: Equipped gadget item.",
		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">&costume</T>: List of equipped costume items.",
		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">&location</T>: Your current location.",
		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">&navpoint</T>: Current navigation point.",
		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">&money</T>: Current amount of gold.",
		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">&omnibits</T>: Earned omnibits and weekly cap.",
		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">&pets</T>: List summoned pets names.",
		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">&target</T>: Current target name.",
		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">&nearby</T>: List up to 8 nearby players.",
		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">&party</T>: List up to 8 players in your party.",
		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">&friendlist</T>: List up to 8 players in your friend list.",
		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">&ignorelist</T>: List up to 8 ignored players.",
		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">&neighborlist</T>: List up to 8 neighbors.",
		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">&channels</T>: List your players channels.",
		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">&circles</T>: List your circles.",
		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">&pvet3</T>: PvE tier three contract.",
		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">&pvpt3</T>: PvP tier three contract.",
		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">&time</T>: Current time.",
		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">&fps</T>: Current FPS.",
		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">&lag</T>: Current latency.",

	"<P Font=\"CRB_Header11_O\"><T TextColor=\"0\">.</T></P>",

		"<T TextColor=\"UI_TextHoloTitle\" Font=\"CRB_Header11_O\">Commands:</T>",

	"<P Font=\"CRB_Header11_O\"><T TextColor=\"0\">.</T></P>",

		"As stated above, all Wildstar chat and slash commands works alike in Jita as in Carbine's ChatLog. In addition Jita implements a number of basic commands (more are likely to follow in future releases).",

	"<P Font=\"CRB_Header11_O\"><T TextColor=\"0\">.</T></P>",

		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">!help</T>: display Jita's help window.",
		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">!commands</T>: list available Jita commands.",
		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">!macros</T>: list supported Jita macros.",

	"<P Font=\"CRB_Header11_O\"><T TextColor=\"0\">.</T></P>",

		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">!opacity</T>: Set window opacity temporally. !opacity <1-100>.",
		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">!sidebar</T>: Toggle roster on and off.",
		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">!roster</T>: Toggle sidebar on and off.",
		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">!clear</T>: clear chat pane.",
		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">!clone</T>: clone current tab on a new window.",
		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">!close</T>: close current tab.",
		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">!quit</T>: close current chat window.",

	"<P Font=\"CRB_Header11_O\"><T TextColor=\"0\">.</T></P>",

		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">!whois</T>: Show player profile. !whois <firstname lastname>.",
		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">!config</T>: Invoke Advanced settings window..",
		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">!channels</T>: Invoke Channels manger window.",
		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">!transcript</T>: Invoke Chat transcript window.",
		"<T TextColor=\"0\">...</T><T TextColor=\"ChatSupport\">!notifications</T>: Invoke Notifications window.",
	}

	return content
end

function HelpWindow:OnCloseButtonClick()
	self.MainForm:Destroy()

	Jita.WindowManager:RemoveWindow("HelpWindow")
end
