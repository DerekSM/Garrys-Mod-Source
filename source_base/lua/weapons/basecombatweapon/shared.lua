local m_iReloadHudHintCount = 0				// How many times has this weapon displayed its reload HUD hint?
local m_iAltFireHudHintCount = 0			// How many times has this weapon displayed its alt-fire HUD hint?
local m_flHudHintMinDisplayTime = 0.0		// if the hint is squelched before this, reset my counter so we'll display it again.
local m_bAltFireHudHintDisplayed = false	// Have we displayed an alt-fire HUD hint since this weapon was deployed?
local m_bReloadHudHintDisplayed = false		// Have we displayed a reload HUD hint since this weapon was deployed?
local m_flHudHintPollTime = 0.0				// When to poll the weapon again for whether it should display a hud hint.

SWEP.Spawnable = true
SWEP.Category = "Source Base"
SWEP.Author = "Valve\ncode_gs"
SWEP.Spawnable = true
SWEP.Damage = 0.0
SWEP.BulletSpread = VECTOR_CONE_15DEGREES
SWEP.FireRate = 0.0
SWEP.ReloadsSingly = false	// True if this weapon reloads 1 round at a time

-- Fix; add Viewmodel1, 2, etc?

SWEP.Primary =
{
	Ammo = "none",
	ClipSize = -1,
	DefaultClip = 0,
	Automatic = true,
}

SWEP.Secondary =
{
	Ammo = "none",
	ClipSize = -1,
	DefaultClip = 0,
	Automatic = true,
}

SWEP.Sounds = {
	[ "primary" ] = "",
	[ "secondary" ] = "",
	[ "reload" ] = "",
	[ "empty" ] = ""
}

SWEP.ActTable =
{
	[ "ACT_MP_STAND_IDLE" ] = "ACT_HL2MP_IDLE",
	[ "ACT_MP_WALK" ] = "ACT_HL2MP_WALK",
	[ "ACT_MP_RUN" ] = "ACT_HL2MP_RUN",
	[ "ACT_MP_CROUCH_IDLE" ] = "ACT_HL2MP_IDLE_CROUCH",
	[ "ACT_MP_CROUCHWALK" ] = "ACT_HL2MP_WALK_CROUCH",
	[ "ACT_MP_ATTACK_STAND_PRIMARYFIRE" ] = "ACT_HL2MP_GESTURE_RANGE_ATTACK",
	[ "ACT_MP_ATTACK_CROUCH_PRIMARYFIRE" ] = "ACT_HL2MP_GESTURE_RANGE_ATTACK",
	[ "ACT_MP_RELOAD_STAND" ] = "ACT_HL2MP_GESTURE_RELOAD",
	[ "ACT_MP_RELOAD_CROUCH" ] = "ACT_HL2MP_GESTURE_RELOAD",
	[ "ACT_MP_JUMP" ] = "ACT_HL2MP_JUMP_SLAM",
	[ "ACT_MP_SWIM" ] = "ACT_HL2MP_SWIM",
	[ "ACT_MP_SWIM_IDLE" ] = "ACT_HL2MP_SWIM_IDLE"
}

SWEP.IdleOnEmpty = true

SWEP.Activities =
{
	[ "empty" ] = ACT_VM_PRIMARYATTACK,
	[ "primary" ] = ACT_VM_PRIMARYATTACK,
	[ "secondary" ] = ACT_VM_SECONDARYATTACK,
	[ "reload" ] = ACT_VM_RELOAD,
	[ "deploy" ] = ACT_VM_DRAW,
	[ "holster" ] = ACT_VM_HOLSTER,
	[ "idle" ] = ACT_VM_IDLE
}

-- Constructor/spawn method
function SWEP:Initialize()
	self.m_fThinkFunc = self.ItemFrame
	self.m_bInReload = false
	self.m_flNextEmptySoundTime = 0.0
	m_iReloadHudHintCount = 0
	m_iAltFireHudHintCount = 0
	m_flHudHintMinDisplayTime = 0
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
	
	for _, sound in pairs( self.Sounds ) do
		if ( sound ~= "" ) then
			util.PrecacheSound( sound )
		end
	end
