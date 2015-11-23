local _R = debug.getregistry()

function _R.Player:SetDormant( bDormant )
	self:SetNoDraw( bDormant ) -- updates the dormant state serverside and stops networking
end

function _R.ConVar:SetValue( arg ) -- Fix; does this metatable exist?
	RunConsoleCommand( self:GetName(), arg )
end

function swap( arg1, arg2 )
	return arg2, arg1
end

function _R.Player:IsJumping() -- Fix; hook this into usercmds instead
	return ( not self:IsOnGround() )
end

function _R.Player:SetNextAttack()
	-- Placeholder to stop errors
end

function _R.Player:TakeDamage()
	return DAMAGE_YES
end

ITEM_FLAG_SELECTONEMPTY	= bit.lshift( 1, 0 )
ITEM_FLAG_NOAUTORELOAD		= bit.lshift( 1, 1 )
ITEM_FLAG_NOAUTOSWITCHEMPTY	= bit.lshift( 1, 2 )
ITEM_FLAG_LIMITINWORLD		= bit.lshift( 1, 3 )
ITEM_FLAG_EXHAUSTIBLE		= bit.lshift( 1, 4 )	// A player can totally exhaust their ammo supply and lose this weapon
ITEM_FLAG_DOHITLOCATIONDMG	= bit.lshift( 1, 5 )	// This weapon take hit location into account when applying damage
ITEM_FLAG_NOAMMOPICKUPS		= bit.lshift( 1, 6 )	// Don't draw ammo pickup sprites/sounds when ammo is received
ITEM_FLAG_NOITEMPICKUP		= bit.lshift( 1, 7 )	// Don't draw weapon pickup when this weapon is picked up by the player
// NOTE: KEEP g_ItemFlags IN WEAPON_PARSE.CPP UPDATED WITH THESE

function CalculateMeleeDamageForce( info, vecDir, vecForceOrigin, flScale ) -- Fix; convert to user data
	info:SetDamagePosition( vecForceOrigin )

	local flClampForce = ImpulseScale( 75, 400 )

	// Calculate an impulse large enough to push a 75kg man 4 in/sec per point of damage
	local flForceScale = info:GetBaseDamage() * ImpulseScale( 75, 4 )

	if( flForceScale > flClampForce ) then
		flForceScale = flClampForce
	end

	// Fudge blast forces a little bit, so that each
	// victim gets a slightly different trajectory. 
	// This simulates features that usually vary from
	// person-to-person variables such as bodyweight,
	// which are all indentical for characters using the same model.
	flForceScale = flForceScale * random.RandomFloat( 0.85, 1.15 )

	// Calculate the vector and stuff it into the takedamageinfo
	local vecForce = vecDir
	vecForce:Normalize()
	vecForce = vecForce * flForceScale;
	vecForce = vecForce * GetConVar( "phys_pushscale" ):GetFloat()
	vecForce = vecForce * flScale
	info:SetDamageForce( vecForce )
	
	return info
end

function ImpulseScale( flTargetMass, flDesiredSpeed )
	return (flTargetMass * flDesiredSpeed)
end