SWEP.Base = "weapon_dodbasegun"

SWEP.DrawAmmo = true

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

SWEP.Primary = {
	Ammo = DOD_AMMO_SUBMG,
	ClipSize = 999,
	DefaultClip = 210, -- Fix? DefaultAmmoClips = 7; 30*7. Should it be *6?
	Automatic = true
}

SWEP.Secondary = {
	Ammo = "none",
	ClipSize = -1,
	DefaultClip = -1, -- Fix
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
SWEP.SoundData = {
	single_shot = "Weapon_Thompson.Shoot",
	reload = "Weapon_Thompson.WorldReload",
	melee_hit = "Weapon_Punch.HitPlayer",
	melee_hit_world = "Weapon_Punch.HitWorld"
}

// Weapon Sprite data is loaded by the Client DLL.
-- Texture data here

SWEP.ID = WEAPON_THOMPSON
SWEP.AltID = WEAPON_THOMPSON_PUNCH
