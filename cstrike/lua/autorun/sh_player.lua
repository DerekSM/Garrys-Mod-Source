CS_MASK_SHOOT = bit.bor( MASK_SOLID, CONTENTS_DEBRIS )

local BulletTypeParameters = 
{
	[ "ammo_50ae" ] =
	{
		Power = 30,
		Distance = 1000,
	},
	[ "ammo_762mm" ] = 
	{
		Power = 39,
		Distance = 5000,
	},
	[ "ammo_556mm" ] = 
	{
		Power = 35,
		Distance = 4000,
	},
	[ "ammo_556mm_box" ] = 
	{
		Power = 35,
		Distance = 4000,
	},
	[ "ammo_338mag" ] = 
	{
		Power = 45,
		Distance = 8000,
	},
	[ "ammo_9mm" ] = 
	{
		Power = 21,
		Distance = 800,
	},
	[ "ammo_buckshot" ] = 
	{
		Power = 0,
		Distance = 0,
	},
	[ "ammo_45acp" ] = 
	{
		Power = 15,
		Distance = 500,
	},
	[ "ammo_357sig" ] = 
	{
		Power = 25,
		Distance = 800,
	},
	[ "ammo_57mm" ] = 
	{
		Power = 30,
		Distance = 2000,
	}
}

local MaterialParameters = 
{
	[ MAT_METAL ] = 
	{
		Penetration = 0.5,
		Damage = 0.3,
	},
	[ MAT_DIRT ] = 
	{
		Penetration = 0.5,
		Damage = 0.3,
	},
	[ MAT_CONCRETE ] = 
	{
		Penetration = 0.4,
		Damage = 0.25,
	},
	[ MAT_GRATE ] = 
	{
		Penetration = 1.0,
		Damage = 0.99,
	},
	[ MAT_VENT ] = 
	{
		Penetration = 0.5,
		Damage = 0.45,
	},
	[ MAT_TILE ] = 
	{
		Penetration = 0.65,
		Damage = 0.3,
	},
	[ MAT_COMPUTER ] = 
	{
		Penetration = 0.4,
		Damage = 0.45,
	},
	[ MAT_WOOD ] = 
	{
		Penetration = 1.0,
		Damage = 0.6,
	}
}

local function TraceToExit( vecStart, vecDir, flStepSize, flMaxDistance )
	local flDistance = 0
	local vecEnd
	
	while ( flDistance <= flMaxDistance ) do
		flDistance = flDistance + flStepSize
		
		vecEnd = vecStart + flDistance * vecDir
		
		if ( bit.band( util.PointContents( vecEnd ), MASK_SOLID ) == 0 ) then
			// found first free point
			return vecEnd
		end
	end
end

