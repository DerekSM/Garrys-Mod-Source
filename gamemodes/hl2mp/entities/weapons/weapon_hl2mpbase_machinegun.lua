DEFINE_BASECLASS( "weapon_hl2mpbase" )
SWEP.Base = "weapon_hl2mpbase"

SWEP.m_nShotsFired = 0			// Number of consecutive shots fired
SWEP.m_flNextSoundTime = 0.0	// real-time clock of when to make next sound

function SWEP:GetBulletSpread()
	return VECTOR_CONE_3DEGREES
end

function SWEP:PrimaryAttack()
	local pPlayer = self.Owner
	if ( not IsValid( pPlayer ) ) then
		return
	end
	
	// Abort here to handle burst and auto fire modes
	if ( (self:UsesClipsForAmmo1() and self:Clip1() == 0) or (not self:UsesClipsForAmmo1() and pPlayer:GetAmmoCount(self.Primary.Ammo) <= 0) ) then
		return
	end
	
	self.m_nShotsFired = self.m_nShotsFired + 1
	
	pPlayer:DoMuzzleFlash()
	
	// To make the firing framerate independent, we may have to fire more than one bullet here on low-framerate systems, 
	// especially if the weapon we're firing has a really fast rate of fire.
	local iBulletsToFire = 0
	local fireRate = self.FireRate
	
	while ( self:GetNextPrimaryFire() <= CurTime() ) do -- FIX; test this loop and the basecombatweapon loop with this
		// MUST call sound before removing a round from the clip of a CHLMachineGun
		self:WeaponSound( SINGLE, self:GetNextPrimaryFire() )
		self:SetNextPrimaryFire( self:GetNextPrimaryFire() + fireRate )
		iBulletsToFire = iBulletsToFire + 1
	end
	
	// Make sure we don't fire more than the amount in the clip, if this weapon uses clips
	if ( self:UsesClipsForAmmo1() ) then
		if ( iBulletsToFire > self:Clip1() ) then
			iBulletsToFire = self:Clip1()
		end
		
		self:SetClip1( self:Clip1() - iBulletsToFire )
	end
	
	// Fire the bullets
	local info = 
	{
		Num = iBulletsToFire,
		Src = pPlayer:GetShootPos(),
		Dir = pPlayer:GetAutoaimVector( AUTOAIM_5DEGREES ),
		Spread = pPlayer:GetAttackSpread( self ), -- Fix
		-- Distance = MAX_TRACE_LENGTH, -- Fix
		AmmoType = self.Primary.Ammo,
		Tracer = 2
	}
	
	self:FireBullets( info )
	
	//Factor in the view kick
	self:AddViewKick()
	
	if ( self:Clip1() <= 0 and pPlayer:GetAmmoCount( self.Primary.Ammo ) <= 0 ) then
		// HEV suit - indicate out of ammo condition
		pPlayer:SetSuitUpdate("!HEV_AMO0", false, 0)
	end
	
	self:SendWeaponAnim( self:GetPrimaryAttackActivity() )
	pPlayer:SetAnimation( PLAYER_ATTACK1 )
end

function SWEP:DoMachineGunKick( pPlayer, dampEasy, maxVerticleKickAngle, fireDurationTime, slideLimitTime )
	KICK_MIN_X = 0.2	//Degrees -- Fix; do these need to be global?
	KICK_MIN_Y = 0.2	//Degrees
	KICK_MIN_Z = 0.1	//Degrees
	
	local iSeed = bit.band( pPlayer:GetPredictionRandomSeed(), 255 )
	
	//Find how far into our accuracy degradation we are
	local duration = ( fireDurationTime > slideLimitTime ) and slideLimitTime or fireDurationTime
	local kickPerc = duration / slideLimitTime

	// do this to get a hard discontinuity, clear out anything under 10 degrees punch
	pPlayer:ViewPunchReset( 10 )

	//Apply this to the view angles as well
	local vecScratch = Angle( -( KICK_MIN_X + ( maxVerticleKickAngle * kickPerc ) ),
							-( KICK_MIN_Y + ( maxVerticleKickAngle * kickPerc ) ) / 3,
							KICK_MIN_Z + ( maxVerticleKickAngle * kickPerc ) / 8 )

	random.RandomSeed( iSeed )

	//Wibble left and right
	if ( random.RandomInt( -1, 1 ) >= 0 )
		vecScratch.y = vecScratch.y * -1
	end

	random.RandomSeed( iSeed + 1 )

	//Wobble up and down
	if ( random.RandomInt( -1, 1 ) >= 0 )
		vecScratch.z = vecScratch.z * -1
	end


	//Clip this to our desired min/max
	util.ClipPunchAngleOffset( vecScratch, pPlayer:GetViewPunchAngles(), Angle( 24.0, 3.0, 1.0 ) ) -- Fix

	//Add it to the view punch
	// NOTE: 0.5 is just tuned to match the old effect before the punch became simulated
	pPlayer:ViewPunch( vecScratch * 0.5 )
end

function SWEP:Deploy()
	self.m_nShotsFired = 0
	
	return self.BaseClass:Deploy()
end

function SWEP:WeaponSoundRealtime( shoot_type )
	local numBullets = 0
	
	// ran out of time, clamp to current
	if ( self.m_flNextSoundTime < CurTime() ) then
		self.m_flNextSoundTime = CurTime()
	end
	
	// make enough sound events to fill up the next estimated think interval
	local dt = math.Clamp( self.m_flAnimTime - self.m_flPrevAnimTime, 0, 0.2 ) -- Fix; random variables
	if ( self.m_flNextSoundTime < CurTime() + dt ) then
		self:WeaponSound( SINGLE_NPC, self.m_flNextSoundTime )
		self.m_flNextSoundTime = self.m_flNextSoundTime + self:GetFireRate()
		numBullets = numBullets + 1
	end
	-- Repeat to fill up sound queue
	if ( self.m_flNextSoundTime < CurTime() + dt ) then
		self:WeaponSound( SINGLE_NPC, self.m_flNextSoundTime )
		self.m_flNextSoundTime = self.m_flNextSoundTime + self:GetFireRate()
		numBullets = numBullets + 1
	end
	
	return numBullets
end

-- ItemPostFrame