end

function SWEP:GetViewModel()
	return self.ViewModel
end

function SWEP:SetViewModel( sViewModel, iIndex )
	local pOwner = self.Owner
	if ( not IsValid( pOwner ) ) then
		return false
	end
	
	local vm = pOwner:GetViewModel( iIndex )
	if ( not IsValid( vm ) ) then
		return false
	end
	
	if ( iIndex == 0 ) then
		self.ViewModel = sViewModel
	end
	
	vm:SetWeaponModel( sViewModel, self )
end

function SWEP:GetWorldModel()
	return self.WorldModel
end

function SWEP:GetPrintName()
	return self.PrintName
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
	return ( self.Primary.ClipSize > 0 )
end

function SWEP:UsesClipsForAmmo2()
	return ( self.Secondary.ClipSize > 0 )
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

function SWEP:GetSlot()
	return self.Slot
end

function SWEP:GetPosition()
	return self.SlotPos
end

function SWEP:GetOwner()
	return self.Owner
end

function SWEP:UsesHands()
	return self.UseHands
end

function SWEP:FlipsViewModel()
	return self.ViewModelFlip
end

function SWEP:LookupSound( sIndex )
	return self.Sounds[ sIndex:lower() ]
end

function SWEP:LookupActivity( sName )
	return self.Activities[ sName:lower() ]
end

function SWEP:CanBeSelected()
	return ( self:VisibleInWeaponSelection() and self:HasAmmo() or false )
end

function SWEP:HasAmmo()
	// Weapons with no ammo types can always be selected
	if ( self.Primary.Ammo == -1 and self.Secondary.Ammo == -1 ) then
		return true
	elseif ( bit.band( self:GetFlags(), ITEM_FLAG_SELECTONEMPTY ) ) then -- Fix
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
	-- Fix. Let's add a manual drop system
end

function SWEP:MakeTracer( vecTracerSrc, tr, iTracerType )
	local pOwner = self.Owner
	
	if ( not IsValid( pOwner ) ) then
		-- BaseClass.MakeTracer( self, vecTracerSrc, tr, iTracerType ) -- Fix
		return
	end
	
	local pszTracerName = self:GetTracerType()
	
	local iEntIndex = pOwner:EntIndex()
	
	if ( game.Multiplayer() ) then
		iEntIndex = self:EntIndex()
	end
	
	local iAttachment = self:GetTracerAttachment()
	
	if ( iTracerType == TRACER_LINE or iTracerType == TRACER_LINE_AND_WHIZ ) then
		util.Tracer( vecTracerSrc, tr.HitPos, iEntIndex, iAttachment, 0.0, true, pszTracerName )
	end
end

function SWEP:ShouldDisplayAltFireHUDHint()
	if ( m_iAltFireHudHintCount >= WEAPON_RELOAD_HUD_HINT_COUNT ) then
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

function SWEP:RescindAltFireHudHint()
--[[
{
#if !defined( CLIENT_DLL )
	Assert(m_bAltFireHudHintDisplayed);
	
	UTIL_HudHintText( GetOwner(), "" );
	--m_iAltFireHudHintCount;
	m_bAltFireHudHintDisplayed = false;
#endif//CLIENT_DLL
}]]
end

function SWEP:ShouldDisplayReloadHUDHint()
	if ( m_iReloadHudHintCount >= WEAPON_RELOAD_HUD_HINT_COUNT ) then
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

function SWEP:DisplayReloadHudHint()
--[[{
#if !defined( CLIENT_DLL )
	UTIL_HudHintText( GetOwner(), "valve_hint_reload" );
	m_iReloadHudHintCount++;
	m_bReloadHudHintDisplayed = true;
	m_flHudHintMinDisplayTime = gpGlobals->curtime + MIN_HUDHINT_DISPLAY_TIME;
#endif//CLIENT_DLL
}]]
end
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
function SWEP:RescindReloadHudHint()
--[[{
#if !defined( CLIENT_DLL )
	Assert(m_bReloadHudHintDisplayed);

	UTIL_HudHintText( GetOwner(), "" );
	--m_iReloadHudHintCount;
	m_bReloadHudHintDisplayed = false;
#endif//CLIENT_DLL
}
]]
end

