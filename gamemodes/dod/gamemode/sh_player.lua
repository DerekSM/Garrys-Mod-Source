local dod_bonusround = CreateConVar( "dod_bonusround", "1", FCVAR_REPLICATED, "If true, the winners of the round can attack in the intermission." )
-- CreateConVar( "sv_showimpacts", "0", { FCVAR_REPLICATED, FCVAR_CHEAT }, "Shows client (red) and server (blue) bullet impact point" )

TEAM_AXIS = 1 -- Placeholders; fix
TEAM_ALLIES = 2

local _R = debug.getregistry()

_R.Player.m_bProne = false
_R.Player.m_bForceProneChange = false
_R.Player.m_flNextProneCheck = 0

_R.Player.m_flSlowedUntilTime = 0

_R.Player.m_flUnProneTime = 0
_R.Player.m_flGoProneTime = 0

_R.Player.m_flDeployedHeight = STANDING_DEPLOY_HEIGHT
_R.Player.m_flDeployChangeTime = CurTime()

--_R.Player:SetDesiredPlayerClass( PLAYERCLASS_UNDEFINED ) -- Fix

_R.Player.m_flLastViewAnimationTime = CurTime()

-- _R.Player.m_pViewOffsetAnim

function _R.Player:IsInMGDeploy()
	local pWeapon = self:GetActiveWeapon()
	if ( IsValid( pWeapon ) and pWeapon.WeaponType == WPN_TYPE_MG ) then
		return pWeapon:IsDeployed()
	end
	
	return false
end

function _R.Player:NoteWeaponFired()
	local pCurrentCommand = self:GetCurrentCommand()
	if ( IsValid( pCurrentCommand ) ) then -- Fix; make sure this passes
		self.m_iLastWeaponFireUsercmd = pCurrentCommand:CommandNumber() -- Fix
	end
end

hook.Add( "InitPostEntity", "test", function()
	function GAMEMODE:State_Get()
		return STATE_RND_RUNNING
	end
end )

hook.Add( "PlayerSpawn", "DODShit", function( ply )
	ply:SetTeam( TEAM_ALLIES )
end )

function _R.Player:IsProne()
	return false
end

function _R.Player:IsGoingProne()
	return false
end

function _R.Player:IsGettingUpFromProne()
	return false
end

function _R.Player:IsDefusing()
	return false
end

function _R.Player:IsSprinting()
	return false
end

function _R.Player:SetupDataTables()
	self:NetworkVar( "Float", 30, "NextAttack" ) -- Fix
end

function _R.Player:SetNextAttack()
end

function _R.Player:GetNextAttack()
	return 0
end


--------------



local dod_bonusround = CreateConVar( "dod_bonusround", "1", FCVAR_REPLICATED, "If true, the winners of the round can attack in the intermission." )
local sv_showimpacts = CreateConVar( "sv_showimpacts", "0", { FCVAR_REPLICATED, FCVAR_CHEAT }, "Shows client (red) and server (blue) bullet impact point" )

function _R.Player:CanMove()
	local bValidMoveState = ( GAMEMODE:State_Get() == STATE_ACTIVE or GAMEMODE:State_Get() == STATE_OBSERVER_MODE )
	
	if ( not bValidMoveState ) then
		return false
	end
	
	return true
end
--[[ -- Fix
function GetDensityFromMaterial( pSurfaceData )
	float flMaterialMod = 1.0

	if ( not IsValid( pSurfaceData ) ) then return end

	// material mod is how many points of damage it costs to go through
	// 1 unit of the material

	switch( pSurfaceData->game.material )
	{
	//super soft
//	case CHAR_TEX_LEAVES:
//		flMaterialMod = 1.2f;
//		break;

	case CHAR_TEX_FLESH:
		flMaterialMod = 1.35f;
		break;

	//soft
//	case CHAR_TEX_STUCCO:
//	case CHAR_TEX_SNOW:
	case CHAR_TEX_GLASS:
	case CHAR_TEX_WOOD:
	case CHAR_TEX_TILE:
		flMaterialMod = 1.8f;
		break;

	//hard
//	case CHAR_TEX_SKY:
//	case CHAR_TEX_ROCK:
//	case CHAR_TEX_SAND:	
	case CHAR_TEX_CONCRETE:
	case CHAR_TEX_DIRT:		// "sand"
		flMaterialMod = 6.6f;
		break;

	//really hard
//	case CHAR_TEX_HEAVYMETAL:
	case CHAR_TEX_GRATE:
	case CHAR_TEX_METAL:
		flMaterialMod = 13.5f;
		break;

	case 'X':		// invisible collision material
		flMaterialMod = 0.1f;
		break;

	//medium
//	case CHAR_TEX_BRICK:
//	case CHAR_TEX_GRAVEL:
//	case CHAR_TEX_GRASS:
	default:

#ifndef CLIENT_DLL
		AssertMsg( 0, UTIL_VarArgs( "Material has unknown materialmod - '%c' \n", pSurfaceData->game.material ) );
#endif

		flMaterialMod = 5.0f;
		break;
	}

	Assert( flMaterialMod > 0 );

	return flMaterialMod;
}]]

