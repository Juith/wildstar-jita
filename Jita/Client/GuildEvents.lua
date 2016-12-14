local Jita = Apollo.GetAddon("Jita")
local Client = Jita:Extend("Client")

-- 

function Client:OnGuildRoster(guild, roster) 
	if guild:GetType() == GuildLib.GuildType_Guild then
		local stream = self:GetStream("Default::Guild")

		if roster then
			stream.Members = {}
		end

		for key, member in pairs(roster) do
			if member.fLastOnline == 0 then
				self:AddStreamMember(stream, member.strName)

				self:AddPlayerProfile(member.strName)
			end
		end

		stream.IsRequestingMembersList = false
	end

	if guild:GetType() == GuildLib.GuildType_Circle then
		local stream = self:GetStream("Society::" .. guild:GetName())

		if roster then
			stream.Members = {}
		end

		for key, member in pairs(roster) do
			if member.fLastOnline == 0 then
				self:AddStreamMember(stream, member.strName)

				self:AddPlayerProfile(member.strName)
			end
		end

		stream.IsRequestingMembersList = false
	end

	self:AddCurrentPlayerToStreamsMembers()
end
