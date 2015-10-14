DEFINE_BASECLASS( "weapon_dodbasemelee" )
SWEP.Base = "weapon_dodbasemelee"

SWEP.CrosshairMinDistance = 8
SWEP.CrosshairDeltaDistance = 3
SWEP.MuzzleFlashType = 0
SWEP.ViewModelFOV = 45
SWEP.vm_normal_offset = Vector( 3, 1, 0 )
SWEP.default_team = TEAM_ALLIES

// Weapon characteristics:
SWEP.Damage = 60
SWEP.FireDelay = 0.1
SWEP.Recoil = 0
SWEP.IdleTimeAfterFire = 5.0
SWEP.IdleInterval = 5.0
SWEP.WeaponType = WPN_TYPE_MELEE -- Fix? Vs. "SubMG"
SWEP.Weight = 5
SWEP.item_flags = 0
SWEP.PrintName = "#Weapon_AmerKnife"
SWEP.bucket = 2
SWEP.bucket_position = 1

SWEP.ViewModel = "models/weapons/v_amerk.mdl"
SWEP.WorldModel = "models/weapons/w_amerk.mdl"

SWEP.anim_prefix = "knife"

SWEP.CanDrop = false

SWEP.WeaponID = WEAPON_AMERKNIFE

SWEP.ShootSounds = 
{
	[ MELEE_MISS ] = "Weapon_Knife.Swing",
	[ MELEE_HIT ] = "Weapon_Punch.HitPlayer",
	[ SPECIAL1 ] = "Weapon_Knife.SlashPlayer",
	[ MELEE_HIT_WORLD ] = "Weapon_Punch.HitWorld"
}

function SWEP:PrimaryAttack()
	self:MeleeAttack( self.Damage, MELEE_DMG_FIST, 0.2, 0.4 ) -- Fix; scale with self.Damage
end

local acttable = 
{ -- Fix; send in to SetWeaponHoldType
	[ ACT_DOD_STAND_AIM ] = ACT_DOD_STAND_AIM_KNIFE,
	[ ACT_DOD_CROUCH_AIM ]		=			ACT_DOD_CROUCH_AIM_KNIFE,
	[ ACT_DOD_CROUCHWALK_AIM ]	=			ACT_DOD_CROUCHWALK_AIM_KNIFE,
	[ ACT_DOD_WALK_AIM ] =			ACT_DOD_WALK_AIM_KNIFE,
	[ ACT_DOD_RUN_AIM ] =			ACT_DOD_RUN_AIM_KNIFE,				
	[ ACT_PRONE_IDLE ] =				ACT_DOD_PRONE_AIM_KNIFE,			
	[ ACT_PRONE_FORWARD ] =				ACT_DOD_PRONEWALK_AIM_KNIFE,		
	[ ACT_DOD_STAND_IDLE ] =				ACT_DOD_STAND_AIM_KNIFE,			
	[ ACT_DOD_CROUCH_IDLE ] =			ACT_DOD_CROUCH_AIM_KNIFE,			
	[ ACT_DOD_CROUCHWALK_IDLE ] =				ACT_DOD_CROUCHWALK_AIM_KNIFE,			
	[ ACT_DOD_WALK_IDLE ] =				ACT_DOD_WALK_AIM_KNIFE,				
	[ ACT_DOD_RUN_IDLE ] =						ACT_DOD_RUN_AIM_KNIFE,				
	[ ACT_SPRINT ] =				ACT_DOD_SPRINT_AIM_KNIFE,				

	[ ACT_RANGE_ATTACK2 ] =	ACT_DOD_PRIMARYATTACK_KNIFE,	
	[ ACT_DOD_SECONDARYATTACK_CROUCH ] =	ACT_DOD_PRIMARYATTACK_CROUCH_KNIFE,	
	[ ACT_DOD_SECONDARYATTACK_PRONE ] =		ACT_DOD_PRIMARYATTACK_PRONE_KNIFE,	

	// Hand Signals
	[ ACT_DOD_HS_IDLE ] =				ACT_DOD_HS_IDLE_KNIFE,
	[ ACT_DOD_HS_CROUCH ] =				ACT_DOD_HS_CROUCH_KNIFE
}

function SWEP:Initialize()
	self:RegisterHoldType( "amerknife", acttable )
	
	self.BaseClass:Initialize()
end