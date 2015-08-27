function game.MultiPlayer()
	return not self.SinglePlayer()
end

AUTOAIM_NONE = 0
AUTOAIM_ON = 1
AUTOAIM_ON_CONSOLE = 2

GR_NONE = 0

GR_WEAPON_RESPAWN_YES = 1
GR_WEAPON_RESPAWN_NO = 2

GR_ITEM_RESPAWN_YES = 3
GR_ITEM_RESPAWN_NO = 4

GR_PLR_DROP_GUN_ALL = 5
GR_PLR_DROP_GUN_ACTIVE = 6
GR_PLR_DROP_GUN_NO = 7

GR_PLR_DROP_AMMO_ALL = 8
GR_PLR_DROP_AMMO_ACTIVE = 9
GR_PLR_DROP_AMMO_NO = 10

GR_NOTTEAMMATE = 0
GR_TEAMMATE = 1
GR_ENEMY = 2
GR_ALLY = 3
GR_NEUTRAL = 4
--[[
// Damage Queries - these need to be implemented by the various subclasses (single-player, multi-player, etc).
	// The queries represent queries against damage types and properties.
	virtual bool	Damage_IsTimeBased( int iDmgType ) = 0;			// Damage types that are time-based.
	virtual bool	Damage_ShouldGibCorpse( int iDmgType ) = 0;		// Damage types that gib the corpse.
	virtual bool	Damage_ShowOnHUD( int iDmgType ) = 0;			// Damage types that have client HUD art.
	virtual bool	Damage_NoPhysicsForce( int iDmgType ) = 0;		// Damage types that don't have to supply a physics force & position.
	virtual bool	Damage_ShouldNotBleed( int iDmgType ) = 0;		// Damage types that don't make the player bleed.
	//Temp: These will go away once DamageTypes become enums.
	virtual int		Damage_GetTimeBased( void ) = 0;				// Actual bit-fields.
	virtual int		Damage_GetShouldGibCorpse( void ) = 0;
	virtual int		Damage_GetShowOnHud( void ) = 0;					
	virtual int		Damage_GetNoPhysicsForce( void )= 0;
	virtual int		Damage_GetShouldNotBleed( void ) = 0;
]]--

local g_Language = CreateConVar( "g_Language", "0", FCVAR_REPLICATED )
local ak_autoaim_mode = CreateConVar( "sk_autoaim_mode", "1", { FCVAR_ARCHIVE, FCVAR_REPLICATED } )

