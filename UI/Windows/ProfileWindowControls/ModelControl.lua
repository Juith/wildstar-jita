local Jita = Apollo.GetAddon("Jita")
local ProfileWindow = Jita:Extend("ProfileWindow")

local Utils = Jita.Utils
local Consts = Jita.Consts

--

function ProfileWindow:GenerateModel(profile)
	local unit = GameLib.GetPlayerUnitByName(self.Metadata.Name or '')

	-- cut it shot is player is nearby
	if unit then
		self:LoadModel(unit)

		return
	end

	if not profile
	or not profile.Faction
	or not profile.Race
	or not profile.Gender
	then
		return
	end

	if profile.Faction == Unit.CodeEnumFaction.DominionPlayer then
		self.MainForm:FindChild("DominionIcon"):Show(true)
	elseif profile.Faction == Unit.CodeEnumFaction.ExilesPlayer then
		self.MainForm:FindChild("ExileIcon"):Show(true)
	else
		self.MainForm:FindChild("FactionUnsureIcon"):Show(true)
	end

	-- for reasons, some races won't change for players on the other faction
	if profile.Faction ~= Jita.Player.Unit:GetFaction() then
		return
	end

	-- SetRaceAndGender does not support Granok and Mechari
	if (profile.Race == GameLib.CodeEnumRace.Granok  and GameLib.CodeEnumRace.Granok  ~= Jita.Player.Unit:GetRaceId())
	or (profile.Race == GameLib.CodeEnumRace.Mechari and GameLib.CodeEnumRace.Mechari ~= Jita.Player.Unit:GetRaceId())
	then
		return
	end

	self:LoadModel(Jita.Player.Unit)

	self.MainForm:FindChild("ExpandCharacterPreviewIcon"):Show(false)

	self.MainForm:FindChild("CharacterPortrait"):SetRaceAndGender(profile.Race, profile.Gender)

	self.MainForm:FindChild('CharacterPortrait'):RemoveItem(GameLib.CodeEnumItemSlots.Weapon)
	self.MainForm:FindChild('CharacterPortrait'):RemoveItem(GameLib.CodeEnumItemSlots.Head)
	self.MainForm:FindChild('CharacterPortrait'):RemoveItem(GameLib.CodeEnumItemSlots.Shoulder)
	self.MainForm:FindChild('CharacterPortrait'):RemoveItem(GameLib.CodeEnumItemSlots.Chest)
	self.MainForm:FindChild('CharacterPortrait'):RemoveItem(GameLib.CodeEnumItemSlots.Hands)
	self.MainForm:FindChild('CharacterPortrait'):RemoveItem(GameLib.CodeEnumItemSlots.Legs)
	self.MainForm:FindChild('CharacterPortrait'):RemoveItem(GameLib.CodeEnumItemSlots.Feet)

	-- looks are somewhat validated in iccom
	for _, __ in ipairs(profile.Looks) do
		if __[1] ~= nil and __[2] ~= nil then
			self.MainForm:FindChild("CharacterPortrait"):SetLook(__[1], __[2]) 
		end
	end

	-- idem for bones
	for _, __ in ipairs(profile.Bones) do
		if __[1] ~= nil and __[2] ~= nil then
			self.MainForm:FindChild("CharacterPortrait"):SetBone(__[1], __[2] / 10) 
		end
	end

	-- nts:
	-- Dominion chestplate 50524

	for _, __ in ipairs(profile.Costume) do
		if __[1] ~= nil and __[2] ~= nil then
			local item = Item.GetDataFromId(__[2])

			if item then
				self.MainForm:FindChild("CharacterPortrait"):SetItem(item)
			end
		end
	end
end

function ProfileWindow:LoadModel(unit)
	self.MainForm:FindChild("ExileIcon"):Show(false)
	self.MainForm:FindChild("DominionIcon"):Show(false)
	self.MainForm:FindChild("FactionUnsureIcon"):Show(false)

	if not unit then
		return
	end

	self.MainForm:FindChild("CharacterPortrait"):SetData(unit)
	self.MainForm:FindChild("CharacterPortrait"):SetCostume(unit)
	self.MainForm:FindChild("CharacterPortrait"):SetSpin(0)
	self.MainForm:FindChild("CharacterPortrait"):SetSheathed(true)
	self.MainForm:FindChild("ExpandCharacterPreviewIcon"):Show(true)
end

function ProfileWindow:OnModelLoaded()
	self.MainForm:FindChild("ExileIcon"):Show(false)
	self.MainForm:FindChild("DominionIcon"):Show(false)
	self.MainForm:FindChild("FactionUnsureIcon"):Show(false)

	self.PlayerModelLoaded = true
end

function ProfileWindow:OnExpandCharacterPreviewIconClick()
	local costumeWindow = self.MainForm:FindChild("CharacterPortrait")
	local unit          = costumeWindow:GetData()

	Jita.WindowManager:LoadWindow("ModelPreviewWindow"):ShowModelPreview(unit, costumeWindow)
end
