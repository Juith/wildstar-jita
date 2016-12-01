local Jita = Apollo.GetAddon("Jita")
local Client = Jita:Extend("Client")

local Utils = Jita.Utils
local Consts = Jita.Consts

--

function Client:SubstituteJitaMacros(text)
--/- Oh no! some nanosecond spent parsing. Unacceptable!
--/
--/- Example:
--/-     Hiya, I'm &me, a level &level &gender &class, now hanging with my &faction buddies &nearby and faithful &pets at &location. Fear me for I'm a &ilevelilvl &path equipped with some super awesome &weapon.
--/-
--/- Implemented Macros: 
--/-    &me
--/-    &faction
--/-    &race
--/-    &gender
--/-    &class
--/-    &path
--/-    &guild
--/-    &level
--/-    &ilevel
--/-    &navpoint

--/-    &items
--/-       &chest
--/-       &head
--/-       &feet
--/-       &legs
--/-       etc.

--/-    &costume
--/-    &location
--/-    &money
--/-    &omnibits
--/-    &pets
--/-    &nearby
--/-    &party
--/-    &friendlist
--/-    &ignorelist
--/-    &neighborlist
--/-    &target
--/-    &channels
--/-    &circles

--/-    &pvet3
--/-    &pvpt3

--/-    &time
--/-    &fps
--/-    &lag