function _R.Player:FireBullet( vecSrc, shootAngles, flSpread, flDistance, iPenetration, sBulletType, iDamage, flRangeModifier, bDoEffects, x, y )
	local vecDirShooting = shootAngles:Forward()
	local vecRight = shootAngles:Right()
	local vecUp = shootAngles:Up()
	
	local fCurrentDamage = iDamage	// damage of the bullet at it's current trajectory
	local flCurrentDistance = 0.0	// distance that the bullet has traveled so far

	local flPenetrationPower, flPenetrationDistance = 
	BulletTypeParameters[ sBulletType ] and BulletTypeParameters[ sBulletType ].Power or 0, BulletTypeParameters[ sBulletType ] and BulletTypeParameters[ sBulletType ].Distance or 0 -- Fix

	// add the spray 
	local vecDir = ( vecDirShooting + x * flSpread * vecRight + y * flSpread * vecUp ):GetNormalized()
	
	local lastPlayerHit = NULL
	
	-- Fix; draw hitboxes
	
	while ( fCurrentDamage > 0 ) do
		local vecEnd = vecSrc + vecDir * flDistance
		
		local mask = bit.bor( CS_MASK_SHOOT, CONTENTS_HITBOX )
		local filter = { self, lastPlayerHit }
		
		local tr = util.TraceLine( {
			start = vecSrc,
			endpos = vecEnd,
			mask = mask,
			filter = filter
		} )
		
		// Check for player hitboxes extending outside their collision bounds
		--tr = util.ClipTraceToPlayers( vecSrc, vecEnd + vecDir * 40.0, mask, filter, tr ) -- Fix

		lastPlayerHit = tr.Entity:IsPlayer() and tr.Entity or NULL

		if ( tr.Fraction == 1.0 ) then
			break // we didn't hit anything, stop tracing shoot
		end
		
		-- Fix; bullet stats

		//
		// Propogate a bullet impact event
		// @todo Add this for shotgun pellets (which dont go thru here)
		//
		hook.Call( "bullet_impact", self, tr.HitPos )

		/************* MATERIAL DETECTION *************/
		local iEnterMaterial = tr.MatType
	
		local flPenetrationModifier, flDamageModifier = 
		MaterialParameters[ iEnterMaterial ] and MaterialParameters[ iEnterMaterial ].Penetration or 0, MaterialParameters[ iEnterMaterial ] and MaterialParameters[ iEnterMaterial ].Damage or 0 -- FIX
		
		local hitGrate = bit.band( util.PointContents( tr.HitPos ), CONTENTS_GRATE ) ~= 0

		// since some railings in de_inferno are CONTENTS_GRATE but CHAR_TEX_CONCRETE, we'll trust the
		// CONTENTS_GRATE and use a high damage modifier.
		if ( hitGrate ) then
			// If we're a concrete grate (TOOLS/TOOLSINVISIBLE texture) allow more penetrating power.
			flPenetrationModifier = 1.0
			flDamageModifier = 0.99
		end
		
		// calculate the damage based on the distance the bullet travelled.
		flCurrentDistance = flCurrentDistance + tr.Fraction * flDistance
		fCurrentDamage = fCurrentDamage * math.pow( flRangeModifier, ( flCurrentDistance / 500 ) )

		// check if we reach penetration distance, no more penetrations after that
		if (flCurrentDistance > flPenetrationDistance and iPenetration > 0) then
			iPenetration = 0
		end

		local iDamageType = bit.bor( DMG_BULLET, DMG_NEVERGIB )
		-- Fix; underwater decals
		--if ( bDoEffects ) then
			// See if the bullet ended up underwater + started out of the water
			if ( bit.band( util.PointContents( tr.HitPos ), bit.bor( CONTENTS_WATER, CONTENTS_SLIME ) ) > 0 ) then
				local waterTrace = util.TraceLine( 
				{
					start = vecSrc,
					endpos = tr.HitPos,
					filter = self,
					mask = bit.bor( MASK_SHOT, CONTENTS_WATER, CONTENTS_SLIME )
				})
				
				if ( not waterTrace.StartSolid ) then
					
					local data = EffectData()
					data:SetOrigin( waterTrace.HitPos )
					data:SetNormal( waterTrace.HitNormal )
					data:SetScale( random.RandomFloat( 8, 12 ) )
					if ( bit.band( util.PointContents( waterTrace.HitPos ), CONTENTS_SLIME ) > 0 ) then
						data:SetFlags( bit.bor( data:GetFlags(), FX_WATER_IN_SLIME ) ) -- FIX
					end
					util.Effect( "gunshotsplash", data )
				end
			else
				// Do Regular hit effects

				// Don't decal nodraw surfaces
				local pEntity = tr.Entity
					--if ( not ( not GetConVar( "friendlyfire" ):GetBool() and IsValid( pEntity ) and pEntity:Team() == self:Team() ) ) then
						--util.DoImpactEffects( tr, iDamageType ) -- FIX
				util.ImpactTrace( tr, iDamageType )
			end
		--end // bDoEffects

		// add damage to entity that we hit
		local info = DamageInfo()
		info:SetAttacker( self )
		local weap = self:GetActiveWeapon()
		if IsValid( weap ) then
			info:SetInflictor( weap )
		end
		info:SetDamage( fCurrentDamage )
		info:SetDamageType( iDamageType )
		info:CalculateBulletDamageForce( sBulletType, vecDir, tr.HitPos )
		--[[
		if tr.Entity:IsPlayer() then
			hook.Run( "ScaleCSSPlayerDamage", tr.Entity, tr.HitGroup, info )
		elseif tr.Entity:IsNPC() then
			hook.Run( "ScaleCSSNPCDamage", tr.Entity, tr.HitGroup, info )
		end]]
			
		if SERVER then
			tr.Entity:DispatchTraceAttack( info, tr )
		end

		// check if bullet can penetrate another entity
		if ( ( iPenetration == 0 and not hitGrate ) or iPenetration < 0 ) then
			break // no, stop
		end
		
		// try to penetrate object, maximum penetration is 128 inch
		local penetrationEnd = TraceToExit( tr.HitPos, vecDir, 24, 128 )
		
		if ( not penetrationEnd ) then
			break
		end
		
		// find exact penetration exit
		local exitTr = util.TraceLine( 
		{
			start = penetrationEnd,
			endpos = tr.HitPos,
			mask = bit.bor( CS_MASK_SHOOT, CONTENTS_HITBOX ),
		})

		if ( exitTr.Entity ~= tr.Entity and IsValid( exitTr.Entity ) ) then
			// something was blocking, trace again
			exitTr = util.TraceLine( 
			{
				start = penetrationEnd,
				endpos = tr.HitPos,
				mask = bit.bor( CS_MASK_SHOOT, CONTENTS_HITBOX ),
				filter = exitTr.Entity,
			})
		end
		
		// get material at exit point
		local iExitMaterial = exitTr.MatType

		hitGrate = hitGrate and bit.band( util.PointContents( tr.HitPos ), CONTENTS_GRATE ) > 0

		// if enter & exit point is wood or metal we assume this is 
		// a hollow crate or barrel and give a penetration bonus
		if ( iEnterMaterial == iExitMaterial ) then
			if ( iExitMaterial == MAT_WOOD or iExitMaterial == MAT_METAL ) then
				flPenetrationModifier = flPenetrationModifier * 2
			end
    	end

		local flTraceDistance = ( exitTr.HitPos - tr.HitPos ):Length()

		// check if bullet has enough power to penetrate this distance for this material
		if ( flTraceDistance > ( flPenetrationPower * flPenetrationModifier ) ) then
			break // bullet hasn't enough power to penetrate this distance
		end

		// penetration was successful

		// bullet did penetrate object, exit Decal
		--if ( bDoEffects ) then
			--util.DoImpactEffects( exitTr, iDamageType ) -- FIX
			util.ImpactTrace( exitTr, iDamageType )
		--end

		// setup new start end parameters for successive trace
		
		flPenetrationPower = flPenetrationPower - flTraceDistance / flPenetrationModifier
		flCurrentDistance = flCurrentDistance + flTraceDistance

		vecSrc = exitTr.HitPos
		flDistance = ( flDistance - flCurrentDistance ) * 0.5

		// reduce damage power each time we hit something other than a grate
		fCurrentDamage = fCurrentDamage * flDamageModifier

		// reduce penetration counter
		iPenetration = iPenetration - 1
	end
