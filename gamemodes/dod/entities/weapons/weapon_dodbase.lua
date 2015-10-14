DEFINE_BASECLASS( "basecombatweapon" )

SWEP.Base = "basecombatweapon"

MELEE_DMG_SECONDARYATTACK	= bit.lshift( 1, 0 )
MELEE_DMG_FIST				= bit.lshift( 1, 1 )
MELEE_DMG_EDGE				= bit.lshift( 1, 2 )
MELEE_DMG_STRONGATTACK		= bit.lshift( 1, 3 )

DOD_AMMO_SUBMG		= "DOD_AMMO_SUBMG"
DOD_AMMO_ROCKET		= "DOD_AMMO_ROCKET"
DOD_AMMO_COLT		= "DOD_AMMO_COLT"
DOD_AMMO_P38		= "DOD_AMMO_P38"
DOD_AMMO_C96		= "DOD_AMMO_C96"	
DOD_AMMO_WEBLEY		= "DOD_AMMO_WEBLEY"
DOD_AMMO_GARAND		= "DOD_AMMO_GARAND"
DOD_AMMO_K98		= "DOD_AMMO_K98"
DOD_AMMO_M1CARBINE	= "DOD_AMMO_M1CARBINE"
DOD_AMMO_ENFIELD	= "DOD_AMMO_ENFIELD"
DOD_AMMO_SPRING		= "DOD_AMMO_SPRING"
DOD_AMMO_FG42		= "DOD_AMMO_FG42"		
DOD_AMMO_BREN		= "DOD_AMMO_BREN"
DOD_AMMO_BAR		= "DOD_AMMO_BAR"		
DOD_AMMO_30CAL		= "DOD_AMMO_30CAL"	
DOD_AMMO_MG34		= "DOD_AMMO_MG34"		
DOD_AMMO_MG42		= "DOD_AMMO_MG42"
DOD_AMMO_HANDGRENADE	= "DOD_AMMO_HANDGRENADE"
DOD_AMMO_HANDGRENADE_EX	= "DOD_AMMO_HANDGRENADE_EX"	// the EX is for EXploding! :)
DOD_AMMO_STICKGRENADE	= "DOD_AMMO_STICKGRENADE"
DOD_AMMO_STICKGRENADE_EX	= "DOD_AMMO_STICKGRENADE_EX"
DOD_AMMO_SMOKEGRENADE_US	= "DOD_AMMO_SMOKEGRENADE_US"
DOD_AMMO_SMOKEGRENADE_GER	= "DOD_AMMO_SMOKEGRENADE_GER"
DOD_AMMO_SMOKEGRENADE_US_LIVE	= "DOD_AMMO_SMOKEGRENADE_US_LIVE"
DOD_AMMO_SMOKEGRENADE_GER_LIVE	= "DOD_AMMO_SMOKEGRENADE_GER_LIVE"
DOD_AMMO_RIFLEGRENADE_US		= "DOD_AMMO_RIFLEGRENADE_US"
DOD_AMMO_RIFLEGRENADE_GER		= "DOD_AMMO_RIFLEGRENADE_GER"
DOD_AMMO_RIFLEGRENADE_US_LIVE	= "DOD_AMMO_RIFLEGRENADE_US_LIVE"
DOD_AMMO_RIFLEGRENADE_GER_LIVE	= "DOD_AMMO_RIFLEGRENADE_GER_LIVE"

CreateConVar( "friendlyfire", "0" )

CROSSHAIR_CONTRACT_PIXELS_PER_SECOND = 7.0

WEAPON_NOCLIP = -1

WEAPON_NONE = 0

//Melee
WEAPON_AMERKNIFE = 1
WEAPON_SPADE = 2

//Pistols
WEAPON_COLT = 3
WEAPON_P38 = 4
WEAPON_C96 = 5

//Rifles
WEAPON_GARAND = 6
WEAPON_M1CARBINE = 7
WEAPON_K98 = 8
	
//Sniper Rifles
WEAPON_SPRING = 9
WEAPON_K98_SCOPED = 10

//SMG
WEAPON_THOMPSON = 11
WEAPON_MP40 = 12
WEAPON_MP44 = 13
WEAPON_BAR = 14

//Machine guns
WEAPON_30CAL = 15
WEAPON_MG42 = 16

//Rocket weapons
WEAPON_BAZOOKA = 17
WEAPON_PSCHRECK = 18

//Grenades
WEAPON_FRAG_US = 19
WEAPON_FRAG_GER = 20

WEAPON_FRAG_US_LIVE = 21
WEAPON_FRAG_GER_LIVE = 22

WEAPON_SMOKE_US = 23
WEAPON_SMOKE_GER = 24

WEAPON_RIFLEGREN_US = 25
WEAPON_RIFLEGREN_GER = 26

WEAPON_RIFLEGREN_US_LIVE = 27
WEAPON_RIFLEGREN_GER_LIVE = 28

// not actually separate weapons, but defines used in stats recording
// find a better way to do this without polluting the list of actual weapons.
WEAPON_THOMPSON_PUNCH = 29
WEAPON_MP40_PUNCH = 30

WEAPON_GARAND_ZOOMED = 31	
WEAPON_K98_ZOOMED = 32
WEAPON_SPRING_ZOOMED = 33
WEAPON_K98_SCOPED_ZOOMED = 34
	
WEAPON_30CAL_UNDEPLOYED = 35
WEAPON_MG42_UNDEPLOYED = 36

WEAPON_BAR_SEMIAUTO = 37
WEAPON_MP44_SEMIAUTO = 38
		
