// How many times to display altfire hud hints (per weapon)
WEAPON_ALTFIRE_HUD_HINT_COUNT = 1
WEAPON_RELOAD_HUD_HINT_COUNT = 1

//Start with a constraint in place (don't drop to floor)
SF_WEAPON_START_CONSTRAINED	= bit.lshift( 1, 0 )	
SF_WEAPON_NO_PLAYER_PICKUP	= bit.lshift( 1, 1 )
SF_WEAPON_NO_PHYSCANNON_PUNT = bit.lshift( 1, 2 )

// entity capabilities
// These are caps bits to indicate what an object's capabilities (currently used for +USE, save/restore and level transitions)
FCAP_MUST_SPAWN	= 0x00000001		// Spawn after restore
FCAP_ACROSS_TRANSITION = 0x00000002		// should transfer between transitions 
// UNDONE: This will ignore transition volumes (trigger_transition), but not the PVS!!!
FCAP_FORCE_TRANSITION = 0x00000004		// ALWAYS goes across transitions
FCAP_NOTIFY_ON_TRANSITION = 0x00000008		// Entity will receive Inside/Outside transition inputs when a transition occurs

FCAP_IMPULSE_USE = 0x00000010		// can be used by the player
FCAP_CONTINUOUS_USE	= 0x00000020		// can be used by the player
FCAP_ONOFF_USE = 0x00000040		// can be used by the player
FCAP_DIRECTIONAL_USE = 0x00000080		// Player sends +/- 1 when using (currently only tracktrains)
// NOTE: Normally +USE only works in direct line of sight.  Add these caps for additional searches
FCAP_USE_ONGROUND = 0x00000100
FCAP_USE_IN_RADIUS = 0x00000200
FCAP_SAVE_NON_NETWORKABLE = 0x00000400

FCAP_MASTER = 0x10000000		// Can be used to "master" other entities (like multisource)
FCAP_WCEDIT_POSITION = 0x40000000		// Can change position and update Hammer in edit mode
FCAP_DONT_SAVE = 0x80000000		// Don't save this

SWEP.m_fMinRange1 = 65
SWEP.m_fMinRange2 = 65
SWEP.m_fMaxRange1 = 1024
SWEP.m_fMaxRange2 = 1024

SWEP.m_bReloadsSingly = false

EMPTY = 1
SINGLE = 2
SINGLE_NPC = 3
WPN_DOUBLE = 4 // Can't be "DOUBLE" because windows.h uses it.
DOUBLE_NPC = 5
BURST = 6
RELOAD = 7
RELOAD_NPC = 8
MELEE_MISS = 9
MELEE_HIT = 10
MELEE_HIT_WORLD = 11
SPECIAL1 = 12
SPECIAL2 = 13
SPECIAL3 = 14

SWEP.HoldType = "normal"

SWEP.Primary =
{
	Ammo = -1,
	ClipSize = -1
}

SWEP.Secondary =
{
	Ammo = -1,
	ClipSize = -1
}

SWEP.ShootSounds = {
	"", -- EMPTY
	"", -- SINGLE
	"", -- SINGLE_NPC
	"", -- WPN_DOUBLE
	"", -- DOUBLE_NPC
	"", -- BURST
	"", -- RELOAD
	"", -- RELOAD_NPC
	"", -- MELEE_MISS
	"", -- MELEE_HIT
	"", -- MELEE_HIT_WORLD
	"", -- SPECIAL1
	"", -- SPECIAL2,
	"", -- SPECIAL3
}

function SWEP:Initialize()
	self:SetHoldType( self.HoldType )
	
	self.m_iReloadHintCount = 0
	self.m_iAltFireHudHintCount = 0
	self.m_flHudHintMinDisplayTime = 0
end

function SWEP:OnRemove()
	-- We do nothing here since we don't have to worry about weapon constraints
end