--[[
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
]]

function SWEP:_SendWeaponAnim( iActivity ) -- Fix; after switch and restore, the idle breaks. Resaving the file fixes
	local retval = self:SendWeaponAnim( iActivity )
	self:SetWeaponIdleTime( CurTime() + self:SequenceDuration() ) -- SetIdealActivity carry over
	
	return retval
end

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
	return game.GetAmmoID( self.Secondary.Ammo ) > 0
end

function SWEP:UsesSecondaryAmmo()
	return game.GetAmmoID( self.Secondary.Ammo ) > 0
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
			vm:AddEffects( EF_NODRAW )
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

function SWEP:ReloadOrSwitchWeapons()
	local pOwner = self.Owner
	if ( not IsValid( pOwner ) ) then return end
	
	local curtime = CurTime()
	local flNextPrimaryAttack = self:GetNextPrimaryFire()
	local flNextSecondaryAttack = self:GetNextSecondaryFire()
	
	self.m_bFireOnEmpty = false
	
	// If we don't have any ammo, switch to the next best weapon
	if ( not self:HasAnyAmmo() and flNextPrimaryAttack < curtime and flNextSecondaryAttack < curtime ) then
		// weapon isn't useable, switch.
		if ( ( bit.band(self:GetFlags(), ITEM_FLAG_NOAUTOSWITCHEMPTY) == 0 ) and ( GM:SwitchToNextBestWeapon( pOwner, self ) ) ) then
			self:SetNextPrimaryFire( curtime + 0.3 )
			return true
		end
	else
		// Weapon is useable. Reload if empty and weapon has waited as long as it has to after firing
		if ( self:UsesClipsForAmmo1() and 
			(self:Clip1() == 0) and 
			bit.band(self:GetFlags(), ITEM_FLAG_NOAUTORELOAD) == 0 and 
			flNextPrimaryAttack < curtime and 
			flNextSecondaryAttack < curtime ) then
			// if we're successfully reloading, we're done
			if ( self:Reload() ) then
				return true
			end
		end
	end
	
	return false
end

function SWEP:DefaultDeploy( iActivity )
	// Weapons that don't autoswitch away when they run out of ammo 
	// can still be deployed when they have no ammo.
	if ( not self:CanDeploy() ) then
		return false
	end
	
	local pOwner = self.Owner
	if ( IsValid( pOwner ) ) then
		// Dead men deploy no weapons
		if ( not pOwner:Alive() ) then
			return false
		end
		
		--self:SetViewModel()
		self:_SendWeaponAnim( iActivity )
		
		pOwner:SetNextAttack( CurTime() + self:SequenceDuration() )
		-- ActTable = pOwner:TranslateActTable( self.ActTable )
	end
	self.m_fThinkFunc = self.ItemFrame
	self.m_bInReload = false
	
	// Can't shoot again until we've finished deploying
	self:SetNextPrimaryFire( CurTime() + self:SequenceDuration() )
	self:SetNextSecondaryFire( CurTime() + self:SequenceDuration() )
	m_flHudHintMinDisplayTime = 0
	
	m_bAltFireHudHintDisplayed = false
	m_bReloadHudHintDisplayed = false
	m_flHudHintPollTime = CurTime() + 5.0
	
	return true
end

function SWEP:Deploy()
	if ( SERVER ) then
		local retval = self:SharedDeploy()
		--[[
		local pOwner = self.Owner
		
		if ( IsValid( pOwner ) ) then
			print"sent"
			net.Start( "Source Base - Clientside Deploy" )
				net.WriteEntity( self ) -- Necessary for prediction
			net.Send( pOwner )
		end
		]]
		-- We network this so that singleplayer/SelectWeapon will Deploy shared
		self:CallOnClient( "SharedDeploy" )
		
		return retval
	else
		--return self:SharedDeploy() -- Fix; tempd
	end
	-- Return true as a fail-safe
	-- This might cause a slight prediction error if the user can't deploy
	-- Fix
	return true 
