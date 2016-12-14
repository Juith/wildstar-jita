--[[
	Debug window is an optimised monstrosity that will hit performances
	hard and low. Better run it as an independent add-on if there is need 
	for a serious benchmark.
]]--

local Jita = Apollo.GetAddon("Jita")
local DebugWindow = Jita:Extend("DebugWindow")

local Utils = Jita.Utils

--

function DebugWindow:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self

	o.MainForm = nil

	return o
end

function DebugWindow:Init()
end

function DebugWindow:LoadForms()
	self.MainForm = Apollo.LoadForm(Jita.XmlDoc, "JCC_DebugWindow", nil, self)
	self.MainForm:Show(true, true)
end

function DebugWindow:Tick()
	if not self.MainForm or not self.MainForm:IsValid() then  
		return
	end

	local info = Apollo.GetAddonInfo("ChatLog")

	if info then
		local message = "Counter part:\n"

		if info then
			message = message .. "\n  - Name: " .. info.strName
			message = message .. "\n  - Mem: " .. string.format("%.2fkb", info.nMemoryUsage / 1024)
			message = message .. "\n  - Calls: " .. info.nTotalCalls
			message = message .. "\n  - Cycles: " .. string.format("%.3fms", info.fCallTimePerFrame * 1000.0)
			message = message .. "\n  - Longest: " .. string.format("%.3fs", info.fLongestCall)
		end

		self.MainForm:FindChild("CounterPart"):SetText(message)
	end
	
	info = Apollo.GetAddonInfo("Jita")

	local message = "Addon info:\n"

	if info then
		message = message .. "\n  - Name: " .. info.strName
		message = message .. "\n  - Mem: " .. string.format("%.2fkb", info.nMemoryUsage / 1024)
		message = message .. "\n  - Calls: " .. info.nTotalCalls
		message = message .. "\n  - Cycles: " .. string.format("%.3fms", info.fCallTimePerFrame * 1000.0)
		message = message .. "\n  - Longest: " .. string.format("%.3fs", info.fLongestCall)
	end

	message = message .. "\n\n"

	message = message .. "Core info:\n"

	message = message .. "\n  - Version: "   .. Jita:GetAddonVersion()
	message = message .. "\n  - IIComm: "    .. Jita:GetICCommVersion()
	message = message .. "\n  - Seconds: "   .. Jita.Seconds
	message = message .. "\n  - Timestamp: " .. Jita.Timestamp
	message = message .. "\n  - Factory: "   .. Utils:Count(Jita.Factory)
	message = message .. "\n  - Settings: "  .. Utils:Count(Jita.CoreSettings) .. ", " .. Utils:Count(Jita.UserSettings)

	message = message .. "\n\n"

	message = message .. "Client info:\n"
	
	local clientInfoStreams         = Utils:Count(Jita.Client.Streams)
	local clientInfoChannels        = 0
	local clientInfoMessagesTotal   = 0
	local clientInfoMembersTotal    = 0
	local clientInfoMembersNearby   = Utils:Count(Jita.Client.LocalPlayers)
	local clientInfoMembersProfiles = Utils:Count(Jita.Client.MembersProfiles)
	
	for _, stream in ipairs(Jita.Client.Streams) do
		clientInfoChannels      = clientInfoChannels      + Jita.Utils:Count(stream.Channels)
		clientInfoMembersTotal  = clientInfoMembersTotal  + Jita.Utils:Count(stream.Members)
		clientInfoMessagesTotal = clientInfoMessagesTotal + Jita.Utils:Count(stream.Messages)
	end

	message = message .. "\n  - Streams: "          .. clientInfoStreams         
	message = message .. "\n  - Channels: "         .. clientInfoChannels        
	message = message .. "\n  - Messages: "         .. clientInfoMessagesTotal  
	message = message .. "\n  - Members: "          .. clientInfoMembersTotal   
	message = message .. "\n  - Members Nearby: "   .. clientInfoMembersNearby  
	message = message .. "\n  - Members Profiles: " .. clientInfoMembersProfiles

	message = message .. "\n\n"

	message = message .. "Window Manager info:\n"

	message = message .. "\n  - Windows: "          .. Utils:Count(Jita.WindowManager.Windows)

	message = message .. "\n\n"

	local stratas = Apollo.GetStrata() or {}

	for _, strata in ipairs(stratas) do
		local temp = "Windows in stratum " .. strata .. ":\n"

		local windows = Apollo.GetWindowsInStratum(strata) or {}
		local count = 0

		for __, window in ipairs(windows) do
			if string.match(window:GetName(), Jita:GetWindowNamespace()) then
				temp = temp .. "\n  #" .. 
					window:GetId() .. " " .. 
					(window:IsValid() and "Valid  " or "Invalid") .. " " .. 
					(window:IsShown() and "Shown  " or "Hidden ") .. " " .. 
					string.gsub(window:GetName(), Jita:GetWindowNamespace(), "")

				count = count + 1
			end
		end

		if count > 0 then
			message = message .. temp .. "\n  " .. count .. " items found.\n\n"
		end
	end

	self.MainForm:FindChild("InfoPane"):SetText(message)

	self.MainForm:FindChild("UpdateTimerProgressBar"):SetFullSprite("CRB_Nameplates:sprNP_GreenProg")

	--/- 2048k
	if info.nMemoryUsage / 2048 > 1000 then
		self.MainForm:FindChild("UpdateTimerProgressBar"):SetFullSprite("CRB_Nameplates:sprNP_PurpleProg")
	end

	--/- 0.1ms
	if info.fCallTimePerFrame * 1000.0 > 0.1 then
		self.MainForm:FindChild("UpdateTimerProgressBar"):SetFullSprite("CRB_Raid:sprRaid_HealthProgBar_Red")
	end

	self.MainForm:FindChild("UpdateTimerProgressBar"):SetMax(60)
	self.MainForm:FindChild("UpdateTimerProgressBar"):SetFloor(0)
	self.MainForm:FindChild("UpdateTimerProgressBar"):SetProgress(Jita.Seconds)
	self.MainForm:FindChild("UpdateTimerProgressBar"):Show(true)

	--

	if Jita.ICCommNode then
		message = "ICComm info:\n"
		
		local icNode = Jita.ICCommNode

		local delay = icNode.Channel.ThrottleLeap - Jita.Timestamp
		if delay < 0 then delay = 0 end


		local bufferInTot = 0
		local bufferOutTot = 0
		local bufferInSize = 0
		local bufferOutSize = 0
		
		for i, __ in pairs(icNode.Buffer.In) do
			for j, ___ in ipairs(__) do
				bufferInTot = bufferInTot + 1
				bufferInSize = bufferInSize + ___:len()
			end
		end
		for i, __ in pairs(icNode.Buffer.Out) do
			for j, ___ in ipairs(__) do
				bufferOutTot = bufferOutTot + 1
				bufferOutSize = bufferOutSize + ___:len()
			end
		end

		message = message .. "\n  - Channel: " .. tostring(icNode.Channel.Name) .. ", " .. tostring(icNode.Channel.Type) .. ": " .. tostring(icNode.Channel.Ready)
		message = message .. "\n  - Buffer In: " .. Utils:Count(icNode.Buffer.In) .. " , " .. bufferInTot  .. " , " .. bufferInSize 
		message = message .. "\n  - Buffer Out: " .. Utils:Count(icNode.Buffer.Out) .. " , " .. bufferOutTot .. " , " .. bufferOutSize 
		message = message .. "\n  - Throttle Leap: " .. math.floor(icNode.Channel.ThrottleLeap)
		message = message .. "\n  - Throttle Delay: " .. delay

		message = message .. "\n  - KA Leap: " .. icNode.Channel.KeepAliveLeap
		
		message = message .. "\n  - MPS Up: " .. icNode.Channel.MPSUpload .. " , " .. icNode.Channel.TotalMessagesUpload
		message = message .. "\n  - MPS Down: " .. icNode.Channel.MPSDownload .. " , " .. icNode.Channel.TotalMessagesDownload
		
		message = message .. "\n  - CPS Up: " .. icNode.Channel.CPSUpload .. " , " .. icNode.Channel.TotalDataUpload
		message = message .. "\n  - CPS Down: " .. icNode.Channel.CPSDownload .. " , " .. icNode.Channel.TotalDataDownload
		
		message = message .. "\n  - Average Up: " .. string.format("%.3f", icNode.Channel.AverageUpload)
		message = message .. "\n  - Average Down: " .. string.format("%.3f", icNode.Channel.AverageDownload)

		self.MainForm:FindChild("ICCommInfo"):SetText(message)
	end
	

	if Jita.Player then
		local player  = Jita.Player

		message = "Player info:\n"

		message = message .. "\n  - Name: " .. tostring(player.Name)
		message = message .. "\n  - Unit: " .. tostring(player.Unit)
		message = message .. "\n  - Profile: " .. tostring(player.Profile) .. "\n    .. " .. tostring(player.Profile.Name) .. "\n    .. " .. tostring(player.Profile.JitaUser) .. "\n    .. " .. tostring(player.Profile.Location) 

		message = message .. "\n    .. looks:" .. Jita.Utils:Count(player.Profile.Looks)
		message = message .. "\n    .. bones:" .. Jita.Utils:Count(player.Profile.Bones)

		if player.Profile.Bio then
			message = message .. "\n    .. bio:" .. player.Profile.Bio:len()
		else
			message = message .. "\n    .. bio:nil"
		end

		if player.Location then
			message = message .. "\n  - Location: " .. tostring(player.Location) .. "\n    .. " .. tostring(player.Location.ID) .. "\n    .. " .. tostring(player.Location.Zone) .. "\n    .. " .. tostring(player.Location.Subzone) .. "\n    .. " .. tostring(player.Location.Residence) .. "\n    .. " .. tostring(player.Location.Name)
		end

		self.MainForm:FindChild("PlayerInfo"):SetText(message)
	end
end