function SWEP:SetupDataTables()
	-- self:NetworkVar( "Entity", nil, "Owner" )
	-- self:NetworkVar( "Float", nil, "PrimaryAttack" )
	-- self:NetworkVar( "Float", nil, "SecondaryAttack" )
	self:NetworkVar( "Float", 0, "WeaponIdleTime" )
	-- self:NetworkVar( "Int", nil, "ViewModelIndex" )
	-- self:NetworkVar( "Int", nil, "WorldModelIndex" )
	-- self:NetworkVar( "Int", 0, "State" ) // See WEAPON_* definitions
	-- self:NetworkVar( "Int", nil, "PrimaryAmmoType" )
	-- self:NetworkVar( "Int", nil, "SecondaryAmmoType" )
	-- self:NetworkVar( "Int", nil, "Clip1" )
	-- self:NetworkVar( "Int", nil, "Clip2" )
end

function SWEP:Precache()
	util.PrecacheModel( self.ViewModel )
	util.PrecacheModel( self.WorldModel )
	
	for _, sound in ipairs( self.ShootSounds ) do
		util.PrecacheSound( sound )
	end
end

function SWEP:GetShootSound( iIndex )
	return self.ShootSounds[ iIndex ]
end

function SWEP:GetViewModel()
	return self.ViewModel
end

function SWEP:GetWorldModel()
	return self.WorldModel
end

function SWEP:GetAnimPrefix()
	return self.AnimationPrefix
end

function SWEP:GetPrintName()
	return self.PrintName -- Fix? Already declared; should this be shared?
end

function SWEP:GetMaxClip1()
	return self.Primary.ClipSize
end

function SWEP:GetMaxClip2()
	return self.Secondary.ClipSize
end

function SWEP:GetDefaultClip1()
	return self.Primary.DefaultClip
end

function SWEP:GetDefaultClip2()
	return self.Secondary.DefaultClip
end

function SWEP:UsesClipsForAmmo1()
	return ( self:GetMaxClip1() ~= WEAPON_NOCLIP )
end

function SWEP:IsMeleeWeapon()
	return self.m_bMeleeWeapon
end

function SWEP:UsesClipsForAmmo2()
	return ( self:GetMaxClip2() ~= WEAPON_NOCLIP )
end

function SWEP:GetWeight()
	return self.Weight
end

function SWEP:AllowsAutoSwitchTo()
	return self.AutoSwitchTo
end

function SWEP:AllowsAutoSwtichFrom()
	return self.AutoSwitchFrom
end

function SWEP:GetWeaponFlags()
	return self:GetFlags() -- Fix
end

function SWEP:GetSlot()
	return self.Slot
end

function SWEP:GetPosition()
	return self.SlotPos
end

function SWEP:GetClassName()
	return self.ClassName
end

function SWEP:GetSpriteActive()
end

-- 10,000 accessors later

function SWEP:GetOwner()
	return self.Owner
end
--[[
function SWEP:SetOwner( owner )
	self.Owner = owner
end]]

function SWEP:IsAllowedToSwitch()
	return true
end

function SWEP:CanBeSelected()
	if ( not self:VisibleInWeaponSelection() ) then
		return false
	end
	
	return self:HasAmmo()
end

function SWEP:HasAmmo()
	// Weapons with no ammo types can always be selected
	if ( self.Primary.Ammo == -1 and self.Secondary.Ammo == -1 ) then
		return true
	elseif ( bit.band( self:GetFlags(), ITEM_FLAG_SELECTONEMPTY ) ) then
		return true
	end
	
	local player = self.Owner
	if ( not IsValid( player ) ) then 
		return false
	end
	
	return ( self:Clip1() > 0 or player:GetAmmoCount( self.Primary.Ammo ) or self:Clip2() > 0 or player:GetAmmoCount( self.Secondary.Ammo ) )
end

function SWEP:VisibleInWeaponSelection()
	return true
end

function SWEP:HasWeaponIdleTimeElapsed()
	if ( CurTime() > self:GetWeaponIdleTime() ) then
		return true
	end
	
	return false
end

function SWEP:Drop( vecVelocity )
	-- Cool; Fix. Let's add some really sick drop system!
end

function SWEP:MakeTracer( vecTracerSrc, tr, iTracerType )
	local pOwner = self.Owner
	
	if ( not IsValid( pOwner ) ) then
		-- self.BaseClass( vecTracerSrc, tr, iTracerType ) -- Fix
		return
	end
	
	local pszTracerName = self:GetTracerType()
	
	local iEntIndex = pOwner:EntIndex()
	
	if ( not game.SinglePlayer() ) then
		iEntIndex = self:EntIndex()
	end
	
	local iAttachment = self:GetTracerAttachment()
	
	if ( iTracerType == TRACER_LINE or iTracerType == TRACER_LINE_AND_WHIZ ) then
		util.Tracer( vecTracerSrc, tr.endpos, iEntIndex, iAttachment, 0.0, true, pszTracerName )
	end
