local _R = debug.getregistry()
--[[
function _R.Player:GetPunchAngle()
	return self.m_vecPunchAngle
end
]]--
function _R.Player:SetPunchAngle( punchAngle )
	self:SetViewPunchAngles( punchAngle )
end