function TraceToExit( start, dir, endpos, flStepSize, flMaxDistance )
	local flDistance = 0
	local last = start

	while ( flDistance < flMaxDistance ) do
		flDistance = flDistance + flStepSize

		// no point in tracing past the max distance.
		// if this check fails, we save ourselves a traceline later
		if ( flDistance > flMaxDistance ) then
			flDistance = flMaxDistance
		end

		endpos = start + flDistance * dir 

		// point contents fails to return proper contents inside a func_detail brush, eg the dod_flash 
		// stairs

		//int contents = UTIL_PointContents( end );

		local tr = util.TraceLine( { 
			start = endpos,
			endpos = endpos,
			mask = bit.bor( MASK_SOLID, CONTENTS_HITBOX )
		} )

		//if ( (UTIL_PointContents ( end ) & MASK_SOLID) == 0 )

		if ( not tr.StartSolid ) then
			// found first free point
			return true
		end
	end

	return false
end

NEW_HITBOX_GROUP_CODE = 1
-- #undef ARM_PENETRATION -- Fix

--[[function _R.Player:FireBullets( const FireBulletsInfo_t &info )
{
	trace_t			tr;								
	trace_t			reverseTr;						//Used to find exit points
	static int		iMaxPenetrations	= 6;
	int				iPenetrations		= 0;
	float			flDamage			= info.m_iDamage;		//Remaining damage in the bullet
	Vector			vecSrc				= info.m_vecSrc;
	Vector			vecEnd				= vecSrc + info.m_vecDirShooting * info.m_flDistance;

	static int		iTraceMask = ( ( MASK_SOLID | CONTENTS_DEBRIS | CONTENTS_HITBOX | CONTENTS_PRONE_HELPER ) & ~CONTENTS_GRATE );
	 
	CBaseEntity		*pLastHitEntity		= this;	// start with us so we don't trace ourselves
		
	int iDamageType = GetAmmoDef()->DamageType( info.m_iAmmoType );
	int iCollisionGroup = COLLISION_GROUP_NONE;

#ifdef GAME_DLL
	bool iNumHeadshots = 0;
#endif

	while ( flDamage > 0 && iPenetrations < iMaxPenetrations )
	{
		//DevMsg( 2, "penetration: %d, starting dmg: %.1f\n", iPenetrations, flDamage );

		CBaseEntity *pPreviousHit = pLastHitEntity;

		// skip the shooter always
		CTraceFilterSkipTwoEntities ignoreShooterAndPrevious( this, pPreviousHit, iCollisionGroup );
		UTIL_TraceLine( vecSrc, vecEnd, iTraceMask, &ignoreShooterAndPrevious, &tr );

		const float rayExtension = 40.0f;
		UTIL_ClipTraceToPlayers( vecSrc, vecEnd + info.m_vecDirShooting * rayExtension, iTraceMask, &ignoreShooterAndPrevious, &tr );

		if ( tr.fraction == 1.0f )
			break; // we didn't hit anything, stop tracing shoot

		// New hitbox code that uses hitbox groups instead of trying to trace
		// through the player
		if ( tr.m_pEnt && tr.m_pEnt->IsPlayer() )
		{
			switch( tr.hitgroup )
			{
#ifdef GAME_DLL
			case HITGROUP_HEAD:
				{
					if ( tr.m_pEnt->GetTeamNumber() != GetTeamNumber() )
					{
						iNumHeadshots++;
					}
				}
				break;
#endif

			case HITGROUP_LEFTARM:
			case HITGROUP_RIGHTARM:
				{
					//DevMsg( 2, "Hit arms, tracing against alt hitboxes.. \n" );

					CDODPlayer *pPlayer = ToDODPlayer( tr.m_pEnt );

					// set hitbox set to "dod_no_arms"
					pPlayer->SetHitboxSet( 1 );

					trace_t newTr;

					// re-fire the trace
					UTIL_TraceLine( vecSrc, vecEnd, iTraceMask, &ignoreShooterAndPrevious, &newTr );

					// if we hit the same player in the chest
					if ( tr.m_pEnt == newTr.m_pEnt )
					{
						//DevMsg( 2, ".. and we hit the chest.\n" );

						Assert( tr.hitgroup != newTr.hitgroup );	// If we hit this, hitbox sets are broken

						// use that damage instead
						tr = newTr;
					}

					// set hitboxes back to "dod"
					pPlayer->SetHitboxSet( 0 );
				}
				break;

			default:
				break;
			}			
		}
			
		pLastHitEntity = tr.m_pEnt;

		if ( sv_showimpacts.GetBool() )
		{
#ifdef CLIENT_DLL
			// draw red client impact markers
			debugoverlay->AddBoxOverlay( tr.endpos, Vector(-1,-1,-1), Vector(1,1,1), QAngle(0,0,0), 255, 0, 0, 127, 4 );

			if ( tr.m_pEnt && tr.m_pEnt->IsPlayer() )
			{
				C_BasePlayer *player = ToBasePlayer( tr.m_pEnt );
				player->DrawClientHitboxes( 4, true );
			}
#else
			// draw blue server impact markers
			NDebugOverlay::Box( tr.endpos, Vector(-1,-1,-1), Vector(1,1,1), 0,0,255,127, 4 );

			if ( tr.m_pEnt && tr.m_pEnt->IsPlayer() )
			{
				CBasePlayer *player = ToBasePlayer( tr.m_pEnt );
				player->DrawServerHitboxes( 4, true );
			}
#endif
		}

#ifdef CLIENT_DLL
		// See if the bullet ended up underwater + started out of the water
		if ( enginetrace->GetPointContents( tr.endpos ) & (CONTENTS_WATER|CONTENTS_SLIME) )
		{	
			trace_t waterTrace;
			UTIL_TraceLine( vecSrc, tr.endpos, (MASK_SHOT|CONTENTS_WATER|CONTENTS_SLIME), this, iCollisionGroup, &waterTrace );
			
			if( waterTrace.allsolid != 1 )
			{
				CEffectData	data;
 				data.m_vOrigin = waterTrace.endpos;
				data.m_vNormal = waterTrace.plane.normal;
				data.m_flScale = random->RandomFloat( 8, 12 );

				if ( waterTrace.contents & CONTENTS_SLIME )
				{
					data.m_fFlags |= FX_WATER_IN_SLIME;
				}

				DispatchEffect( "gunshotsplash", data );
			}
		}
		else
		{
			//Do Regular hit effects

			// Don't decal nodraw surfaces
			if ( !( tr.surface.flags & (SURF_SKY|SURF_NODRAW|SURF_HINT|SURF_SKIP) ) )
			{
				CBaseEntity *pEntity = tr.m_pEnt;
				if ( !( !friendlyfire.GetBool() && pEntity && pEntity->GetTeamNumber() == GetTeamNumber() ) )
				{
					UTIL_ImpactTrace( &tr, iDamageType );
				}
			}
		}
#endif

		// Get surface where the bullet entered ( if it had different surfaces on enter and exit )
		surfacedata_t *pSurfaceData = physprops->GetSurfaceData( tr.surface.surfaceProps );
		Assert( pSurfaceData );
		
		float flMaterialMod = GetDensityFromMaterial(pSurfaceData);

		if ( iDamageType & DMG_MACHINEGUN )
		{
			flMaterialMod *= 0.65;
		}

		// try to penetrate object
		Vector penetrationEnd;
		float flMaxDistance = flDamage / flMaterialMod;

#ifndef CLIENT_DLL
		ClearMultiDamage();

		float flActualDamage = flDamage;

		CTakeDamageInfo dmgInfo( info.m_pAttacker, info.m_pAttacker, flActualDamage, iDamageType );
		CalculateBulletDamageForce( &dmgInfo, info.m_iAmmoType, info.m_vecDirShooting, tr.endpos );
		tr.m_pEnt->DispatchTraceAttack( dmgInfo, info.m_vecDirShooting, &tr );

		DevMsg( 2, "Giving damage ( %.1f ) to entity of type %s\n", flActualDamage, tr.m_pEnt->GetClassname() );

		TraceAttackToTriggers( dmgInfo, tr.startpos, tr.endpos, info.m_vecDirShooting );
#endif

		int stepsize = 16;

		// displacement always stops the bullet
		if ( tr.IsDispSurface() )
		{
			DevMsg( 2, "bullet was stopped by displacement\n" );
			ApplyMultiDamage();
			break;
		}

		// trace through the solid to find the exit point and how much material we went through
		if ( !TraceToExit( tr.endpos, info.m_vecDirShooting, penetrationEnd, stepsize, flMaxDistance ) )
		{
			DevMsg( 2, "bullet was stopped\n" );
			ApplyMultiDamage();
			break;
		}

		// find exact penetration exit
		CTraceFilterSimple ignoreShooter( this, iCollisionGroup );
		UTIL_TraceLine( penetrationEnd, tr.endpos, iTraceMask, &ignoreShooter, &reverseTr );

		// Now we can apply the damage, after we have traced the entity
		// so it doesn't break or die before we have a change to test against it
#ifndef CLIENT_DLL
		ApplyMultiDamage();
#endif

		// Continue looking for the exit point
		if( reverseTr.m_pEnt != tr.m_pEnt && reverseTr.m_pEnt != NULL )
		{
			// something was blocking, trace again
			CTraceFilterSkipTwoEntities ignoreShooterAndBlocker( this, reverseTr.m_pEnt, iCollisionGroup );
			UTIL_TraceLine( penetrationEnd, tr.endpos, iTraceMask, &ignoreShooterAndBlocker, &reverseTr );
		}

		if ( sv_showimpacts.GetBool() )
		{
			debugoverlay->AddLineOverlay( penetrationEnd, reverseTr.endpos, 255, 0, 0, true, 3.0 );
		}

		// penetration was successful

#ifdef CLIENT_DLL
		// bullet did penetrate object, exit Decal
		if ( !( reverseTr.surface.flags & (SURF_SKY|SURF_NODRAW|SURF_HINT|SURF_SKIP) ) )
		{
			CBaseEntity *pEntity = reverseTr.m_pEnt;
			if ( !( !friendlyfire.GetBool() && pEntity && pEntity->GetTeamNumber() == GetTeamNumber() ) )
			{
				UTIL_ImpactTrace( &reverseTr, iDamageType );
			}
		}
#endif

		//setup new start end parameters for successive trace

		// New start point is our last exit point
		vecSrc = reverseTr.endpos + /* 1.0 * */ info.m_vecDirShooting;

		// Reduce bullet damage by material and distanced travelled through that material
		// if it is < 0 we won't go through the loop again
		float flTraceDistance = VectorLength( reverseTr.endpos - tr.endpos );
		
		flDamage -= flMaterialMod * flTraceDistance;

		if( flDamage > 0 )
		{
			DevMsg( 2, "Completed penetration, new damage is %.1f\n", flDamage );
		}
		else
		{
			DevMsg( 2, "bullet was stopped\n" );
		}

		iPenetrations++;
	}

#ifdef GAME_DLL
	HandleHeadshotAchievement( iNumHeadshots );
#endif
}]]
--[[
// BUG! This is not called on the client at respawn, only first spawn!
function _R.Player:Spawn() -- Fix; move to Player class?
	self:Spawn()

	// Reset the animation state or we will animate to standing
	// when we spawn

	self:SetJumping( false )

	self.m_flMinNextStepSoundTime = CurTime()

	self.m_bPlayingProneMoveSound = false
end
]]
function _R.Player:IsSprinting()
	local flVelSqr = self:GetAbsVelocity():LengthSqr()

	return self.m_bIsSprinting and ( flVelSqr > 0.5 )
