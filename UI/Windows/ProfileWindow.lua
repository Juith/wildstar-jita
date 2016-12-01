local Jita = Apollo.GetAddon("Jita")
local ProfileWindow = Jita:Extend("ProfileWindow")

local Utils = Jita.Utils
local Consts = Jita.Consts

--

function ProfileWindow:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self

	o.Metadata = nil

	o.MainForm = nil

	return o
end

function ProfileWindow:Init()
	Apollo.RegisterEventHandler("Jita_ICComm_StreamingChunkedData", "OnICComm_StreamingChunkedData", self)
	Apollo.RegisterEventHandler("Jita_ICComm_ReceivedPlayerData"  , "OnICComm_ReceivedPlayerData"  , self)
end

function ProfileWindow:LoadForms()
	self.MainForm = Apollo.LoadForm(Jita.XmlDoc, "JCC_CharacterProfileWindow", nil, self)

	Jita.WindowManager.Themes:ApplyCurrentThemeToWindow(self)

	self.MainForm:FindChild("BodyContainer"):SetBGOpacity(.9)
	self.MainForm:FindChild("BodyContainer"):SetNCOpacity(.9)

	self.MainForm:Show(false, true)
end

function ProfileWindow:ShowCharacterProfile(metadata) 
	if not metadata then
		return
	end

	if self.Metadata and self.Metadata.Name == metadata.Name then
		return
	end

	self:StopTimers()
	
	self.Metadata = metadata

	self.PlayerInfoLoaded = false
	self.PlayerModelLoaded = false

	local unit = GameLib.GetPlayerUnitByName(self.Metadata.Name)
	local unitPlayer = Jita.Player.Unit
	local friendList = FriendshipLib.GetList() or {}

	self.MainFormLastLocation = nil

	if self.MainForm and self.MainForm:IsValid() then
		self.MainFormLastLocation = self.MainForm:GetLocation()

		self.MainForm:Destroy()
	end

	self:LoadForms()

	if self.MainFormLastLocation then
		self.MainFormLastLocation = self.MainFormLastLocation:ToTable() 
		self.MainFormLastLocation.nOffsets[4] = self.MainFormLastLocation.nOffsets[2] + 353 - 44
		self.MainForm:MoveToLocation(WindowLocation.new(self.MainFormLastLocation))
	end

	local profile = Jita.Client:GetPlayerProfile(self.Metadata.Name)

	if not profile then
		profile = Jita.Client:AddPlayerProfile(self.Metadata.Name)
	end

	profile:PullDataFromExternalAddons()

	local mainFormTitle = self.MainForm:FindChild("MainFormTitle")
	local tabsContainer = self.MainForm:FindChild("TabsContainer")
	
	mainFormTitle:Show(true)
	tabsContainer:Show(false)

	-- if profile.ExternalBios then
		self:GenerateBioTabs("JITA")
	-- end

	-- if unit ~= nil then
	if unit ~= nil then
		self:LoadModel(unit)

		if profile then
			profile:PullDataFromUnit(unit)
			profile:PullDataFromPortrait(self.MainForm:FindChild("CharacterPortrait"))

			self:SetUserInfoVals(profile)

			-- Keepme:
			-- tests if pulling looks from costume window works
			-- self:GenerateModel(profile)
		end
	else
		if self.Metadata.IsCrossfaction == true then
			if unitPlayer:GetFaction() == Unit.CodeEnumFaction.DominionPlayer then 
				if not self.PlayerModelLoaded then
					self.MainForm:FindChild("FactionUnsureIcon"):Show(false)
					self.MainForm:FindChild("ExileIcon"):Show(true)
				end

				if profile then
					profile.Faction = Unit.CodeEnumFaction.ExilesPlayer
				end
			elseif unitPlayer:GetFaction() == Unit.CodeEnumFaction.ExilesPlayer then 
				if not self.PlayerModelLoaded then
					self.MainForm:FindChild("FactionUnsureIcon"):Show(false)
					self.MainForm:FindChild("DominionIcon"):Show(true)
				end

				if profile then
					profile.Faction = Unit.CodeEnumFaction.DominionPlayer
				end
			end
		else
			self.MainForm:FindChild("FactionUnsureIcon"):Show(true)
		end

		if profile and profile.InfoUpdated == true then
			self:SetUserInfoVals(profile)
		else
			self.MainForm:FindChild("WhoLoadingIcon"):Show(true)

			Jita.Client:DoWhoRequest(self.Metadata.Name)
		end
	end

	for key, player in pairs(friendList) do
		if player.strCharacterName == self.Metadata.Name then
			if player.bFriend then
				self.MainForm:FindChild("IsFriendIcon"):Show(true)
				self.MainForm:FindChild("IsFriendIcon"):SetTooltip("Friend")
			elseif player.bRival then
				self.MainForm:FindChild("IsRivalIcon"):Show(true)
				self.MainForm:FindChild("IsRivalIcon"):SetTooltip("Rival")
			elseif player.bIgnore then
				self.MainForm:FindChild("IsIgnoredIcon"):Show(true)
				self.MainForm:FindChild("IsIgnoredIcon"):SetText("Ignored")
			end

			if player.strNote ~= "" then
				self.MainForm:FindChild("HasNote"):Show(true)
				self.MainForm:FindChild("HasNote"):SetTooltip(player.strNote)
			end
		end
	end

	if not profile or profile.JitaUser == false then
		self.MainForm:FindChild("IsResquestingBioTimeOut"):SetText("Profile request is taking a while. Either the player is not using Jita Chat Client or the Com channel is busy in which case you may try again later.")
	end

	if profile and profile.BioUpdated == true then
		self.MainForm:FindChild("IICommLoadingLeftIcon"):Show(false)
		self.MainForm:FindChild("IsResquestingBio"):Show(false)
		self.MainForm:FindChild("IsResquestingBioTimeOut"):Show(false)

		self:GenerateBio(profile)

		if not unit and profile.ModelUpdated == true then
			self:GenerateModel(profile)
		end
	else
		self.MainForm:FindChild("IsResquestingBio"):SetText("Requesting player's profile..")
		
		self.MainForm:FindChild("IICommLoadingLeftIcon"):Show(true)
		self.MainForm:FindChild("IsResquestingBio"):Show(true)
		self.MainForm:FindChild("IsResquestingBioTimeOut"):Show(false)

		if self.IICommProfileRequestTimer then
			self.IICommProfileRequestTimer:Stop()
		end

		Event_FireGenericEvent("Jita_ICComm_RequestPlayerData", self.Metadata.Name)

		self.IICommProfileRequestTimer = ApolloTimer.Create(10, false, "OnIICommProfileRequestTimer", self)
	end

	self.MainForm:Show(true)
	self.MainForm:ToFront()