WEAPON_MAX = 39		// number of weapons weapon index

//Class Heirarchy for dod weapons

/*

  CWeaponDODBase
	|
	|
	|--> CWeaponDODBaseMelee
	|		|
	|		|--> CWeaponSpade
	|		|--> CWeaponUSKnife
	|
	|--> CWeaponDODBaseGrenade
	|		|
	|		|--> CWeaponHandgrenade
	|		|--> CWeaponStickGrenade
	|		|--> CWeaponSmokeGrenadeUS
	|		|--> CWeaponSmokeGrenadeGER
	|
	|--> CWeaponBaseRifleGrenade
	|		|
	|		|--> CWeaponRifleGrenadeUS
	|		|--> CWeaponRifleGrenadeGER
	|
	|--> CDODBaseRocketWeapon
	|		|
	|		|--> CWeaponBazooka
	|		|--> CWeaponPschreck
	|
	|--> CWeaponDODBaseGun
			|
			|--> CDODFullAutoWeapon
			|		|
			|		|--> CWeaponC96
			|		|
			|		|--> CDODFullAutoPunchWeapon
			|		|		|
			|		|		|--> CWeaponThompson
			|		|		|--> CWeaponMP40
			|		|
			|		|--> CDODBipodWeapon
			|				|
			|				|->	CWeapon30Cal
			|				|->	CWeaponMG42
			|
			|--> CDODFireSelectWeapon
			|		|
			|		|--> CWeaponMP44
			|		|--> CWeaponBAR
			|
			|
			|--> CDODSemiAutoWeapon
					|
					|--> CWeaponColt
					|--> CWeaponP38
					|--> CWeaponM1Carbine
					|--> CDODSniperWeapon
						|
						|--> CWeaponSpring
						|--> CWeaponScopedK98
						|--> CWeaponGarand
						|--> CWeaponK98

*/

Primary_Mode = 0
Secondary_Mode = 1

NUM_MUZZLE_FLASH_TYPES = 4

--[[
function IsAmmoType( iAmmoType, pAmmoName )
	return GetAmmoDef:Index( pAmmoName ) == iAmmoType -- Fix
end

function WeaponIDToAlias( id ) -- Fix; is this needed?
	if ( (id>= WEAPON_MAX) or (id < 0) ) then
		return
	end
	
	return s_WeaponAliasInfo[ id ]
end
]]

SWEP.m_iSmackDamageType = 0

SWEP.ID = WEAPON_NONE
SWEP.StatsID = WEAPON_NONE
SWEP.AltID = WEAPON_NONE
SWEP.DrawCrosshair = true
--SWEP.DrawViewModel = true
SWEP.DrawMuzzleFlash = true
SWEP.HideWhenZoomed = false
SWEP.SwayScale = 1.0

SWEP.DrawAmmo = true

SWEP.CrosshairMinDistance = 4
SWEP.CrosshairDeltaDistance = 3
SWEP.MuzzleFlashType = 0
SWEP.MuzzleFlashScale = 0.5

SWEP.Damage = 1
SWEP.AccuracyMovePenalty = 0.1
SWEP.Recoil = 99.0
SWEP.Penetration = 1.0
SWEP.IdleTimeAfterFire = 1.0
SWEP.IdleInterval = 1.0
SWEP.CanDrop = true
SWEP.BulletsPerShot = 1

SWEP.HudClipHeight = 0
SWEP.HudClipBaseHeight = 0
SWEP.ClipBulletHeight = 0

SWEP.AmmoPickupClips = 2 -- Fix, wtf is this

SWEP.ViewModelFOV = 90.0

SWEP.BotAudibleRange = 2000.0

SWEP.Tracer = 0

SWEP.WeaponType = WPN_TYPE_UNKNOWN

SWEP.Primary =
{
	Accuracy = 1.0,
	Delay = 0.1,
	ClipSize = WEAPON_NOCLIP,
	DefaultClip = 0, -- This is ClipSize on the Valve base
	Automatic = true
}

SWEP.Secondary =
{
	Accuracy = 1.0,
	Delay = 0.1,
	ClipSize = WEAPON_NOCLIP,
	DefaultClip = 0, -- Refer to the first comment
	Automatic = false
}
	

function SWEP:ObjectCaps()
	return ( bit.bor( BaseClass.ObjectCaps( self ), FCAP_USE_IN_RADIUS ) )
end

SWEP.OverrideActivities =
{
	[ ACT_DOD_STAND_AIM ] = ACT_DOD_STAND_AIM,
	[ ACT_DOD_CROUCH_AIM ] = ACT_DOD_CROUCH_AIM,
	[ ACT_DOD_CROUCHWALK_AIM ] = ACT_DOD_CROUCHWALK_AIM,
	[ ACT_DOD_WALK_AIM ] = ACT_DOD_WALK_AIM,
	[ ACT_DOD_RUN_AIM ] = ACT_DOD_RUN_AIM,
	[ ACT_PRONE_IDLE ] = ACT_PRONE_IDLE,
	[ ACT_PRONE_FORWARD ] = ACT_PRONE_FORWARD,
	[ ACT_MP_STAND_IDLE ] = ACT_DOD_STAND_IDLE,
	[ ACT_MP_CROUCH_IDLE ] = ACT_DOD_CROUCH_IDLE,
	[ ACT_MP_CROUCHWALK ] = ACT_DOD_CROUCHWALK_IDLE,
	[ ACT_MP_WALK ] = ACT_DOD_WALK_IDLE,
	[ ACT_MP_RUN ] = ACT_DOD_RUN_IDLE,
	[ ACT_SPRINT ] = ACT_SPRINT, -- Fix; mp_sprint?
	
	[ ACT_RANGE_ATTACK1 ] = ACT_RANGE_ATTACK1,
	[ ACT_MP_ATTACK_STAND_PRIMARYFIRE ] = ACT_DOD_PRIMARYATTACK_KNIFE, -- Fix
	[ ACT_MP_ATTACK_CROUCH_PRIMARYFIRE ] = ACT_DOD_PRIMARYATTACK_CROUCH,
	[ ACT_DOD_PRIMARYATTACK_PRONE ] = ACT_DOD_PRIMARYATTACK_PRONE,
	[ ACT_RANGE_ATTACK2 ] = ACT_RANGE_ATTACK2,
	[ ACT_DOD_SECONDARYATTACK_CROUCH ] = ACT_DOD_SECONDARYATTACK_CROUCH,
	[ ACT_DOD_SECONDARYATTACK_PRONE ] = ACT_DOD_SECONDARYATTACK_PRONE,
	
	// Hand Signals
	--[ ACT_DOD_HS_IDLE ] = ACT_DOD_HS_IDLE,
	--[ ACT_DOD_HS_CROUCH ] = ACT_DOD_HS_CROUCH
}