end

function _R.Player:CanAttack()
	if ( self:IsSprinting() ) then 
		return false
	elseif ( self:GetMoveType() == MOVETYPE_LADDER ) then
		return false
	elseif ( self:IsJumping() ) then
		return false
	elseif ( self:IsDefusing() ) then
		return false
	// cannot attack while prone moving. except if you have a bazooka
	elseif ( self:IsProne() and self:GetAbsVelocity():LengthSqr() > 1 ) then
		return false
	elseif( self:IsGoingProne() or self:IsGettingUpFromProne() ) then
		return false
	end
	--[[
	CDODGameRules *rules = DODGameRules();

	Assert( rules );

	DODRoundState state = rules->State_Get();
	]]-- Fix
	
	if ( dod_bonusround:GetBool() ) then
		if ( self:Team() == TEAM_ALLIES ) then
			return ( state == STATE_RND_RUNNING or state == STATE_ALLIES_WIN )
		else
			return ( state == STATE_RND_RUNNING || state == STATE_AXIS_WIN )
		end
	else
        return ( state == STATE_RND_RUNNING )
	end
end

--[[
function _R.Player:SetAnimation( PLAYER_ANIM playerAnim )
{
	// In DoD, its CPlayerAnimState object manages ALL the animation state.
	return;
}
]]--

