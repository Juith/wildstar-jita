local Jita = Apollo.GetAddon("Jita")
local ChannelsManagerWindow = Jita:Extend("ChannelsManagerWindow")

local Utils = Jita.Utils
local Consts = Jita.Consts

--

function ChannelsManagerWindow:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self

	o.MainForm = nil

	return o
end

function ChannelsManagerWindow:Init()
end

function ChannelsManagerWindow:LoadForms()
	self.MainForm = Apollo.LoadForm(Jita.XmlDoc, "JCC_ChannelsManagerWindow", nil, self)

	Jita.WindowManager.Themes:ApplyCurrentThemeToWindow(self)

	self.MainForm:FindChild("BodyContainer"):SetBGOpacity(.9)
	self.MainForm:FindChild("BodyContainer"):SetNCOpacity(.9)
	
	self.SubscriptionsListVScroll = 0
	
	self:ShowSubscriptions()

	self.MainForm:Show(true)
	self.MainForm:ToFront()
end

function ChannelsManagerWindow:ShowSubscriptions()
	self.MainForm:FindChild("HelpButton"):SetTooltip("Note that while you're able to leave some Standard channels, "
		.. "the server will likely auto-join them next session."
		.. "\nSome entries listed under Other Known Channels might be obsolete.")

	self.ChannelNameEditBox = self.MainForm:FindChild("ChannelNameEditBox") 
	self.SubscriptionsList = self.MainForm:FindChild("SubscriptionsList") 
	self.SharePlayersChannelsButton = self.MainForm:FindChild("SharePlayersChannelsButton") 
	
	self.SharePlayersChannelsButton:SetCheck(Jita.UserSettings.IIComm_SharePlayersChannels)

	self.ChannelNameEditBox:SetText("")
	self.SubscriptionsList:SetText("")
	self.SubscriptionsList:DestroyChildren()

	local channels = ChatSystemLib.GetChannels()

	for _, channel in ipairs(channels) do
		local line = Apollo.LoadForm(Jita.XmlDoc, "SubscriptionLineControl", self.SubscriptionsList, self)

		line:FindChild("Name"):SetText(" " .. channel:GetName())

		local color = Consts.ChatMessagesColors[ channel:GetType() ] or ApolloColor.new("white")

		line:FindChild("Name"):SetTextColor(color:GetColorString())

		--

		local typeName = 'Standard'

		if channel:GetType() == ChatSystemLib.ChatChannel_Society      then typeName = 'Circle' end
		if channel:GetType() == ChatSystemLib.ChatChannel_Custom       then typeName = 'Player' end
		if channel:GetType() == ChatSystemLib.ChatChannel_Guild        then typeName = 'Guild'  end
		if channel:GetType() == ChatSystemLib.ChatChannel_GuildOfficer then typeName = 'Guild'  end

		line:FindChild("Type"):SetText(" " .. typeName)

		--

		if channel:GetCommand() ~= '' then
			line:FindChild("Command"):SetText(" /" .. channel:GetCommand())
		end

		--

		if channel:IsOwner()     == true then line:FindChild("IsOwner"):FindChild("Check"):Show(true)     end
		if channel:IsModerator() == true then line:FindChild("IsModerator"):FindChild("Check"):Show(true) end

		--

		if channel:CanLeave() == true then
			line:FindChild("JoinLeave"):FindChild("LeaveButton"):SetData(channel)
			line:FindChild("JoinLeave"):FindChild("LeaveButton"):Show(true)
		end
	end
	
	Apollo.LoadForm(Jita.XmlDoc, "SubscriptionOtherKnownControl", self.SubscriptionsList, self)

	for channelType, channelName in pairs(Consts.ChatChannels) do
		if self:IsMemberOf(channelType) == false then
			self:GenerateOtherKnownChannelsLine(channelType, channelName)
		end
	end

	self.SubscriptionsList:ArrangeChildrenVert(0)
	self.SubscriptionsList:SetVScrollPos(self.SubscriptionsListVScroll)
end

function ChannelsManagerWindow:GenerateOtherKnownChannelsLine(channelType, channelName)
	local line = Apollo.LoadForm(Jita.XmlDoc, "SubscriptionLineControl", self.SubscriptionsList, self)

	line:FindChild("Name"):SetText(" " ..channelName)

	if channelType == ChatSystemLib.ChatChannel_Custom then
		line:FindChild("Type"):SetText(" Player")
	else
		line:FindChild("Type"):SetText(" Standard")
	end

	line:FindChild("Name"):SetTextColor("gray")
	line:FindChild("Type"):SetTextColor("gray")

	if channelType == ChatSystemLib.ChatChannel_Custom then
		line:FindChild("JoinLeave"):FindChild("JoinButton"):SetData(channelName)
	else
		line:FindChild("JoinLeave"):FindChild("JoinButton"):SetData(channelType)
	end

	line:FindChild("JoinLeave"):FindChild("JoinButton"):Show(true)
end

function ChannelsManagerWindow:IsMemberOf(channelType, channelName)
	local channels = ChatSystemLib.GetChannels()

	for _, item in ipairs(channels) do
		if (item:GetType() == channelType and not channelName)
		or (item:GetName() == channelName and channelType == ChatSystemLib.ChatChannel_Custom)
		then
			return true
		end
	end

	return false
end

function ChannelsManagerWindow:OnSharePlayersChannelsButtonCheck()
	Jita.UserSettings.IIComm_SharePlayersChannels = true
end

function ChannelsManagerWindow:OnSharePlayersChannelsButtonUncheck()
	Jita.UserSettings.IIComm_SharePlayersChannels = false
end

function ChannelsManagerWindow:OnJoinButtonClick(wndHandler, wndControl)
	if not self.ChannelNameEditBox then
		return
	end

	local channel = wndControl:GetData()

	if not channel then
		return
	end

	ChatSystemLib.JoinChannel(channel)

	self:ReloadSubscriptionsList()
end

function ChannelsManagerWindow:OnCreateJoinButtonClick(wndHandler, wndControl)
	if not self.ChannelNameEditBox then
		return
	end

	local channel = self.ChannelNameEditBox:GetText()

	if not channel then
		return
	end

	ChatSystemLib.JoinChannel(channel)

	self:ReloadSubscriptionsList()
end

function ChannelsManagerWindow:OnLeaveButtonClick(wndHandler, wndControl)
	local channel = wndControl:GetData()

	if not channel then
		return
	end

	if not self.SubscriptionsList then
		return
	end

	channel:Leave()
	
	self:ReloadSubscriptionsList()
end

function ChannelsManagerWindow:ReloadSubscriptionsList()
	self.SubscriptionsListVScroll = self.SubscriptionsList:GetVScrollPos()

	self.SubscriptionsList:DestroyChildren()
	self.SubscriptionsList:SetText("Loading..") -- not, really. We'll simply give the server enough time to respond

	self.LeaveChannelTimer = ApolloTimer.Create(2.0, false, "OnLeaveChannelTimer", self)
end

function ChannelsManagerWindow:OnLeaveChannelTimer(wndHandler, wndControl)
	self:ShowSubscriptions()
end

function ChannelsManagerWindow:OnCloseButtonClick()
	self.MainForm:Destroy()

	Jita.WindowManager:RemoveWindow("ChannelsManagerWindow")
end