function SWEP:GetWeaponID()
	return self.ID
end

function SWEP:GetStatsWeaponID()
	return self.StatsID
end

function SWEP:GetAltWeaponID()
	return self.AltID
end

function SWEP:IsA( id )
	return self:GetWeaponID() == id
end

function SWEP:IsSilenced()
	return false
end

function SWEP:CanDrop()
	return self.CanDrop
end

function SWEP:ShouldDrawCrosshair()
	return self.DrawCrosshair
end

function SWEP:ShouldDrawViewModel()
	return true -- Fix, Let's not use SWEP.DrawViewModel because we're overriding a default func
end

function SWEP:ShouldDrawMuzzleFlash()
	return self.DrawMuzzleFlash
end

function SWEP:GetWeaponAccuracy( flPlayerSpeed )
	return 0	-- Fix?
end

function SWEP:HideViewModelWhenZoomed()
	return self.HideWhenZoomed
end

function SWEP:SetupDataTables()
	BaseClass.SetupDataTables( self )
	self:NetworkVar( "Vector", 0, "InitialDropVelocity" ) -- Let the engine handle this for us -- Fix
	self:NetworkVar( "Float", 1, "SmackTime" )
end

if CLIENT then
	function SWEP:GetViewModelSwayScale()
		return self.SwayScale
	end
else
end

function SWEP:GetExtraAmmoCount()
	return self.Primary.DefaultClip
end

function SWEP:GetSecondaryDeathNoticeName() -- Fix
	return "world"
end

function SWEP:GetMeleeActivity()
	return ACT_VM_SECONDARYATTACK
end

local head_hull_mins = Vector( -16, -16, -18 )
local head_hull_maxs = Vector( 16, 16, 18 )

function SWEP:FindHullIntersection( vecSrc, tr, mins, maxs, pEntity )
	local i, j, k
	local distance = 1e6
	local minmaxs = { mins, maxs }
	local vecHullEnd = vecSrc + ( ( tr.HitPos - vecSrc ) * 2 )
	local vecEnd = Vector( 0, 0, 0 )
	
	-- CTraceFilterSimple filter( pEntity, COLLISION_GROUP_NONE )
	
	local tmpTrace = util.TraceLine( {
		start = vecSrc,
		endpos = vecHullEnd,
		mask = MASK_SOLID,
		filter = pEntity,
	} )
	
	if ( tmpTrace.Fraction < 1.0 ) then
		tr = tmpTrace
		return
	end

	for i = 1, 2 do
		for j = 1, 2 do
			for k = 1, 2 do
				vecEnd.x = vecHullEnd.x + minmaxs[i].x
				vecEnd.y = vecHullEnd.y + minmaxs[j].y
				vecEnd.z = vecHullEnd.z + minmaxs[k].z
				
				tmpTrace = util.TraceLine( {
					start = vecSrc,
					endpos = vecEnd,
					mask = MASK_SOLID,
					filter = pEntity,
				} )
				if ( tmpTrace.Fraction < 1.0 ) then
					local thisDistance = ( tmpTrace.HitPos - vecSrc ):Length()
					if ( thisDistance < distance ) then
						tr = tmpTrace
						distance = thisDistance
					end
				end
			end
		end
	end
	
	return tr
end

function SWEP:Initialize()
	self.m_bInAttack = false
	self.m_iAltFireHint = 0
end

function SWEP:PlayEmptySound()
	EmitSound( "Default.ClipEmpty_Rifle", self:GetPos(), self:EntIndex() ) -- Fix, add DOD soundscapes
	
	return false
end
--[[
function SWEP:SendWeaponAnim( iActivity )
	return BaseClass:SendWeaponAnim( iActivity )
end
]]--
function SWEP:CanAttack()
	local pPlayer = self.Owner
	
	return pPlayer:CanAttack()
end

CreateConVar( "cl_autoreload", "1" )

function SWEP:ShouldAutoReload()
	local pPlayer = self.Owner
	
	return GetConVar( "cl_autoreload" ):GetBool() -- pPlayer:ShouldAutoReload() -- Fix
end