end

function SWEP:SharedDeploy()
	return self:DefaultDeploy( self.Activities[ "deploy" ] )
end

function SWEP:SetThinkFunction( func )
	self.m_fThinkFunc = func
end

function SWEP:GetThinkFunction()
	return self.m_fThinkFunc
end

function SWEP:GetLastWeapon()
	return self
end
-- Fix these three; uses?
function SWEP:CanLower()
	return false
end

function SWEP:Ready()
	return false
end

function SWEP:Lower()
	return false
end

function SWEP:_GetActivity() -- fix
	return self:GetSequenceActivity( self:GetSequence() )
end

function SWEP:DefaultHolster( pSwitchingTo, iActivity )
	// cancel any reload in progress.
	self.m_bInReload = false
	
	// kill any think functions
	-- If for some reason the weapon is still active after a holster frame,
	-- make the think do nothing to prevent errors
	timer.Simple( 0, function() 
		if IsValid( self ) then 
			self.m_fThinkFunc = ( function() end ) -- Fix; does this work 
		end 
	end )
	
	// Send holster animation
	--[[self:_SendWeaponAnim( iActivity )
	
	// Some weapon's don't have holster anims yet, so detect that
	local flSequenceDuration = 0
	if ( self:_GetActivity() == self:GetHolsterActivity() ) then
		flSequenceDuration = self:SequenceDuration()
	end
	
	local pOwner = self.Owner
	if ( IsValid( pOwner ) ) then
		pOwner:SetNextAttack( CurTime() + flSequenceDuration )
		pOwner:SetFOV( 0, 0 ) // reset the default FOV
	end
	
	// If we don't have a holster anim, hide immediately to avoid timing issues
	if ( flSequenceDuration == 0 ) then
		--self:SetWeaponVisible( false )
	else
		// Hide the weapon when the holster animation's finished
		timer.Simple( flSequenceDuration + 0.1, function()
			print"timer ran"
			if ( IsValid( pOwner ) ) then
				local newWep = owner:GetActiveWeapon()
				print( newWep )
				if ( newWep == self ) then
					self:SetWeaponVisible( false )
				else
					local vm = owner:GetViewModel()
					if ( IsValid( vm ) ) then
						vm:SetModel( newWep:GetViewModel() )
					end
				end
			end
		end )
				
	end]]
	
	// if we were displaying a hud hint, squelch it.
	if ( m_flHudHintMinDisplayTime and CurTime() < m_flHudHintMinDisplayTime ) then
		if( m_bAltFireHudHintDisplayed ) then
			self:RescindAltFireHudHint()
		end
		if( m_bReloadHudHintDisplayed ) then
			self:RescindReloadHudHint()
		end
	end
	
	return true
end

function SWEP:Holster( pSwitchingTo )
	return self:DefaultHolster( pSwitchingTo, self.Activities[ "holster" ] )
end

function SWEP:CanHolster()
	return true
end

function SWEP:ItemFrame()
	local pOwner = self.Owner
	if ( not IsValid( pOwner ) ) then
		return
	end
	
	if ( not ( m_bAltFireHudHintDisplayed or m_bReloadHudHintDisplayed ) and CurTime() < m_flHudHintMinDisplayTime and CurTime() > m_flHudHintPollTime ) then
		if ( pPlayer:GetStickDist() > 0.0 ) then -- Fix
			// If the player is moving, they're unlikely to switch away from the current weapon
			// the moment this weapon displays its HUD hint.
			if ( self:ShouldDisplayReloadHUDHint() ) then
				self:DisplayReloadHudHint()
			elseif ( self:ShouldDisplayAltFireHUDHint() ) then
				self:DisplayAltFireHudHint()
			end
		else
			m_flHudHintPollTime = CurTime() + 2.0
		end
	end
	
	if ( self:UsesClipsForAmmo1() ) then
		self:CheckReload()
	end
	
	// Secondary attack has priority
	if ( not ( pOwner:KeyDown( IN_ATTACK ) or pOwner:KeyDown( IN_ATTACK2 ) or pOwner:KeyDown( IN_RELOAD ) )
	and not self:ReloadOrSwitchWeapons() and not self.m_bInReload ) then
		self:WeaponIdle()
	end
