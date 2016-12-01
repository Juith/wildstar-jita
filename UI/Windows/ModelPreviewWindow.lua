local Jita = Apollo.GetAddon("Jita")
local ModelPreviewWindow = Jita:Extend("ModelPreviewWindow")

--

function ModelPreviewWindow:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self

	o.MainForm = nil

	return o
end

function ModelPreviewWindow:Init()
end

function ModelPreviewWindow:LoadForms()
	self.MainForm = Apollo.LoadForm(Jita.XmlDoc, "JCC_ModelPreviewWindow", nil, self)
	self.MainForm:Show(false, true)
end

function ModelPreviewWindow:ShowModelPreview(unit, costumeWindow)
	self.MainFormLastLocation = nil

	if self.MainForm and self.MainForm:IsValid() then
		self.MainFormLastLocation = self.MainForm:GetLocation()

		self.MainForm:Destroy()
	end

	self:LoadForms()

	if self.MainFormLastLocation then
		self.MainFormLastLocation = self.MainFormLastLocation:ToTable() 
		self.MainForm:MoveToLocation(WindowLocation.new(self.MainFormLastLocation))
	end

	--

	if unit then
		local unitTarget = unit:GetTarget()

		if not unitTarget then
			self.MainForm:FindChild('TargetPortrait'):Show(false) 
		else
			self.MainForm:FindChild('TargetPortrait'):SetCostume(unitTarget) 
			self.MainForm:FindChild('TargetPortrait'):Show(true)
		end

		self.MainForm:FindChild('PlayerName'):SetText(unit:GetName()) 

		local unitInfos = ""
		local unitGuild = unit:GetGuildName()

		if unitGuild then 
			unitInfos = "Tag: " .. unitGuild .. "\n"
		end

		if unit:GetFaction() == Unit.CodeEnumFaction.DominionPlayer then
			unitInfos = unitInfos .. "Faction: Dominion\n"
		elseif unit:GetFaction() == Unit.CodeEnumFaction.ExilesPlayer then
			unitInfos = unitInfos .. "Faction: Exile\n" -- scum
		end

		if  unitTarget then
			unitInfos = unitInfos .. "Target: " .. unitTarget:GetName() .. "\n"
		end

		if  unit:IsFriend() or unit:IsAccountFriend() then
			unitInfos = unitInfos .. "Friend\n"
		end

		self.MainForm:FindChild('PlayerInfos'):SetText(unitInfos) 

		self.MainForm:FindChild('CharacterPortrait'):SetCostume(unit)
		self.MainForm:FindChild('CharacterPortrait'):SetCamera("Paperdoll")
		self.MainForm:FindChild('CharacterPortrait'):SetSpin(0)
		self.MainForm:FindChild('CharacterPortrait'):SetSheathed(true)

		-- Default_Dominion_StartScreen_Loop_01 = 7723 ,
		-- Default_Exile_StartScreen_Loop_01 = 7724 ,
		if unit:GetFaction() == 166 then
			self.MainForm:FindChild("CharacterPortrait"):SetModelSequence(7723)
		elseif unit:GetFaction() == 167 then
			self.MainForm:FindChild("CharacterPortrait"):SetModelSequence(7724)
		end
	else
		self.MainForm:FindChild('CharacterPortrait'):SetCostumeFromCostumeWindow(costumeWindow)

		-- Todo:
		-- replicate costume.
			-- self.MainForm:FindChild("CharacterPortrait"):SetModelSequence(7723)
			-- self.MainForm:FindChild('CharacterPortrait'):RemoveItem(GameLib.CodeEnumItemSlots.Weapon)
			-- self.MainForm:FindChild('CharacterPortrait'):RemoveItem(GameLib.CodeEnumItemSlots.Head)
			-- self.MainForm:FindChild('CharacterPortrait'):RemoveItem(GameLib.CodeEnumItemSlots.Shoulder)
			-- self.MainForm:FindChild('CharacterPortrait'):RemoveItem(GameLib.CodeEnumItemSlots.Chest)
			-- self.MainForm:FindChild('CharacterPortrait'):RemoveItem(GameLib.CodeEnumItemSlots.Hands)
			-- self.MainForm:FindChild('CharacterPortrait'):RemoveItem(GameLib.CodeEnumItemSlots.Legs)
			-- self.MainForm:FindChild('CharacterPortrait'):RemoveItem(GameLib.CodeEnumItemSlots.Feet)
	end

	self.MainForm:Invoke()
end

function ModelPreviewWindow:OnCloseButtonClick()
	self.MainForm:Destroy()
	
	Jita.WindowManager:RemoveWindow("ModelPreviewWindow")
end


function ModelPreviewWindow:OnActionsBtnClick()
	local unit = self.MainForm:FindChild("TargetPortrait"):GetData()

	if unit ~= nil then
		Event_FireGenericEvent("GenericEvent_NewContextMenuPlayerDetailed", nil, unit:GetName(), unit)
	end
end
