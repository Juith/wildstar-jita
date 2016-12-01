local Jita = Apollo.GetAddon("Jita")
local Client = Jita:Extend("Client")

local Utils = Jita.Utils

-- 

function Client:OnChangeWorld()
	if self.ChangeWorldTimer then
		self.ChangeWorldTimer:Stop()
	end

	self.ChangeWorldTimer = ApolloTimer.Create(3, false, "UpdateLocalStreamMembers", self)
end

function Client:OnSubZoneChanged(idZone, strZoneName) 
	self:UpdateLocalStreamMembers()

	if not strZoneName 
	or not Jita.Player
	or not Jita.Player.Location
	then
		return
	end

	Jita.Player:UpdateLocation(strZoneName)
end

function Client:OnUnitCreated(unitCreated)
	if unitCreated:GetType() ~= "Player" then
		return
	end

	if unitCreated:IsThePlayer() then
		self:UpdateLocalStreamMembers()
	end

	if Utils:Count(self.LocalPlayers) > Jita.CoreSettings.Client_MaxLocalPlayers then
		return
	end

	self.LocalPlayers[unitCreated:GetName()] = unitCreated
end

function Client:OnUnitDestroyed(unitDestroyed)
	if unitDestroyed:GetType() ~= "Player" then
		return
	end

	for name, unit in pairs(self.LocalPlayers) do
		if unitDestroyed:GetName() == name then
			self.LocalPlayers[name] = nil
		end
	end
end

function Client:UpdateLocalStreamMembers()
	self:PullLocalMembers()

	self:GenerateChatWindowsRoster()
end
