local Jita = Apollo.GetAddon("Jita")
local NotificationWindow = Jita:Extend("NotificationWindow")

local Utils = Jita.Utils
local Consts = Jita.Consts

--

function NotificationWindow:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self

	o.MainForm = nil

	return o
end

function NotificationWindow:Init()
end

function NotificationWindow:LoadForms()
	self.MainForm = Apollo.LoadForm(Jita.XmlDoc, "JCC_NotificationWindow", nil, self)

	Jita.WindowManager.Themes:ApplyCurrentThemeToWindow(self)

	self.MainForm:FindChild("BodyContainer"):SetBGOpacity(.9)
	self.MainForm:FindChild("BodyContainer"):SetNCOpacity(.9)

	--

	self.NotificationsPane = self.MainForm:FindChild("NotificationsPane")

	local notifications = Jita.Client.Notifications

	self:GenerateChatNotifications(notifications)

	--

	self.MainForm:Show(true)
	self.MainForm:ToFront()
end

function NotificationWindow:GenerateChatNotifications(notifications)
	for _, notification in ipairs(notifications) do
		if notification.Content then
			local channel = Jita.Client.Channels[notification.Channel]

			if channel and channel:GetType() and channel:GetName() then
				local xmlLine = XmlDoc.new()

				local crChannel = Consts.ChatMessagesColors[channel:GetType()] or ApolloColor.new("white")

				xmlLine:AddLine("", crChannel, "Default", "Left")

				xmlLine:AppendText(notification.StrTime .. " ", crChannel, "Default", "Left")

				xmlLine:AppendText("[" .. channel:GetName() .. "] : ", crChannel, "Default", "Left")

				xmlLine:AppendText(notification.Content, crChannel, "Default", "Left")

				--

				local wndLine = Apollo.LoadForm(Jita.XmlDoc, "ChatMessageInlineControl", self.NotificationsPane, self)

				wndLine:SetDoc(xmlLine)

				wndLine:SetHeightToContentHeight()

				local nLeft, nTop, nRight, nBottom = wndLine:GetAnchorOffsets()
				wndLine:SetAnchorOffsets(nLeft, nTop + 2 , nRight, nTop + nBottom + 4)
			end
		end

		self.NotificationsPane:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)

		self.NotificationsPane:SetVScrollPos(self.NotificationsPane:GetVScrollRange()) 
	end
end

function NotificationWindow:OnClearNotificationsButtonClick()
	Jita.Client.Notifications = {}

	self.NotificationsPane:DestroyChildren()
	
	self:OnCloseButtonClick()
end

function NotificationWindow:OnCloseButtonClick()
	self.MainForm:Destroy()

	Jita.WindowManager:RemoveWindow("NotificationWindow")
end