function SWEP:Think()
	local flSmackTime = self:GetSmackTime()
	local curtime = CurTime()
	--[[
	if ( flSmackTime > 0 and curtime > flSmackTime ) then
		self:Smack()
		self:SetSmackTime( -1 )
	end
	]]
	local pPlayer = self.Owner
	
	if ( not IsValid( pPlayer ) ) then return end
	
	--local m_bInReload = self:GetSequence() == ACT_VM_RELOAD
	local flNextPrimaryAttack = self:GetNextPrimaryFire()
	local flNextSecondaryAttack = self:GetNextSecondaryFire()
	local flNextAttack = flNextPrimaryAttack < flNextSecondaryAttack and flNextPrimaryAttack or flNextSecondaryAttack
	local iClip1 = self:Clip1()
	
	if ((self.m_bInReload) and (flNextAttack <= curtime)) then
		// complete the reload.
		local j = math.min( self:GetMaxClip1() - iClip1, pPlayer:GetAmmoCount( self.Primary.Ammo ) )
		
		// Add them to the clip
		iClip1 = iClip1 + j
		self:SetClip1( iClip1 )
		pPlayer:RemoveAmmo( j, self.Primary.Ammo )
		
		self.m_bInReload = false
		self:SetSequence( ACT_VM_IDLE )
		
		self:FinishReload()
	end
	
	if ((pPlayer:KeyDown( IN_ATTACK2 )) and (flNextSecondaryAttack <= curtime)) then
		if ( self:Clip2() ~= -1 and not pPlayer:GetAmmoCount( self:GetSecondaryAmmoType() ) ) then
			self.m_bFireOnEmpty = true
		end
		
		--self:SecondaryAttack()
		
		--pPlayer->m_nButtons &= ~IN_ATTACK2; -- Fix
	elseif ((pPlayer:KeyDown( IN_ATTACK ) ) and (flNextPrimaryAttack <= curtime ) and not self.m_bInAttack ) then
		if ( (iClip1 == 0) or (self:GetMaxClip1() == -1 and not pPlayer:GetAmmoCount( self:GetPrimaryAmmoType() ) ) ) then
			self.m_bFireOnEmpty = true
		end
		
		if ( self:CanAttack() ) then
			--self:PrimaryAttack()
		end
	elseif ( pPlayer:KeyDown( IN_RELOAD ) and self:GetMaxClip1() ~= WEAPON_NOCLIP and not self.m_bInReload and flNextPrimaryAttack < curtime ) then
		// reload when reload is pressed, or if no buttons are down and weapon is empty.
		self:Reload()
	
	elseif ( not ( pPlayer:KeyDown( IN_ATTACK ) or pPlayer:KeyDown( IN_ATTACK2 ) ) ) then
		// no fire buttons down
		
		self.m_bFireOnEmpty = false
		
		self.m_bInAttack = false
		
		if ( not self:IsUseable() and flNextPrimaryAttack < curtime ) then
			// Intentionally blank -- used to switch weapons here
		elseif ( self:ShouldAutoReload() and self:IsUseable() ) then
			// weapon is useable. Reload if empty and weapon has waited as long as it has to after firing
			if ( iClip1 == 0 and not (bit.band(self:GetFlags(), ITEM_FLAG_NOAUTORELOAD)) and self:GetNextPrimaryFire() < curtime ) then
				self:Reload()
				return
			end
		end
		
		self:WeaponIdle()
		return
	end
end

function SWEP:WeaponIdle()	
	if (self:GetWeaponIdleTime() > CurTime()) then
		return
	end
	
	self:SendWeaponAnim( self:GetIdleActivity() )
	
	self:SetWeaponIdleTime( CurTime() + self:SequenceDuration() )
end

function SWEP:GetIdleActivity()
	return ACT_VM_IDLE
end

function SWEP:Precache()
	// precache base first, it loads weapon scripts
	BaseClass.Precache( self )

	util.PrecacheSound( "Default.ClipEmpty_Rifle" )
end

function SWEP:DefaultDeploy( iActivity, szAnimExt )
	local pOwner = self.Owner
	if ( not IsValid( pOwner ) ) then
		return false
	end
	
	--pOwner:SetAnimationExtension( szAnimExt ) -- Fix
	
	self:SendWeaponAnim( iActivity )
	pOwner:SetNextAttack( CurTime() + self:SequenceDuration() ) -- Fix
	self:SetNextPrimaryFire( CurTime() )
	self:SetNextSecondaryFire( CurTime() )
	
	--self:SetVisible( true )
	--self:SetWeaponModelIndex( szWeaponModel ) -- Fix
	
	local vm = pOwner:GetViewModel()
	
	if ( IsValid( vm ) ) then
		//set sleeves to proper team
		if ( pOwner:Team() == TEAM_ALLIES ) then
			vm:SetSkin( SLEEVE_ALLIES )
		elseif ( pOwner:Team() == TEAM_AXIS ) then
			vm:SetSkin( SLEEVE_AXIS )
		end
	end
	
	return true
end

-- Fix; temp
SLEEVE_ALLIES = 0
SLEEVE_AXIS = 1

--[[
void CWeaponDODBase::SetWeaponModelIndex( const char *pName )
{
 	 m_iWorldModelIndex = modelinfo->GetModelIndex( pName );
}
]]
function SWEP:CanBeSelected()
	if ( not self:VisibleInWeaponSelection() ) then
		return false
	end
	
	return true
end

function SWEP:Drop( vecVelocity )
	if ( not CLIENT ) then
		if ( self.m_iAltFireHint ) then
			local pPlayer = self.Owner
			if ( pPlayer ) then
				pPlayer:StopHintTimer( self.m_iAltFireHint )
			end
		end
	end
	
	// cancel any reload in progress
	self.m_bInReload = false
	
	self:SetSmackTime( -1 )
	
	self:SetInitialDropVelocity( vecVelocity )
	
	BaseClass.Drop( self, vecVelocity )
