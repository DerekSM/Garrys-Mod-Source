DEFINE_BASECLASS( "weapon_hl2mpbase_machinegun" )
SWEP.Base = "weapon_hl2mpbase_machinegun"

if ( SERVER ) then
	local sk_weapon_ar2_alt_fire_radius = CreateConVar( "sk_weapon_ar2_alt_fire_radius", "10" )
	local sk_weapon_ar2_alt_fire_duration = CreateConVar( "sk_weapon_ar2_alt_fire_duration", "4" )
	local sk_weapon_ar2_alt_fire_mass = CreateConVar( "sk_weapon_ar2_alt_fire_mass", "150" )
end

SWEP.MinRange1 = 65
SWEP.MaxRange1 = 2048

SWEP.MinRange2 = 256
SWEP.MaxRange2 = 1024

-- Fix; accessorfunc
SWEP.MinBurst = 2
SWEP.MaxBurst = 5
SWEP.FireRate = 0.1

SWEP.m_nVentPose = -1
SWEP.m_flDelayedFire = 0.0
SWEP.m_bShotDelayed = false

SWEP.m_nShotsFired = 0

SWEP.ProficiencyTable = 
{
	{ 7.0,		0.75	},
	{ 5.00,		0.75	},
	{ 3.0,		0.85	},
	{ 5.0/3.0,	0.75	},
	{ 1.00,		1.0		},
}

function SWEP:Precache()
	self.BaseClass:Precache()
	
--[[#ifndef CLIENT_DLL

	UTIL_PrecacheOther( "prop_combine_ball" );
	UTIL_PrecacheOther( "env_entity_dissolver" );
#endif]]
end

function SWEP:GetTracerType()
	return "AR2Tracer"
end

function SWEP:GetBulletSpread()
	return VECTOR_CONE_3DEGREES
end

-- ItemPostFrame

function SWEP:GetPrimaryAttackActivity()
	if ( self.ShotsFired < 2 ) then
		return ACT_VM_PRIMARYATTACK
	elseif ( self.ShotsFired < 3 ) then
		return ACT_VM_RECOIL1
	elseif ( self.ShotsFired < 4 ) then
		return ACT_VM_RECOIL2
	end
	
	return ACT_VM_RECOIL3
end

function SWEP:DoImpactEffect( tr, nDamageType )
	local data = EffectData()
	
	data:SetOrigin( tr.HitPos + ( tr.HitNormal * 1.0 ) )
	data:SetNormal( tr.HitNormal )
	
	util.Effect( "AR2Impact", data )
	
	self.BaseClass:DoImpactEffect( tr, nDamageType )
end

function SWEP:DelayedAttack()
	self.m_bShotDelayed = false
	
	local pOwner = self.Owner
	
	if ( not IsValid( pOwner ) ) then
		return
	end
	
	// Deplete the clip completely
	self:SendWeaponAnim( ACT_VM_SECONDARYATTACK )
	self:SetNextSecondaryFire( CurTime() + self:SequenceDuration() )
	pOwner:SetNextAttack( CurTime() + self:SequenceDuration() )
	
	// Register a muzzleflash for the AI
	pOwner:DoMuzzleFlash()
	
	self:WeaponSound( WPN_DOUBLE )
	
	// Fire the bullets
	local vecSrc = pOwner:GetShootPos()
	local vecAiming = pOwner:GetAutoaimVector( AUTOAIM_2DEGREES )
	local impactPoint = vecSrc + ( vecAiming * MAX_TRACE_LENGTH )
	
	// Fire the bullets
	local vecVelocity = vecAiming * 1000.0
	
	if ( SERVER ) then
		// Fire the combine ball
		ents.CreateCombineBall( {
			origin = vecSrc,
			velocity = vecVelocity,
			radius = sk_weapon_ar2_alt_fire_radius:GetFloat(),
			mass = sk_weapon_ar2_alt_fire_mass:GetFloat(),
			lifetime = sk_weapon_ar2_alt_fire_duration:GetFloat(),
			owner = pOwner
		} ) -- Fix
		
		// View effects
		pOwner:ScreenFade( SCREENFADE.IN, Color( 255, 255, 255, 255 ), 0.1, 0 )
	end
	
	//Disorient the player
	local angles = pOwner:GetLocalAngles()
	
	angles.x = angles.x + random.RandomInt( -4, 4 )
	angles.y = angles.y + random.RandomInt( -4, 4 )
	angles.z = 0
	
	// pOwner:SnapEyeAngles( angles )
	
	pOwner:ViewPunch( Angle( pOwner:SharedRandomInt( "ar2pax", -8, -12 ), 
							pOwner:SharedRandomInt( "ar2pay", 1, 2 ),
							0 ) -- Fix; randomint in SWEP or owner?
					)
	
	// Decrease ammo
	pOwner:RemoveAmmo( 1, self.Secondary.Ammo )
	
	// Can shoot again immediately
	self:SetNextPrimaryFire( CurTime() + 0.5 )
	
	// Can blow up after a short delay (so have time to release mouse button)
	self:SetNextSecondaryFire( CurTime() + 1.0 )
end

function SWEP:SecondaryAttack()
	if ( self.m_bShotDelayed ) then
		return
	end
	
	// Cannot fire underwater
	if ( IsValid( self.Owner ) and self.Owner:WaterLevel() == 3 ) then
		self:SendWeaponAnim( ACT_VM_DRYFIRE )
		self:WeaponSound( EMPTY ) -- Fix? Weapon randomly calls baseclass here
		self:SetNextSecondaryFire( CurTime() + 0.5 )
		return
	end
	
	self.m_bShotDelayed = true
	self:SetNextPrimaryFire( CurTime() + 0.5 )
	self:SetNextSecondaryFire( CurTime() + 0.5 )
	self.m_flDelayedFire = CurTime() + 0.5
	
	self:SendWeaponAnim( ACT_VM_FIDGET )
	self:WeaponSound( SPECIAL1 )
end

function SWEP:CanHolster()
	if ( self.m_bShotDelayed ) then
		return false
	end
	
	return self.BaseClass:CanHolster()
end

function SWEP:Deploy()
	self.m_bShotDelayed = false
	self.m_flDelayedFire = 0.0
	
	return self.BaseClass:Deploy()
end

function SWEP:Reload()
	if ( self.m_bShotDelayed ) then
		return false
	end
	
	return self.BaseClass:Reload()
end

function SWEP:AddViewKick() -- Fix
	EASY_DAMPEN = 0.5
	MAX_VERTICAL_KICK = 8.0		// Degrees
	SLIDE_LIMIT = 5.0			// Seconds
	
	//Get the view kick
	local pPlayer = self.Owner
	
	if ( not IsValid( pPlayer ) ) then
		return
	end
	
	self:DoMachineGunKick( pPlayer, EASY_DAMPEN, MAX_VERTICAL_KICK, self.m_fFireDuration, SLIDE_LIMIT ) -- Fix; FireDuration?
end
--[[
function SWEP:GetProficiencyValues()
end]]-- Refer to SWEP.ProficiencyTable