-- Todo:
--    &queues
--    &quests
--    &mount
--    &bags

	-- random shit is random
	if Jita.Timestamp < 2 then
		return text
	end

	-- cut it short
	if not text or not string.match(text, "&") then
		return text
	end

	--

	if string.match(text, "&me") then
		local name = Jita.Player.Unit:GetName()

		text = string.gsub(text, "&me", name)
	end

	--

	if string.match(text, "&faction") then
		local faction = Jita.Player.Unit:GetFaction()
		
		faction = Consts.karFactionToString[ faction ] or ''

		text = string.gsub(text, "&faction", faction)
	end

	--

	if string.match(text, "&race") then
		local race = Jita.Player.Unit:GetRaceId()
		
		race = Consts.karRaceToString[ race ] or ''

		text = string.gsub(text, "&race", race)
	end

	--

	if string.match(text, "&gender") then
		local gender = Jita.Player.Unit:GetGender()

		if Jita.Player.Unit:GetRaceId() == GameLib.CodeEnumRace.Chua then
			gender = -1
		end

		gender = Consts.karGenderToString[ gender ] or ''

		text = string.gsub(text, "&gender", gender)
	end

	--

	if string.match(text, "&class") then
		local class = Jita.Player.Unit:GetClassId()
		
		class = Consts.karClassToString[ class ] or ''

		text = string.gsub(text, "&class", class)
	end

	--

	if string.match(text, "&path") then
		local path = Jita.Player.Unit:GetPlayerPathType()

		path = Consts.ktPathToString[ path ] or ''

		text = string.gsub(text, "&path", path)
	end

	--

	if string.match(text, "&guild") then
		local guild = Jita.Player.Unit:GetGuildName() or ''

		text = string.gsub(text, "&guild", guild)
	end

	--

	if string.match(text, "&level") then
		local level = Jita.Player.Unit:GetLevel() or ''

		text = string.gsub(text, "&level", level)
	end

	--

	if string.match(text, "&ilevel") then
		local ilevel = Jita.Player.Unit:GetEffectiveItemLevel() or 0

		text = string.gsub(text, "&ilevel", math.floor(ilevel) + 1) -- oopsie
	end

	--

	if string.match(text, "&navpoint") then
		local navpoint = GameLib.GetNavPointChatLinkString() or ''

		text = string.gsub(text, "&navpoint", navpoint)
	end

	--

	if string.match(text, "&items") then
		local links = ''

		for _, item in pairs(Jita.Player.Unit:GetEquippedItems()) do
			if item:GetSlotName() and item:GetSlotName() ~= '' then -- idk
				links = links .. " " .. item:GetChatLinkString()
			end
		end

		text = string.gsub(text, "&items", links)
	end

	--

	for name, slot in pairs(GameLib.CodeEnumEquippedItems) do
		local macro  = "&" .. string.lower(tostring(name))

		if string.match(text, macro) then
			local link = ''

			for _, item in pairs(Jita.Player.Unit:GetEquippedItems()) do
				if slot == item:GetSlot() then
					link = item:GetChatLinkString()
				end
			end

			text = string.gsub(text, macro, link)
		end
	end

	if string.match(text, "&weapon") then
		local link = ''

		for _, item in pairs(Jita.Player.Unit:GetEquippedItems()) do
			if item:GetSlot() == GameLib.CodeEnumEquippedItems.WeaponPrimary then
				link = item:GetChatLinkString()
			end
		end

		text = string.gsub(text, "&weapon", link)
	end

	--

	if string.match(text, "&costume") then
		local links = ''

		local index = CostumesLib.GetCostumeIndex()

		local costume = CostumesLib.GetCostume(index)

		if costume then
			for _, slot in pairs(GameLib.CodeEnumEquippedItems) do
				local item = costume:GetSlotItem(slot)

				if item then
					links = links .. " " .. item:GetChatLinkString()
				end
			end
		end

		text = string.gsub(text, "&costume", links)
	end

	--

	if string.match(text, "&location") then
		local location = ''

		if Jita.Player.Location then
			location = tostring(Jita.Player.Location.Name)
		else
			local zone = GameLib.GetCurrentZoneMap()

			location = tostring(zone.strName)
		end

		local postion = Jita.Player.Unit:GetPosition()

		if postion then
			location = location ..  " <"
			location = location .. tonumber(math.floor(postion.x))
			location = location ..  ", "
			location = location .. tonumber(math.floor(postion.z))
			location = location ..  ">"
		end

		text = string.gsub(text, "&location", location)
	end

	--

	if string.match(text, "&money") then
		local money = ''
		
		local info = GameLib.GetPlayerCurrency()

		if info then
			money = info:GetMoneyString()
		end

		text = string.gsub(text, "&money", money)
	end

	--

	if string.match(text, "&omnibits") then
		local omnibits = ''
		
		local info = GameLib.GetOmnibitsBonusInfo()

		if info then
			omnibits = "Omnibits Earned: " .. tonumber(info.nWeeklyBonusEarned) .. ". Weekly Cap: " .. tonumber(info.nWeeklyBonusMax)
		end

		text = string.gsub(text, "&omnibits", omnibits)
	end

	--

	if string.match(text, "&target") then
		local target = ''

		local unit = Jita.Player.Unit:GetTarget()

		if unit then
			target = unit:GetName()
		end

		text = string.gsub(text, "&target", target)
	end

	--

	if string.match(text, "&pets") then
		local list = {}
		local pets = GameLib.GetPlayerPets()

		if pets then
			for _, unit in pairs (pets) do
				table.insert(list, unit:GetName())
			end
		end

		pets = table.concat(list, ', ')

		text = string.gsub(text, "&pets", pets)
	end

	--

	if string.match(text, "&nearby") then 
		local list = {}

		local cp = 1
		for name, unit in pairs(self.LocalPlayers) do
			if Jita.Player.Unit:GetName() ~= name
			and cp < 9
			then
				table.insert(list, name)

				cp = cp + 1
			end
		end

		local nearby = table.concat(list, ', ')

		text = string.gsub(text, "&nearby", nearby)
	end

	--

	if string.match(text, "&party") then
		local list = {}

		for cp = 1, GroupLib.GetMemberCount() do
			local member = GroupLib.GetGroupMember(cp)

			if member
			and member.strCharacterName
			and Jita.Player.Unit:GetName() ~= member.strCharacterName
			and cp < 9 
			then
				table.insert(list, member.strCharacterName)
			end
		end

		local party = table.concat(list, ', ')

		text = string.gsub(text, "&party", party)
	end
	
	--

	if string.match(text, "&friendlist") then
		local list = {}

		local friendlist = FriendshipLib.GetList() or {}

		local cp = 1
		for _, player in pairs(friendlist) do
			if player.bFriend 
			and cp < 9
			then
				table.insert(list, player.strCharacterName)

				cp = cp + 1
			end
		end

		friendlist = table.concat(list, ', ')

		text = string.gsub(text, "&friendlist", friendlist)
	end

	--

	if string.match(text, "&ignorelist") then
		local list = {}

		local friendList = FriendshipLib.GetList() or {}

		local cp = 1
		for _, player in pairs(friendList) do
			if player.bIgnore 
			and cp < 9
			then
				table.insert(list, player.strCharacterName)

				cp = cp + 1
			end
		end

		local ignorelist = table.concat(list, ', ')

		text = string.gsub(text, "&ignorelist", ignorelist)
	end

	--

	if string.match(text, "&neighborlist") then
		local list = {}

		local neighborlist = HousingLib.GetNeighborList() or {}

		local cp = 1
		for _, player in pairs(neighborlist) do
			if cp < 9 then
				table.insert(list, player.strCharacterName)

				cp = cp + 1
			end
		end

		neighborlist = table.concat(list, ', ')

		text = string.gsub(text, "&neighborlist", neighborlist)
	end

	--

	if string.match(text, "&channels") then
		local list = {}

		for _, channel in ipairs(ChatSystemLib.GetChannels()) do
			if channel:GetType() == ChatSystemLib.ChatChannel_Custom then
				table.insert(list, channel:GetName())
			end
		end

		local channels = table.concat(list, ', ')

		text = string.gsub(text, "&channels", channels)
	end

	--

	if string.match(text, "&circles") then
		local list = {}

		for _, channel in ipairs(ChatSystemLib.GetChannels()) do
			if channel:GetType() == ChatSystemLib.ChatChannel_Society then
				table.insert(list, channel:GetName())
			end
		end

		local circles = table.concat(list, ', ')

		text = string.gsub(text, "&circles", circles)
	end

	--

	if string.match(text, "&pvet3") then
		local t3 = ''

		local contracts = ContractsLib.GetPeriodicContracts()

		local pve = contracts[ContractsLib.ContractType.Pve] or {}

		for _, item in ipairs(pve) do
			if item 
			and item:GetQuest() 
			and item:GetQuality() == ContractsLib.ContractQuality.Superb
			then
				t3 = item:GetQuest():GetChatLinkString()
			end
		end

		text = string.gsub(text, "&pvet3", t3)
	end

	--

	if string.match(text, "&pvpt3") then
		local t3 = ''

		local contracts = ContractsLib.GetPeriodicContracts()

		local pvp = contracts[ContractsLib.ContractType.Pvp] or {}

		for _, item in ipairs(pvp) do
			if item 
			and item:GetQuest() 
			and item:GetQuality() == ContractsLib.ContractQuality.Superb
			then
				t3 = item:GetQuest():GetChatLinkString()
			end
		end

		text = string.gsub(text, "&pvpt3", t3)
	end

	--

	if string.match(text, "&time") then
		local t = Utils:GetFormatedTimeString()

		text = string.gsub(text, "&time", t)
	end

	--

	if string.match(text, "&fps") then
		local fps = math.floor(GameLib.GetFrameRate()*10)*0.1 .. " " .. Apollo.GetString("CRB_FPS")

		text = string.gsub(text, "&fps", fps)
	end

	--

	if string.match(text, "&lag") then -- ikr, cause it's shorter token
		local lag = GameLib.GetLatency() .. "ms"

		text = string.gsub(text, "&lag", lag)
	end

	return text
end
