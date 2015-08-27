ENT.Type = "point"

ENT.m_bDisabled = false -- Fix; how to handle map side

function ENT:IsDisabled()
	return self.m_bDisabled
end

function ENT:InputEnable()
	self.m_bDisabled = false
end

function ENT:InputDisable()
	self.m_bDisabled = true
end