local _R = debug.getregistry()

function _R.Player:GetAutoaimVector( flScale )
	local forward = AngleVectors( self:GetAngles() + self:GetPunchAngle() )
	return forward
end
--[[
function _R.Player:SetPunchAngle( angle )
	self.m_vecPunchAngle = angle -- Fix; network this shit
end

function _R.Player:GetPunchAngle()
	return self.m_vecPunchAngle
end

hook.Add( "EntityTakeDamage", "Source Base - Damage Punch", function( ent )
	if ( ent:IsPlayer() ) then
		ent.m_vecPunchAngle.p = -2
	end
end )]]