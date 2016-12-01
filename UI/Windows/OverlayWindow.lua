local Jita = Apollo.GetAddon("Jita")
local OverlayWindow = Jita:Extend("OverlayWindow")

--

function OverlayWindow:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self

	o.MainForm = nil

	o.Messages = {
		Total = 0,
		Local = 0,
		InstanceParty = 0,
		Zone = 0,
		Nexus = 0,
		GuildCircle = 0,
		Custom = 0,
		Whisper = 0
	}

	return o
end

function OverlayWindow:Init()
end

function OverlayWindow:LoadForms()
	self.MainForm = Apollo.LoadForm(Jita.XmlDoc, "JCC_OverlayWindow", nil, self)
	self.MainForm:Show(false, true)
end

function OverlayWindow:Invoke()
	self.MainForm:Show(true)
end

function OverlayWindow:Close()
	self:ResetCounters()

	self.MainForm:Show(false)
end

function OverlayWindow:OnOverlayButtonClick()
	self:Close()

	self:ResetCounters()
	
	self:UpdateMessagesCount()

	Jita.WindowManager:LoadWindow("ChatWindow", { LoadForms = true, Name = "MainChatWindow" })
	Jita.WindowManager:LoadWindow("MainChatWindow"):RestoreSavedState(Jita.WindowManager.MainChatWindowStateCache)
	Jita.WindowManager:InvokeChatWindows()
end

function OverlayWindow:UpdateMessagesCount()
	local text = ""

	if self.Messages.Local         > 0 then text = text .. tostring(self.Messages.Local        ) .. ".." end
	if self.Messages.InstanceParty > 0 then text = text .. tostring(self.Messages.InstanceParty) .. ".." end
	if self.Messages.Zone          > 0 then text = text .. tostring(self.Messages.Zone         ) .. ".." end
	if self.Messages.Nexus         > 0 then text = text .. tostring(self.Messages.Nexus        ) .. ".." end
	if self.Messages.GuildCircle   > 0 then text = text .. tostring(self.Messages.GuildCircle  ) .. ".." end
	if self.Messages.Custom        > 0 then text = text .. tostring(self.Messages.Custom       ) .. ".." end
	if self.Messages.Whisper       > 0 then text = text .. tostring(self.Messages.Whisper      ) .. ".." end

	local width = Apollo.GetTextWidth("CRB_Header9_O", text .. "..")

	if text == "" then width = 0 end

	local nLeft, nTop, nRight, nBottom = self.MainForm:FindChild("OverlayButton"):GetAnchorOffsets()
	self.MainForm:FindChild("OverlayButton"):SetAnchorOffsets(nLeft, nTop, width + 31, nBottom)

	local aml = ""

	aml = aml .. "<P Align=\"Center\">"

	if self.Messages.Local         > 0 then aml = aml .. self:GenerateCountAml(self.Messages.Local         , "white"         ) end
	if self.Messages.InstanceParty > 0 then aml = aml .. self:GenerateCountAml(self.Messages.InstanceParty , "ChatParty"     ) end
	if self.Messages.Zone          > 0 then aml = aml .. self:GenerateCountAml(self.Messages.Zone          , "ChatZone"      ) end
	if self.Messages.Nexus         > 0 then aml = aml .. self:GenerateCountAml(self.Messages.Nexus         , "ChatNexus"     ) end
	if self.Messages.GuildCircle   > 0 then aml = aml .. self:GenerateCountAml(self.Messages.GuildCircle   , "ChatGuild"     ) end
	if self.Messages.Custom        > 0 then aml = aml .. self:GenerateCountAml(self.Messages.Custom        , "ChannelCustom" ) end
	if self.Messages.Whisper       > 0 then aml = aml .. self:GenerateCountAml(self.Messages.Whisper       , "ChannelWhisper") end

	aml = aml .. "</P>"

	self.MainForm:FindChild("Counts"):SetAML(aml)
end

function OverlayWindow:OnChatMessage(channelType)
	-- cut it short if overlay is not active
	if not self.MainForm:IsShown() then 
		return
	end

	if channelType == ChatSystemLib.ChatChannel_System
	or channelType == ChatSystemLib.ChatChannel_Command
	or channelType == ChatSystemLib.ChatChannel_Realm
	or channelType == ChatSystemLib.ChatChannel_Support
	or channelType == ChatSystemLib.ChatChannel_Say
	or channelType == ChatSystemLib.ChatChannel_Yell
	or channelType == ChatSystemLib.ChatChannel_Emote
	or channelType == ChatSystemLib.ChatChannel_Party
	or channelType == ChatSystemLib.ChatChannel_AnimatedEmote
	then
		self.Messages.Local = self.Messages.Local + 1
	end

	if channelType == ChatSystemLib.ChatChannel_Party          then self.Messages.InstanceParty = self.Messages.InstanceParty + 1 end
	if channelType == ChatSystemLib.ChatChannel_Instance       then self.Messages.InstanceParty = self.Messages.InstanceParty + 1 end

	if channelType == ChatSystemLib.ChatChannel_Zone           then self.Messages.Zone = self.Messages.Zone + 1 end

	if channelType == ChatSystemLib.ChatChannel_Nexus          then self.Messages.Nexus = self.Messages.Nexus + 1 end

	if channelType == ChatSystemLib.ChatChannel_Guild          then self.Messages.GuildCircle = self.Messages.GuildCircle + 1 end
	if channelType == ChatSystemLib.ChatChannel_GuildOfficer   then self.Messages.GuildCircle = self.Messages.GuildCircle + 1 end
	if channelType == ChatSystemLib.ChatChannel_Society        then self.Messages.GuildCircle = self.Messages.GuildCircle + 1 end

	if channelType == ChatSystemLib.ChatChannel_Custom         then self.Messages.Custom = self.Messages.Custom + 1 end

	if channelType == ChatSystemLib.ChatChannel_Whisper        then self.Messages.Whisper = self.Messages.Whisper + 1 end
	if channelType == ChatSystemLib.ChatChannel_AccountWhisper then self.Messages.Whisper = self.Messages.Whisper + 1 end

	self.Messages.Total = self.Messages.Total + 1

	self:UpdateMessagesCount()
end

function OverlayWindow:ResetCounters()
	self.Messages = {
		Total = 0,
		Local = 0,
		InstanceParty = 0,
		Zone = 0,
		Nexus = 0,
		GuildCircle = 0,
		Custom = 0,
		Whisper = 0
	}
end

function OverlayWindow:GenerateCountAml(count, color)
	return "<T TextColor=\"" .. color .. "\" Font=\"CRB_Header9_O\">"
	.. count
	.. "</T><T TextColor=\"0\">.</T><T TextColor=\"0\">.</T>"
end
