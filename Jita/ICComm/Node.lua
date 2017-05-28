--/- 100 CPS at this time and age is ridiculous
--/- Switching node to relay mode after requesting a profile is still uncompleted.

local Jita = Apollo.GetAddon("Jita")
local Node = Jita:Extend("ICCommNode")

local Utils = Jita.Utils
local Consts = Jita.Consts

require "ICComm"
require "ICCommLib"

--

local ICCOMM_CMD_KEEP_ALIVE           = 1
local ICCOMM_CMD_REQUEST_DATA         = 2
local ICCOMM_CMD_SENT_DATA            = 3
local ICCOMM_CMD_SENT_CHUNK           = 4
local ICCOMM_CMD_HALT_SENDING         = 5
local ICCOMM_CMD_SEE_OTHER            = 6
local ICCOMM_CMD_FORWARD_REQUEST      = 7
local ICCOMM_CMD_MISDIRECTED_REQUEST  = 8

local ICCOMM_KEEP_ALIVE_TYPE_SUMMARY  = 1
local ICCOMM_KEEP_ALIVE_TYPE_CHANNELS = 2

local ICCOMM_DATA_TYPE_INFO           = 1
local ICCOMM_DATA_TYPE_MODEL          = 2
local ICCOMM_DATA_TYPE_BIO            = 3
local ICCOMM_DATA_TYPE_INTERESTS      = 4

--

function Node:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self 

	o.Name = nil

	o.Channel = {
		Name     = nil,
		Type     = nil,
		Refrence = nil,
		Ready    = false,
		Timer    = nil,

		-- Timestamp at which we may send data
		-- Used to self throttle/delay sending messages
		ThrottleLeap = 0,

		-- Timestamp at which we may ping the network
		KeepAliveLeap = 30,

		-- numbers of exchanged Messages Per Second
		-- get rest every second
		MPSUpload            = 0,
		MPSDownload          = 0,

		-- hard limit to exchanged messages per second
		-- to prevent flooding and whatnot.
		HardLimitMPSUpload   = 0,
		HardLimitMPSDownload = 0,

		-- amount of exchanged Characters Per Second
		-- get rest every second
		CPSUpload            = 0,
		CPSDownload          = 0,

		-- soft limits to exchanged data on a channel per second
		-- Upon reaching these values, we self throttle outbound traffic
		-- by penalising Node.Channel.ThrottleLeap
		LimitCPSUpload       = 0,
		LimitCPSDownload     = 0,

		-- hard limit to exchanged data per second
		-- past the limits, outbound messages get dropped, inbound messages get ignored.
		HardLimitCPSUpload   = 0,
		HardLimitCPSDownload = 0,

		-- Statistics
		TotalMessagesUpload   = 0,
		TotalMessagesDownload = 0,
		TotalDataUpload       = 0,
		TotalDataDownload     = 0,
		AverageUpload         = 0,
		AverageDownload       = 0,
	}

	o.Network = {}

	-- Chunked messages awaiting to be parsed
	o.Buffer = {
		In  = {},
		Out = {},
		Wnd = {},
	}

	return o
end

function Node:Init(core)
	Apollo.LinkAddon(core, self)

	Apollo.RegisterEventHandler("ChangeWorld"                  , "OnChangeWorld"      , self)
	Apollo.RegisterEventHandler("UnitEnteredCombat"            , "OnUnitEnteredCombat", self)
	Apollo.RegisterEventHandler("Jita_ICComm_RequestPlayerData", "RequestPlayerData"  , self) 
end

--

function Node:Debug(msg)
--/- as dumb as it looks

	if not Jita.CoreSettings.EnableIICommDebug then
		return
	end

	Print(msg)
end

function Node:OnChangeWorld()
--/- keep quite for seconds upon zoning 

	self.Channel.ThrottleLeap = self.Channel.ThrottleLeap + 4
end

function Node:OnUnitEnteredCombat(unit, bInCombat)
--/- go silent for a while when entering combat

	if unit and unit:IsThePlayer() then
		self.Channel.ThrottleLeap = self.Channel.ThrottleLeap + 4
	end