function _R.Player:GetPlayerMins()
	if ( self:IsObserver() ) then
		return VEC_OBS_HULL_MIN	
	else
		if ( bit.band( self:GetFlags(), FL_DUCKING ) ) then
			return VEC_DUCK_HULL_MIN
		elseif ( self:IsProne() ) then
			return VEC_PRONE_HULL_MIN
		else
			return VEC_HULL_MIN
		end
	end
end

function _R.Player:GetPlayerMaxs()
	if ( self:IsObserver() ) then
		return VEC_OBS_HULL_MAX	
	else
		if ( bit.band( self:GetFlags(), FL_DUCKING ) ) then
			return VEC_DUCK_HULL_MAX
		elseif ( self:IsProne() ) then
			return VEC_PRONE_HULL_MAX
		else
			return VEC_HULL_MAX
		end
	end
end

function _R.Player:ShouldCollide( collisionGroup, contentsMask )
	if ( ( collisionGroup == COLLISION_GROUP_PLAYER_MOVEMENT ) ) then
		local teamNum = self:Team()
		if ( teamNum == TEAM_ALLIES ) then
			if ( not bit.band( contentsMask, CONTENTS_TEAM2 ) ) then
				return false
			end
		elseif ( teamNum == TEAM_AXIS ) then
			if ( not bit.band( contentsMask, CONTENTS_TEAM1 ) ) then
				return false
			end
		end
	end
	
	return self.BaseClass:ShouldCollide( collisionGroup, contentsMask ) -- Fix
