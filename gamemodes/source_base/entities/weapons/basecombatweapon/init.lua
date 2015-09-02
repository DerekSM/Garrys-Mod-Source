AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

function SWEP:WeaponRangeAttack1Condition( flDot, flDist )
	if ( self:UsesPrimaryAmmo() and not self:HasPrimaryAmmo() ) then
		return COND_NO_PRIMARY_AMMO
	elseif ( flDist < self.m_fMinRange1 ) then
		return COND_TOO_CLOSE_TO_ATTACK
	elseif ( flDist > self.m_fMinRange1 ) then
		return COND_TOO_FAR_TO_ATTACK
	elseif ( flDot < 0.5 ) then // UNDONE: Why check this here? Isn't the AI checking this already?
		return COND_NOT_FACING_ATTACK
	end
	
	return COND_CAN_RANGE_ATTACK1
end

function SWEP:WeaponRangeAttack2Condition( flDot, flDist )
	return COND_NONE
end

function SWEP:WeaponMeleeAttack1Condition( flDot, flDist )
	return COND_NONE
end

function SWEP:WeaponMeleeAttack2Condition( flDot, flDist )
	return COND_NONE
end

function SWEP:ObjectCaps()
	local caps = self.BaseClass:ObjectCaps()
	if ( not self:IsFollowingEntity() and not self:HasSpawnFlags( SF_WEAPON_NO_PLAYER_PICKUP ) ) then -- Fix
		caps = bit.bor( caps, FCAP_IMPULSE_USE )
	end
	
	return caps
end