end

--

function Node:Tick()
	if not self.Channel.Refrence or not self.Channel.Ready then
		return false
	end

	-- advertise presence to network
	if Jita.Timestamp == self.Channel.KeepAliveLeap then
		self:KeepAlive()

		-- see ya on 5, maybe.
		self.Channel.KeepAliveLeap = 
			Jita.Timestamp
			+ 300
			+ math.floor(self.Channel.AverageUpload + self.Channel.AverageDownload * 2)
	end

	-- sync sending timer
	if self.Channel.ThrottleLeap < Jita.Timestamp then
		self.Channel.ThrottleLeap = Jita.Timestamp
	end

	-- if player's dead, we keep silent for he may RIP.
	if Jita.Player.Unit:IsDead() == true then
		self.Channel.ThrottleLeap = Jita.Timestamp + 1
	end

	-- in combat slows sending rate by half
	if Jita.Player.Unit:IsInCombat() == true 
	and Jita.Timestamp % 2 == 0
	then
		self.Channel.ThrottleLeap = Jita.Timestamp + 1
	end

	-- thing that actually send data
	self:SortOutboundQueue()

	-- data porn
	self.Channel.TotalMessagesUpload   = self.Channel.TotalMessagesUpload   + self.Channel.MPSUpload
	self.Channel.TotalMessagesDownload = self.Channel.TotalMessagesDownload + self.Channel.MPSDownload

	self.Channel.TotalDataUpload       = self.Channel.TotalDataUpload   + self.Channel.CPSUpload
	self.Channel.TotalDataDownload     = self.Channel.TotalDataDownload + self.Channel.CPSDownload

	self.Channel.AverageUpload         = self.Channel.TotalDataUpload   / Jita.Timestamp
	self.Channel.AverageDownload       = self.Channel.TotalDataDownload / Jita.Timestamp

	self.Channel.MPSUpload   = 0
	self.Channel.MPSDownload = 0 

	self.Channel.CPSUpload   = 0
	self.Channel.CPSDownload = 0 
end

--

function Node:Connect(channelName, channelType)
	if channelName then
		self.Channel.Name = channelName
	end

	if channelType then
		self.Channel.Type = channelType
	end

	self.Channel.LimitCPSUpload   = ICCommLib.GetUploadCapacityByType(self.Channel.Type)
	self.Channel.LimitCPSDownload = ICCommLib.GetDownloadCapacityByType(self.Channel.Type)

	self.Channel.HardLimitCPSUpload   = self.Channel.LimitCPSUpload   * 16
	self.Channel.HardLimitCPSDownload = self.Channel.LimitCPSDownload * 8

	self.Channel.HardLimitMPSUpload   = 16
	self.Channel.HardLimitMPSDownload = 32

	self:Debug("~ Connecting to " .. self.Channel.Name .. "/" .. self.Channel.Type .. " " .. self.Channel.LimitCPSUpload .. "/" .. self.Channel.LimitCPSDownload .. " " .. self.Channel.HardLimitCPSUpload .. "/" .. self.Channel.HardLimitCPSDownload .. " " .. self.Channel.HardLimitMPSUpload .. "/" .. self.Channel.HardLimitMPSDownload)

	self.Channel.Timer = ApolloTimer.Create(5, true, "Join", self)
end

function Node:Join()
	if not Jita.LibJSON or not Jita.LibCRC32 then
		return
	end

	if not self.Channel.Name or not self.Channel.Type then
		return
	end

	if not self.Channel.Refrence then
		self.Channel.Refrence = ICCommLib.JoinChannel(
			self.Channel.Name,
			self.Channel.Type
		)

		self.Channel.Refrence:SetJoinResultFunction("OnJoin", self)
	end

	if self.Channel.Refrence:IsReady() then
		self:Debug("~ " .. self.Channel.Name .. " is ready.")

		self.Channel.Refrence:SetReceivedMessageFunction("OnMessage", self)
		self.Channel.Refrence:SetThrottledFunction("OnThrottle", self)
		self.Channel.Refrence:SetSendMessageResultFunction("OnSent", self)

		if self.Channel.Timer then 
			self.Channel.Timer:Stop()
		end

		self.Channel.Ready = true

		return
	end

	self:Debug("~ " .. self.Channel.Name .. " is pending..")
