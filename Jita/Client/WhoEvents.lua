local Jita = Apollo.GetAddon("Jita")
local Client = Jita:Extend("Client")

local Consts = Jita.Consts

--

function Client:DoWhoRequest(name) 
--/- Request a player basic info

	if not name or name == "" then
		return
	end

	-- this part is total rip off from ViragsSocial
	local tmp = Apollo.GetString(1)
	local cmd = nil

	if     tmp == "Cancel"    then cmd = "/who"
	elseif tmp == "Abbrechen" then cmd = "/wer"
	elseif tmp == "Annuler"   then cmd = "/qui" end

	if cmd then
		local Who = Apollo.GetAddon("Who")

		if Who then
			Apollo.RemoveEventHandler("WhoResponse", Who)
		end

		ChatSystemLib.Command(cmd .. " \"" .. name .. "\"")
	end
end

function Client:OnWhoResponse(arResponse, eWhoResult, strResponse)
	local name   = ""
	local result = "Ok"

	if eWhoResult == GameLib.CodeEnumWhoResult.OK 
	or eWhoResult == GameLib.CodeEnumWhoResult.Partial
	then
		local tWhoPlayers = arResponse

		for _, unit in pairs(tWhoPlayers) do
			name = unit.strName or ""

			local title    = unit.strName    or ""
			local level    = unit.nLevel     or 0
			local class    = unit.eClassId   or 0
			local race     = unit.eRaceId    or 0
			local faction  = unit.eFactionId or 0
			local path     = Consts.ktStringToPath[unit.strPath] or 0
			local gender   = 0
			local location = unit.strZone or ""

			if unit.strSubZone and unit.strSubZone:len() > 0 then
				if location:len() > 0 then
					location = location .. ', '
				end

				location = location .. unit.strSubZone
			end

			local info = 
			{
				Title    = title,
				Level    = level,
				Class    = class,
				Race     = race,
				Faction  = faction,
				Path     = path,
				Gender   = "",
				Location = location
			}

			local profile = self:GetPlayerProfile(unit.strName)

			if profile then
				profile:Update("Info", info)

				if  profile.Faction ~= Unit.CodeEnumFaction.DominionPlayer
				and profile.Faction ~= Unit.CodeEnumFaction.ExilesPlayer
				then
					profile.Faction = Consts.karRaceToFaction[profile.Race] or 0
				end
			end
		end

		if self.WhoResponseTimer then
			self.WhoResponseTimer:Stop()
		end

		self.WhoResponseTimer = ApolloTimer.Create(1, false, "OnWhoResponseTimer", self)

		result = "Ok"
	elseif eWhoResult == GameLib.CodeEnumWhoResult.UnderCooldown then
		ChatSystemLib.PostOnChannel(
			ChatSystemLib.ChatChannel_Debug,
			Apollo.GetString("Who_UnderCooldown")
		)

		result = "UnderCooldown"
	end

	if Jita.WindowManager:GetWindow("ProfileWindow") then
		Jita.WindowManager:GetWindow("ProfileWindow"):OnWhoResponse(name, result)
	end
end

function Client:OnWhoResponseTimer()
	local Who = Apollo.GetAddon("Who")

	if Who then
		Apollo.RegisterEventHandler("WhoResponse", "OnWhoResponse", Who)
	end

	self.WhoResponseTimer:Stop()
end