end

function SWEP:Think()
	self.m_fThinkFunc( self )
end

-- Fix; ItemBusyFrame = PostThink. Find an implementation for this?

function SWEP:HandleFireOnEmpty()
	// If we're already firing on empty, reload if we can
	if ( self.m_bFireOnEmpty ) then
		self:ReloadOrSwitchWeapons()
	else
		if ( self.m_flNextEmptySoundTime < CurTime() ) then
			self:WeaponSound( "empty" )
			self.m_flNextEmptySoundTime = CurTime() + 0.5
		end
		
		self.m_bFireonEmpty = true
	end
end

function SWEP:GetBulletSpread( proficiency )
	return self.BulletSpread
end

function SWEP:SetBulletSpread( iSpread )
	self.BulletSpread = iSpread
end

function SWEP:GetFireRate()
	return self.FireRate
end

function SWEP:SetFireRate( flRate )
	self.FireRate = flRate
end

function SWEP:GetDamage( flDistance, iLocation )
	return self.Damage
end

function SWEP:SetDamage( damage )
	self.Damage = damage
end

function SWEP:AddViewModelBob( origin, angles )
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
	soundtime = soundtime or 0
	
	// If we have some sounds from the weapon classname.txt file, play a random one of them
	local shootsound = self:LookupSound( sound_type )
	if ( not shootsound ) then
		return
	end
	
	local params
	-- Fix; do all this sound shit
	self.Owner:EmitSound( shootsound )
end

function SWEP:StopWeaponSound( sound_type )
end

function SWEP:_DefaultReload( iClipSize1, iClipSize2, iActivity ) -- Fix; do we need arguments
	if ( self.m_bInReload ) then
		return false
	end

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
		self:WeaponSound( "reload" )
	end
	
	self:_SendWeaponAnim( iActivity )
	
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
	return self:_DefaultReload( self:GetMaxClip1(), self:GetMaxClip2(), self:GetReloadActivity() )
end

function SWEP:WeaponIdle()
	//Idle again if we've finished
	-- Fix
	if ( self:HasWeaponIdleTimeElapsed() and (( not self.IdleOnEmpty and self:UsesClipsForAmmo1() and self:Clip1() > 0 ) or self.IdleOnEmpty) ) then
		self:_SendWeaponAnim( self:GetIdleActivity() )
		return true
	end
	
	return false
end

function SWEP:IsWeaponZoomed() -- Fix
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
		self:StopWeaponSound( "reload" )
	end
	
	self.m_bInReload = false
end

function SWEP:PrimaryAttack()
	local iClip1 = self:Clip1()
	
	// If my clip is empty (and I use clips) start reload
	if ( self:UsesClipsForAmmo1() and iClip1 <= 0 ) then
		self:HandleFireOnEmpty()
		return
	end
	
	// Only the player fires this way so we can cast
	local pPlayer = self.Owner
	
	if ( not IsValid( pPlayer ) ) then
		return
	end
	
	pPlayer:MuzzleFlash()
	
	self:_SendWeaponAnim( self.Activities[ "primary" ] )
	
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
		self:WeaponSound( "primary", flNextPrimaryAttack )
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
	
	-- info.Distance = MAX_TRACE_LENGTH -- Fix
	info.AmmoType = self.Primary.Ammo
	info.Tracer = 2
	
	if ( SERVER ) then-- Fix
		// Fire the bullets
		info.Spread = self:GetBulletSpread() --pPlayer:GetAttackSpread() -- Fix
	else
		//!!!HACKHACK - what does the client want this function for?
		info.Spread = self:GetBulletSpread() -- Fix
	end
	
	pPlayer:FireBullets( info )
	
	if ( iClip1 <= 0 and pPlayer:GetAmmoCount( self.Primary.Ammo ) <= 0 ) then
		// HEV suit - indicate out of ammo condition
		-- pPlayer:SetSuitUpdate("!HEV_AMO0", false, 0 ) -- Fix; add HEV suit stuff
	end
