local Jita = Apollo.GetAddon("Jita")
local Profile = Jita:Extend("Profile")

local Utils = Jita.Utils
local Consts = Jita.Consts

--

function Profile:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self 

	o.Name            = nil
	o.Title           = nil
	o.Level           = nil
	o.Faction         = nil
	o.Race            = nil
	o.Gender          = nil
	o.Class           = nil
	o.Path            = nil
	o.Location        = nil

	o.Looks           = {}
	o.Bones           = {}
	o.Costume         = {}

	o.Bio             = nil

	o.Interests       = nil

	o.ExternalBios    = nil -- biographies found while digging other add-ons

	o.Slang           = nil

	o.InfoUpdated     = false
	o.ModelUpdated    = false
	o.BioUpdated      = false

	o.JitaUser        = false

	return o
end

function Profile:Update(what, data)
	if not what or not data then
		return
	end

	if what == "Info" then
		self.Title    = data.Title or self.Name
		self.Level    = tonumber(data.Level  ) or self.Level
		self.Faction  = tonumber(data.Faction) or self.Faction
		self.Race     = tonumber(data.Race   ) or self.Race   
		self.Gender   = tonumber(data.Gender ) or self.Gender 
		self.Class    = tonumber(data.Class  ) or self.Class  
		self.Path     = tonumber(data.Path   ) or self.Path   
		self.Location = data.Location or self.Location

		self.InfoUpdated = true

	elseif what == "Model" then
		self.Faction = tonumber(data.Faction) or self.Faction
		self.Race    = tonumber(data.Race   ) or self.Race
		self.Gender  = tonumber(data.Gender ) or self.Gender

		self.Looks   = data.Looks   or self.Looks
		self.Bones   = data.Bones   or self.Bones
		self.Costume = data.Costume or self.Costume

		self.ModelUpdated = true 

	elseif what == "Bio" then
		self.Bio = data or "" 
		self.Bio = string.sub(self.Bio, 1, 1024)

		self.BioUpdated = true

		self.JitaUser = true

	elseif what == "Interests" then
		self.Interests = tonumber(data.Interests) or self.Interests
	end
end

function Profile:PullDataFromUnit(unit)
	if not unit then
		return
	end

	local title = unit:GetTitle() or ""
	if title == "" then title = unit:GetName() end

	local info = 
	{
		Name     = unit:GetName(),
		Title    = title,
		Level    = unit:GetLevel(),
		Class    = unit:GetClassId(),
		Race     = unit:GetRaceId(),
		Path     = unit:GetPlayerPathType(),
		Gender   = unit:GetGender(),
		Faction  = unit:GetFaction(),
	}

	if info.Race
	and info.Faction
	and info.Faction ~= Unit.CodeEnumFaction.DominionPlayer
	and info.Faction ~= Unit.CodeEnumFaction.ExilesPlayer
	then
		info.Faction = Consts.karRaceToFaction[info.Race] or 0
	end

	if not unit:IsThePlayer()
	or (unit:IsThePlayer() and not self.Location)
	then
		local location = ''

		local zone = GameLib.GetCurrentZoneMap()

		if zone and zone.strName then
			location = zone.strName
		end

		local subZoneName = GetCurrentZoneName()

		if subZoneName and subZoneName:len() > 0 then
			location = location .. ', ' .. subZoneName
		end

		info.Location = location
	end

	self:Update("Info", info)
	
	--

	if not unit:IsThePlayer() then
		return
	end

	local model = {}
	local costumeItem = nil
	local costumeItemVisible = true

	--/- we only care for chest piece for now
	local costumeDisplayed = CostumesLib.GetCostume(
		CostumesLib.GetCostumeIndex()
	)

	if costumeDisplayed then
		costumeItem = costumeDisplayed:GetSlotItem(GameLib.CodeEnumItemSlots.Chest)

		-- Keepme:
		-- gotta keep it pg
		costumeItemVisible = costumeDisplayed:IsSlotVisible(GameLib.CodeEnumItemSlots.Chest)
	end

	if not costumeItem then
		for idx, itemEquipment in pairs(unit:GetEquippedItems()) do
			if itemEquipment:GetSlot() 
			== GameLib.CodeEnumEquippedItems.Chest then
				costumeItem = itemEquipment
			end
		end
	end

	if costumeItem ~= nil 
	and costumeItemVisible == true
	then
		local costumeItemId = costumeItem:GetItemId() or 0

		model.Costume = {{
			GameLib.CodeEnumItemSlots.Chest,
			costumeItemId
		}}
	end

	-- Todo:
	-- also care about dyes maybe.

	self:Update("Model", model)
end

function Profile:PullDataFromPortrait(portrait)
	if not portrait then
		return
	end

	local model = 
	{
		Looks = {},
		Bones = {},
	}

	local looks = portrait:GetLooks()
	local bones = portrait:GetBonesInfo().arBones

	for _, look in ipairs(looks) do
		local slider = { look.sliderId, look.valueIdx }

		table.insert(model.Looks, slider)
	end

	for _, bone in ipairs(bones) do
		if bone.nCurrentValue ~= 0 then
			-- we don't really care about fidelity, so attempt
			-- to shrink values down to a digit
			local slider = {
				bone.idSlider,
				Utils:Round(bone.nCurrentValue, 1) * 10 
			}

			table.insert(model.Bones, slider)
		end
	end

	self:Update("Model", model)
end

function Profile:PullDataFromExternalAddons()
	local status, externalBios = pcall(Profile.FetchExternalAddons, self.Name)

	if status and type(externalBios) == "table" then
		self.ExternalBios = externalBios
	end
end

function Profile.FetchExternalAddons(name)
--/- to invoke via pcall

	if not name or name == "" then
		return
	end

	local externalBios = {}
	local hasExternalBios = false

	-- This is Me
	local ThisIsMe = Apollo.GetAddon("ThisIsMe")

	if ThisIsMe then
		local characterProfiles = ThisIsMe.characterProfiles or {}

		for aName, profile in pairs(characterProfiles) do
			if profile and aName == name then
				if type(profile.Snippets) == "table" then
					local bio = profile.Snippets[2] or ''
					
					bio = Utils:Trim(bio)

					if bio and bio ~= '' then
						externalBios.TIM = Utils:Trim(bio)

						hasExternalBios = true
					end
				end
			end
		end
	end

	-- KatiaBuilderToolkit
	local KatiaBuilderToolkit = Apollo.GetAddon("KatiaBuilderToolkit")

	if KatiaBuilderToolkit then
		local rpplots = KatiaBuilderToolkit.rpplots or {}

		for owner, plot in pairs(rpplots) do
			if owner and plot and owner == name then
				if plot[6] and plot[6] == 'no' then -- pg, you know
					local text = ""

					text = text .. "Plot name: " .. (plot[2] or '') .. " (" .. owner .. ")" .. "\n"
					text = text .. "Venue: "     .. (plot[3] or '') .. "\n"
					text = text .. "Faction: "   .. (plot[1] or '') .. "\n"
					text = text .. "Active: "    .. (plot[4] or '') .. "\n"
					text = text .. "Open: "      .. (plot[5] or '') .. "\n"

					local population = tonumber(plot.population)

					if not population or population == 0 then
						text = text .. "Population: Unknown".. "\n"
					else
						text = text .. "Population: " .. population .. "\n"
					end

					externalBios.KRP = Utils:Trim(text)

					hasExternalBios = true
				end
			end
		end
	end

	if hasExternalBios then
		return externalBios
	end
end