end

function Node:OnJoin(channel, eResult)
	local t = {
		[4] = "BadName",
		[5] = "Join", 
		[6] = "Left", 
		[7] = "MissingEntitlement",
		[3] = "NoGroup",
		[2] = "NoGuild",
		[1] = "TooManyChannels",
	}

	if eResult and eResult ~= 5 then
		self:Debug("~ " .. tostring(t[eResult]) .. eResult)
	end
end

function Node:OnThrottle(channel, sender, idMessage)
	self:Debug("~ OnThrottle " .. sender .. idMessage)

	-- delay some
	self.Channel.ThrottleLeap = self.Channel.ThrottleLeap + 2

	-- attempt to send one more time and call it quit
	local msg =  nil

	for _, wMsg in ipairs(self.Buffer.Wnd) do
		if wMsg.ID == idMessage then
			msg = wMsg
		end
	end

	if msg then
		self:Send(msg.Frame, msg.Recipient, true)

		self.Buffer.Wnd[idMessage] = nil
	end
end

function Node:OnMessage(channel, message, sender)
	if not message then
		return
	end
	
	local size = string.len(message)

	self:Debug("> " .. string.format("%20s ", sender) .. string.format("%3s ", size) .. string.sub(message, 1, 100) .. " ..")

	self.Channel.MPSDownload = self.Channel.MPSDownload + 1

	--

	self.Channel.CPSDownload = self.Channel.CPSDownload + size

	if self.Channel.CPSDownload > self.Channel.LimitCPSDownload then
		local penality = size * 2 / self.Channel.LimitCPSDownload

		self.Channel.ThrottleLeap = self.Channel.ThrottleLeap + penality
	end

	-- drop message if cps exceeded hard cap
	if self.Channel.CPSDownload > self.Channel.HardLimitCPSDownload then
		return
	end

	-- drop message if mps exceeded hard cap
	if self.Channel.MPSDownload > self.Channel.HardLimitMPSDownload then
		return
	end

	--

	local decoded = self:DecodeMessage(message, sender)

	if decoded and decoded.Command ~= nil then
		self:OnCommand(decoded)
	end
end

function Node:Send(frame, recipient, isRewind)
	local id  = 0

	if recipient ~= nil then
		id = self.Channel.Refrence:SendPrivateMessage(recipient, frame)
	else
		id = self.Channel.Refrence:SendMessage(frame)
	end

	if not isRewind then
		table.insert(self.Buffer.Wnd, { ID = id, Frame = frame, Recipient = recipient })
	end

	self:Debug("< " .. string.format("%20s ", (recipient or "Network")) .. string.format("%3s ", string.len(frame)) .. string.sub(frame, 1, 100) .. " ..")
end

function Node:OnSent(channel, eResult, idMessage)
	local t = {
		[7] = "InvalidText",
		[8] = "MissingEntitlement", 
		[3] = "NotInChannel", 
		[1] = "Sent", 
		[2] = "Throttled" 
	}

	if eResult and eResult ~= 1 then
		self:Debug("~ " .. tostring(t[eResult]) .. " " .. idMessage .. " " .. eResult)
	end
end

