DEFINE_BASECLASS( "weapon_dodbase" )
SWEP.Base = "weapon_dodbase"

SWEP.WeaponID = WEAPON_C96

SWEP.CrosshairMinDistance = 8
SWEP.CrosshairDeltaDistance = 3
SWEP.MuzzleFlashType = 0
SWEP.MuzzleFlashScale = 0.3
SWEP.ViewModelFOV = 45
SWEP.vm_normal_offset = Vector( -.5, -1, 1.2 )
SWEP.vm_prone_offset = Vector( -4, -3.5, 1.9 )
SWEP.default_team = TEAM_AXIS

// Weapon characteristics:
SWEP.Damage = 40
SWEP.Accuracy = 0.065
SWEP.FireDelay = 0.065
SWEP.AccuracyMovePenalty = 0.1
SWEP.Recoil = 3.0
SWEP.Penetration = 1.0
SWEP.IdleTimeAfterFire = 5.0
SWEP.IdleInterval = 5.0
SWEP.BulletsPerShot = 1
SWEP.WeaponType = WPN_TYPE_PISTOL
SWEP.Weight = 10
SWEP.item_flags = 0
SWEP.PrintName = "#Weapon_C96"
SWEP.bucket = 1
SWEP.bucket_position = 1

SWEP.CanDrop = false

SWEP.Primary = {
	Ammo = "DOD_AMMO_C96",
	ClipSize = 20,
	DefaultClip = 60, -- Fix? DefaultAmmoClips = 7; 30*7. Should it be *6?
	Automatic = true
}

SWEP.Secondary = {
	Ammo = "none",
	ClipSize = -1,
	DefaultClip = -1, -- Fix
	Automatic = false -- Fix. I changed this on purpose because fuck DOD right click aim
}

SWEP.HudClipHeight = 141
SWEP.HudClipBaseHeight = 0
SWEP.HudClipBulletHeight = 7

//Weapon Model
SWEP.ViewModel = "models/weapons/v_c96.mdl"
SWEP.WorldModel = "models/weapons/w_c96.mdl"

//Player Animation
SWEP.anim_prefix = "pistol"

// Sounds for the weapon. There is a max of 16 sounds per category (i.e. max 16 "single_shot" sounds)
SWEP.ShootSounds = { -- Fix; unify shootsound tables
	[ "primary" ] = "Weapon_C96.Shoot",
	[ "reload" ] = "Weapon_c96.WorldReload"
}

// Weapon Sprite data is loaded by the Client DLL.
-- Texture data here
SWEP.HoldType = "smg"
SWEP.AnimHoldType = "c96"

SWEP.Spawnable = true

SWEP.ActTable =
	{
		[ "ACT_DOD_STAND_AIM" ] = "ACT_DOD_STAND_AIM_C96",
		[ "ACT_DOD_CROUCH_AIM" ]		=			"ACT_DOD_CROUCH_AIM_C96",
		[ "ACT_DOD_CROUCHWALK_AIM" ]	=			"ACT_DOD_CROUCHWALK_AIM_C96",
		[ "ACT_DOD_WALK_AIM" ] =			"ACT_DOD_WALK_AIM_C96",
		[ "ACT_DOD_RUN_AIM" ] =			"ACT_DOD_RUN_AIM_C96",				
		[ "ACT_PRONE_IDLE" ] =				"ACT_DOD_PRONE_AIM_C96",			
		[ "ACT_PRONE_FORWARD" ] =				"ACT_DOD_PRONEWALK_IDLE_C96",		
		[ "ACT_MP_STAND_IDLE" ] =				"ACT_DOD_STAND_IDLE_C96",			
		[ "ACT_MP_CROUCH_IDLE" ] =			"ACT_DOD_CROUCH_IDLE_C96",			
		[ "ACT_MP_CROUCHWALK" ] =				"ACT_DOD_CROUCHWALK_IDLE_C96",			
		[ "ACT_MP_WALK" ] =				"ACT_DOD_WALK_IDLE_C96",				
		[ "ACT_MP_RUN" ] =						"ACT_DOD_RUN_IDLE_C96",				
		[ "ACT_SPRINT" ] =				"ACT_DOD_SPRINT_IDLE_C96",				
		
		[ "ACT_RANGE_ATTACK1" ] = "ACT_DOD_PRIMARYATTACK_C96",
		[ "ACT_DOD_PRIMARYATTACK_CROUCH" ] = "ACT_DOD_PRIMARYATTACK_C96",
		[ "ACT_DOD_PRIMARYATTACK_PRONE" ] = "ACT_DOD_PRIMARYATTACK_PRONE_C96",
		
		[ "ACT_RELOAD" ] = "ACT_DOD_RELOAD_C96",
		[ "ACT_DOD_RELOAD_CROUCH" ] = "ACT_DOD_RELOAD_CROUCH_C96",
		[ "ACT_DOD_RELOAD_PRONE" ] = "ACT_DOD_RELOAD_PRONE_C96",
		
		// Hand Signals
		[ "ACT_DOD_HS_IDLE" ] =				"ACT_DOD_HS_IDLE_MP44",
		[ "ACT_DOD_HS_CROUCH" ] =				"ACT_DOD_HS_CROUCH_MP44"
	}

function SWEP:GetIdleActivity()
	local actIdle
	
	if ( self:Clip1() <= 0 ) then
		actIdle = ACT_VM_IDLE_EMPTY
	else
		actIdle = ACT_VM_IDLE
	end
	
	return actIdle
end

function SWEP:GetPrimaryAttackActivity()
	local actIdle
	
	if ( self:Clip1() <= 0 ) then
		actIdle = ACT_VM_PRIMARYATTACK_EMPTY
	else
		actIdle = ACT_VM_PRIMARYATTACK
	end
	
	return actIdle
end

function SWEP:GetDrawActivity()
	local actIdle
	
	if ( self:Clip1() <= 0 ) then
		actIdle = ACT_VM_DRAW_EMPTY
	else
		actIdle = ACT_VM_DRAW
	end
	
	return actIdle
end

function SWEP:GetReloadActivity()
	local actIdle
	
	if ( self:Clip1() <= 0 ) then
		actIdle = ACT_VM_RELOAD_EMPTY
	else
		actIdle = ACT_VM_RELOAD
	end
	
	return actIdle
end