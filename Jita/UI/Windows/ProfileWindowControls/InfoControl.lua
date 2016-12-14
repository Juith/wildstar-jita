local Jita = Apollo.GetAddon("Jita")
local ProfileWindow = Jita:Extend("ProfileWindow")

local Utils = Jita.Utils
local Consts = Jita.Consts

--

function ProfileWindow:SetUserInfoVals(data)
	data = data or {}

	self.MainForm:FindChild("IsApiInCoolDown"):Show(false)
	self.MainForm:FindChild("DominionIcon"):Show(false)
	self.MainForm:FindChild("ExileIcon"):Show(false)
	self.MainForm:FindChild("FactionUnsureIcon"):Show(false)

	self.MainForm:FindChild("UserInfoVals"):FindChild("Name"   ):SetText(data.Title                              or "Unknown")
	self.MainForm:FindChild("UserInfoVals"):FindChild("Level"  ):SetText(data.Level                              or "Unknown")
	self.MainForm:FindChild("UserInfoVals"):FindChild("Class"  ):SetText(Consts.karClassToString[data.Class]     or "Unknown")
	self.MainForm:FindChild("UserInfoVals"):FindChild("Race"   ):SetText(Consts.karRaceToString[data.Race]       or "Unknown")
	self.MainForm:FindChild("UserInfoVals"):FindChild("Path"   ):SetText(Consts.ktPathToString[data.Path]        or "Unknown")
	self.MainForm:FindChild("UserInfoVals"):FindChild("Faction"):SetText(Consts.karFactionToString[data.Faction] or "Unknown")
	self.MainForm:FindChild("UserInfoVals"):FindChild("Zone"   ):SetText(data.Location                           or "Unknown")
	self.MainForm:FindChild("UserInfoVals"):FindChild("Zone"   ):SetTooltip(data.Location                        or "Unknown")

	self.PlayerInfoLoaded = true

	if self.PlayerModelLoaded == true then
		return
	end

	if data.Faction == Unit.CodeEnumFaction.DominionPlayer then
		self.MainForm:FindChild("DominionIcon"):Show(true)
	elseif data.Faction == Unit.CodeEnumFaction.ExilesPlayer then
		self.MainForm:FindChild("ExileIcon"):Show(true)
	else
		self.MainForm:FindChild("FactionUnsureIcon"):Show(true)
		self.MainForm:FindChild("UserInfoVals"):FindChild("Faction"):SetText("Unsure")
	end
end

function ProfileWindow:OnWhoResponse(name, result)
	if not self.MainForm then
		return
	end

	self.MainForm:FindChild("MightBeOffline"):Show(false)
	self.MainForm:FindChild("IsApiInCoolDown"):Show(false)
	self.MainForm:FindChild("WhoLoadingIcon"):Show(false)

	if result == "Ok" then  
		if name == "" then
			self.Metadata.MightBeOffline = true

			self.MainForm:FindChild("MightBeOffline"):Show(true)

			self.MainForm:FindChild("IICommLoadingCenterIcon"):Show(true)
			self.MainForm:FindChild("IICommLoadingLeftIcon"):Show(false)
			self.MainForm:FindChild("IsResquestingBio"):Show(false)
			self.MainForm:FindChild("IsResquestingBioTimeOut"):Show(false)

			return
		end

		if self.Metadata.Name ~= name then
			return
		end

		local profile = Jita.Client:GetPlayerProfile(name)

		if profile and profile.InfoUpdated == true then
			self:SetUserInfoVals(profile)
		end
	elseif result == "UnderCooldown" and not self.PlayerInfoLoaded then
		self.MainForm:FindChild("IsApiInCoolDown"):Show(true)
	end
end
