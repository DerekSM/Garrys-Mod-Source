SWEP.Base = "weapon_cs_base"

SWEP.Type = "pistol"

SWEP.m_flLastFire = 0
SWEP.MaxAccuracy = 0.92
SWEP.MinAccuracy = 0.725
-- There really is no consistency with Valve's modifier numbers here
SWEP.SpreadModifiers =
{
	[1] = 1.5,
	[2] = 0.255,
	[3] = 0.075,
	[4] = 0.15,
	[5] = 0.25,
	[6] = 0.275
}

SWEP.Primary.Automatic = false
SWEP.Primary.Cooldown = 0.2
SWEP.TimeToIdle = 2
SWEP.IdleInterval = 4

SWEP.Sounds =
{
	[ "empty" ] = "Default.ClipEmpty_Pistol"
}

function SWEP:PrimaryAttack()
	local pPlayer = self.Owner
	if ( not IsValid( pPlayer ) ) then return end
	
	if ( pPlayer:IsFlagSet( FL_ONGROUND ) ) then
		self:Shoot( self.SpreadModifiers[1] * (1 - self.m_flAccuracy) )
	elseif ( pPlayer:GetAbsVelocity():Length2D() > 5 ) then
		self:Shoot( self.SpreadModifiers[2] * (1 - self.m_flAccuracy) )
	elseif ( pPlayer:IsFlagSet( FL_DUCKING ) ) then
		self:Shoot( self.SpreadModifiers[3] * (1 - self.m_flAccuracy) )
	else
		self:Shoot( self.SpreadModifiers[4] * (1 - self.m_flAccuracy) )
	end
end

function SWEP:Shoot( flSpread )
	local pPlayer = self.Owner
	
	// Mark the time of this shot and determine the accuracy modifier based on the last shot fired...
	self.m_flAccuracy = self.m_flAccuracy - self.SpreadModifiers[5] * (self.SpreadModifiers[6] - (CurTime() - self.m_flLastFire))
	
	if ( self.m_flAccuracy > self.MaxAccuracy ) then
		self.m_flAccuracy = self.MaxAccuracy
	elseif (self.m_flAccuracy < self.MinAccuracy) then
		self.m_flAccuracy = self.MinAccuracy
	end
	
	self.m_flLastFire = CurTime()
	local clip = self:Clip1()
	
	if ( clip <= 0 ) then
		if (self.m_bFireOnEmpty) then -- Fix
			self:PlayEmptySound()
			self:SetNextPrimaryFire( CurTime() + 0.2 )
		end
		
		return
	end
	
	clip = clip - 1
	self:SetClip1( clip )
	
	pPlayer:MuzzleFlash()
	
	if ( clip > 0 ) then
		self:_SendWeaponAnim( self:GetPrimaryActivity() )
	else
		self:_SetWeaponAnim( self:GetEmptyActivity() )
	end
	
	// player "shoot" animation
	pPlayer:SetAnimation( pPlayer:GetPrimaryAnimation() )
	
	self:FireBullets
	(
		pPlayer:GetShootPos(),
		pPlayer:EyeAngles() + 2.0 * pPlayer:GetPunchAngle(),
		bit.band( pPlayer:GetPredictionRandomSeed(), 255 ),
		flSpread
	)
	
	self:SetNextPrimaryFire( CurTime() + self.Primary.Cooldown )
	self:SetNextSecondaryFire( CurTime() + self.Primary.Cooldown )
	
	self:SetWeaponIdleTime( CurTime() + 2 )
	
	local angle = pPlayer:GetPunchAngle()
	angle.x = angle.x - 2
	pPlayer:SetPunchAngle( angle )
end

function SWEP:PlayEmptySound()
	self:EmitSound( self.Sounds[ "empty" ] )
end

function SWEP:Reload()
	if ( not self:_DefaultReload( self.Primary.ClipSize, self.Secondary.ClipSize, self:GetReloadActivity() ) ) then
		return false
	end
	
	local pPlayer = self.Owner
	
	pPlayer.m_iShotsFired = 0
	self.m_flAccuracy = self.BaseAccuracy
	
	return true
end

function SWEP:Precache()
	BaseClass.Precache( self )
	
	util.PrecacheSound( "Default.ClipEmpty_Pistol" )
end