end

function SWEP:Holster( pSwitchingTo )
	if ( not CLIENT ) then
		local pPlayer = self.Owner
		
		if ( IsValid( pPlayer ) ) then
			pPlayer:SetFOV( 0, 0 ) // reset the default FOV -- Fix second argument/should it immidiately reset?
			
			if ( self.m_iAltFireHint ) then
				pPlayer:StopHintTimer( self.m_iAltFireHint )
			end
		end
	end
	
	self.m_bInReload = false
	
	self:SetSmackTime( -1 )
	
	return BaseClass.Holster( self, pSwitchingTo )
end

function SWEP:Deploy()
	if ( not CLIENT ) then
		local pPlayer = self.Owner
		
		if ( IsValid( pPlayer ) ) then
			pPlayer:SetFOV( 0, 0 )
			
			if ( self.m_iAltFireHint ) then
				pPlayer:StartHintTimer( self.m_iAltFireHint )
			end
		end
	end
	
	return BaseClass.Deploy( self )
end

if ( CLIENT ) then
	
	--[[
	void CWeaponDODBase::OnDataChanged( DataUpdateType_t type )
	{
		if ( m_iState == WEAPON_NOT_CARRIED && m_iOldState != WEAPON_NOT_CARRIED ) 
		{
			// we are being notified of the weapon being dropped
			// add an interpolation history so the movement is smoother

			// Now stick our initial velocity into the interpolation history 
			CInterpolatedVar< Vector > &interpolator = GetOriginInterpolator();

			interpolator.ClearHistory();
			float changeTime = GetLastChangeTime( LATCH_SIMULATION_VAR );

			// Add a sample 1 second back.
			Vector vCurOrigin = GetLocalOrigin() - InitialDropVelocity;
			interpolator.AddToHead( changeTime - 1.0, &vCurOrigin, false );

			// Add the current sample.
			vCurOrigin = GetLocalOrigin();
			interpolator.AddToHead( changeTime, &vCurOrigin, false );

			Vector estVel;
			EstimateAbsVelocity( estVel );

			/*Msg( "estimated velocity ( %.1f %.1f %.1f )  initial velocity ( %.1f %.1f %.1f )\n",
				estVel.x,
				estVel.y,
				estVel.z,
				InitialDropVelocity.m_Value.x,
				InitialDropVelocity.m_Value.y,
				InitialDropVelocity.m_Value.z );*/

			OnWeaponDropped();
		}

		BaseClass::OnDataChanged( type );

		if ( GetPredictable() && !ShouldPredict() )
			ShutdownPredictable();
	}
	]]--