g_DefaultViewVectors = {
	Vector( 0, 0, 64 ),			//VEC_VIEW (m_vView) -- Fix ENUM number to match lua arrays
								
	Vector(-16, -16, 0 ),		//VEC_HULL_MIN (m_vHullMin)
	Vector( 16,  16,  72 ),		//VEC_HULL_MAX (m_vHullMax)
													
	Vector(-16, -16, 0 ),		//VEC_DUCK_HULL_MIN (m_vDuckHullMin)
	Vector( 16,  16,  36 ),		//VEC_DUCK_HULL_MAX	(m_vDuckHullMax)
	Vector( 0, 0, 28 ),			//VEC_DUCK_VIEW		(m_vDuckView)
													
	Vector(-10, -10, -10 ),		//VEC_OBS_HULL_MIN	(m_vObsHullMin)
	Vector( 10,  10,  10 ),		//VEC_OBS_HULL_MAX	(m_vObsHullMax)
													
	Vector( 0, 0, 14 )			//VEC_DEAD_VIEWHEIGHT (m_vDeadViewHeight)
end

local old_radius_damage = CreateConVar( "old_radiusdamage", "0.0", FCVAR_REPLICATED )

if ( CLIENT ) then
	
	function GM:IsBonusChallangeTimeBased()
		return true
	end
	
else
	
	function GM:CanHaveAmmo( pPlayer, iAmmoIndex )
		if ( type( iAmmoIndex ) == "string" ) then
			iAmmoIndex = game.GetAmmoIndex( iAmmoIndex ) -- Fix AF
		end
		
		if ( iAmmoIndex > -1 ) then
			// Get the max carrying capacity for this ammo
			local iMaxCarry = game.GetMaxCarry( iAmmoIndex ) -- Fix
			
			// Does the player have room for more of this type of ammo?
			if ( pPlayer:GetAmmoCount( iAmmoIndex ) < iMaxCarry ) then -- Fix, index?
				return true
			end
		end
		
		return false
	end
	
	function GM:GetPlayerSpawnSpot( pPlayer )
		local pSpawnSpot = pPlayer:EntSelectSpawnPoint() -- Fix
		-- Fix; create an Assert function for entity validity?
		if ( not IsValid( pSpawnSpot ) ) then return end
		
		pPlayer:SetLocalPos( pSpawnSpot:GetPos() + Vector( 0, 0, 1 ) )
		pPlayer:SetAbsVelocity( vec3_origin )
		pPlayer:SetLocalAngles( pSpawnSpot:GetLocalAngles() )
		pPlayer:SetViewPunchAngles( vec3_origin )
		pPlayer:SetEyeAngles( pSpawnSpot:GetLocalAnlges() )
		
		return pSpawnSpot
	end
	
	// checks if the spot is clear of players
	function GM:IsSpawnPointValid( pSpot, pPlayer )
		if ( not pSpot:IsTriggered( pPlayer ) ) then
			return false
		end
		
		for _, ent in pairs( ents.FindInSphere( pSpot:GetPos(), 128 ) ) do -- Fix; ipairs
			// if ent is a client, don't spawn on 'em
			if ( ent:IsPlayer() and ent ~= pPlayer ) then
				return false
			end
		end
		
		return true
	end
	
	function GM:CanHavePlayerItem( pPlayer, pWeapon ) -- Fix; add commented out shit
		return true
	end
	
	function GM:RefreshSkillData( forceUpdate ) -- Fix
	end
	
	local function IsExplosionTraceBlocked( ptr )
		if ( ptr.HitWorld ) then
			return true
		elseif ( not IsValid( ptr.Entity ) ) then
			return false
		end
		
		if ( ptr.Entity:GetMoveType() == MOVETYPE_PUSH ) then
			// All doors are push, but not all things that push are doors. This 
			// narrows the search before we start to do classname compares.
			local class = ptr.Entity:GetClass()
			if ( class == "prop_door_rotating" or
			class == "func_door" or
			class == "func_door_rotating" ) then
				return true
		end
		
		return false
	end
	
	ROBUST_RADIUS_PROBE_DIST = 16.0 // If a solid surface blocks the explosion, this is how far to creep along the surface looking for another way to the target
	
	function GM:RadiusDamage()
	end
	
	// Hook into the convar from the engine
	local skill = CreateConVar( "skill", "1" ) -- Fix; what is this?
	
	function GM:WeaponTraceEntity( pEntity, vecStart, vecEnd, mask, ptr )
		util.TraceEntity( {
			start = vecStart,
			endpos = vecEnd,
			mask = mask
			output = ptr -- See if that will update the pointer from the called function, fix
		}, pEntity )
		return 1.0
	end
	
	function GM:MarkAchievement()
		-- Fix
	end
	
end

function GM:SwitchToNextBestWeapon( pPlayer, pCurrentWeapon )
	return false
end

function GM:GetNextBestWeapon( pPlayer, pCurrentWeapon )
	return NULL
end

function GM:ShouldCollide( collisionGroup0, collisionGroup1 )
	if ( collisionGroup0 > collisionGroup1 ) then
		// swap so that lowest is always first
		collisionGroup0, collisionGroup1 = swap(collisionGroup0, collisionGroup1) -- fix
	end

	if ( not HL2MP ) then -- FIX FIX FIX!!!!!!!!! Let's have a global enum for a gamemode instead of checking the name
		if ( (collisionGroup0 == COLLISION_GROUP_PLAYER or collisionGroup0 == COLLISION_GROUP_PLAYER_MOVEMENT) and
			collisionGroup1 == COLLISION_GROUP_PUSHAWAY ) then
			return false
		end
	end

	if ( collisionGroup0 == COLLISION_GROUP_DEBRIS and collisionGroup1 == COLLISION_GROUP_PUSHAWAY ) then
		// let debris and multiplayer objects collide
		return true
	end
	
	// --------------------------------------------------------------------------
	// NOTE: All of this code assumes the collision groups have been sorted!!!!
	// NOTE: Don't change their order without rewriting this code !!!
	// --------------------------------------------------------------------------

	// Don't bother if either is in a vehicle...
	if (( collisionGroup0 == COLLISION_GROUP_IN_VEHICLE ) or ( collisionGroup1 == COLLISION_GROUP_IN_VEHICLE )) then
		return false
	elseif ( ( collisionGroup1 == COLLISION_GROUP_DOOR_BLOCKER ) and ( collisionGroup0 ~= COLLISION_GROUP_NPC ) ) then
		return false
	elseif ( ( collisionGroup0 == COLLISION_GROUP_PLAYER ) and ( collisionGroup1 == COLLISION_GROUP_PASSABLE_DOOR ) ) then
		return false
	elseif ( collisionGroup0 == COLLISION_GROUP_DEBRIS or collisionGroup0 == COLLISION_GROUP_DEBRIS_TRIGGER ) then
		// put exceptions here, right now this will only collide with COLLISION_GROUP_NONE
		return false
	// Dissolving guys only collide with COLLISION_GROUP_NONE
	elseif ( (collisionGroup0 == COLLISION_GROUP_DISSOLVING or collisionGroup1 == COLLISION_GROUP_DISSOLVING) and
		collisionGroup0 ~= COLLISION_GROUP_NONE ) then
		return false
	// doesn't collide with other members of this group
	// or debris, but that's handled above
	elseif ( collisionGroup0 == COLLISION_GROUP_INTERACTIVE_DEBRIS and collisionGroup1 == COLLISION_GROUP_INTERACTIVE_DEBRIS ) then
		return false
	// This change was breaking HL2DM
	// Adrian: TEST! Interactive Debris doesn't collide with the player.
	elseif ( not HL2MP and collisionGroup0 == COLLISION_GROUP_INTERACTIVE_DEBRIS and 
		( collisionGroup1 == COLLISION_GROUP_PLAYER_MOVEMENT or collisionGroup1 == COLLISION_GROUP_PLAYER ) ) then
		 return false
	elseif ( collisionGroup0 == COLLISION_GROUP_BREAKABLE_GLASS and collisionGroup1 == COLLISION_GROUP_BREAKABLE_GLASS ) then
		return false
	// interactive objects collide with everything except debris & interactive debris
	elseif ( collisionGroup1 == COLLISION_GROUP_INTERACTIVE && collisionGroup0 != COLLISION_GROUP_NONE ) then
		return false
	// Projectiles hit everything but debris, weapons, + other projectiles
	elseif ( collisionGroup1 == COLLISION_GROUP_PROJECTILE and 
			( collisionGroup0 == COLLISION_GROUP_DEBRIS or 
			collisionGroup0 == COLLISION_GROUP_WEAPON or
			collisionGroup0 == COLLISION_GROUP_PROJECTILE ) ) then
			return false
	// Don't let vehicles collide with weapons
	// Don't let players collide with weapons...
	// Don't let NPCs collide with weapons
	// Weapons are triggers, too, so they should still touch because of that
	elseif ( collisionGroup1 == COLLISION_GROUP_WEAPON and
			( collisionGroup0 == COLLISION_GROUP_VEHICLE or
			collisionGroup0 == COLLISION_GROUP_PLAYER or
			collisionGroup0 == COLLISION_GROUP_NPC ) then
			return false
	// collision with vehicle clip entity??
	elseif ( collisionGroup0 == COLLISION_GROUP_VEHICLE_CLIP or collisionGroup1 == COLLISION_GROUP_VEHICLE_CLIP ) then
		// yes then if it's a vehicle, collide, otherwise no collision
		// vehicle sorts lower than vehicle clip, so must be in 0
		if ( collisionGroup0 == COLLISION_GROUP_VEHICLE ) then
			return true
		end
		// vehicle clip against non-vehicle, no collision
		return false
	end

	return true
end

function GM:GetViewVectors()
	return g_DefaultViewVectors
end

function GM:GetAmmoDamage( pAttacker, pVictim, nAmmoType )
	local flDamage = 0
	
	if ( pAttacker:IsPlayer() ) then
		flDamage = game -- Fix; ammo library shit
	end
end

function GM:GetDamageMultiplier()
	return 1.0 -- Fix; uses?
end

function GM:InRoundRestart()
	return false
end

if ( SERVER ) then

	function GM:GetChatPrefix( bTeamOnly, pPlayer ) -- Fix; where is this called? Why is this serverside?
		if ( IsValid( pPlayer ) and not pPlayer:Alive() ) then
			if ( bTeamOnly ) then
				return "*DEAD*(TEAM)"
			else
				return "*DEAD*"
			end
		end
		
		return "" -- Fix, no (TEAM)?
	end
	
end