end

function SWEP:SecondaryAttack()
end

function SWEP:FireBullets()
end

--[[
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
]]
--[[
function SWEP:ActivityOverride( baseAct, pRequired )
end -- Fix, do activities


function SWEP:ActivityList()
	return
end

function SWEP:ActivityListCount()
	return 0
end
]]

function SWEP:GetControlPanelInfo( nPanelIndex, pPanelName )
	return NULL
end

function SWEP:GetControlPanelClassName( nPanelIndex, pPanelName )
	return "vgui_screen"
end

function SWEP:CanDeploy()
	return true -- ( not self:HasAnyAmmo() and self:AllowsAutoSwtichFrom() ) -- FIx
end

function SWEP:GetDefaultAnimSpeed() -- Fix
	return 1.0
end

function SWEP:GetAnimPrefix()
	return -- Fix
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--SWEP.HoldType = "normal"

ACT_HL2MP_SWIM = ACT_HL2MP_IDLE + 9 -- Fix; temp hack
ACT_RANGE_ATTACK = ACT_HL2MP_IDLE + 8
ACT_HL2MP_SWIM_IDLE = 2057

-- FIX: Investigate the 1784 - 1787 gap

SWEP.HoldTypes =
{
	[ "normal" ] =
	{
		[ ACT_MP_STAND_IDLE ] = ACT_HL2MP_IDLE,
		[ ACT_MP_WALK ] = ACT_HL2MP_WALK,
		[ ACT_MP_RUN ] = ACT_HL2MP_RUN,
		[ ACT_MP_CROUCH_IDLE ] = ACT_HL2MP_IDLE_CROUCH,
		[ ACT_MP_CROUCHWALK ] = ACT_HL2MP_WALK_CROUCH,
		[ ACT_MP_ATTACK_STAND_PRIMARYFIRE ] = ACT_HL2MP_GESTURE_RANGE_ATTACK,
		[ ACT_MP_ATTACK_CROUCH_PRIMARYFIRE ] = ACT_HL2MP_GESTURE_RANGE_ATTACK,
		[ ACT_MP_RELOAD_STAND ] = ACT_HL2MP_GESTURE_RELOAD,
		[ ACT_MP_RELOAD_CROUCH ] = ACT_HL2MP_GESTURE_RELOAD,
		[ ACT_MP_JUMP ] = ACT_HL2MP_JUMP_SLAM, -- Fix
		[ ACT_RANGE_ATTACK1 ] = ACT_HL2MP_GESTURE_RANGE_ATTACK, -- Fix
		[ ACT_MP_SWIM ] = ACT_HL2MP_SWIM,
		[ ACT_MP_SWIM_IDLE ] = ACT_HL2MP_SWIM_IDLE
	},
	
	[ "pistol" ] =
	{
		[ ACT_MP_STAND_IDLE ] = ACT_HL2MP_IDLE_PISTOL,
		[ ACT_MP_WALK ] = ACT_HL2MP_WALK_PISTOL,
		[ ACT_MP_RUN ] = ACT_HL2MP_RUN_PISTOL,
		[ ACT_MP_CROUCH_IDLE ] = ACT_HL2MP_IDLE_CROUCH_PISTOL,
		[ ACT_MP_CROUCHWALK ] = ACT_HL2MP_WALK_CROUCH_PISTOL,
		[ ACT_MP_ATTACK_STAND_PRIMARYFIRE ] = ACT_HL2MP_GESTURE_RANGE_ATTACK_PISTOL,
		[ ACT_MP_ATTACK_CROUCH_PRIMARYFIRE ] = ACT_HL2MP_GESTURE_RANGE_ATTACK_PISTOL,
		[ ACT_MP_RELOAD_STAND ] = ACT_HL2MP_GESTURE_RELOAD_PISTOL,
		[ ACT_MP_RELOAD_CROUCH ] = ACT_HL2MP_GESTURE_RELOAD_PISTOL,
		[ ACT_MP_JUMP ] = ACT_HL2MP_JUMP_PISTOL,
		[ ACT_RANGE_ATTACK1 ] = ACT_HL2MP_GESTURE_RANGE_ATTACK_PISTOL,
		[ ACT_MP_SWIM ] = ACT_HL2MP_SWIM_PISTOL,
		[ ACT_MP_SWIM_IDLE ] = ACT_HL2MP_SWIM_IDLE_PISTOL
	},
	
	[ "fist" ] =
	{
		[ ACT_MP_STAND_IDLE ] = ACT_HL2MP_IDLE_FIST,
		[ ACT_MP_WALK ] = ACT_HL2MP_WALK_FIST,
		[ ACT_MP_RUN ] = ACT_HL2MP_RUN_FIST,
		[ ACT_MP_CROUCH_IDLE ] = ACT_HL2MP_IDLE_CROUCH_FIST,
		[ ACT_MP_CROUCHWALK ] = ACT_HL2MP_WALK_CROUCH_FIST,
		[ ACT_MP_ATTACK_STAND_PRIMARYFIRE ] = ACT_HL2MP_GESTURE_RANGE_ATTACK_FIST,
		[ ACT_MP_ATTACK_CROUCH_PRIMARYFIRE ] = ACT_HL2MP_GESTURE_RANGE_ATTACK_FIST,
		[ ACT_MP_RELOAD_STAND ] = ACT_HL2MP_GESTURE_RELOAD_FIST,
		[ ACT_MP_RELOAD_CROUCH ] = ACT_HL2MP_GESTURE_RELOAD_FIST,
		[ ACT_MP_JUMP ] = ACT_HL2MP_JUMP_FIST,
		[ ACT_RANGE_ATTACK1 ] = ACT_HL2MP_GESTURE_RANGE_ATTACK_FIST,
		[ ACT_MP_SWIM ] = ACT_HL2MP_SWIM_FIST,
		[ ACT_MP_SWIM_IDLE ] = ACT_HL2MP_SWIM_IDLE_FIST
	},
	
	[ "passive" ] =
	{
		[ ACT_MP_STAND_IDLE ] = ACT_HL2MP_IDLE_PASSIVE,
		[ ACT_MP_WALK ] = ACT_HL2MP_WALK_PASSIVE,
		[ ACT_MP_RUN ] = ACT_HL2MP_RUN_PASSIVE,
		[ ACT_MP_CROUCH_IDLE ] = ACT_HL2MP_IDLE_CROUCH_PASSIVE,
		[ ACT_MP_CROUCHWALK ] = ACT_HL2MP_WALK_CROUCH_PASSIVE,
		[ ACT_MP_ATTACK_STAND_PRIMARYFIRE ] = ACT_HL2MP_GESTURE_RANGE_ATTACK_PASSIVE,
		[ ACT_MP_ATTACK_CROUCH_PRIMARYFIRE ] = ACT_HL2MP_GESTURE_RANGE_ATTACK_PASSIVE,
		[ ACT_MP_RELOAD_STAND ] = ACT_HL2MP_GESTURE_RELOAD_PASSIVE,
		[ ACT_MP_RELOAD_CROUCH ] = ACT_HL2MP_GESTURE_RELOAD_PASSIVE,
		[ ACT_MP_JUMP ] = ACT_HL2MP_JUMP_PASSIVE,
		[ ACT_RANGE_ATTACK1 ] = ACT_HL2MP_GESTURE_RANGE_ATTACK_PASSIVE,
		[ ACT_MP_SWIM ] = ACT_HL2MP_SWIM_PASSIVE,
		[ ACT_MP_SWIM_IDLE ] = ACT_HL2MP_SWIM_IDLE_PASSIVE
	},
	
	[ "ar2" ] =
	{
		[ ACT_MP_STAND_IDLE ] = ACT_HL2MP_IDLE_AR2,
		[ ACT_MP_WALK ] = ACT_HL2MP_WALK_AR2,
		[ ACT_MP_RUN ] = ACT_HL2MP_RUN_AR2,
		[ ACT_MP_CROUCH_IDLE ] = ACT_HL2MP_IDLE_CROUCH_AR2,
		[ ACT_MP_CROUCHWALK ] = ACT_HL2MP_WALK_CROUCH_AR2,
		[ ACT_MP_ATTACK_STAND_PRIMARYFIRE ] = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2,
		[ ACT_MP_ATTACK_CROUCH_PRIMARYFIRE ] = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2,
		[ ACT_MP_RELOAD_STAND ] = ACT_HL2MP_GESTURE_RELOAD_AR2,
		[ ACT_MP_RELOAD_CROUCH ] = ACT_HL2MP_GESTURE_RELOAD_AR2,
		[ ACT_MP_JUMP ] = ACT_HL2MP_JUMP_AR2,
		[ ACT_RANGE_ATTACK1 ] = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2,
		[ ACT_MP_SWIM ] = ACT_HL2MP_SWIM_AR2,
		[ ACT_MP_SWIM_IDLE ] = ACT_HL2MP_SWIM_IDLE_AR2
	}
}