end

function _R.Player:OnRemove()
	self.m_pViewOffsetAnim = nil
end

function _R.Player:IsDucking()
	return bit.band( self:GetFlags(), FL_DUCKING )
end

function _R.Player:IsProne()
	return self.m_bProne
end

function _R.Player:IsGettingUpFromProne()
	return ( self.m_flUnProneTime > 0 )
end

function _R.Player:IsGoingProne()
	return ( self.m_flGoProneTime > 0 )
end

function _R.Player:SetSprinting( bSprinting )
	if ( bSprinting && not self.m_bIsSprinting ) then
		self:StartSprinting()

		// only one penalty per key press
		if ( self.m_bGaveSprintPenalty == false ) then
			self.m_flStamina = self.m_flStamina - INITIAL_SPRINT_STAMINA_PENALTY
			self.m_bGaveSprintPenalty = true
		end
	elseif ( not bSprinting and self.m_bIsSprinting ) then
		self:StopSprinting()
	end
end

// this is reset when we let go of the sprint key
function _R.Player:ResetSprintPenalty()
	self.m_bGaveSprintPenalty = false
end

function _R.Player:StartSprinting()
	self.m_bIsSprinting = true

	if ( SERVER ) then
		self:RemoveHintTimer( HINT_USE_SPRINT )
	end
end

function _R.Player:StopSprinting()
	self.m_bIsSprinting = false
end

function _R.Player:SetProne( bProne, bNoAnimation )
	self.m_bProne = bProne

	if ( bNoAnimation ) then
		self.m_flGoProneTime = 0
		self.m_flUnProneTime = 0

		// cancel the view animation!
		self.m_bForceProneChange = true
	end

	if ( not bProne /*&& IsSniperZoomed()*/ ) then	// forceunzoom for going prone is in StartGoingProne -- Fix
		self:ForceUnzoom()
	end
end

function _R.Player:SetJumping( bJumping )
	self.m_bJumping = bJumping
	
	if ( self:IsSniperZoomed() ) then
		self:ForceUnzoom()
	end
end

function _R.Player:ForceUnzoom()
	local pWeapon = self:GetActiveDODWeapon() -- Fix
	if ( IsValid( pWeapon ) and bit.band( pWeapon.m_WeaponType, WPN_MASK_GUN ) ) then
		local pSniper = false -- Fix

		if ( pSniper ) then
			pSniper:ZoomOut()
		end
	end
end

function _R.Player:IsBazookaDeployed()
	local pWeapon = self:GetActiveDODWeapon() -- Fix
	if ( IsValid( pWeapon ) and pWeapon.m_WeaponType == WPN_TYPE_BAZOOKA ) then
		return pBazooka:IsDeployed() and not pBazooka.m_bInReload
	end

	return false
end

function _R.Player:IsBazookaOnlyDeployed()
	local pWeapon = self:GetActiveDODWeapon() -- Fix
	if ( IsValid( pWeapon ) and pWeapon.m_WeaponType == WPN_TYPE_BAZOOKA ) then
		return pBazooka:IsDeployed()
	end

	return false
end

function _R.Player:IsSniperZoomed()
	local pWeapon = self:GetActiveDODWeapon()
	if ( IsValid( pWeapon ) and bit.band( pWeapon.m_WeaponType, WPN_MASK_GUN ) ) then
		return pWeapon:IsSniperZoomed() -- Fix
	end

	return false
end

function _R.Player:IsInMGDeploy()
	local pWeapon = self:GetActiveDODWeapon()
	if ( IsValid( pWeapon ) and pWeapon.WeaponType == WPN_TYPE_MG ) then
		return pWeapon:IsDeployed()
	end
	
	return false
end

function _R.Player:IsProneDeployed()
	return ( self:IsProne() and self:IsInMGDeploy() )
end

function _R.Player:IsSandbagDeployed()
	return ( not self:IsProne() and self:IsInMGDeploy() )
end

function _R.Player:SetDesiredPlayerClass( playerclass )
	self.m_iDesiredPlayerClass = playerclass
end

function _R.Player:DesiredPlayerClass()
	return self.m_iDesiredPlayerClass
end

function _R.Player:SetPlayerClass( playerclass )
	self.m_iPlayerClass = playerclass
end

function _R.Player:PlayerClass() -- Fix
	return self.m_iPlayerClass
end

function _R.Player:SetStamina( flStamina )
	self.m_flStamina = math.clamp( flStamina, 0, 100 )
end

function _R.Player:GetActiveDODWeapon() -- Fix?
	local pWeapon = self:GetActiveWeapon()
	if ( IsValid( pWeapon ) and pWeapon.Whatever ) then -- Fix; find variable to get a dod weapon
		return pWeapon
	else
		return
	end
end

