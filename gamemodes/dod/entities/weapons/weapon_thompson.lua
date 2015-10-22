DEFINE_BASECLASS( "weapon_dodfullauto_punch" )

SWEP.Base = "weapon_dodfullauto_punch"

SWEP.CrosshairMinDistance = 8
SWEP.CrosshairDeltaDistance = 3
SWEP.MuzzleFlashType = 0
SWEP.MuzzleFlashScale = 0.3
SWEP.ViewModelFOV = 45
SWEP.vm_normal_offset = Vector( 1.5, -.4, .32 )
SWEP.vm_prone_offset = Vector( 0, -3, 1 )
SWEP.default_team = TEAM_ALLIES

// Weapon characteristics:
SWEP.Damage = 40
SWEP.Accuracy = 0.055
SWEP.FireDelay = 0.085
SWEP.AccuracyMovePenalty = 0.1
SWEP.Recoil = 2.15
SWEP.Penetration = 1.0
SWEP.IdleTimeAfterFire = 5.0
SWEP.IdleInterval = 5.0
SWEP.BulletsPerShot = 1
SWEP.WeaponType = WPN_TYPE_SUBMG -- Fix? Vs. "SubMG"
SWEP.Weight = 20
SWEP.item_flags = 0
SWEP.PrintName = "#Weapon_Thompson" -- Fix?
SWEP.bucket = 0
SWEP.bucket_position = 1

SWEP.Primary = 
{
	Ammo = "DOD_AMMO_SUBMG",
	ClipSize = 30,
	DefaultClip = 210, -- Fix? DefaultAmmoClips = 7; 30*7; check with actual in-game ammo values
	Automatic = true
}

SWEP.Secondary = 
{
	Ammo = "none",
	ClipSize = -1,
	DefaultClip = -1,
	Automatic = false -- Fix. I changed this on purpose because fuck DOD right click aim
}

SWEP.Tracer = 2

SWEP.HudClipHeight = 184
SWEP.HudClipBaseHeight = 2
SWEP.HudClipBulletHeight = 6

//Weapon Model
SWEP.ViewModel = "models/weapons/v_thompson.mdl" -- Fix, precache?
SWEP.WorldModel = "models/weapons/w_thompson.mdl"

//Player Animation
SWEP.anim_prefix = "tommy"

// Sounds for the weapon. There is a max of 16 sounds per category (i.e. max 16 "single_shot" sounds)
SWEP.ShootSounds = { -- Fix; unify shootsound tables
	[ SINGLE ] = "Weapon_Thompson.Shoot",
	[ RELOAD ] = "Weapon_Thompson.WorldReload",
	[ MELEE_HIT ] = "Weapon_Punch.HitPlayer",
	[ MELEE_HIT_WORLD ] = "Weapon_Punch.HitWorld"
}

// Weapon Sprite data is loaded by the Client DLL.
-- Texture data here

SWEP.WeaponID = WEAPON_THOMPSON
SWEP.AltWeaponID = WEAPON_THOMPSON_PUNCH

-- Fix; check if in CDODFullAutoPunch weapons if we need to modify the activities to incorporate _EMPTY. The C96 seems to do this in its own file

SWEP.HoldType = "smg"
SWEP.AnimHoldType = "thompson"

SWEP.HoldTypes = 
{
	[ SWEP.AnimHoldType ] = 
	{
		[ ACT_DOD_STAND_AIM ] = "ACT_DOD_STAND_AIM_TOMMY",
		[ ACT_DOD_CROUCH_AIM ]		=			"ACT_DOD_CROUCH_AIM_TOMMY",
		[ ACT_DOD_CROUCHWALK_AIM ]	=			"ACT_DOD_CROUCHWALK_AIM_TOMMY",
		[ ACT_DOD_WALK_AIM ] =			"ACT_DOD_WALK_AIM_TOMMY",
		[ ACT_DOD_RUN_AIM ] =			"ACT_DOD_RUN_AIM_TOMMY",				
		[ ACT_PRONE_IDLE ] =				"ACT_DOD_PRONE_AIM_TOMMY",			
		[ ACT_PRONE_FORWARD ] =				"ACT_DOD_PRONEWALK_IDLE_TOMMY",		
		[ ACT_MP_STAND_IDLE ] =				"ACT_DOD_STAND_IDLE_TOMMY",			
		[ ACT_MP_CROUCH_IDLE ] =			"ACT_DOD_CROUCH_IDLE_TOMMY",			
		[ ACT_MP_CROUCHWALK ] =				"ACT_DOD_CROUCHWALK_IDLE_TOMMY",			
		[ ACT_MP_WALK ] =				"ACT_DOD_WALK_IDLE_TOMMY",				
		[ ACT_MP_RUN ] =						"ACT_DOD_RUN_IDLE_TOMMY",				
		[ ACT_SPRINT ] =				"ACT_DOD_SPRINT_IDLE_TOMMY",				
		
		[ ACT_RANGE_ATTACK1 ] = "ACT_DOD_PRIMARYATTACK_TOMMY",
		[ ACT_DOD_PRIMARYATTACK_CROUCH ] = "ACT_DOD_PRIMARYATTACK_TOMMY",
		[ ACT_DOD_PRIMARYATTACK_PRONE ] = "ACT_DOD_PRIMARYATTACK_PRONE_TOMMY",
		[ ACT_RANGE_ATTACK2 ] =	"ACT_DOD_SECONDARYATTACK_TOMMY",	
		[ ACT_DOD_SECONDARYATTACK_CROUCH ] =	"ACT_DOD_SECONDARYATTACK_CROUCH_TOMMY",	
		[ ACT_DOD_SECONDARYATTACK_PRONE ] =		"ACT_DOD_PRIMARYATTACK_PRONE_TOMMY",	
		
		// Hand Signals
		[ ACT_DOD_HS_IDLE ] =				"ACT_DOD_HS_IDLE_TOMMY",
		[ ACT_DOD_HS_CROUCH ] =				"ACT_DOD_HS_CROUCH_TOMMY"
	}
}

--[[
function SWEP:TranslateActivity(act)
	return acttable[act] or -1
end]]
	