// entity capabilities
// These are caps bits to indicate what an object's capabilities (currently used for +USE, save/restore and level transitions)
FCAP_MUST_SPAWN = 0x00000001		// Spawn after restore
FCAP_ACROSS_TRANSITION = 0x00000002		// should transfer between transitions 
// UNDONE: This will ignore transition volumes (trigger_transition), but not the PVS!!!
FCAP_FORCE_TRANSITION = 0x00000004		// ALWAYS goes across transitions
FCAP_NOTIFY_ON_TRANSITION = 0x00000008		// Entity will receive Inside/Outside transition inputs when a transition occurs

FCAP_IMPULSE_USE = 0x00000010		// can be used by the player
FCAP_CONTINUOUS_USE = 0x00000020		// can be used by the player
FCAP_ONOFF_USE = 0x00000040		// can be used by the player
FCAP_DIRECTIONAL_USE = 0x00000080		// Player sends +/- 1 when using (currently only tracktrains)
// NOTE: Normally +USE only works in direct line of sight.  Add these caps for additional searches
FCAP_USE_ONGROUND = 0x00000100
FCAP_USE_IN_RADIUS = 0x00000200
FCAP_SAVE_NON_NETWORKABLE = 0x00000400

FCAP_MASTER = 0x10000000		// Can be used to "master" other entities (like multisource)
FCAP_WCEDIT_POSITION = 0x40000000		// Can change position and update Hammer in edit mode
FCAP_DONT_SAVE = 0x80000000		// Don't save this

// How many bits are used to transmit parent attachment indices?
NUM_PARENTATTACHMENT_BITS = 6

// Maximum number of vphysics objects per entity
VPHYSICS_MAX_OBJECT_LIST_COUNT = 1024

// Shared EntityMessage between game and client .dlls
BASEENTITY_MSG_REMOVE_DECALS  = 1

//-----------------------------------------------------------------------------
// For invalidate physics recursive
//-----------------------------------------------------------------------------
enum InvalidatePhysicsBits_t
{
	POSITION_CHANGED	= 0x1,
	ANGLES_CHANGED		= 0x2,
	VELOCITY_CHANGED	= 0x4,
	ANIMATION_CHANGED	= 0x8,
};

local _R = debug.getregistry()

do
	local arg = EP1 and "1" or "0" -- Fix; is episodic ep1?
	CreateConVar( "hl2_episodic", arg, FCVAR_REPLICATED )
end

if ( GAME_DLL ) then
	-- CreateConVar( "ent_debugkeys", "" ) -- Already implemented into GMod!
	-- function ParseKeyvalue()
	-- function ExtractKeyvalue()
end

local function SpawnBlood( vecSpot, vecDir, bloodColor, flDamage )
	util.BloodDrips( vecSpot, vecDir, bloodColor, math.floor( flDamage ) ) -- Fix; figure out how (int) rounds
end

function _R.Entity:EarPos()
	return self:EyePos() -- Fix; needed?
end

function _R.Entity:SetBlocksLOS( bBlocksLOS )
	if ( bBlocksLOS ) then
		self:RemoveEFlags( EFL_DONTBLOCKLOS )
	else
		self:AddEFlags( EFL_DONTBLOCKLOS )
	end
end

function _R.Entity:BlocksLOS()
	return not self:IsEFlagSet( EFL_DONTBLOCKLOS )
end

function _R.Entity:SetAIWalkable( bBlocksLOS )
	if ( bBlocksLOS ) then
		self:RemoveEFlags( EFL_DONTWALKON )
	else
		self:AddEFlags( EFL_DONTWALKON )
	end
end

function _R.Entity:IsAIWalkable()
	return not self:IsEFlagSet( EFL_DONTWALKON )
end

-- Fix; redo KeyValue?

function _R.Entity:ShouldCollide( collisionGroup, contentsMask ) -- Fix; where is this called
	if ( self.m_CollisionGroup == COLLISION_GROUP_DEBRIS ) then
		if ( not bit.band( contentsMask, CONTENTS_DEBRIS ) ) then
			return false
		end
	end
	
	return true
end
		
function _R.Entity:SetPredictionRandomSeed( cmd )
	if ( not cmd ) then
		self.m_nPredictionRandomSeed = -1
		return
	end
	
	self.m_nPredictionRandomSeed = ( bit.band( md5.PseudoRandom( cmd:CommandNumber() ), 0x7fffffff ) )
end

function _R.Entity:GetPredictionRandomSeed()
	return self.m_nPredictionRandomSeed
end

function _R.Entity:DecalTrace( pTrace, decalName )
	util.Decal( decalName, pTrace.StartPos, pTrace.HitPos ) -- Fix; startpos?