function _R.Player:SetDeployed( bDeployed, flHeight )
	if( ( CurTime() - self.m_flDeployChangeTime ) < 0.2 ) then
		return
	end

	self.m_flDeployChangeTime = CurTime()
	self.m_vecDeployedAngles = self:EyeAngles()

	if ( flHeight > 0 ) then
		self.m_flDeployedHeight = flHeight
	else
		self.m_flDeployedHeight = self:GetViewOffset().z -- Fix?
	end
end

function _R.Player:GetDeployedAngles()
	return self.m_vecDeployedAngles
end

function _R.Player:SetDeployedYawLimits( flLeftYaw, flRightYaw )
	self.m_flDeployedYawLimitLeft = flLeftYaw;
	self.m_flDeployedYawLimitRight = -flRightYaw;

	self.m_vecDeployedAngles = self:EyeAngles()
end
--[[
function _R.Player:ClampDeployedAngles( vecTestAngles )
{
	Assert( vecTestAngles );

	// Clamp Pitch
	vecTestAngles->x = clamp( vecTestAngles->x, MAX_DEPLOY_PITCH, MIN_DEPLOY_PITCH );

	// Clamp Yaw - do a bit more work as yaw will wrap around and cause problems
	float flDeployedYawCenter = GetDeployedAngles().y;

	float flDelta = AngleNormalize( vecTestAngles->y - flDeployedYawCenter );

	if( flDelta < m_flDeployedYawLimitRight )
	{
		vecTestAngles->y = flDeployedYawCenter + m_flDeployedYawLimitRight;
	}
	else if( flDelta > m_flDeployedYawLimitLeft )
	{
		vecTestAngles->y = flDeployedYawCenter + m_flDeployedYawLimitLeft;
	}

	/*
	Msg( "delta %.1f ( left %.1f, right %.1f ) ( %.1f -> %.1f )\n",
		flDelta,
		flDeployedYawCenter + m_flDeployedYawLimitLeft,
		flDeployedYawCenter + m_flDeployedYawLimitRight,
		before,
		vecTestAngles->y );
		*/

}

float _R.Player:GetDeployedHeight()
{
	return m_flDeployedHeight;
}

float _R.Player:GetSlowedTime()
{
	return m_flSlowedUntilTime;
}

function _R.Player:SetSlowedTime( float t )
{
	m_flSlowedUntilTime = gpGlobals->curtime + t;
}

function _R.Player:StartGoingProne()
{
	// make the prone sound
	CPASFilter filter( m_pOuter->GetAbsOrigin() );
	filter.UsePredictionRules();
	m_pOuter->EmitSound( filter, m_pOuter->entindex(), "Player.GoProne" );

	// slow to prone speed
	m_flGoProneTime = gpGlobals->curtime + TIME_TO_PRONE;

	m_flUnProneTime = 0.0f;	//reset

	if ( IsSniperZoomed() )
		ForceUnzoom();
}

function _R.Player:StandUpFromProne()
{	
	// make the prone sound
	CPASFilter filter( m_pOuter->GetAbsOrigin() );
	filter.UsePredictionRules();
	m_pOuter->EmitSound( filter, m_pOuter->entindex(), "Player.UnProne" );

	// speed up to target speed
	m_flUnProneTime = gpGlobals->curtime + TIME_TO_PRONE;

	m_flGoProneTime = 0.0f;	//reset 
}

bool _R.Player:CanChangePosition()
{
	if ( IsInMGDeploy() )
		return false;

	if ( IsGettingUpFromProne() )
		return false;

	if ( IsGoingProne() )
		return false;

	return true;
}

function _R.Player:UpdateStepSound( surfacedata_t *psurface, const Vector &vecOrigin, const Vector &vecVelocity )
{
	Vector knee;
	Vector feet;
	float height;
	int	fLadder;

	if ( m_flStepSoundTime > 0 )
	{
		m_flStepSoundTime -= 1000.0f * gpGlobals->frametime;
		if ( m_flStepSoundTime < 0 )
		{
			m_flStepSoundTime = 0;
		}
	}

	if ( m_flStepSoundTime > 0 )
		return;

	if ( GetFlags() & (FL_FROZEN|FL_ATCONTROLS))
		return;

	if ( GetMoveType() == MOVETYPE_NOCLIP || GetMoveType() == MOVETYPE_OBSERVER )
		return;

	if ( !sv_footsteps.GetFloat() )
		return;

	float speed = VectorLength( vecVelocity );
	float groundspeed = Vector2DLength( vecVelocity.AsVector2D() );

	// determine if we are on a ladder
	fLadder = ( GetMoveType() == MOVETYPE_LADDER );

	float flDuck;

	if ( ( GetFlags() & FL_DUCKING) || fLadder )
	{
		flDuck = 100;
	}
	else
	{
		flDuck = 0;
	}

	static float flMinProneSpeed = 10.0f;
	static float flMinSpeed = 70.0f;
	static float flRunSpeed = 110.0f;

	bool onground = ( GetFlags() & FL_ONGROUND );
	bool movingalongground = ( groundspeed > 0.0f );
	bool moving_fast_enough =  ( speed >= flMinSpeed );

	// always play a step sound if we are moving faster than 

	// To hear step sounds you must be either on a ladder or moving along the ground AND
	// You must be moving fast enough

	CheckProneMoveSound( groundspeed, onground );

	if ( !moving_fast_enough || !(fLadder || ( onground && movingalongground )) )
	{
		return;
	}

	bool bWalking = ( speed < flRunSpeed );		// or ducking!

	VectorCopy( vecOrigin, knee );
	VectorCopy( vecOrigin, feet );

	height = GetPlayerMaxs()[ 2 ] - GetPlayerMins()[ 2 ];

	knee[2] = vecOrigin[2] + 0.2 * height;

	float flVol;

	// find out what we're stepping in or on...
	if ( fLadder )
	{
		psurface = physprops->GetSurfaceData( physprops->GetSurfaceIndex( "ladder" ) );
		flVol = 1.0;
		m_flStepSoundTime = 350;
	}
	else if ( enginetrace->GetPointContents( knee ) & MASK_WATER )
	{
		static int iSkipStep = 0;

		if ( iSkipStep == 0 )
		{
			iSkipStep++;
			return;
		}

		if ( iSkipStep++ == 3 )
		{
			iSkipStep = 0;
		}
		psurface = physprops->GetSurfaceData( physprops->GetSurfaceIndex( "wade" ) );
		flVol = 0.65;
		m_flStepSoundTime = 600;
	}
	else if ( enginetrace->GetPointContents( feet ) & MASK_WATER )
	{
		psurface = physprops->GetSurfaceData( physprops->GetSurfaceIndex( "water" ) );
		flVol = bWalking ? 0.2 : 0.5;
		m_flStepSoundTime = bWalking ? 400 : 300;		
	}
	else
	{
		if ( !psurface )
			return;

		if ( bWalking )
		{
			m_flStepSoundTime = 400;
		}
		else
		{
			if ( speed > 200 )
			{
				int speeddiff = PLAYER_SPEED_SPRINT - PLAYER_SPEED_RUN;
				int diff = speed - PLAYER_SPEED_RUN;

				float percent = (float)diff / (float)speeddiff;

				m_flStepSoundTime = 300.0f - 30.0f * percent;
			}
			else 
			{
				m_flStepSoundTime = 400;
			}
		}

		switch ( psurface->game.material )
		{
		default:
		case CHAR_TEX_CONCRETE:						
			flVol = bWalking ? 0.2 : 0.5;
			break;

		case CHAR_TEX_METAL:	
			flVol = bWalking ? 0.2 : 0.5;
			break;

		case CHAR_TEX_DIRT:
			flVol = bWalking ? 0.25 : 0.55;
			break;

		case CHAR_TEX_VENT:	
			flVol = bWalking ? 0.4 : 0.7;
			break;

		case CHAR_TEX_GRATE:
			flVol = bWalking ? 0.2 : 0.5;
			break;

		case CHAR_TEX_TILE:	
			flVol = bWalking ? 0.2 : 0.5;
			break;

		case CHAR_TEX_SLOSH:
			flVol = bWalking ? 0.2 : 0.5;
			break;
		}
	}

	m_flStepSoundTime += flDuck; // slower step time if ducking

	if ( GetFlags() & FL_DUCKING )
	{
		flVol *= 0.65;
	}

	// protect us from prediction errors a little bit
	if ( m_flMinNextStepSoundTime > gpGlobals->curtime )
	{
		return;
	}

	m_flMinNextStepSoundTime = gpGlobals->curtime + 0.1f;	

	PlayStepSound( feet, psurface, flVol, false );
}

function _R.Player:CheckProneMoveSound( int groundspeed, bool onground )
{
#ifdef CLIENT_DLL
	bool bShouldPlay = (groundspeed > 10) && (onground == true) && m_Shared.IsProne() && IsAlive();

	if ( m_bPlayingProneMoveSound && !bShouldPlay )
	{
		StopSound( "Player.MoveProne" );
		m_bPlayingProneMoveSound= false;
	}
	else if ( !m_bPlayingProneMoveSound && bShouldPlay )
	{
		CRecipientFilter filter;
		filter.AddRecipientsByPAS( WorldSpaceCenter() );
		EmitSound( filter, entindex(), "Player.MoveProne" );

		m_bPlayingProneMoveSound = true;
	}
#endif
}

//-----------------------------------------------------------------------------
// Purpose: 
// Input  : step - 
//			fvol - 
//			force - force sound to play
//-----------------------------------------------------------------------------
function _R.Player:PlayStepSound( Vector &vecOrigin, surfacedata_t *psurface, float fvol, bool force )
{
	if ( gpGlobals->maxClients > 1 && !sv_footsteps.GetFloat() )
		return;

#if defined( CLIENT_DLL )
	// during prediction play footstep sounds only once
	if ( prediction->InPrediction() && !prediction->IsFirstTimePredicted() )
		return;
#endif

	if ( !psurface )
		return;

	unsigned short stepSoundName = m_Local.m_nStepside ? psurface->sounds.stepleft : psurface->sounds.stepright;
	m_Local.m_nStepside = !m_Local.m_nStepside;

	if ( !stepSoundName )
		return;

	IPhysicsSurfaceProps *physprops = MoveHelper( )->GetSurfaceProps();
	const char *pSoundName = physprops->GetString( stepSoundName );
	CSoundParameters params;

	// we don't always know the model, so go by team
	char *pModelNameForGender = DOD_PLAYERMODEL_AXIS_RIFLEMAN;

	if( GetTeamNumber() == TEAM_ALLIES )
		pModelNameForGender = DOD_PLAYERMODEL_US_RIFLEMAN;

	if ( !CBaseEntity::GetParametersForSound( pSoundName, params, pModelNameForGender ) )
		return;	

	CRecipientFilter filter;
	filter.AddRecipientsByPAS( vecOrigin );

#ifndef CLIENT_DLL
	// im MP, server removed all players in origins PVS, these players 
	// generate the footsteps clientside
	if ( gpGlobals->maxClients > 1 )
		filter.RemoveRecipientsByPVS( vecOrigin );
#endif

	EmitSound_t ep;
	ep.m_nChannel = params.channel;
	ep.m_pSoundName = params.soundname;
	ep.m_flVolume = fvol;
	ep.m_SoundLevel = params.soundlevel;
	ep.m_nFlags = 0;
	ep.m_nPitch = params.pitch;
	ep.m_pOrigin = &vecOrigin;

	EmitSound( filter, entindex(), ep );
}

Activity _R.Player:TranslateActivity( Activity baseAct, bool *pRequired /* = NULL */ )
{
	Activity translated = baseAct;

	if ( GetActiveWeapon() )
	{
		translated = GetActiveWeapon()->ActivityOverride( baseAct, pRequired );
	}
	else if (pRequired)
	{
		*pRequired = false;
	}

	return translated;
}

function _R.Player:SetCPIndex( int index )
{
#ifdef CLIENT_DLL

	if ( m_pOuter->IsLocalPlayer() )
	{
		if ( index == -1 )
		{
			// just left an area
			g_pClientMode->GetViewportAnimationController()->StartAnimationSequence( "ObjectiveIconShrink" ); 
		}
		else
		{
			g_pClientMode->GetViewportAnimationController()->StartAnimationSequence( "ObjectiveIconGrow" ); 
		}
	}

#endif

	m_iCPIndex = index;
}

function _R.Player:SetLastViewAnimTime( float flTime )
{
	m_flLastViewAnimationTime = flTime;
}

float _R.Player:GetLastViewAnimTime()
{
	return m_flLastViewAnimationTime;
}

function _R.Player:ResetViewOffsetAnimation()
{
    if ( m_pViewOffsetAnim )
	{
		//cancel it!
		m_pViewOffsetAnim->Reset();
	}
}

function _R.Player:ViewOffsetAnimation( Vector vecDest, float flTime, ViewAnimationType type )
{
	if ( !m_pViewOffsetAnim )
	{
		m_pViewOffsetAnim =  CViewOffsetAnimation::CreateViewOffsetAnim( m_pOuter );
	}

	Assert( m_pViewOffsetAnim );

	if ( m_pViewOffsetAnim )
	{
		m_pViewOffsetAnim->StartAnimation( m_pOuter->GetViewOffset(), vecDest, flTime, type );
	}
}

function _R.Player:ViewAnimThink()
{
	// Check for the flag that will reset our view animations
	// when the player respawns
	if ( m_bForceProneChange )
	{
		ResetViewOffsetAnimation();

		m_pOuter->SetViewOffset( VEC_VIEW );

		m_bForceProneChange = false;
	}

	if ( m_pViewOffsetAnim )
	{
		m_pViewOffsetAnim->Think();
	}
}

function _R.Player:ComputeWorldSpaceSurroundingBox( Vector *pVecWorldMins, Vector *pVecWorldMaxs )
{
	Vector org = m_pOuter->GetAbsOrigin();

	if ( IsProne() )
	{
		static Vector vecProneMin(-44, -44, 0 );
		static Vector vecProneMax(44, 44, 24 );

		VectorAdd( vecProneMin, org, *pVecWorldMins );
		VectorAdd( vecProneMax, org, *pVecWorldMaxs );
	}
	else
	{
		static Vector vecMin(-32, -32, 0 );
		static Vector vecMax(32, 32, 72 );

		VectorAdd( vecMin, org, *pVecWorldMins );
		VectorAdd( vecMax, org, *pVecWorldMaxs );
	}
}]]