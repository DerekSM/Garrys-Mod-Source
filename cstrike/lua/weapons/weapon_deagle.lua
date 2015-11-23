SWEP.Base = "weapon_csbase_gun"

-- Forced values
SWEP.Weight = 7
SWEP.Primary.ClipSize = 7

SWEP.BaseAccuracy = 0.9

function SWEP:PrimaryAttack()
	local pPlayer = self.Owner
	if ( not IsValid( pPlayer ) ) then return end
	
	if ( not pPlayer:IsFlagSet( FL_ONGROUND ) ) then
		self:Shoot( 1.5 * (1 - self.m_flAccuracy) )
	elseif ( pPlayer:GetAbsVelocity():Length2D() > 5 ) then
		self:Shoot( 0.25 * (1 - self.m_flAccuracy) )
	elseif ( pPlayer:IsFlagSet( FL_DUCKING ) ) then
		self:Shoot( 0.115 * (1 - self.m_flAccuracy) )
	else
		self:Shoot( 0.13 * (1 - self.m_flAccuracy) )
	end
end

function SWEP:Shoot( flSpread )
	local pPlayer = self.Owner
	
	pPlayer.m_iShotsFired = pPlayer.m_iShotsFired + 1
	
	if ( pPlayer.m_iShotsFired > 1 ) then -- Fix
		return
	end
	
	// Mark the time of this shot and determine the accuracy modifier based on the last shot fired...
	self.m_flAccuracy = self.m_flAccuracy - (0.35 * (0.4 - (CurTime() - self.m_flLastFire))) -- Fix
	
	if ( self.m_flAccuracy > self.BaseAccuracy ) then
		self.m_flAccuracy = 0.9
	elseif ( self.m_flAccuracy < 0.55 ) then -- fix
		self.m_flAccuracy = 0.55
	end
	
	self.m_flLastFire = CurTime()
	local clip1 = self:Clip1()
	
	if ( clip1 <= 0 ) then
		if ( self.m_bFireOnEmpty() ) then
			self:PlayEmptySound()
			self:SetNextPrimaryFire( CurTime() + 0.2 )
		end
		
		return
	end
	
	self:SetClip1( clip1 - 1 )
	
	pPlayer:MuzzleFlash()
	
	if ( clip1 > 1 ) then
		self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
	else
		self:SendWeaponAnim( ACT_VM_DRYFIRE )
	end
	
	//SetPlayerShieldAnim();
	
	// player "shoot" animation
	pPlayer:SetAnimation( PLAYER_ATTACK1 )

	//pPlayer->m_iWeaponVolume = BIG_EXPLOSION_VOLUME;
	//pPlayer->m_iWeaponFlash = BRIGHT_GUN_FLASH;
	
	self:_FireBullets
	(
		pPlayer:GetShootPos(),
		pPlayer:EyeAngles() + 2.0 * pPlayer:GetPunchAngle(),
		bit.band( pPlayer:GetPredictionRandomSeed(), 255 ),
		flSpread
	) // bullets
	
	self:SetNextPrimaryFire( CurTime() + self.CycleTime )
	
	self:SetWeaponIdleTime( CurTime() + 1.8 )
	
	local punchAngle = pPlayer:GetPunchAngle()
	punchAngle.p = punchAngle.p - 2
	pPlayer:SetPunchAngle( punchAngle )
	
	//ResetPlayerShieldAnim();
end

function SWEP:Reload()
	if ( not self:PistolReload() ) then
		return false
	end
	
	self.m_flAccuracy = self.BaseAccuracy
	return true
end

function SWEP:WeaponIdle()