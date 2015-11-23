--[[function util.ImpactTrace( pTrace, iDamageType, pCustomImpactName )
	local pEntity = pTrace.Entity

	// Is the entity valid, is the surface sky?
	if ( not IsValid( pEntity ) or pTrace.HitSky or pTrace.Fraction == 1.0 ) then
		return
	end
	
	pCustomImpactName = pCustomImpactName or "Generic Impact"
	
	pEntity:ImpactTrace( pTrace, iDamageType, pCustomImpactName )
end]]