end

function _R.Player:HasShield()
	return false
end

function _R.Player:SetShieldDrawnState()
	return false
end

function _R.Player:GetDefaultFOV()
	return 90 -- Fix
end

_R.Player.m_iDirection = false
// GOOSEMAN : Kick the view..
function _R.Player:KickBack( up_base, lateral_base, up_modifier, lateral_modifier, up_max, lateral_max, direction_change )
	if ( not IsFirstTimePredicted() ) then return end
	
	local flKickUp = up_base
	local flKickLateral = lateral_base
	
	if ( self.m_iShotsFired > 1 ) then -- Not the first round fired
		flKickUp = flKickUp + self.m_iShotsFired * up_modifier
		flKickLateral = flKickLateral + self.m_iShotsFired * lateral_modifier
	end
	
	local angle = self:GetPunchAngle()
	
	angle.p = angle.p - flKickUp
	if ( angle.p < -1 * up_max ) then
		angle.p = -1 * up_max
	end
	
	if ( self.m_bDirection ) then
		angle.y = angle.y + flKickLateral
		if ( angle.y > lateral_max ) then
			angle.y = lateral_max
		end
	else
		angle.y = angle.y - flKickLateral
		if ( angle.y < -1 * lateral_max ) then
			angle.y = -1 * lateral_max
		end
	end
	
	if ( self:SharedRandomInt( "KickBack", 0, direction_change ) == 0 ) then
		self.m_bDirection = not self.m_bDirection
	end
	
	self:SetPunchAngle( angle )
