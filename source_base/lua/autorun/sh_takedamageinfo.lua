local _R = debug.getregistry()

function _R.CTakeDamageInfo:CalculateBulletDamageForce( sBulletType, vecBulletDir, vecForceOrigin, flScale )
	sBulletType = isstring( sBulletType ) and sBulletType or game.GetAmmoName( sBulletType )
	flScale = flScale or 1.0
	
	self:SetDamagePosition( vecForceOrigin )
	vecBulletDir:Normalize()
	vecBulletDir = vecBulletDir * 1000
	vecBulletDir = vecBulletDir * GetConVar( "phys_pushscale" ):GetFloat()
	vecBulletDir = vecBulletDir * flScale
	self:SetDamageForce( vecBulletDir )
end