end

function ProfileWindow:StopTimers()
	if self.IICommProfileRequestTimer then
		self.IICommProfileRequestTimer:Stop()
	end

	if Jita.Client.WhoResponseTimer then
		Jita.Client.WhoResponseTimer:Stop()
	end
end

function ProfileWindow:OnRefreshButtonClick()
	self:StopTimers()

	if not self.Metadata then
		return
	end

	local profile = Jita.Client:GetPlayerProfile(self.Metadata.Name)

	if not profile then
		return
	end

	if self.Metadata.Name ~= Jita.Player.Name then
		profile.InfoUpdated  = false
		profile.ModelUpdated = false
		profile.BioUpdated   = false
	end

	local metadata = self.Metadata

	self.Metadata = nil

	self:ShowCharacterProfile(metadata)
end

function ProfileWindow:OnCloseButtonClick()
	self:StopTimers()

	self.MainForm:Destroy() 

	Jita.WindowManager:RemoveWindow("ProfileWindow")
end

function ProfileWindow:OnIICommProfileRequestTimer()
	self.IICommProfileRequestTimer:Stop()

	if self.Metadata.MightBeOffline and self.Metadata.MightBeOffline == true then
		return
	end

	if self.MainForm and self.MainForm:IsShown() then
		self.MainForm:FindChild("IICommLoadingLeftIcon"):Show(true)
		self.MainForm:FindChild("IsResquestingBio"):Show(false)
		self.MainForm:FindChild("IsResquestingBioTimeOut"):Show(true)

		local profile = Jita.Client:GetPlayerProfile(self.Metadata.Name)

		if self.Metadata.IsCrossfaction and profile.InfoUpdated == false then
			self.MainForm:FindChild("WhoLoadingIcon"):Show(false)

			local info = 
			{
				Title    = self.Metadata.Name,
				Level    = nil,
				Class    = nil,
				Race     = nil,
				Path     = nil,
				Gender   = nil,
				Faction  = nil,
				Location = nil
			}

			self:SetUserInfoVals(info)
		end
	end
