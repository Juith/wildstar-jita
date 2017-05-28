local Jita = Apollo.GetAddon("Jita")
local Client = Jita:Extend("Client")

--

function Client:InitGreetings()
	self:PushBetaGreetings() 

	if Jita.SaveData
	and Jita.SaveData.Realm
	and Jita.SaveData.Realm.NewAddonVersionDetected
	and Jita.SaveData.Realm.NewAddonVersionDetected > Jita:GetAddonVersion() * 10
	then
		self:PushNewVersionGreetings()
	end
end

function Client:PushBetaGreetings()
	local stream = self:GetStream(Jita.UserSettings.DefaultStream)

	if not stream then
		return
	end

	stream:AddMessage({
		Type    = "aml",
		Content =  {
		"<T Font=\"CRB_Header10_O\">Jita <T TextColor=\"FF8EFF68\">0." .. math.floor(Jita:GetAddonVersion()) .. "</T> &lt; Beta</T>",
		"Type <T TextColor=\"ChatSupport\">!help</T> to display help window, <T TextColor=\"ChatSupport\">!commands</T> to list available Jita commands and <T TextColor=\"ChatSupport\">!macros</T> for a detailed list of macros.",
	}})
end

function Client:PushNewVersionGreetings()
	local stream = self:GetStream(Jita.UserSettings.DefaultStream)

	if not stream then
		return
	end

	stream:AddMessage({
		Type    = "aml",
		Content =  {
		"<T TextColor=\"UI_TextHoloTitle\" Font=\"CRB_Header10_O\">Notice: </T>",
		"A newer version has been reported as available for download at Curse Network.",
	}})
end

function Client:PushFirstRunGreetings()
--/- this was used to display a first run greetings before it was moved to help window.

	local stream = self:GetStream(Jita.UserSettings.DefaultStream)

	if not stream then
		return
	end

	stream:AddMessage({
		Type    = "aml",
		Content =  {
		"<T TextColor=\"UI_TextHoloTitle\" Font=\"CRB_Header11_O\">Greetings, </T>",
		
	"<P><T TextColor=\"0\">.</T></P>",
	
		"This is a first run (and a beta stage) message to help you through the user interface.",

	"<P><T TextColor=\"0\">.</T></P>",

		"<T TextColor=\"UI_TextHoloTitle\" Font=\"CRB_Header10_O\">Chat tabs:</T>",

	"<P Font=\"CRB_Header10_O\"><T TextColor=\"0\">.</T></P>",

		"<T TextColor=\"ChatSupport\">Jita Chat Client</T> moves away from confined in-game chat logs toward a more traditional approach where, except for a few, channels and instant messages are segregated into their own tabs. By default, five main tabs are open:",

	-- redacted
	}})
end