function Node:Enqueue(command, data, recipient, chunked)
	local message = self:EncodeMessage(command, data)

	if not message then
		return
	end

	if chunked ~= true or message:len() < self.Channel.LimitCPSUpload then
		table.insert(self.Buffer.Out, {
			Command = command, 
			Message = message, 
			MayExceedLimit = false, 
			Recipient = recipient 
		})

		return
	end

	-- chunk encoded message on packets to be sent over next 8 seconds
	-- any remaining data is to be sent in one burst
	local chunks = Utils:Chunk(message, self.Channel.LimitCPSUpload - 16, 8)

	for i=1, #chunks - 1 do
		local part = self:EncodeMessage(ICCOMM_CMD_SENT_CHUNK, {i, #chunks, chunks[i]})

		table.insert(self.Buffer.Out, { 
			Command = ICCOMM_CMD_SENT_CHUNK, 
			Message = part, 
			MayExceedLimit = false,
			Recipient = recipient 
		})
	end

	local part = self:EncodeMessage(ICCOMM_CMD_SENT_CHUNK, {#chunks, #chunks, chunks[#chunks]})

	table.insert(self.Buffer.Out, {
		Command = ICCOMM_CMD_SENT_CHUNK, 
		Message = part, 
		MayExceedLimit = true, 
		Recipient = recipient
	})
end

function Node:SortOutboundQueue()
	local wSize = #self.Buffer.Wnd

	-- Rewind must not exceed 4 frames
	if wSize > 4 then
		for i = 5, wSize do
			table.remove(self.Buffer.Wnd, 1)
		end
	end

	--

	local oSize = #self.Buffer.Out

	if oSize < 1 then
		return
	end

	-- OutboundQueue must not exceed double mps hard limit
	if oSize > self.Channel.HardLimitMPSUpload * 2 then
		for i = self.Channel.HardLimitMPSUpload * 2, oSize do
			table.remove(self.Buffer.Out, 1)
		end
	end

	if self.Channel.ThrottleLeap > Jita.Timestamp then
		return
	end

	for i = 1, #self.Buffer.Out do
		local item = table.remove(self.Buffer.Out, 1)

		if item then
			local size = string.len(item.Message)

			-- messages to send must not exceed hard cap
			if self.Channel.CPSUpload + size < self.Channel.HardLimitCPSUpload then
				self.Channel.CPSUpload = self.Channel.CPSUpload + size 

				if self.Channel.CPSUpload > self.Channel.LimitCPSUpload then
					local penality = size * 2 / self.Channel.LimitCPSUpload

					self.Channel.ThrottleLeap = self.Channel.ThrottleLeap + penality
				end

				if item.Recipient ~= nil then
					self:Send(item.Message, item.Recipient)
				else
					self:Send(item.Message)
				end

				self.Channel.MPSUpload = self.Channel.MPSUpload + 1

				-- pause queue past this limit
				if self.Channel.MPSUpload > self.Channel.HardLimitMPSUpload
				or self.Channel.CPSUpload > self.Channel.LimitCPSUpload
				or self.Channel.CPSUpload > self.Channel.CPSUpload * 0.75 -- >75%  bandwidth consumed
				then
					return
				end
			else
				self:Debug("! " .. string.format("%18s ", (item.Recipient or "Network")) .. string.format("%3s ", string.len(item.Message)) .. string.sub(item.Message, 1, 100) .. " ..")
			end
		end
	end
end

function Node:OnCommand(decoded)
	if not decoded then
		return
	end

	if decoded.Command == ICCOMM_CMD_KEEP_ALIVE then
		self:OnReceivedKeepAlive(decoded)

	elseif decoded.Command == ICCOMM_CMD_REQUEST_DATA then
		self:OnReceivedRequestData(decoded)

	elseif decoded.Command == ICCOMM_CMD_SENT_DATA then
		self:OnReceivedData(decoded)

	elseif decoded.Command == ICCOMM_CMD_SENT_CHUNK then
		self:OnReceivedChunk(decoded)

	elseif decoded.Command == ICCOMM_CMD_HALT_SENDING then
		self:OnReceivedHaltSending(decoded)

	elseif decoded.Command == ICCOMM_CMD_SEE_OTHER then
		self:OnReceivedSeeOther(decoded)

	elseif decoded.Command == ICCOMM_CMD_FORWARD_REQUEST then
		self:OnReceivedForwardRequest(decoded)
	end
end

--

function Node:KeepAlive() 
--/- Advertise player presence on global channel
--/- Occurs every so often and self regulate its delay to avoid congestions 

	if not Jita.CoreSettings.IIComm_KeepAlive then
		return
	end

	-- Only one keep alive per queue.
	-- Shouldn't happen often, still good to check.
	self.Buffer.Out = Utils:RemoveIf(
		self.Buffer.Out, 
		function(_) return _.Command == ICCOMM_CMD_KEEP_ALIVE end
	)

	local profile = Jita.Player.Profile

	local data = {}

	-- addon version and faction are required

	table.insert(data, profile.Faction or 0)
	table.insert(data, Jita:GetAddonVersion() * 10)

	-- extra info are sent on low rate (based on random chances for now)

	local rand = Utils:Random(1, 2)

	if rand == ICCOMM_KEEP_ALIVE_TYPE_SUMMARY
	and Jita.UserSettings.IIComm_ShareInfo
	then
		local extra = {}

		table.insert(extra, profile.Level  or 0)
		table.insert(extra, profile.Race   or 0)
		table.insert(extra, profile.Gender or 0)
		table.insert(extra, profile.Class  or 0)
		table.insert(extra, profile.Path   or 0)

		if profile.Bio then
			table.insert(extra, profile.Bio:len())
		else
			table.insert(extra, 0)
		end

		if Jita.UserSettings.IIComm_ShareInterests
		and profile.Interests 
		and profile.Interests > 0 
		then
			table.insert(extra, profile.Interests)
		end

		table.insert(data, ICCOMM_KEEP_ALIVE_TYPE_SUMMARY)
		table.insert(data, extra)
	else
		rand = Utils:Random(1, 4)

		if rand == ICCOMM_KEEP_ALIVE_TYPE_CHANNELS
		and Jita.UserSettings.IIComm_SharePlayersChannels
		then
			local extra = {}

			local cp = 1
			for _, channel in ipairs(ChatSystemLib.GetChannels()) do
				if channel:GetType() == ChatSystemLib.ChatChannel_Custom
				and cp < 6
				then
					local info = {}

					table.insert(info, channel:GetName())
					table.insert(info, Utils:Count(channel:GetMembers()))
					table.insert(extra, info)

					cp = cp + 1
				end
			end

			table.insert(data, ICCOMM_KEEP_ALIVE_TYPE_CHANNELS)
			table.insert(data, extra)
		end
	end

	self:Enqueue(ICCOMM_CMD_KEEP_ALIVE, data)
end

function Node:RequestPlayerData(recipient)
	if not self.Channel.Refrence
	or not self.Channel.Ready
	then
		return
	end

	local dataTypes = { 
		ICCOMM_DATA_TYPE_INFO,
		ICCOMM_DATA_TYPE_MODEL,
		ICCOMM_DATA_TYPE_BIO
	}

	self:RequestData(recipient, dataTypes)
end

function Node:RequestData(recipient, dataTypes, metadata)
	self:Enqueue(ICCOMM_CMD_REQUEST_DATA, dataTypes, recipient)
end

--

function Node:OnReceivedKeepAlive(decoded)
	if self.KeepAliveLastSender and self.KeepAliveLastSender ~= decoded.Sender then
		self.Channel.KeepAliveLeap = self.Channel.KeepAliveLeap + 1
	end

	self.KeepAliveLastSender = decoded.Sender

	--

	local profile = Jita.Client:GetPlayerProfile(decoded.Sender)

	if not profile then
		profile = Jita.Client:AddPlayerProfile(decoded.Sender)
	end

	if profile then
		profile.JitaUser = true
	end

	--

	if not decoded.Data or type(decoded.Data) ~= "table" then
		return
	end

	local faction = tonumber(decoded.Data[1])
	local version = tonumber(decoded.Data[2])

	if profile and (faction == 166 or faction == 167) then
		profile.Faction = faction
	else
		return -- ain't trusting that shit
	end

	if Jita:GetAddonVersion()
	and version > Jita:GetAddonVersion() * 10
	and version < 99
	then
		Jita.NewAddonVersionDetected = version
	end
end

function Node:OnReceivedRequestData(decoded) 
	local dataTypes = decoded.Data

	if type(dataTypes) ~= "table" then 
		return
	end

	if not decoded.Sender then 
		return
	end

	local profile = Jita.Player.Profile

	if not profile then 
		return
	end

	-- Will only reply to one query at time per sender
	self.Buffer.Out = Utils:RemoveIf(
		self.Buffer.Out, 
		function(_) return _.Recipient == decoded.Sender end
	)

	self:Enqueue(ICCOMM_CMD_SEE_OTHER, {
		Jita.LibCRC32.Hash(decoded.Sender)
	})

	for _, dataType in pairs(dataTypes) do
		local data = {}

		if dataType == ICCOMM_DATA_TYPE_INFO
		or dataType == ICCOMM_DATA_TYPE_MODEL
		or dataType == ICCOMM_DATA_TYPE_BIO
		or dataType == ICCOMM_DATA_TYPE_INTERESTS
		then
			table.insert(data, tonumber(dataType))
		end

		--

		if dataType == ICCOMM_DATA_TYPE_INFO
		and Jita.UserSettings.IIComm_ShareInfo
		then
			table.insert(data, profile.Level   or 0)
			table.insert(data, profile.Faction or 0)
			table.insert(data, profile.Race    or 0)
			table.insert(data, profile.Gender  or 0)
			table.insert(data, profile.Class   or 0)
			table.insert(data, profile.Path    or 0)

			if Jita.UserSettings.IIComm_ShareLocation
			and profile.Location
			then
				table.insert(data, profile.Location or '')
			end
		end

		if dataType == ICCOMM_DATA_TYPE_MODEL
		and Jita.UserSettings.IIComm_ShareModel
		then
			if dataType == ICCOMM_DATA_TYPE_MODEL then
				table.insert(data, profile.Faction or 0)
				table.insert(data, profile.Race    or 0)
				table.insert(data, profile.Gender  or 0)
			end

			table.insert(data, profile.Looks   or {})
			table.insert(data, profile.Bones   or {})
			table.insert(data, profile.Costume or {})
		end

		if dataType == ICCOMM_DATA_TYPE_BIO
		and Jita.UserSettings.IIComm_ShareBio
		then
			table.insert(data, profile.Bio or '')
		end

		if dataType == ICCOMM_DATA_TYPE_INTERESTS
		and Jita.UserSettings.IIComm_ShareInterests
		then
			table.insert(data, profile.Interests or {})
		end

		--

		self:Enqueue(ICCOMM_CMD_SENT_DATA, data, decoded.Sender,
			dataType == ICCOMM_DATA_TYPE_BIO 
			or
			dataType == ICCOMM_DATA_TYPE_MODEL
		)
	end
end

function Node:OnReceivedData(decoded)
	local profile = Jita.Client:GetPlayerProfile(decoded.Sender)

	if not profile then
		return
	end

	local dataType = tonumber(decoded.Data[1])

	if dataType == ICCOMM_DATA_TYPE_INFO then
		local info = {
			Level   = tonumber(decoded.Data[2]),
			Faction = tonumber(decoded.Data[3]),
			Race    = tonumber(decoded.Data[4]),
			Gender  = tonumber(decoded.Data[5]),
			Class   = tonumber(decoded.Data[6]),
			Path    = tonumber(decoded.Data[7]),
		}

		local location = tostring(decoded.Data[8])

		if location and location ~= 'nil' and location:len() > 0 then
			if location and location ~= 'nil' and location:len() > 0 then
				info.Location = location
			end
		end

		profile:Update("Info", info)
	end

	if dataType == ICCOMM_DATA_TYPE_MODEL then
		local model = {}

		if dataType == ICCOMM_DATA_TYPE_MODEL then
			model.Faction = tonumber(decoded.Data[2])
			model.Race    = tonumber(decoded.Data[3])
			model.Gender  = tonumber(decoded.Data[4])
		end

		-- For Looks, Bones and Costume, we only do a minimum data validation
		-- Feeding players portraits random data seemed to be gracefully
		-- handled on game client side, so we won't bother much.

		model.Looks   = {}
		model.Bones   = {}
		model.Costume = {}

		local index = 5

		if decoded.Data[index] 
		and type(decoded.Data[index]) == "table"
		then
			for _, __ in ipairs(decoded.Data[index]) do
				if type(__) == "table" then
					local k = tonumber(__[1]) or 0
					local v = tonumber(__[2]) or 0

					if (k > 0 and k < 100) 
					and (v > 0 and v < 100) 
					then
						table.insert(model.Looks, { k, v })
					end
				end
			end
		end

		index = index + 1
		if decoded.Data[index] 
		and type(decoded.Data[index]) == "table" 
		then
			for _, __ in ipairs(decoded.Data[index]) do
				if type(__) == "table" then
					local k = tonumber(__[1]) or 0
					local v = tonumber(__[2]) or 0

					if (k > 0 and k < 100) 
					and (v > -11 and v < 11) 
					then
						table.insert(model.Bones, { k, v })
					end
				end
			end
		end

		index = index + 1
		if decoded.Data[index]
		and type(decoded.Data[index]) == "table"
		then
			for _, __ in ipairs(decoded.Data[index]) do
				if type(__) == "table" then
					local k = tonumber(__[1]) or 0
					local v = tonumber(__[2]) or 0

					if (k > 0 and k < 10) 
					and (v > 0 and v < 100000) 
					then
						table.insert(model.Costume, { k, v })
					end
				end
			end
		end

		profile:Update("Model", model)
	end

	if dataType == ICCOMM_DATA_TYPE_BIO then
		local bio = decoded.Data[2]

		profile:Update("Bio", bio)
	end

	if dataType == ICCOMM_DATA_TYPE_INTERESTS then
		local interests = tonumber(decoded.Data[2])

		profile:Update("Interests", interests)
	end

	Event_FireGenericEvent(
		"Jita_ICComm_ReceivedPlayerData",
		decoded.Sender,
		dataType
	)

	-- Keepme:
	if profile.InfoUpdated   == true 
	and profile.ModelUpdated == true
	and profile.BioUpdated   == true 
	then
		self:Enqueue(ICCOMM_CMD_FORWARD_REQUEST, {
			Jita.LibCRC32.Hash(decoded.Sender)
		})
	end
end

function Node:OnReceivedChunk(decoded)
	local order = tonumber(decoded.Data[1])
	local total = tonumber(decoded.Data[2])

	-- invalid
	if order == nil or total == nil or order > total then
		self.Buffer.In[decoded.Sender] = nil

		return

	-- last
	elseif order == total then
		if not self.Buffer.In[decoded.Sender] then
			return
		end

		local unchunked = ""

		for i = 1, #self.Buffer.In[decoded.Sender] do
			unchunked = unchunked .. self.Buffer.In[decoded.Sender][i]
		end

		unchunked = unchunked .. tostring(decoded.Data[3])

		self.Buffer.In[decoded.Sender] = nil

		--

		local orginal = self:DecodeMessage(unchunked, decoded.Sender)

		if type(orginal) == "table" and orginal.Command ~= nil then
			self:OnCommand(orginal)
		end

	-- next
	else
		self.Buffer.In[decoded.Sender] = self.Buffer.In[decoded.Sender] or {}

		-- will give room for 16 chunks per user
		if #self.Buffer.In[decoded.Sender] < 16 then
			table.insert(self.Buffer.In[decoded.Sender], 
				tostring(decoded.Data[3])
			)
		else
			self.Buffer.In[decoded.Sender] = nil
		end
	end

	Event_FireGenericEvent(
		"Jita_ICComm_StreamingChunkedData", 
		decoded.Sender, 
		total, 
		order
	)
end

function Node:OnReceivedHaltSending(decoded)
--/- unimplemented

end

function Node:OnReceivedSeeOther(decoded) 
--/- unimplemented

end

function Node:OnReceivedForwardRequest(decoded)
--/- unimplemented

end

--

function Node:EncodeMessage(command, data) 
	local payload = { command }

	if data ~= nil then
		table.insert(payload, data)
	end

	data = Jita.LibJSON.encode(payload)

	return data
end

function Node:DecodeMessage(message, sender)
	if not message then
		return
	end

	local status, json = pcall(Jita.LibJSON.decode, message)

	if not status or type(json) ~= "table" then
		return
	end

	local decoded = {
		Sender  = sender,
		Message = message,
		Command = tonumber(json[1]),
		Data    = json[2],
	}

	return decoded
end
