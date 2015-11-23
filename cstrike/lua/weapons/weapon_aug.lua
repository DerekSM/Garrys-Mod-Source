




-- FIX SPECIAL FIRING!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! (damage not setting properly)
-- Look into zooming while primary firing; match CS:S behaviour





SWEP.Base = "weapon_csbase_scoped"

SWEP.Spawnable = true -- Fix; temp placement
SWEP.Category = "Counter-Strike: Source"

SWEP.MaxSpeed = 221
SWEP.Type = "rifle"
SWEP.Price = 3500
SWEP.ArmorRatio = 1.4
SWEP.Team = 2
SWEP.MuzzleFlashScale = 1.3
SWEP.MuzzleFlashStyle = "CS_MUZZLEFLASH_X"
SWEP.CanUseWithShield = false

SWEP.Penetration = 2
SWEP.Damage = 32
SWEP.RangeModifier = 0.96
SWEP.Bullets = 1
SWEP.Primary.Cooldown = 0.09
SWEP.AccuracyDivisor = 215
SWEP.AccuracyOffset = 0.3
SWEP.MaxInaccuracy = 1.0
SWEP.TimeToIdle = 1.9
SWEP.IdleInterval = 20

SWEP.PrintName = "#Cstrike_WPNHUD_Aug"
SWEP.ViewModel = "models/weapons/v_rif_aug.mdl"
SWEP.WorldModel = "models/weapons/w_rif_aug.mdl"
SWEP.ViewModelFlip = true

SWEP.Bucket = 0
SWEP.BucketPos = 0

SWEP.Primary.ClipSize = 30
SWEP.Primary.DefaultClip = 500
SWEP.Primary.Ammo = "SMG1"
SWEP.Weight = 25
SWEP.ItemFlags = 0

SWEP.Sounds =
{
	[ "primary" ] = "Weapon_AUG.Single"
}

SWEP.ZoomLevels = 1

SWEP.ZoomFOV =
{
	[1] = 55
}

SWEP.ZoomTime =
{
	[0] = 0.15,
	[1] = 0.2
}

SWEP.Special =
{
	Damage = 18,
	RangeModifier = 0.9,
	SoundType = "primary"
}

SWEP.ZoomAfterReload = false

function SWEP:PrimaryAttack()
	local pPlayer = self.Owner
		
	if ( not IsValid( pPlayer ) ) then return end
	
	local flCycleTime = self.Primary.Cooldown
	
	if ( self.m_iZoomLevel > 0 ) then
		flCycleTime = 0.135 -- fix; scale to set variable
	end
	
	if ( not pPlayer:IsFlagSet( FL_ONGROUND ) ) then
		self:Shoot( 0.035 + 0.4 * self.m_flAccuracy, flCycleTime )
	elseif ( pPlayer:GetAbsVelocity():Length2D() > 140 ) then
		self:Shoot( 0.035 + 0.07 * self.m_flAccuracy, flCycleTime )
	else
		self:Shoot( 0.02 * self.m_flAccuracy, flCycleTime )
	end
end

function SWEP:KickBack()
	local pPlayer = self.Owner
	
	if ( pPlayer:GetAbsVelocity():Length2D() > 5 ) then
		pPlayer:KickBack( 1, 0.45, 0.275, 0.05, 4, 2.5, 7 )
	elseif ( not pPlayer:IsFlagSet( FL_ONGROUND ) ) then
		pPlayer:KickBack( 1.25, 0.45, 0.22, 0.18, 5.5, 4, 5 )
	elseif ( pPlayer:IsFlagSet( FL_DUCKING ) ) then
		pPlayer:KickBack( 0.575, 0.325, 0.2, 0.011, 3.25, 2, 8 )
	else
		pPlayer:KickBack( 0.625, 0.375, 0.25, 0.0125, 3.5, 2.25, 8 )
	end
end