else

	//-----------------------------------------------------------------------------
	// Purpose: Get the accuracy derived from weapon and player, and return it
	//-----------------------------------------------------------------------------
	function SWEP:GetBulletSpread()
		local cone = VECTOR_CONE_8DEGREES
		return cone
	end
	--[[
	//-----------------------------------------------------------------------------
	// Purpose: 
	//-----------------------------------------------------------------------------
	void CWeaponDODBase::ItemBusyFrame() -- Fix; investigate BusyFrame
	{
		if( ShouldAutoReload() && !m_bInReload )
		{
			// weapon is useable. Reload if empty and weapon has waited as long as it has to after firing
			if ( m_iClip1 == 0 && !(GetWeaponFlags() & ITEM_FLAG_NOAUTORELOAD) && m_flNextPrimaryAttack < gpGlobals->curtime )
			{
				Reload();
			}
		}

		BaseClass::ItemBusyFrame();
	}
	]]--
	//-----------------------------------------------------------------------------
	// Purpose: Match the anim speed to the weapon speed while crouching
	//-----------------------------------------------------------------------------
	function SWEP:GetDefaultAnimSpeed()
		return 1.0
	end

	function SWEP:ShouldRemoveOnRoundRestart()
		if ( IsValid( self.Owner ) ) then
			return false
		else
			return true
		end
	end
	--[[
	//=========================================================
	// Materialize - make a CWeaponDODBase visible and tangible
	//=========================================================
	function SWEP:Materialize()
		if ( self:IsEffectActive( EF_NODRAW ) ) then
			self:RemoveEffects( EF_NODRAW );
			self:MuzzleFlash()
		end

		self:AddSolidFlags( FSOLID_TRIGGER );
		
		self:SetThinkFunction(self:SUB_Remove) -- I don't understand why we're trying to remove the entity right after we Materialized it
		self:SetNextThink( curtime + 1 );
		
	}

	//=========================================================
	// AttemptToMaterialize - the item is trying to rematerialize,
	// should it do so now or wait longer?
	//=========================================================
	void CWeaponDODBase::AttemptToMaterialize()
	{
		float time = g_pGameRules->FlWeaponTryRespawn( this );

		if ( time == 0 )
		{
			Materialize();
			return;
		}

		SetNextThink( gpGlobals->curtime + time );
	}

	//=========================================================
	// CheckRespawn - a player is taking this weapon, should 
	// it respawn?
	//=========================================================
	void CWeaponDODBase::CheckRespawn()
	{
		//GOOSEMAN : Do not respawn weapons!
		return;
	}

		
	//=========================================================
	// Respawn- this item is already in the world, but it is
	// invisible and intangible. Make it visible and tangible.
	//=========================================================
	function SWEP:Respawn()
	{
		// make a copy of this weapon that is invisible and inaccessible to players (no touch function). The weapon spawn/respawn code
		// will decide when to make the weapon visible and touchable.
		CBaseEntity *pNewWeapon = CBaseEntity::Create( GetClassname(), g_pGameRules->VecWeaponRespawnSpot( this ), GetAbsAngles(), GetOwner() );

		if ( pNewWeapon )
		{
			pNewWeapon->AddEffects( EF_NODRAW );// invisible for now
			pNewWeapon->SetTouch( NULL );// no touch
			pNewWeapon->SetThink( &CWeaponDODBase::AttemptToMaterialize );

			UTIL_DropToFloor( this, MASK_SOLID );

			// not a typo! We want to know when the weapon the player just picked up should respawn! This new entity we created is the replacement,
			// but when it should respawn is based on conditions belonging to the weapon that was taken.
			pNewWeapon->SetNextThink( gpGlobals->curtime + g_pGameRules->FlWeaponRespawnTime( this ) );
		}
		else
		{
			Msg( "Respawn failed to create %s!\n", GetClassname() );
		}

		return pNewWeapon;
	}

	bool CWeaponDODBase::Reload()
	{
		return BaseClass::Reload();
	}
	]]--
	--[[
	function SWEP:Spawn()
		BaseClass:Spawn()

		// Set this here to allow players to shoot dropped weapons
		self:SetCollisionGroup( COLLISION_GROUP_WEAPON )
		
		self:SetExtraAmmoCount( 0 )	//Start with no additional ammo

		--self:CollisionProp()->UseTriggerBounds( true, 10.0f ); -- Fix?
	end]] -- Fix
	--[[
	void CWeaponDODBase::SetDieThink( bool bDie )
	{
		if( bDie )
			SetContextThink( &CWeaponDODBase::Die, gpGlobals->curtime + 45.0f, "DieContext" );
		else
			SetContextThink( NULL, gpGlobals->curtime, "DieContext" );
	}

	void CWeaponDODBase::Die( void )
	{
		UTIL_Remove( this );
	}

#endif]]
end

function SWEP:_DefaultReload( iClipSize1, iClipSize2, iActivity )
	local pOwner = self.Owner
	if ( not IsValid( pOwner ) ) then
		return false
	end
	
	// If I don't have any spare ammo, I can't reload
	if ( pOwner:GetAmmoCount( self.Primary.Ammo ) <= 0 ) then
		return false
	end
	
	local bReload = false
	
	// If you don't have clips, then don't try to reload them.
	if ( self:UsesClipsForAmmo1() ) then
		// need to reload primary clip?
		local primary = math.min( iClipSize1 - self:Clip1(), pOwner:GetAmmoCount( self.Primary.Ammo ) )
		if ( primary ~= 0 ) then
			bReload = true
		end
	end
	
	if ( self:UsesClipsForAmmo2() ) then
		// need to reload secondary clip?
		local secondary = math.min( iClipSize2 - self:Clip2(), pOwner:GetAmmoCount( self.Secondary.Ammo ) )
		if ( secondary ~= 0 ) then
			bReload = true
		end
	end
	
	if ( not bReload ) then
		return false
	end
	
	if ( CLIENT ) then
		self:PlayWorldReloadSound( pOwner )
	else
		pOwner:DoAnimationEvent( PLAYERANIMEVENT_RELOAD )
	end
	
	self:SendWeaponAnim( iActivity )
	
	// Play the player's reload animation
	if ( pOwner:IsPlayer() ) then
		pOwner:SetAnimation( PLAYER_RELOAD )
	end
	
	local flSequenceEndTime = CurTime() + self:SequenceDuration()
	pOwner:SetNextAttack( flSequenceEndTime )
	self:SetNextPrimaryFire( flSequenceEndTime )
	self:SetNextSecondaryFire( flSequenceEndTime )
	
	self.m_bInReload = true
	
	return true
end

if CLIENT then
	function SWEP:PlayWorldReloadSound( pPlayer )
		if ( not IsValid( pPlayer ) ) then return end
		
		local shootsound = self:GetShootSound( RELOAD )
		if ( not shootsound ) then
			return
		end
		
		// Play weapon sound from the owner
		EmitSound( shootsound, self:GetPos(), pPlayer:EntIndex(), nil, 0.0 ) -- Fix, Uh, we're not playing it?
	end
end

function SWEP:IsUseable()
	local pPlayer = self.Owner
	
	if ( self:Clip1() <= 0 ) then
		if ( pPlayer:GetAmmoCount( self:GetPrimaryAmmoType() ) <= 0 and self:GetMaxClip1() ~= -1 ) then
			// clip is empty (or nonexistant) and the player has no more ammo of this type.
			return false
		end
	end
	
	return true
end

if ( SERVER ) then
	local dod_meleeattackforcescale = CreateConVar( "dod_meleeattackforcescale", "8.0", { FCVAR_CHEAT, FCVAR_GAMEDLL } )
end
--[[
void CWeaponDODBase::RifleButt( void )
{
	//MeleeAttack( 60, MELEE_DMG_BUTTSTOCK | MELEE_DMG_SECONDARYATTACK, 0.2f, 0.9f );
}

void CWeaponDODBase::Bayonet( void )
{
	//MeleeAttack( 60, MELEE_DMG_BAYONET | MELEE_DMG_SECONDARYATTACK, 0.2f, 0.9f );
}
]]--
function SWEP:Punch()
	self:MeleeAttack( 60, bit.bor( MELEE_DMG_FIST, MELEE_DMG_SECONDARYATTACK ), 0.2, 0.4 )
end

//--------------------------------------------
// iDamageAmount - how much damage to give
// iDamageType - DMG_ bits 
// flDmgDelay - delay between attack and the giving of damage, usually timed to animation
// flAttackDelay - time until we can next attack 
//--------------------------------------------
function SWEP:MeleeAttack( iDamageAmount, iDamageType, flDmgDelay, flAttackDelay )
	if ( not self:CanAttack() ) then
		return
	end

	local pPlayer = self.Owner

	if ( SERVER ) then
		// Move other players back to history positions based on local player's lag
		pPlayer:LagCompensation( true )
	end

	local vForward, vRight, vUp = AngleVectors( pPlayer:EyeAngles() )
	local vecSrc = pPlayer:GetShootPos()
	local vecEnd = vecSrc + vForward * 48

	local iTraceMask = bit.bor( MASK_SOLID, CONTENTS_HITBOX, CONTENTS_DEBRIS )

	local tr = util.TraceLine( {
		start = vecSrc,
		endpos = vecEnd,
		mask = iTraceMask
	} )

	local rayExtension = 40.0
	local tr = util.ClipTraceToPlayers( vecSrc, vecEnd + vForward * rayExtension, iTraceMask, filter, tr )

	// If the exact forward trace did not hit, try a larger swept box 
	if ( tr.Fraction >= 1.0 ) then
		local head_hull_mins = Vector( -16, -16, -18 )
		local head_hull_maxs = Vector( 16, 16, 18 )
		
		util.TraceHull( {
			start = vecSrc,
			endpos = vecEnd,
			maxs = head_hull_maxs,
			mins = head_hull_mins,
			filter = filter,
			mask = MASK_SOLID,
			output = tr
		} )
		
		if ( tr.Fraction < 1.0 ) then
			// Calculate the point of intersection of the line (or hull) and the object we hit
			// This is and approximation of the "best" intersection
			local pHit = tr.Entity
			if ( not IsValid( pHit ) or pHit:IsBSPModel() ) then
				self:FindHullIntersection( vecSrc, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, pPlayer )
			end
			vecEnd = tr.HitPos	// This is the point on the actual surface (the hull could have hit space)

			// Make sure it is in front of us
			local vecToEnd = vecEnd - vecSrc
			vecToEnd:Normalize( vecToEnd )

			// if zero length, always hit
			if ( vecToEnd:Length() > 0 ) then
				local dot = vForward:Dot( vecToEnd )

				// sanity that our hit is within range
				if ( math.abs(dot) < 0.95 ) then
					// fake that we actually missed
					tr.fraction = 1.0
				end
			end
		end
	end

	self:WeaponSound( MELEE_MISS );

	local bDidHit = ( tr.Fraction < 1.0 )

	if ( bDidHit ) then	//if the swing hit 	
		// delay the decal a bit
		self.m_trHit = tr

		// Store the ent in an EHANDLE, just in case it goes away by the time we get into our think function.
		self.m_pTraceHitEnt = tr.Entity 

		self.m_iSmackDamage = iDamageAmount
		self.m_iSmackDamageType = iDamageType

		self:SetSmackTime( CurTime() + flDmgDelay )
	end

	self:SendWeaponAnim( self:GetMeleeActivity() )

	// player animation
	pPlayer:DoAnimationEvent( PLAYERANIMEVENT_ATTACK_SECONDARY ) -- Fix; originally PLAYERANIMEVENT_SECONDARY_ATTACK
	
	-- Fix; should we SetNextAttack here?
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

//Think function to delay the impact decal until the animation is finished playing
function SWEP:Smack()
	local pPlayer = self.Owner
	
	if ( not IsValid( pPlayer ) ) then return end

	local vForward, vRight, vUp = AngleVectors( pPlayer:EyeAngles() )
	local vecSrc	= pPlayer:GetShootPos()
	local vecEnd	= vecSrc + vForward * 48

	local iTraceMask = bit.bor( MASK_SOLID, CONTENTS_HITBOX, CONTENTS_DEBRIS )

	local tr = util.TraceLine( {
		start = vecSrc,
		endpos = vecEnd,
		mask = iTraceMask
	} )

	local rayExtension = 40.0
	tr = util.ClipTraceToPlayers( vecSrc, vecEnd + vForward * rayExtension, iTraceMask, filter, tr )

	// If the exact forward trace did not hit, try a larger swept box 
	if ( tr.Fraction >= 1.0 ) then
		local head_hull_mins = Vector( -16, -16, -18 )
		local head_hull_maxs = Vector( 16, 16, 18 )
		
		tr = util.TraceHull( {
			start = vecSrc,
			endpos = vecEnd,
			maxs = head_hull_maxs,
			mins = head_hull_mins,
			filter = filter,
			mask = MASK_SOLID,
		} )
		
		if ( tr.Fraction < 1.0 ) then
			// Calculate the point of intersection of the line (or hull) and the object we hit
			// This is and approximation of the "best" intersection
			local pHit = tr.Entity
			if ( not IsValid( pHit ) or self:IsBSPModel() ) then
				self:FindHullIntersection( vecSrc, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, pPlayer )
			end
		end
	end
	
	-- self.m_trHit = tr -- Let's set this after we dispatch the attack
	
	if ( not IsValid( tr.Entity ) or ( tr.HitSky ) ) then 
		return
	end
	
	if ( tr.Fraction == 1.0 ) then
		return
	end
	
	if ( tr.Entity:IsPlayer() ) then
		if ( bit.band( self.m_iSmackDamageType, MELEE_DMG_STRONGATTACK ) ) then
			self:WeaponSound( SPECIAL1 )
		else
			self:WeaponSound( MELEE_HIT )
		end
	else
		self:WeaponSound( MELEE_HIT_WORLD )
	end
	
	local iDamageType = bit.bor( DMG_CLUB, DMG_NEVERGIB )
	
	if ( not CLIENT ) then
		//if they hit the bounding box, just assume a chest hit
		if ( tr.HitGroup == HITGROUP_GENERIC ) then
			tr.HitGroup = HITGROUP_CHEST
		end
		
		local flDamage = self.m_iSmackDamage
		
		local info = DamageInfo()
		info:SetInflictor( pPlayer )
		info:SetAttacker( pPlayer )
		info:SetDamage( flDamage )
		info:SetDamageType( iDamageType )
		
		if ( bit.band( self.m_iSmackDamageType, MELEE_DMG_SECONDARYATTACK ) ) then
			--info:SetDamageCustom( MELEE_DMG_SECONDARYATTACK )
		end
		
		local flScale = (1.0 / flDamage) * GetConVar( "dod_meleeattackforcescale" ):GetFloat()
		
		local vecForceDir = vForward
		
		local info = CalculateMeleeDamageForce( info, vecForceDir, tr.HitPos, flScale )
		
		if ( tr.Entity == pPlayer ) then return end
		
		self.m_trHit = tr.Entity:DispatchTraceAttack( info, tr, vForward ) -- Fix; should we be overriding this? Also, should we network clientside?
		-- self:ApplyMultiDamage() -- Fix
	else
		self.m_trHit = tr -- Fixxxxxxx
	end
	
	local data = EffectData()
	data:SetOrigin( tr.HitPos )
	data:SetStart( tr.StartPos )
	data:SetSurfaceProp( tr.SurfaceProps )
	data:SetHitBox( tr.HitBox )
	
	if ( CLIENT ) then
		data:SetEntity( tr.Entity )
	else
		data:SetEntIndex( tr.Entity:EntIndex() )
	end	
	
	if ( not CLIENT ) then -- Fix fix fix; we are using a recipient filter for DispatchEffect, however, it's only serverside. Is it networked?
		local effectfilter = RecipientFilter()
		effectfilter:AddPAS( tr.HitPos )
		effectfilter:RemovePlayer( pPlayer )
	end
	
	data:SetAngles( pPlayer:GetAngles() )
	data:SetFlags( 0x1 )	//IMPACT_NODECAL
	data:SetDamageType( iDamageType )
	
	local bHitPlayer = IsValid( tr.Entity ) and tr.Entity:IsPlayer()
	
	// don't do any impacts if we hit a teammate and ff it off
	if ( bHitPlayer and tr.Entity:Team() == pPlayer:Team() and not GetConVar( "friendlyfire" ):GetBool() ) then
		return
	end
	
	if ( bHitPlayer and SERVER ) then -- Temp fix; running serverside for recipientfilter
		util.Effect( "Impact", data, true, effectfilter )
	elseif ( bit.band( self.m_iSmackDamageType, MELEE_DMG_EDGE ) and SERVER ) then
		data:SetDamageType( DMG_SLASH )
		util.Effect( "KnifeSlash", data, true, effectfilter )
	end
end

if ( CLIENT ) then
	local g_lateralBob = 0
	local g_verticalBob = 0
	
	-- local cl_bobcycle = CreateClientConVar( "cl_bobcycle", "0.8" -- Fix; do this shit convar stuff later
	
	function SWEP:FireAnimationEvent( origin, angles, event, options )
		local iOptions = tonumber( options )
		local pViewModel = self.Owner:GetViewModel()
		
		if ( not IsValid( pViewModel ) ) then return end
	
		if ( event == 5001 ) then
			if ( self:ShouldDrawMuzzleFlash() ) then
				local data = EffectData()
				data:SetFlags( iOptions ) -- Fix
				data:SetEntity( pViewModel )
				data:SetAttachment( 1 )
				
				local iFlashType = ( iOptions % 10 ) % NUM_MUZZLE_FLASH_TYPES
				
				//3 = mg flash
				//0-2 = normal flash
				
				data:SetHitBox( iFlashType )
				data:SetMagnitude( ( iOptions / 10 ) * 0.1 )
				
				util.Effect( "DOD_MuzzleFlash", data )
			end
			return true
		elseif ( event == 6002 ) then
			local data = EffectData()
			data:SetHitBox( iOptions )
			data:SetEntity( IsValid( self.Owner ) and self.Owner )
			
			local attachment = pViewModel:GetAttachment( 2 )
			
			data:SetOrigin( attachment.Pos )
			data:SetAngles( attachment.Ang )
			
			util.Effect( "DOD_EjectBrass", data )
			return true
		end
		
		return BaseClass.FireAnimationEvent( self, origin, angles, event, options )
	end
	
	function SWEP:ShouldAutoEjectBrass()
		local pLocalPlayer = LocalPlayer()
		if ( not IsValid( pLocalPlayer ) ) then
			return true
		end
		
		local flMaxDistSqr = 250 ^ 2
		
		local flDistSqr = pLocalPlayer:EyePos():DistToSqr( self:GetOrigin() )
		return ( flDistSqr < flMaxDistSqr )
	end
	
	function SWEP:GetEjectBrassShellType()
		return 1 -- Fix
	end
	
else
	
	function SWEP:AddViewmodelBob( viewmodel, origin, angles )
	end
	
	function SWEP:CalcViewmodelBob()
		return 0.0
	end
	--[[
	function SWEP:Use( pActivator, pCaller, useType, values ) -- Fix; can weapons entities even be called like this?
		if ( self:CanDrop() == false ) then
			return
		end
		
		if ( IsValid( pPlayer ) ) then
			pActivator:PickupObject( self )
		end
	end]]
end