end -- Fix; the Source implementation is so shitty

function SWEP:ShouldDisplayAltFireHUDHint()
	if ( self.m_iAltFireHudHintCount >= WEAPON_RELOAD_HUD_HINT_COUNT ) then
		return false
	elseif ( self:UsesSecondaryAmmo() and self:HasSecondaryAmmo() ) then
		return true
	elseif ( not self:UsesSecondaryAmmo() and self:HasPrimaryAmmo() ) then
		return true
	end
	
	return false
end

function SWEP:DisplayAltFireHudHint()
--[[
#if !defined( CLIENT_DLL )
	CFmtStr hint;
	hint.sprintf( "#valve_hint_alt_%s", GetClassname() );
	UTIL_HudHintText( GetOwner(), hint.Access() );
	m_iAltFireHudHintCount++;
	m_bAltFireHudHintDisplayed = true;
	m_flHudHintMinDisplayTime = gpGlobals->curtime + MIN_HUDHINT_DISPLAY_TIME;
#endif//CLIENT_DLL]]-- Fix
end
--[[
void CBaseCombatWeapon::RescindAltFireHudHint()
{
#if !defined( CLIENT_DLL )
	Assert(m_bAltFireHudHintDisplayed);
	
	UTIL_HudHintText( GetOwner(), "" );
	--m_iAltFireHudHintCount;
	m_bAltFireHudHintDisplayed = false;
#endif//CLIENT_DLL
}
]]

function SWEP:ShouldDisplayReloadHUDHint()
	if ( self.m_iReloadHudHintCount >= WEAPON_RELOAD_HUD_HINT_COUNT ) then
		return false
	end
	
	local pOwner = self.Owner
	
	if ( IsValid( self.Owner ) and pOwner:IsPlayer() and self:UsesClipsForAmmo1() and self:Clip1() < (self:GetMaxClip1() / 2) ) then
		if ( pOwner:GetAmmoCount( self.Primary.Ammo ) > 0 ) then
			return true
		end
	end
	
	return false
end
--[[
void CBaseCombatWeapon::DisplayReloadHudHint()
{
#if !defined( CLIENT_DLL )
	UTIL_HudHintText( GetOwner(), "valve_hint_reload" );
	m_iReloadHudHintCount++;
	m_bReloadHudHintDisplayed = true;
	m_flHudHintMinDisplayTime = gpGlobals->curtime + MIN_HUDHINT_DISPLAY_TIME;
#endif//CLIENT_DLL
}
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
void CBaseCombatWeapon::RescindReloadHudHint()
{
#if !defined( CLIENT_DLL )
	Assert(m_bReloadHudHintDisplayed);

	UTIL_HudHintText( GetOwner(), "" );
	--m_iReloadHudHintCount;
	m_bReloadHudHintDisplayed = false;
#endif//CLIENT_DLL
}
]]

if ( CLIENT ) then
	function SWEP:FireAnimationEvent( origin, angles, event, options )
		return false
	end
end

function SWEP:SendViewModelAnim( nSequence )
	if ( CLIENT ) then
		if ( not self:GetPredictable() ) then
			return
		end
	end
	
	if ( nSequence < 0 ) then
		return
	end
	
	local pOwner = self.Owner
	
	if ( not IsValid( pOwner ) ) then
		return
	end
	
	local vm = pOwner:GetViewModel()
	
	if ( not IsValid( vm ) ) then
		return
	end
	
	self:SetViewModel() -- Fix; is this needed?
	vm:SendViewModelMatchingSequence( nSequence )
end

function SWEP:GetViewModelSequenceDuration()
	local pOwner = self.Owner
	if ( not IsValid( self.Owner ) ) then
		return 0
	end
	
	local vm = pOwner:GetViewModel()
	if ( not IsValid( vm ) ) then
		return 0
	end
	
	self:SetViewModel()
	return vm:SequenceDuration()
end

function SWEP:IsViewModelSequenceFinished()
	// These are not valid activities and always complete immediately
	if ( self:GetActivity() == ACT_RESET or self:GetActivity() == ACT_INVALID ) then
		return true
	end
	
	local pOwner = self.Owner
	if ( not IsValid ( pOwner ) ) then
		return false
	end
	
	local vm = pOwner:GetViewModel()
	if ( not IsValid( vm ) ) then
		return false
	end
	
	return vm:IsSequenceFinished() -- Fix; add this function
end

function SWEP:SetViewModel()
	local pOwner = self.Owner
	if ( not IsValid ( pOwner ) ) then
		return false
	end
	
	local vm = pOwner:GetViewModel()
	if ( not IsValid( vm ) ) then
		return false
	end
	
	vm:SetWeaponModel( self:GetViewModel() ) -- Fix; is this done by the engine?
end
--[[
function SWEP:SendWeaponAnim( iActivity )
	return self:SetIdealActivity( iActivity ) -- Fix? Is this needed?
end
]]--
function SWEP:HasAnyAmmo()
	// If I don't use ammo of any kind, I can always fire
	if ( not self:UsesPrimaryAmmo() and not self:UsesSecondaryAmmo() ) then
		return true
	end
	
	// Otherwise, I need ammo of either type
	return ( self:HasPrimaryAmmo() or self:HasSecondaryAmmo() )
end

function SWEP:HasPrimaryAmmo()
	// If I use a clip, and have some ammo in it, then I have ammo
	if ( self:UsesClipsForAmmo1() ) then
		if ( self:Clip1() > 0 ) then
			return true
		end
	end
	
	// Otherwise, I have ammo if I have some in my ammo counts
	local pOwner = self.Owner
	if ( IsValid( pOwner ) ) then
		if ( pOwner:GetAmmoCount( self.Primary.Ammo ) > 0 ) then
			return true
		end
	else
		// No owner, so return how much primary ammo I have along with me
		-- Whelp, you solved the mystery. Go back and check through redundant validity checks, since SWEPs don't run with no owner
		if ( self:GetPrimaryAmmoCount() > 0 ) then
			return true
		end
	end
	
	return false
end

function SWEP:HasSecondaryAmmo()
	// If I use a clip, and have some ammo in it, then I have ammo
	if ( self:UsesClipsForAmmo2() ) then
		if ( self:Clip2() > 0 ) then
			return true
		end
	end
	
	// Otherwise, I have ammo if I have some in my ammo counts
	local pOwner = self.Owner
	if ( IsValid( pOwner ) ) then
		if ( pOwner:GetAmmoCount( self.Secondary.Ammo ) > 0 ) then
			return true
		end
	end
	
	return false
end

function SWEP:UsesPrimaryAmmo()
	if ( self.Primary.Ammo ~= "none" or self.Primary.ClipSize == -1 ) then
		return false
	end
	
	return true
end

function SWEP:UsesSecondaryAmmo()
	if ( self.Secondary.Ammo ~= "none" or self.Secondary.ClipSize == -1 ) then
		return false
	end
	
	return true
end

function SWEP:SetWeaponVisible( visible )
	local vm
	
	local pOwner = self.Owner
	if ( IsValid( pOwner ) ) then
		vm = pOwner:GetViewModel()
	end
	
	if ( visible ) then
		self:RemoveEffects( EF_NODRAW )
		if ( IsValid( vm ) ) then
			vm:RemoveEffects( EF_NODRAW )
		end
	else
		self:AddEffects( EF_NODRAW )
		if ( IsValid( vm ) ) then
			vm:RemoveEffects( EF_NODRAW )
		end
	end
end

function SWEP:IsWeaponVisible()
	local vm
	local pOwner = self.Owner
	if ( IsValid( pOwner ) ) then
		vm = pOwner:GetViewModel()
		if ( IsValid( vm ) ) then
			return ( not vm:IsEffectActive( EF_NODRAW ) )
		end
	end
end

function SWEP:ReloadOrSwitchWeapon()
	local pOwner = self.Owner
	if ( not IsValid( pOwner ) ) then return end
	
	local curtime = CurTime()
	local flNextPrimaryAttack = self:GetNextPrimaryFire()
	local flNextSecondaryAttack = self:GetNextSecondaryFire()
	
	self.m_bFireOnEmpty = false
	
	// If we don't have any ammo, switch to the next best weapon
	if ( not self:HasAnyAmmo() and flNextPrimaryAttack < curtime and flNextSecondaryAttack < curtime ) then
		// weapon isn't useable, switch.
		if ( ( bit.band(self:GetFlags(), ITEM_FLAG_NOAUTOSWITCHEMPTY) == false ) and ( GM:SwitchToNextBestWeapon( pOwner, self ) ) ) then -- Fix; add this function
			self:SetNextPrimaryFire( curtime + 0.3 )
			return true
		end
	else
		// Weapon is useable. Reload if empty and weapon has waited as long as it has to after firing
		if ( self:UsesClipsForAmmo1() and (self:Clip1() == 0) and bit.band(self:GetFlags(), ITEM_FLAG_NOAUTORELOAD) == false and flNextPrimaryAttack < curtime and flNextSecondaryAttack < curtime ) then
			if ( self:Reload() ) then
				return true
			end
		end
	end
	
	return false
end

function SWEP:DefaultDeploy( iActivity, szAnimExt )
	// Msg( "deploy %s at %f\n", GetClassname(), gpGlobals->curtime );

	// Weapons that don't autoswitch away when they run out of ammo 
	// can still be deployed when they have no ammo.
	if ( not self:HasAnyAmmo() and self:AllowsAutoSwtichFrom() ) then
		return false
	end
	
	local pOwner = self.Owner
	if ( IsValid( pOwner ) ) then
		// Dead men deploy no weapons
		if ( not pOwner:Alive() ) then
			return false
		end
		
		pOwner:SetAnimationExtension( szAnimExt ) -- Fix
		
		self:SetViewModel() -- Fix; not needed
		self:SendWeaponAnim( iActivity )
		
		pOwner:SetNextAttack( curTime + self:SequenceDuration() )
	end
	
	// Can't shoot again until we've finished deploying
	self:SetNextPrimaryFire( CurTime() + self:SequenceDuration() )
	self:SetNextSecondaryFire( CurTime() + self:SequenceDuration() )
	self.m_flHudHintMinDisplayTime = 0
	
	self.m_bAltFireHudHintDisplayed = false
	self.m_bReloadHudHintDisplayed = false
	self.m_flHudHintPollTime = CurTime() + 5.0
	
	self:SetWeaponVisible( true )
	
/*

This code is disabled for now, because moving through the weapons in the carousel 
selects and deploys each weapon as you pass it. (sjb)

*/

	 -- self:SetContextThink() -- Fix
	 
	 return true
end

function SWEP:Deploy()
	return self:DefaultDeploy( self:GetDrawActivity(), self:GetAnimPrefix() )
end

function SWEP:GetDrawActivity()
	return ACT_VM_DRAW
end

function SWEP:SetThinkFunction( func )
	self.ThinkFunc = func
end

function SWEP:GetThinkFunction()
	return self.ThinkFunc
end

function SWEP:Holster( pSwitchingTo )

	// cancel any reload in progress.
	self.m_bInReload = false
	
	// kill any think functions
	--self:SetThinkFunction( function() end ) -- Fix; get lua exposure instead of a dumb hack
	
	// Send holster animation
	self:SendWeaponAnim( ACT_VM_HOLSTER )
	--[[
	// Some weapon's don't have holster anims yet, so detect that
	local flSequenceDuration = 0
	if ( self:GetActivity() == ACT_VM_HOLSTER ) then
		flSequenceDuration = self:SequenceDuration()
	end
	
	local pOwner = self.Owner
	if ( IsValid( pOwner ) ) then
		pOwner:SetNextAttack( CurTime() + flSequenceDuration )
	end
	
	// If we don't have a holster anim, hide immediately to avoid timing issues
	if ( not flSequenceDuration ) then
		self:SetVisible( false ) -- fix
	else
		// Hide the weapon when the holster animation's finished
		--self:SetContextThink() -- Fix
	end
	
	// if we were displaying a hud hint, squelch it.
	if ( self.m_flHudHintMinDisplayTime and CurTime() < self.m_flHudHintMinDisplayTime ) then
		if( self.m_bAltFireHudHintDisplayed ) then
			self:RescindAltFireHudHint()
		end
		if( self.m_bReloadHudHintDisplayed ) then
			self:RescindReloadHudHint()
		end
	end
	]]
	return true
end

function SWEP:CanHolster()
	return true
end

if ( SERVER ) then
	function SWEP:InputHideWeapon( inputdata )
		// Only hide if we're still the active weapon. If we're not the active weapon
		if ( IsValid( self.Owner ) ) then
			self:SetWeaponVisible( false )
		end
	end
end

function SWEP:HideThink()
	// Only hide if we're still the active weapon. If we're not the active weapon
	if ( IsValid( self.Owner ) ) then
		self:SetWeaponVisible( false )
	end
end

function SWEP:ItemFrame()
end

SWEP.ThinkFunc = SWEP.ItemFrame

function SWEP:Think() -- Fix
	self.ThinkFunc()
end

-- Fix; ItemBusyFrame = PostThink. Find an implementation for this?

function SWEP:HandleFireOnEmpty()
	// If we're already firing on empty, reload if we can
	if ( self.m_bFireOnEmpty ) then
		self:ReloadOrSwitchWeapons()
		self.m_fFireDuration = 0.0
	else
		if ( self.m_flNextEmptySoundTime < CurTime() ) then
			self:WeaponSound( EMPTY )
			self.m_flNextEmptySoundTime = CurTime() + 0.5
		end
		
		self.m_bFireonEmpty = true
	end
end

function SWEP:GetBulletType()
	return 0 -- Fix
end

function SWEP:GetBulletSpread()
	local cone = VECTOR_CONE_15DEGREES
	return cone
end
--[[
function SWEP:GetProficiencyValues()
end]]-- Fix

function SWEP:GetFireRate()
	return 0 -- Fix
end

function SWEP:GetMinBurst()
	return 1
end

function SWEP:GetMaxBurst()
	return 1
end

function SWEP:GetMinRestTime()
	return 0.3
end

function SWEP:GetMaxRestTime()
	return 0.6
end

function SWEP:GetRandomBurst()
	return random.RandomInt( self:GetMinBurst(), self:GetMaxBurst() )
end

function SWEP:GetMaxAutoAimDeflection()
	return 0.99
end

function SWEP:WeaponAutoAimScale()
	return 1.0
end

function SWEP:StartSprinting() -- Fix; default shit?
	return false
end

function SWEP:StopSprinting()
	return false
end

function SWEP:GetDamage( flDistance, iLocation )
	return 0.0
end

function SWEP:GetActivity()
	return m_Activity -- Fix, tracked internally?
end

function SWEP:CalcViewmodelBob()
	return 0.0
end

function SWEP:ShouldShowControlPanels()
	return true
end

function SWEP:CanBePickedUpByNPCs()
	return true
end

function SWEP:GetPrimaryAmmoType()
	return self.Primary.Ammo -- Fix
end

function SWEP:GetSecondaryAmmoType()
	return self.Secondary.Ammo
end

--[[
function SWEP:Clip1()
	return self.m_iClip1 -- Fix; would be cool if you overrided the clip shit, but you'd have to do it the right way
end
]]

-- this is used for ground weapons. Fix this if you'll end up needing ammo counts for that
--[[
function SWEP:GetPrimaryAmmoCount()
	return self.m_iPrimaryAmmoCount
end]]

function SWEP:WeaponSound( sound_type, soundtime )
	// If we have some sounds from the weapon classname.txt file, play a random one of them
	local shootsound = self:GetShootSound( sound_type )
	if ( not shootsound ) then
		return
	end
	
	local params
	-- Fix; do all this sound shit
end

function SWEP:DefaultReload( iClipSize1, iClipSize2, iActivity )
	print( "run" )
	
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
		self:WeaponSound( RELOAD )
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

function SWEP:Reload()
	return self:DefaultReload( self:GetMaxClip1(), self:GetMaxClip2(), ACT_VM_RELOAD )
end

function SWEP:WeaponIdle()
	//Idle again if we've finished
	if ( self:HasWeaponTimeElapsed() ) then
		self:SendWeaponAnim( ACT_VM_IDLE )
	end
end

function SWEP:GetPrimaryAttackActivity()
	return ACT_VM_PRIMARYATTACK
end

function SWEP:GetSecondaryAttackActivity()
	return ACT_VM_SECONDARYATTACK
end

function SWEP:AddViewKick()
	//NOTENOTE: By default, weapon will not kick up (defined per weapon)
end

function SWEP:GetDeathNoticeName()
	if ( SERVER ) then
		return self.m_iszName -- Fix
	else
		return "GetDeathNoticeName not implemented on client yet"
	end
end

if ( CLIENT ) then
	function SWEP:CreateMove( flInputSampleTime, pCmd, vecOldViewAngles ) -- Fix
	end
end

function SWEP:IsWeaponZoomed()
	return false
end

function SWEP:CheckReload()
	if ( self.m_bReloadsSingly ) then
		local pOwner = self.Owner
		local iClip1 = self:Clip1()
		if ( not IsValid( pOwner ) ) then
			return
		end
		
		if ( ( self.m_bInReload ) and ( self:GetNextPrimaryFire() <= CurTime() ) ) then
			if ( ( pOwner:KeyDown( IN_ATTACK ) or pOwner:KeyDown( IN_ATTACK2 ) ) and iClip1 > 0 ) then
				self.m_bInReload = false
				return
			end
			
			// If out of ammo end reload
			if ( pOwner:GetAmmoCount( self.Primary.Ammo ) <= 0 ) then
				self:FinishReload()
				return
			// If clip not full reload again
			elseif ( iClip1 < self:GetMaxClip1() ) then
				// Add them to the clip
				self:SetClip1( iClip1 + 1 )
				pOwner:RemoveAmmo( 1, self.Primary.Ammo )
				
				self:Reload()
				return
			// Clip full, stop reloading
			else
				self:FinishReload()
				self:SetNextPrimaryFire( CurTime() )
				self:SetNextSecondaryFire( CurTime() )
				return
			end
		end
	else
		if ( ( self.m_bInReload ) and ( self:GetNextPrimaryFire() <= CurTime() ) ) then
			self:FinishReload()
			self:SetNextPrimaryFire( CurTime() )
			self:SetNextSecondaryFire( CurTime() )
			self.m_bInReload = false
		end
	end
end

function SWEP:FinishReload()
	local pOwner = self.Owner
	local iClip1 = self:Clip1()
	local iClip2 = self:Clip2()
	
	if ( IsValid( pOwner ) ) then
		// If I use primary clips, reload primary
		if ( self:UsesClipsForAmmo1() ) then
			local primary = math.min( self:GetMaxClip1() - iClip1, pOwner:GetAmmoCount( self.Primary.Ammo ) )
			self:SetClip1( iClip1 + primary )
			pOwner:RemoveAmmo( primary, self.Primary.Ammo )
		end
		
		// If I use secondary clips, reload secondary
		if ( self:UsesClipsForAmmo2() ) then
			local secondary = math.min( self:GetMaxClip2() - iClip2, pOwner:GetAmmoCount( self.Secondary.Ammo ) )
			self:SetClip2( iClip2 + secondary )
			pOwner:RemoveAmmo( secondary, self.Secondary.Ammo )
		end
		
		if ( self.m_bReloadsSingly ) then
			self.m_bInReload = false
		end
	end
end

function SWEP:AbortReload()
	if ( CLIENT ) then
		self:StopWeaponSound( RELOAD )
	end
	
	self.m_bInReload = false
end

function SWEP:PrimaryAttack()
	local iClip1 = self:Clip1()
	
	// If my clip is empty (and I use clips) start reload
	if ( self:UsesClipsForAmmo1() and not iClip1 ) then
		self:Reload()
		return
	end
	
	// Only the player fires this way so we can cast
	local pPlayer = self.Owner
	
	if ( not IsValid( pPlayer ) ) then
		return
	end
	
	pPlayer:MuzzleFlash()
	
	self:SendWeaponAnim( self:GetPrimaryAttackActivity() )
	
	// player "shoot" animation
	pPlayer:SetAnimation( PLAYER_ATTACK1 )
	
	local info = {}
	info.Src = pPlayer:GetShootPos()
	
	info.Dir = pPlayer:GetAutoaimVector( AUTOAIM_SCALE_DEFAULT )
	
	// To make the firing framerate independent, we may have to fire more than one bullet here on low-framerate systems, 
	// especially if the weapon we're firing has a really fast rate of fire.
	info.Num = 0
	local fireRate = self:GetFireRate()
	local flNextPrimaryAttack = self:GetNextPrimaryFire()
	
	while ( flNextPrimaryAttack <= CurTime() ) do
		// MUST call sound before removing a round from the clip of a CMachineGun
		self:WeaponSound( SINGLE, flNextPrimaryAttack )
		self:SetNextPrimaryFire( flNextPrimaryAttack + fireRate )
		info.Num = info.Num + 1
		if ( fireRate == 0 ) then
			break
		end
	end
	
	// Make sure we don't fire more than the amount in the clip
	if ( self:UsesClipsForAmmo1() ) then
		info.Num = math.min( info.Num, iClip1 )
		iClip1 = iClip1 - info.Num
		self:SetClip1( iClip1 )
	else
		info.Num = math.min( info.Num, pPlayer:GetAmmoCount( self.Primary.Ammo ) )
		pPlayer:RemoveAmmo( info.Num, self.Primary.Ammo )
	end
	
	info.Distance = MAX_TRACE_LENGTH
	info.AmmoType = self.Primary.Ammo
	info.Tracer = 2
	
	if ( SERVER ) then
		// Fire the bullets
		info.Spread = pPlayer:GetAttackSpread()
	else
		//!!!HACKHACK - what does the client want this function for?
		info.Spread = self:GetBulletSpread()
	end
	
	pPlayer:FireBullets( info )
	
	if ( iClip1 and pPlayer:GetAmmoCount( self.Primary.Ammo ) <= 0 ) then
		// HEV suit - indicate out of ammo condition
		-- pPlayer:SetSuitUpdate("!HEV_AMO0", false, 0 ) -- Fix; add HEV suit stuff
	end
	
	//Add our view kick in
	self:AddViewKick()
	
end

function SWEP:SecondaryAttack()
	return
end

function SWEP:SetIdealActivity( ideal )
	local idealSequence = self:SelectWeightedSequence( ideal )
	
	if ( idealSequence == -1 ) then
		return false
	end
	
	// take the new activity
	self.m_IdealActivity = ideal
	self.m_nIdealSequence = idealSequence
	
	//Find the next sequence in the potential chain of sequences leading to our ideal one
	local nextSequence = self:FindTransitionSequence( self:GetSequence(), idealSequence )
	
	// Don't use transitions when we're deploying
	if ( ideal ~= ACT_VM_DRAW and self:IsWeaponVisible() and nextSequence ~= idealSequence ) then
		//Set our activity to the next transitional animation
		self:Weapon_SetActivity( ACT_TRANSITION ) -- Fix. This function is so stupid
		self:SetSequence( nextSequence )
		self:SendViewModelAnim( nextSequence ) -- Fix
	else
		//Set our activity to the ideal
		self:Weapon_SetActivity( ideal )
		self:SetSequence( idealSequence )
		self:SendViewModelAnim( idealSequence ) -- Fix
	end
	
	self:SetWeaponIdleTime( CurTime() + self:SequenceDuration() )
	return true
end

--[[
function SWEP:ActivityOverride( baseAct, pRequired )
end -- Fix, do activities
]]

function SWEP:ActivityList()
	return
end

function SWEP:ActivityListCount()
	return 0
end

function SWEP:ObjectCaps()
	local caps = 0 -- self:ObjectCaps() --self.BaseClass:ObjectCaps() -- Fix!
	if ( --not self:IsFollwingEntity() and -- fix 
		not self:HasSpawnFlags( SF_WEAPON_NO_PLAYER_PICKUP ) ) then
		caps = bit.bor( caps, FCAP_IMPULSE_USE )
	end
	
	return caps
end

function SWEP:Deploy()
	return self:DefaultDeploy( self:GetDrawActivity(), self:GetAnimPrefix() )
end

function SWEP:CanDeploy()
	return true
end

function SWEP:GetDrawActivity()
	return ACT_VM_DRAW
end

function SWEP:GetDefaultAnimSpeed()
	return 1.0
end

function SWEP:GetAnimPrefix()
	return -- Fix
end

function SWEP:DefaultDeploy()
	return true
end