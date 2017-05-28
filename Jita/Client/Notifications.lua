local Jita = Apollo.GetAddon("Jita")
local Client = Jita:Extend("Client")

local Utils = Jita.Utils

--

function Client:AddNotification(notification)
	table.insert(self.Notifications, notification)

	if #self.Notifications > Jita.CoreSettings.Client_MaxNotifications then
		table.remove(self.Notifications, 1)
	end
end

function Client:CheckForNotifications(senderName, message)
	if not message
	or not message.Channel
	or not message.Content
	or not message.Content.arMessageSegments
	then
		return
	end

	if not senderName then
		return
	end

	local hasKeyword = false
	local hasMention = false

	if senderName:len() == 0 then
		self:CheckMessageForCommands(message)
		self:CheckMessageForPresence(message)
	elseif not message.Content.bSelf then
		hasKeyword = self:CheckMessageForKeyworks(message)
		hasMention = self:CheckMessageForPlayerMentions(message)
	end

	if hasKeyword or hasMention then
		self:AddPlayerOfInterest(senderName)
		
		if Jita.UserSettings.ChatWindow_MessageKeywordPlaySound == true then
			self:PlaySound(self.EnumSounds.Keyword)
		end
	end

	return hasKeyword, hasMention
end

function Client:CheckMessageForCommands(message)
	local channel = self.Channels[message.Channel]
	
	if  channel:GetType() ~= ChatSystemLib.ChatChannel_Command
	and channel:GetType() ~= ChatSystemLib.ChatChannel_Realm -- will shove realm messages as well
	then
		return
	end

	local segments = message.Content.arMessageSegments

	if segments and segments[1] then
		local notification = {
			Content = segments[1].strText,
			Channel = message.Channel,
			Time    = message.Time,
			StrTime = message.StrTime,
		}

		self:AddNotification(notification)
		
		return true
	end
end

function Client:CheckMessageForPresence(message)
	local channel = self.Channels[message.Channel]

	if  channel:GetType() ~= ChatSystemLib.ChatChannel_System
	and channel:GetType() ~= ChatSystemLib.ChatChannel_Society
	and channel:GetType() ~= ChatSystemLib.ChatChannel_Guild
	and channel:GetType() ~= ChatSystemLib.ChatChannel_Party
	then
		return
	end

	local segments = message.Content.arMessageSegments
	
	if not segments or not segments[1] then
		return
	end

	-- Engrish only
	if string.match(segments[1].strText, " has ")
	or string.match(segments[1].strText, "You ")
	or string.match(segments[1].strText, "party")
	or string.match(segments[1].strText, "connected")
	then
		if self.LastPresenceNotification
		and self.LastPresenceNotification == segments[1].strText
		then
			return
		end

		self.LastPresenceNotification = segments[1].strText

		local notification = {
			Content = segments[1].strText,
			Channel = message.Channel,
			Time    = message.Time,
			StrTime = message.StrTime,
		}

		self:AddNotification(notification)
		
		return true
	end
end

function Client:CheckMessageForKeyworks(message)
	if Jita.UserSettings.ChatWindow_MessageKeywordAlert == false 
	or Jita.UserSettings.ChatWindow_MessageKeywordList:len() == 0
	then
		return
	end

	local segments = message.Content.arMessageSegments
	
	if not segments or not segments[1] then
		return
	end

	local hasKeyword = false
	local fullText = ''

	for _, segment in ipairs(segments) do
		fullText = fullText .. (segment.strText or '')

		local strLower = string.lower(segment.strText or '')
		local strList = Jita.UserSettings.ChatWindow_MessageKeywordList

		for word in strLower:gmatch('%w+') do
			for keyword in string.gmatch(strList, "%s*[^%s]+%s*") do
				keyword = string.lower(Utils:Trim(keyword))

				if keyword == word then
					hasKeyword = true
				end
			end
		end
	end
	
	if hasKeyword then
		local notification = {
			Content = message.Content.strDisplayName .. " did mention a keyword : " .. fullText,
			Channel = message.Channel,
			Time    = message.Time,
			StrTime = message.StrTime,
		}

		self:AddNotification(notification)

		return true
	end
end

function Client:CheckMessageForPlayerMentions(message) 
	if not Jita.Player 
	or not Jita.Player.Name
	then
		return
	end

	local segments = message.Content.arMessageSegments
	
	if not segments or not segments[1] then
		return
	end
	
	local fullText = ''

	local hasMention = false

	for _, segment in ipairs(segments) do
		fullText = fullText .. (segment.strText or '')

		local strLower = string.lower(segment.strText or '')

		for word in strLower:gmatch('%w+') do
			local name = Jita.Player.Name or ''

			for keyword in string.gmatch(name, "%s*[^%s]+%s*") do
				keyword = string.lower(Utils:Trim(keyword))

				if keyword and keyword:len() >= 3 and keyword == word then
					hasMention = true
				end
			end
		end
	end

	if hasMention == true then
		local notification = {
			Content = message.Content.strDisplayName .. " did mention your name : " .. fullText,
			Channel = message.Channel,
			Time    = message.Time,
			StrTime = message.StrTime,
		}

		self:AddNotification(notification)
		
		return true
	end
end

function Client:AlertPlayerInRange(maxrange)
	if not Jita.Player 
	or not Jita.Player.Name
	or not Jita.Player.Unit
	then
		return
	end

	if Jita.Player.Unit:IsDead() == true 
	or Jita.Player.Unit:IsInCombat() == true 
	then
		return
	end

	if not self.AlertPlayerInRangeIgnore then
		self.AlertPlayerInRangeIgnore = {[Jita.Player.Name] = 1}
	end

	local newinrange = false
	
	local mainChat = Jita.WindowManager:GetWindow("MainChatWindow")

	for name, target in pairs(self.LocalPlayers) do
		local range = Utils:DistanceToUnit(Jita.Player.Unit, target) or 0
		local tname = target:GetName()

		if range > 0 
		and range <= maxrange 
		and Jita.Player.Name ~= tname
		then
			if not self.AlertPlayerInRangeIgnore[tname] then
				newinrange = true 

				if mainChat then
					mainChat:GenerateChatMessagePlain(tname 
					.. " entered " .. maxrange .."m range.")
				end
			end

			self.AlertPlayerInRangeIgnore[tname] = range 
		else
			self.AlertPlayerInRangeIgnore[tname] = nil
		end
	end

	if newinrange then
		self:PlaySound(self.EnumSounds.Click)
	end
end
