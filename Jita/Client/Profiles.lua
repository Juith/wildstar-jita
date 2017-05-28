local Jita = Apollo.GetAddon("Jita")
local Client = Jita:Extend("Client")

local Utils = Jita.Utils

-- 

function Client:AddPlayerProfile(name, base)
	if not name or name:len() == 0 then
		return
	end

	local exists = self:GetPlayerProfile(name)

	if exists then
		return exists
	end

	local profile = Jita:Yield("Profile")

	if base then
		for _, __ in pairs(base) do
			profile[_] = __
		end
	end

	profile.Name = name

	-- skip any initial overload caused by lots of nearby peeps at c.c.
	if Jita.Timestamp > 1 then
		profile:PullDataFromExternalAddons()
	end

	if #self.MembersProfiles >= Jita.CoreSettings.Client_MaxProfiles then
		table.remove(self.MembersProfiles, 1) 
	end

	table.insert(self.MembersProfiles, profile)

	-- jita users have priority to stay, but they will get pushed out eventually.
	table.sort(self.MembersProfiles, function(a, b) return not a.JitaUser and b.JitaUser end)

	return profile
end

function Client:GetPlayerProfile(name)
	if not name or name:len() == 0 then
		return
	end

	if name == Jita.Player.Name then
		return Jita.Player.Profile
	end

	for _, __ in pairs(self.MembersProfiles) do
		if __.Name == name then
			return __
		end
	end
end

function Client:ValidatePlayersProfiles()
	Jita.Player:Init()

	--

	for pos, profile in pairs(self.MembersProfiles) do
		local exists = profile.JitaUser

		for _, stream in pairs(self.Streams) do
			if not exists then
				exists = stream:GetMember(profile.Name)
			end
		end

		if not exists then
			table.remove(self.MembersProfiles, pos)
		end
	end
end

function Client:AddPlayerOfInterest(name)
	if not name or name:len() == 0 then
		return
	end

	self:RemovePlayerOfInterest(name)

	if Utils:Count(self.PlayersOfInterest) > Jita.CoreSettings.Client_MaxPlayersOfInterest then
		table.remove(self.PlayersOfInterest, 1)
	end

	table.insert(self.PlayersOfInterest, name) 
end

function Client:RemovePlayerOfInterest(name)
	if not name or name:len() == 0 then
		return
	end

	for _, __ in pairs(self.PlayersOfInterest) do
		if __ == name then
			table.remove(self.PlayersOfInterest, _) 
		end
	end
end

function Client:IsPlayerOfInterest(name)
	if not name or name:len() == 0 then
		return false
	end

	local ofInterest = false

	for _, __ in pairs(self.PlayersOfInterest) do
		if __ == name then
			ofInterest = true
		end
	end

	-- Cut it short
	if ofInterest then
		return true
	end

	-- Check in notes
	local hasNotes = self.PrivateNotes[name] or false

	if hasNotes then
		ofInterest = true
	end
	
	-- Check profiles
	local profile = self:GetPlayerProfile(name)

	if profile then
		if profile.IsOfInterest == true then
			ofInterest = true
		end

		if profile.ExternalBios 
		or (profile.Bio and profile.Bio:len() > 0)
		then
			ofInterest = true
		end
	end

	--

	if ofInterest then
		self:AddPlayerOfInterest(name)
	end

	return ofInterest
end
