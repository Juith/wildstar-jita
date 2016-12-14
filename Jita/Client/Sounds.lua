local Jita = Apollo.GetAddon("Jita")
local Client = Jita:Extend("Client")

-- 

Client.EnumSounds = {
	Whisper = 1,
	Click   = 2,
}

function Client:PlaySound(sound)
	if sound == self.EnumSounds.Whisper then
		Sound.Play(Sound.PlayUISocialWhisper)
	end

	if sound == self.EnumSounds.Click then
		Sound.Play(Sound.PlayUI07SelectTabPhysical)
	end
end
