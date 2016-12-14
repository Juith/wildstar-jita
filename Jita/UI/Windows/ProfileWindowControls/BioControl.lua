local Jita = Apollo.GetAddon("Jita")
local ProfileWindow = Jita:Extend("ProfileWindow")

local Utils = Jita.Utils
local Consts = Jita.Consts

--

function ProfileWindow:GenerateBio(profile)
	local nLeft, nTop, nRight, nBottom = self.MainForm:FindChild("BioPane"):GetAnchorOffsets()
	local initialHeight = nBottom - nTop

	local bio = profile.Bio or ""
	bio = Utils:Trim(bio)

	if profile.Name == Jita.Player.Name then
		self.MainForm:FindChild("EditBioButton"):Show(true)
	end

	if bio == "" then
		self.MainForm:FindChild("HasNoBio"):Show(true)

		return
	end

	bio = "<P TextColor=\"UI_WindowTextDefault\" Font=\"CRB_Interface11\">" .. Utils:EscapeHTML(bio) .. "</P>"

	self.MainForm:FindChild("BioPane"):SetAML(bio)
	self.MainForm:FindChild("BioPane"):SetHeightToContentHeight()

	nLeft, nTop, nRight, nBottom = self.MainForm:FindChild("BioPane"):GetAnchorOffsets()
	local stretchedHeight = nBottom - nTop

	local deltaHeight = stretchedHeight - initialHeight

	if deltaHeight > 0 then
		nLeft, nTop, nRight, nBottom  = self.MainForm:FindChild("BodyContainer"):GetAnchorOffsets()
		nBottom = nBottom + deltaHeight

		if nBottom > 507 then
			nBottom = 507
		end

		self.MainForm:FindChild("BodyContainer"):SetAnchorOffsets(nLeft, nTop, nRight, nBottom)

		self.MainForm:FindChild("BioPane"):SetAnchorPoints(0, 0, 1, 1)

		nLeft, nTop, nRight, nBottom = self.MainForm:FindChild("BioPane"):GetAnchorOffsets()
		self.MainForm:FindChild("BioPane"):SetAnchorOffsets(nLeft, nTop, -6,  -6)
		self.MainForm:FindChild("BioPane"):SetVScrollPos(0)
	else
		deltaHeight = 0
	end

	local location = self.MainForm:GetLocation():ToTable()
	location.nOffsets[4] = location.nOffsets[4] + deltaHeight
	self.MainForm:MoveToLocation(WindowLocation.new(location))
end

function ProfileWindow:OnEditBioButtonClick()
	Jita.WindowManager:LoadWindow("ConfigWindow", { LoadForms = true})
end
