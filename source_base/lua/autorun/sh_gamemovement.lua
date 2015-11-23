local _R = debug.getregistry()

function _R.Player:SolidMask( brushOnly )
	return ( brushOnly ) and MASK_PLAYERSOLID_BRUSHONLY or MASK_PLAYERSOLID
end

function _R.Player:GetMins()
	if ( self:IsObserver() ) then
		return VEC_OBS_HULL_MIN
	end
	
	return self:Crouching() and VEC_DUCK_HULL_MIN or VEC_HULL_MIN
end

function _R.Player:GetMaxs()
	if ( self:IsObserver() ) then
		return VEC_OBS_HULL_MAX
	end
	
	return self:Crouching() and VEC_DUCK_HULL_MAX or VEC_HULL_MAX
end

function _R.Player:GetViewOffset()
	return self:Crouching() and VEC_DUCK_VIEW or VEC_VIEW
end

function _R.Player:TraceBBox( vecStart, vecEnd, fMask, collisionGroup, pm )
	-- Fix; need trace ray
end

function _R.Player:TestPosition( pos, collisionGroup, pm )
	-- Fix; trace ray
end

