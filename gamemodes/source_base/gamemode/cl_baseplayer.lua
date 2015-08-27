local _R = debug.getregistry()

function _R.Player:GetAutoaimVector( flScale )
	local forward = AngleVectors( self:GetAngles() + self:GetPunchAngle() )
	return forward
end