DEFINE_BASECLASS( "weapon_dodbasemelee" )
SWEP.Base = "weapon_dodbasemelee"

SWEP.CrosshairMinDistance = 8
SWEP.CrosshairDeltaDistance = 3
SWEP.MuzzleFlashType = 0
SWEP.ViewModelFOV = 45
SWEP.vm_normal_offset = Vector( 6, 0, 1 )
SWEP.default_team = TEAM_AXIS

// Weapon characteristics:
SWEP.Damage = 60
SWEP.FireDelay = 0.1
SWEP.Recoil = 0
SWEP.IdleTimeAfterFire = 5.0
SWEP.IdleInterval = 5.0
SWEP.WeaponType = WPN_TYPE_MELEE -- Fix? Vs. "SubMG"
SWEP.Weight = 5
SWEP.item_flags = 0
SWEP.PrintName = "#Weapon_Spade"
SWEP.bucket = 2
SWEP.bucket_position = 1

SWEP.ViewModel = "models/weapons/v_spade.mdl"
SWEP.WorldModel = "models/weapons/w_spade.mdl"

SWEP.anim_prefix = "spade"

SWEP.CanDrop = false

SWEP.WeaponID = WEAPON_SPADE

SWEP.ShootSounds = 
{	-- Temp; fix
	[ "reload" ] = "Weapon_Knife.Swing",
	[ "empty" ] = "Weapon_Spade.HitPlayer",
	[ "primary" ] = "Weapon_Knife.SlashPlayer",
	[ "secondary" ] = "Weapon_Spade.HitWorld"
}

SWEP.HoldType = "knife"
SWEP.AnimHoldType = "spade"

SWEP.Spawnable = true

SWEP.ActTable = {
	[ ACT_DOD_STAND_AIM ] = ACT_DOD_STAND_AIM_SPADE,
	[ ACT_DOD_CROUCH_AIM ]		=			ACT_DOD_CROUCH_AIM_SPADE,
	[ ACT_DOD_CROUCHWALK_AIM ]	=			ACT_DOD_CROUCHWALK_AIM_SPADE,
	[ ACT_DOD_WALK_AIM ] =			ACT_DOD_WALK_AIM_SPADE,
	[ ACT_DOD_RUN_AIM ] =			ACT_DOD_RUN_AIM_SPADE,				
	[ ACT_PRONE_IDLE ] =				ACT_DOD_PRONE_AIM_SPADE,			
	[ ACT_PRONE_FORWARD ] =				ACT_DOD_PRONEWALK_AIM_SPADE,		
	[ ACT_DOD_STAND_IDLE ] =				ACT_DOD_STAND_AIM_SPADE,			
	[ ACT_DOD_CROUCH_IDLE ] =			ACT_DOD_CROUCH_AIM_SPADE,			
	[ ACT_DOD_CROUCHWALK_IDLE ] =				ACT_DOD_CROUCHWALK_AIM_SPADE,			
	[ ACT_DOD_WALK_IDLE ] =				ACT_DOD_WALK_AIM_SPADE,				
	[ ACT_DOD_RUN_IDLE ] =						ACT_DOD_RUN_AIM_SPADE,				
	[ ACT_SPRINT ] =				ACT_DOD_SPRINT_AIM_SPADE,				

	[ ACT_RANGE_ATTACK2 ] =	ACT_DOD_PRIMARYATTACK_SPADE,	
	[ ACT_DOD_SECONDARYATTACK_CROUCH ] =	ACT_DOD_PRIMARYATTACK_CROUCH_SPADE,	
	[ ACT_DOD_SECONDARYATTACK_PRONE ] =		ACT_DOD_PRIMARYATTACK_PRONE_SPADE,	

	// Hand Signals
	[ ACT_DOD_HS_IDLE ] =				ACT_DOD_HS_IDLE_STICKGRENADE,
	[ ACT_DOD_HS_CROUCH ] =				ACT_DOD_HS_CROUCH_STICKGRENADE,
}