end

function _R.Player:ResetMaxSpeed( speed )
end

-- Fix
--[[

FLT_EPSILON = 1E-5

function _R.Player:DecayPunchAngle()
	local vPunchAngle = self:GetPunchAngle()

	local len = math.sqrt( vPunchAngle.p * vPunchAngle.p + vPunchAngle.y * vPunchAngle.y + vPunchAngle.r * vPunchAngle.r )

	local den = 1 / ( len + FLT_EPSILON )
	vPunchAngle.p = vPunchAngle.p * den
	vPunchAngle.y = vPunchAngle.y * den
	vPunchAngle.r = vPunchAngle.r * den

	len = len - ( ( 10 + len * 0.5 ) * FrameTime() )
	len = math.max( len, 0 )

	vPunchAngle = vPunchAngle * len

	self:SetPunchAngle( vPunchAngle )
end

hook.Add( "Move", "PunchAngle", function( ply, mv )

	if ( IsFirstTimePredicted() ) then
		ply:DecayPunchAngle()
	end]]
		
	--[[if ply:Alive() then

		self:ReduceTimers( ply )
		
		local ground = ply:GetGroundEntity()
		
		if ground ~= NULL then
			if ply:GetVelocityModifier() < 1.0 then
				ply:SetVelocityModifier( ply:GetVelocityModifier() + FrameTime() / 3.0 )
			elseif ply:GetVelocityModifier() > 1.0 then
				ply:SetVelocityModifier( 1.0 )
			end

			if ply:GetStamina() > 0 then
				local flRatio = ( STAMINA_MAX - ( ( ply:GetStamina() / 1000.0 ) * STAMINA_RECOVER_RATE ) ) / STAMINA_MAX

				local flReferenceFrametime = 1.0 / 70.0
				local flFrametimeRatio = FrameTime() / flReferenceFrametime

				flRatio = math.pow( flRatio, flFrametimeRatio )

				local vel = mv:GetVelocity()
				vel.x = vel.x * flRatio
				vel.y = vel.y * flRatio
				mv:SetVelocity( vel )
			end
		end
		
		local maxspeed = 250
		
		local weap = ply:GetActiveWeapon()
		if IsValid( weap ) and weap.GetMaxSpeed then
			maxspeed = weap:GetMaxSpeed()
		end
		
		if bit.band( mv:GetButtons(), IN_DUCK ) > 0 then
			maxspeed = maxspeed * ply:GetCrouchedWalkSpeed()
		end
		
		if not ply:CanMove() then
			maxspeed = 0
		end
		
		mv:SetMaxSpeed( maxspeed * ply:GetVelocityModifier() )

	end
end )]]

--[[
if ( SERVER ) then
	hook.Add( "FinishMove", "CStrike - Direction", function( ply, mv ) -- Fix; temp hack
		if ( mv:GetForwardSpeed() > 0 ) then
			ply.m_iDirection = 1
		elseif ( mv:GetForwardSpeed() == 0 ) then
			ply.m_iDirection = 0
		else
			ply.m_iDirection = -1
		end
	end )
end]]
--[[
if ( SERVER ) then
hook.Add( "Think", "Teststs", function()
	local ply = Entity(1):GetPhysicsObject()
	if not IsValid( ply ) then print"lel" return end
	--[[local fwd,vel = ply:GetAngles():Forward(),ply:GetVelocity()
	vel.z = 0
	
	if ( math.acos(fwd:Dot(vel)/(fwd:Length()*vel:Length())) <= ((50*math.pi)/180) ) then
	if ( ply:WorldToLocal( ply:GetVelocity() ) ) then
		Entity(1):ChatPrint( "forward" )
	else
		Entity(1):ChatPrint( "not" )
	end
end )
end]]