end

function _R.Entity:ImpactTrace( pTrace, iDamageType, pCustomImpactName )
	local pEntity = pTrace.Entity
	
	if ( not IsValid( pEntity ) ) then
		return
	end
	
	local data = EffectData()
	data:SetOrigin( pTrace.HitPos )
	data:SetStart( pTrace.StartPos )
	data:SetSurfaceProp( pTrace.SurfaceProps )
	data:SetDamageType( iDamageType )
	data:SetHitBox( pTrace.HitBox )
	data:SetEntIndex( pEntity:EntIndex()
	data:SetEntity( pEntity )
	
	// Send it on its way
	if ( not pCustomImpactName ) then
		util.Effect( "Impact", data )
	else
		util.Effect( pCustomImpactName, data )
	end
end

function _R.Entity:DamageDecal( bitsDamageType, gameMaterial )
	local nRenderMode = self:GetRenderMode()
	
	if ( nRenderMode == RENDERMODE_TRANSALPHA ) then
		return ""
	elseif ( nRenderMode ~= RENDERMODE_NORMAL and gameMaterial == 'G' ) then
		return "BulletProof"
	elseif ( bitsDamageType == DMG_SLASH ) then
		return "ManhackCut"
	end
	
	// This will get translated at a lower layer based on game material
	return "Impact.Concrete"
end

function _R.Entity:WillSimulateGamePhysics()
	// players always simulate game physics
	if ( not self:IsPlayer() ) then
		local movetype = self:GetMoveType()
		
		if ( movetype == MOVETYPE_NONE or movetype == MOVETYPE_VPHYSICS ) then
			return false
		elseif ( movetype == MOVETYPE_PUSH and self:GetMoveDoneTime() <= 0 ) then -- Fix; find this function
			return false
		end
	end
	
	return true
end

function _R.Entity:CheckHasGamePhysicsSimulation()
	local isSimulating = self:WillSimulateGamePhysics()
	if ( isSimulating ~= self:IsEFlagSet( EFL_NO_GAME_PHYSICS_SIMULATION ) ) then
		return
	elseif ( isSimulating ) then
		self:RemoveEFlags( EFL_NO_GAME_PHYSICS_SIMULATION )
	else
		self:AddEFlags( EFL_NO_GAME_PHYSICS_SIMULATION )
	end
end

function _R.Entity:IsStandable()
	
	local solid = self:GetSolid()
	
	if ( bit.band( self:GetSolidFlags(), FSOLID_NOT_STANDABLE ) ) then
		return false
	elseif ( solid == SOLID_VPHYSICS or solid == SOLID_BBOX ) then
		return true
	end
	
	return self:IsBSPModel()
end

function _R.Entity:IsBSPModel()
	if ( self:GetSolid() == SOLID_BSP ) then
		return true
	end
	
	if ( self:GetSolid() == SOLID_VPHYSICS ) then -- Fix; ModelType
		return true
	end
	
	return false
end

function _R.Entity:GetRootMoveParent()
	local pEntity = self
	local pParent = self:GetMoveParent()
	
	while ( IsValid( pParent ) ) do
		pEntity = pParent
		pParent = pEntity:GetMoveParent()
	end
	
	return pEntity
end
--[[
function _R.Entity:ShouldDrawUnderwaterBulletBubbles() -- Fix; lol, what the fuck is this
	if ( HL2_DLL and GAME_DLL ) then -- Fix, of course
		local maxClients = player.GetAll()
		local pPlayer = ( #maxClients == 1 ) and maxClients[1] or NULL -- Fix; convert all entities to null
	else
		return false
	end
end]]

-- Fix; override TraceAttack

function _R.Entity:DoImpactEffect( tr, nDamageType )
	// give shooter a chance to do a custom impact.
	util.ImpactTrace( tr, nDamageType ) -- Fix?
end

function _R.Entity:ComputeTracerStartPosition( vecShotSrc )
	if ( not HL2MP ) then
		if ( game.MultiPlayer() ) then
			// NOTE: we do this because in MakeTracer, we force it to use the attachment position
			// in multiplayer, so the results from this function should never actually get used.
			return Vector( 999, 999, 999 )
		end
	end
	
	local pVecTracerStart = vecShootSrc
	
	if ( self:IsPlayer() ) then
		// adjust tracer position for player
		local forward, right = self:EyeVectors()
		pVecTracerStart = vecShotSrc + Vector( 0, 0, -4 ) + right * 2 + forward * 16
	else
		local pWeapon = self:GetActiveWeapon()
		
		if ( IsValid( pWeapon ) ) then
			pVecTracerStart = pWeapon:GetAttachment( 1 )[ "Pos" ]
		end
	end
	
	return pVecTracerStart
end

function _R.Entity:MakeTracer( vecTracerSrc, tr, iTracerType )
	local pszTracerName = self:GetTracerType()
	
	local iAttachment = self:GetTracerAttachment()
	
	if ( iTracerType == TRACER_LINE ) then
		util.Tracer( vecTracerSrc, tr.EndPos, self:EntIndex(), iAttachment, 0.0, false, pszTracerName )
	elseif ( iTracerType == TRACER_LINE_AND_WHIZ ) then
		util.Tracer( vecTracerSrc, tr.EndPos, self:EntIndex(), iAttachment, 0.0, true, pszTracerName )
	end
end

-- Fix; fix blood shit

function _R.Entity:TraceBleed( flDamage, vecDir, ptr, bitsDamageType )
	local bloodcolor = self:GetBloodColor()
	
	if ( bloodcolor == DONT_BLEED or bloodcolor == BLOOD_COLOR_MECH or flDamage == 0 ) then
		return
	end
	
	if ( not bit.band( bitsDamageType, bit.bor( DMG_CRUSH, DMG_BULLET, DMG_SLASH, DMG_BLAST, DMG_CLUB, DMG_AIRBOAT ) ) )
		return
	end
	
	// make blood decal on the wall!
	
	if ( GAME_DLL ) then
		if ( not self:Alive() ) then
			// dealing with a dead npc.
			local maxhealth = self:GetMaxHealth()
			
			if ( maxhealth <= 0 ) then
				// no blood decal for a npc that has already decalled its limit
				return
			else
				self:SetMaxHealth( maxhealth - 1 )
			end
		end
	end
	
	local flNoise, cCount
	
	if ( flDamage < 10 ) then
		flNoise = 0.1
		cCount = 1
	elseif ( flDamage < 25 ) then
		flNoise = 0.2
		cCount = 2
	else
		flNoise = 0.3
		cCount = 4
	end
	
	local flTraceDist = bit.band( bitsDamageType, DMG_AIRBOAT ) and 384 or 172
	
	for i = 0, cCount do
		-- FIX; AI_TraceLine?
	end
end

function _R.Entity:GetTracerType()
	return NULL
end

function _R.Entity:FollowEntity( pBaseEntity, bBoneMerge )
	if ( IsValid( pBaseEntity ) ) then
		self:SetParent( pBaseEntity )
		self:SetMoveType( MOVETYPE_NONE )
		
		if ( bBoneMerge ) then
			self:AddEffects( EF_BONEMERGE )
		end
		
		self:AddSolidFlags( FSOLID_NOT_SOLID )
		self:SetLocalPos( vec3_origin )
		self:SetLocalAngles( vec3_angle )
	else
		self:StopFollowingEntity()
	end
end

function _R.Entity:SetEffectEntity( pEffectEnt )
	if ( self.m_hEffectEntity ~= pEffectEnt ) then
		self.m_hEffectEntity = pEffectEnt
	end
end

-- Fix; VPhysics shit

-- We override this function to fix the longtime crash of ragdoll crashes with collision groups
_R.Entity.OldSetCollisionGroup = _R.Entity.SetCollisionGroup -- Fix?

function _R.Entity:SetCollisionGroup( collisionGroup )
	if ( self:GetCollisionGroup() ~= collisionGroup ) then
		self:SetCollisionGroup( collisionGroup )
		self:CollisionRulesChanged() -- RecheckCollisionFilter is called internally by this
	end
end

function _R.Entity:GetWaterType()
	local out = 0
	if ( bit.band( self.m_nWaterType, 1 ) ) then
		out = CONTENTS_WATER -- Fix; bit library shit
	end
	
	if ( bit.band( self.m_nWaterType, 2 ) ) then
		out = CONTENTS_SLIME -- Fix!!
	end
end

function _R.Entity:SetWaterType( nType )
	self.m_nWaterType = 0
	
	if ( bit.band( nType, CONTENTS_WATER ) ) then
		self.m_nWaterType = 1 -- Fix; bit library shit
	end
	
	if ( bit.band( nType, CONTENTS_SLIME ) ) then
		self.m_nWaterType = 2 -- Fix!!
	end
end

-- usercmd shit, fix
--if SERVER then
	hook.Add( "StartCommand", "RandomSeed", function( player, cmd )
		player:SetPredictionRandomSeed( cmd )
		-- Add more, fix
	end )
	--[[
	hook.Add( "FinishMove", "RandomSeed", function( player )
		player:SetPredictionRandomSeed()
	end
	]]
--end

--hook.Add( "

md5 = {}

function md5.PseudoRandom( nSeed )
	local ctx
	local digest = {}
	
	return nSeed
end