local Jita = Apollo.GetAddon("Jita")
local Player = Jita:Extend("Player")

--

function Player:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self

	o.Name     = nil
	o.Unit     = nil
	o.Profile  = nil
	o.Location = nil

	return o
end

function Player:Init()
	self:InitUnit()

	self:InitProfile()
end

function Player:InitUnit()
	local unit = GameLib.GetPlayerUnit()

	if not unit then
		return
	end

	self.Unit = unit or self.Unit
	self.Name = unit:GetName() or self.Name
end

function Player:InitProfile()
	if not self.Profile then
		self.Profile = Jita:Yield("Profile")
	end

	if self.Unit then
		self.Profile:PullDataFromUnit(self.Unit)
	end

	self.Profile.Name       = self.Name
	self.Profile.BioUpdated = true
	self.Profile.JitaUser   = true
end

function Player:RestoreProfile(data)
	self:InitProfile()

	-- for now this is the only field that matter
	if data.Bio then
		self.Profile:Update("Bio", data.Bio)
	end
end

function Player:UpdateLocation(subZoneName)
	local zone = GameLib.GetCurrentZoneMap()

	if not zone then
		return
	end

	local location      = zone.strName
	local residence     = HousingLib.GetResidence()
	local residenceName = nil

	if residence then
		residenceName = residence:GetPropertyName()

		if not residenceName or residenceName == '' then
			residenceName = tostring(residence:GetPropertyOwnerName()) .. "'s Residence"
		end
	end

	if not subZoneName or subZoneName == '' then
		subZoneName = GetCurrentZoneName()
	end

	if subZoneName and subZoneName ~= '' then
		location = location .. ", " .. subZoneName
	elseif residence and residenceName then
		location = location .. ", " .. residenceName
	end

	self.Location = {
		ID        = zone.id,
		Name      = location,
		Zone      = zone.strName,
		Subzone   = subZoneName,
		Residence = residenceName
	}

	if self.Profile then
		self.Profile.Location = location
	end
end
