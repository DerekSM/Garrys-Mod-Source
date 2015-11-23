DEFINE_BASECLASS( "weapon_dodbase" )

SWEP.Base = "weapon_dodbase"

DAMAGE_YES = 1 -- Fix; placeholder
DAMAGE_NO = 0

KNIFE_BODYHIT_VOLUME = 128
KNIFE_WALLHIT_VOLUME = 512

SWEP.Primary =
{ -- fix; adjust these by in-game testing
	Ammo = "none",
	ClipSize = -1, 
	DefaultClip = -1,
	Automatic = true
}

SWEP.Secondary =
{
	Ammo = "none",
	ClipSize = -1,
	DefaultClip = -1,
	Automatic = true
}

function SWEP:PrimaryAttack()
	self:MeleeAttack( 60, MELEE_DMG_EDGE, 0.2, 0.4 )
end

function SWEP:MeleeAttack( iDamageAmount, iDamageType, flDmgDelay, flAttackDelay )
	if ( not self:CanAttack() ) then
		return NULL
	end

	local pPlayer = self.Owner

	if ( SERVER ) then
		// Move other players back to history positions based on local player's lag
		pPlayer:LagCompensation( true )
	end

	local vForward, vRight, vUp = AngleVectors( pPlayer:EyeAngles() )
	local vecSrc = pPlayer:GetShootPos()
	local vecEnd = vecSrc + vForward * 48
	
	-- local filter = filter.Create( pPlayer, COLLISION_GROUP_NONE ) -- The collision group is already NONE by default

	local iTraceMask = bit.bor( MASK_SOLID, CONTENTS_HITBOX, CONTENTS_DEBRIS )

	local tr = util.TraceLine( {
		start = vecSrc,
		endpos = vecEnd,
		mask = iTraceMask
	} )

	local rayExtension = 40.0
	--tr = util.ClipTraceToPlayers( vecSrc, vecEnd + vForward * rayExtension, iTraceMask, filter, tr ) -- Fix

	// If the exact forward trace did not hit, try a larger swept box 
	if ( tr.Fraction >= 1.0 ) then
		local head_hull_mins = Vector( -16, -16, -18 )
		local head_hull_maxs = Vector( 16, 16, 18 )
		
		util.TraceHull( {
			start = vecSrc,
			endpos = vecEnd,
			maxs = head_hull_maxs,
			mins = head_hull_mins,
			mask = MASK_SOLID,
			output = tr
		} )
		
		if ( tr.Fraction < 1.0 ) then
			// Calculate the point of intersection of the line (or hull) and the object we hit
			// This is and approximation of the "best" intersection
			local pHit = tr.Entity
			if ( not IsValid( pHit ) or pHit:IsBSPModel() ) then -- Fix; add pHit:IsBSPModel()? Is that the world? Redundent?
				tr = self:FindHullIntersection( vecSrc, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, pPlayer )
			end
			vecEnd = tr.HitPos	// This is the point on the actual surface (the hull could have hit space)

			// Make sure it is in front of us
			local vecToEnd = vecEnd - vecSrc
			vecToEnd:Normalize()

			// if zero length, always hit
			if ( vecToEnd:Length() > 0 ) then
				local dot = vForward:Dot( vecToEnd )

				// sanity that our hit is within range
				if ( math.abs(dot) < 0.95 ) then
					// fake that we actually missed
					tr.Fraction = 1.0
				end
			end
		end
	end

	local bDidHit = ( tr.Fraction < 1.0 )

	local bDoStrongAttack = false

	if ( bDidHit and tr.Entity:IsPlayer() and tr.Entity:TakeDamage() ~= DAMAGE_YES ) then -- Fix; polymorphic TakeDamage
		bDidHit = false		// still play the animation, we just dont attempt to damage this player
	end

	if ( bDidHit ) then	//if the swing hit
		local pVictim = tr.Entity
		
		// delay the decal a bit
		self.m_trHit = tr

		// Store the ent in an EHANDLE, just in case it goes away by the time we get into our think function.
		self.m_pTraceHitEnt = pVictim

		self.m_iSmackDamage = iDamageAmount
		self.m_iSmackDamageType = iDamageType

		self:SetSmackTime( CurTime() + flDmgDelay )
		
		local iOwnerTeam = pPlayer:Team()
		local iVictimTeam = pVictim:IsPlayer() and pVictim:Team()

		// do the mega attack if its a player, and we would do damage
		if ( pVictim:IsPlayer() and pVictim:TakeDamage() == DAMAGE_YES and ( iVictimTeam ~= iOwnerTeam or ( iVictimTeam == iOwnerTeam and GetConVar( "friendlyfire" ):GetBool() ) ) ) then
			local victimForward = AngleVectors( pVictim:GetAngles() )

			if ( victimForward:Dot( vForward ) > 0.3 ) then
				bDoStrongAttack = true
			end
		end
	end

	if ( bDoStrongAttack ) then
		self.m_iSmackDamage = 300
		flAttackDelay = 0.9
		self:SetSmackTime( CurTime() + 0.4 )

		self.m_iSmackDamageType = bit.bor( MELEE_DMG_EDGE, MELEE_DMG_STRONGATTACK )

		// play a "Strong" attack
		self:SendWeaponAnim( self:GetStrongMeleeActivity() )
	else
		self:WeaponSound( MELEE_MISS )
		self:SendWeaponAnim( self:GetMeleeActivity() )
	end

	// player animation
	pPlayer:DoAnimationEvent( PLAYERANIMEVENT_ATTACK_SECONDARY ) -- Fix; originally PLAYERANIMEVENT_SECONDARY_ATTACK, but the enum isn't derived from HL2:DM

	self:SetNextPrimaryFire( CurTime() + flAttackDelay )
	self:SetNextSecondaryFire( CurTime() + flAttackDelay )
	self:SetWeaponIdleTime( CurTime() + self:SequenceDuration() )
	
	if ( not CLIENT ) then
	--[[
	IGameEvent * event = gameeventmanager->CreateEvent( "dod_stats_weapon_attack" );
	if ( event ) then
		event->SetInt( "attacker", pPlayer->GetUserID() );
		event->SetInt( "weapon", GetAltWeaponID() );

		gameeventmanager->FireEvent( event );
	end
	]]
		pPlayer:LagCompensation( false )
	end

	return tr.Entity
end

function SWEP:GetMeleeActivity()
	return ACT_VM_PRIMARYATTACK
end

function SWEP:GetStrongMeleeActivity()
	return ACT_VM_SECONDARYATTACK -- Fix; should we declare in DODBase like done in the cpp to support melee outside of the melee base? This function was never used in the codebase
end