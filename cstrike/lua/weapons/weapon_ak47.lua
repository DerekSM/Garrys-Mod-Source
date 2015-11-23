SWEP.Base = "weapon_csbase_gun"

SWEP.Spawnable = true -- Fix; temp placement
SWEP.Category = "Counter-Strike: Source"

SWEP.MaxSpeed = 221
SWEP.Type = "rifle"
SWEP.Price = 2500
SWEP.ArmorRatio = 1.55
SWEP.Team = 1
SWEP.MuzzleFlashScale = 1.6
SWEP.MuzzleFlashStyle = "CS_MUZZLEFLASH_X"
SWEP.CanUseWithShield = false

SWEP.Penetration = 2
SWEP.Damage = 36
SWEP.RangeModifier = 0.98
SWEP.Bullets = 1
SWEP.Primary.Cooldown = 0.1
SWEP.AccuracyDivisor = 200
SWEP.AccuracyOffset = 0.35
SWEP.MaxInaccuracy = 1.25
SWEP.TimeToIdle = 1.9
SWEP.IdleInterval = 20

SWEP.PrintName = "#Cstrike_WPNHUD_AK47"
SWEP.ViewModel = "models/weapons/v_rif_ak47.mdl"
SWEP.WorldModel = "models/weapons/w_rif_ak47.mdl"
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
	[ "primary" ] = "Weapon_AK47.Single"
}

--SWEP.VMBounds

function SWEP:PrimaryAttack()
	local pPlayer = self.Owner
	
	if ( not IsValid( pPlayer ) ) then
		return
	end
	
	if ( not pPlayer:IsFlagSet( FL_ONGROUND ) ) then
		self:Shoot( 0.04 + 0.4 * self.m_flAccuracy )
	elseif ( pPlayer:GetAbsVelocity():Length2D() > 140 ) then
		self:Shoot( 0.04 + 0.07 * self.m_flAccuracy )
	else
		self:Shoot( 0.0275 * self.m_flAccuracy )
	end
end

function SWEP:KickBack()
	local pPlayer = self.Owner
	
	if ( pPlayer:GetAbsVelocity():Length2D() > 5 ) then
		pPlayer:KickBack( 1.5, 0.45, 0.225, 0.05, 6.5, 2.5, 7 )
	elseif ( not pPlayer:IsFlagSet( FL_ONGROUND ) ) then
		pPlayer:KickBack( 2, 1.0, 0.5, 0.35, 9, 6, 5 )
	elseif ( pPlayer:IsFlagSet( FL_DUCKING ) ) then
		pPlayer:KickBack( 0.9, 0.35, 0.15, 0.025, 5.5, 1.5, 9 )
	else
		pPlayer:KickBack( 1, 0.375, 0.175, 0.0375, 5.75, 1.75, 8 )
	end
end