function SWEP:SetWeaponHoldType( preset )
	self.ActTable = self.HoldTypes[ preset ] or self.ActTable
end

function SWEP:RegisterHoldType( preset, acttable )
	self.HoldTypes[ preset ] = acttable
end

function SWEP:GetActTable()
	return self.ActTable
end

function SWEP:SetActTable( acttable )
	self.ActTable = acttable
end

local ActToString = {
	[ ACT_MP_STAND_IDLE ] = "ACT_MP_STAND_IDLE",
	[ ACT_MP_WALK ] = "ACT_MP_WALK",
	[ ACT_MP_RUN ] = "ACT_MP_RUN",
	[ ACT_MP_CROUCH_IDLE ] = "ACT_MP_CROUCH_IDLE",
}

local DEBUG = false -- Fix

function SWEP:TranslateActivity( act )
	if ( DEBUG ) then
		if act == ACT_RANGE_ATTACK1 then print"BaseCombatWeapon: Range Attack called" end
	end
	
	if ( act == ACT_MP_SWIM and not ( self.Owner:KeyDown( KEY_W ) or self.Owner:KeyDown( KEY_A ) or self.Owner:KeyDown( KEY_S ) or self.Owner:KeyDown( KEY_D ) ) ) then
		act = ACT_MP_SWIM_IDLE
	end
	
	if ( DEBUG ) then
		local test = self.Owner:GetSequenceActivityName( self.Owner:SelectWeightedSequence( act ) )
		-- Unregistered sequences
		if not self.ActTable[ act ] and ( test ~= "Not Found!" and test ~= ACT_GMOD_NOCLIP_LAYER and test ~= ACT_LAND ) then
			print( "BaseCombatWeapon: Unregistered sequence - " .. test )
		end
	end
	--return 665
	if ( DEBUG ) then
		print( "Quick: " .. QuickTranslation[ act ] )
		print( "Act: " .. self.ActTable[ QuickTranslation[ act ] ] ) 
	end
	return self.ActTable[ act ] or -1
	--return self.Owner.ActivityList[ self.ActTable[ ActToString[ act ] ] ] or -1 -- Fix; return -1 or just re-return the activity?
end

function SWEP:DoFireEffects()
	self:_SendWeaponAnim( self.Activities[ "primary" ] )
	
	local pPlayer = self.Owner
	
	if ( IsValid( pPlayer ) ) then
		pPlayer:MuzzleFlash()
		pPlayer:SetAnimation( pPlayer:LookupAnimation( "primary" ) )
	end
end