end

function ProfileWindow:OnICComm_StreamingChunkedData(sender, total, order)
	if not sender
	or not self.MainForm
	or not self.MainForm:FindChild("IICommLoadingLeftProgress")
	then
		return
	end

	self.MainForm:FindChild("IICommLoadingLeftProgress"):Show(false)

	if sender ~= self.Metadata.Name then
		return
	end

	if not total or total < 1 or not order or order < 1 then 
		return
	end

	if total == order then 
		return
	end

	local profile = Jita.Client:GetPlayerProfile(self.Metadata.Name)

	if profile.BioUpdated == true then
		return
	end

	if profile.InfoUpdated == false then
		self.MainForm:FindChild("IsApiInCoolDown"):Show(false)
		self.MainForm:FindChild("MightBeOffline"):Show(false)
		self.MainForm:FindChild("WhoLoadingIcon"):Show(true)

		self.MainForm:FindChild("IsResquestingBio"):SetText("Retrieving player's profile..")
	elseif profile.ModelUpdated == false then
		self.MainForm:FindChild("IsResquestingBio"):SetText("Retrieving player's model..")
	else
		self.MainForm:FindChild("IsResquestingBio"):SetText("Retrieving player's biography..")
	end

	self.MainForm:FindChild("IsResquestingBioTimeOut"):SetText("Profile request is taking a while. The Com channel might be busy in which case you may try again later.")

	if self.MainForm:FindChild("IsResquestingBio"):IsShown() == false
	and self.MainForm:FindChild("IsResquestingBioTimeOut"):IsShown() == false
	then 
		self.MainForm:FindChild("IsResquestingBio"):Show(true)
	end

	self.MainForm:FindChild("IICommLoadingLeftIcon"):Show(true)
	self.MainForm:FindChild("IICommLoadingCenterIcon"):Show(false)
	self.MainForm:FindChild("IICommLoadingLeftProgress"):Show(true)
	self.MainForm:FindChild("IICommLoadingLeftProgress"):SetText(math.floor((order / total) * 100) .. " %")
end

function ProfileWindow:OnICComm_ReceivedPlayerData(sender, dataType)
	if sender ~= self.Metadata.Name then
		return
	end

	if self.IICommProfileRequestTimer then
		self.IICommProfileRequestTimer:Stop()
	end

	if self.MainForm and self.MainForm:IsShown() then 
		if self.Metadata.Name == sender then
			self.MainForm:FindChild("WhoLoadingIcon"):Show(false)

			local profile = Jita.Client:GetPlayerProfile(self.Metadata.Name)

			if profile then
				if profile.InfoUpdated == true then
					self:SetUserInfoVals(profile)
				end

				if profile.ModelUpdated == true then
					self:GenerateModel(profile)
				end

				if profile.BioUpdated == true then
					self.MainForm:FindChild("IICommLoadingLeftIcon"):Show(false)
					self.MainForm:FindChild("IsResquestingBio"):Show(false)
					self.MainForm:FindChild("IsResquestingBioTimeOut"):Show(false)
					
					self:GenerateBio(profile)
				end
			end
		end
	end
end
