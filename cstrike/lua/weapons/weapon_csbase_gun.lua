DEFINE_BASECLASS( "weapon_cs_base" ) -- Fix; make default spawn method?

SWEP.Base = "weapon_cs_base"

SWEP.BaseAccuracy = 0.2

SWEP.Special =
{
	Damage = 18,
	RangeModifier = 0.9,
	SoundType = "primary"
}

SWEP.Primary.Cooldown = 0.5
SWEP.Secondary.Cooldown = 0.3

function SWEP:Initialize()
	--self.m_bBurstMode = false
	self.m_flAccuracy = self.BaseAccuracy
	self.m_bDelayFire = false
	
	BaseClass.Initialize( self )
end

function SWEP:SharedDeploy()
	self.m_flAccuracy = self.BaseAccuracy
	self.m_bDelayFire = false
	
	return BaseClass.SharedDeploy( self )
end

function SWEP

function SWEP:IsSpecialActive() -- Fix
	return self.m_bInSpecial
end

function SWEP:LookupSound( sSound )
	sSound = sSound:lower()
	
	if ( sSound == "primary" and self.m_bInSpecial ) then -- We are silenced
		return self.Sounds[ self.Special.SoundType:lower() ]
	end
	
	return ( self.Sounds[ sSound:lower() ] )
end

function SWEP:PrimaryAttack()
	self:Shoot( self.m_flAccuracy )
	
	self:SetNextPrimaryFire( CurTime() + self.Primary.Cooldown )
	self:SetNextSecondaryFire( CurTime() + self.Primary.Cooldown )
end

-- Shooting inheritance:
-- Lower classes override the PrimaryAttack method and call Shoot from there
-- This is to prevent useless BaseClass calls that could be solved in a single function
-- Subsequently, the weapons will override KickBack for specific case definition

function SWEP:KickBack()
	--self.Owner:KickBack( 0, 0, 0, 0, 0, 0, 0 )
end

function SWEP:Shoot( flSpread, flCycleTime )
	local pPlayer = self.Owner
	
	if ( not IsValid( pPlayer ) ) then
		return false
	end
	
	self.m_bDelayFire = true
	pPlayer.m_iShotsFired = pPlayer.m_iShotsFired + 1
	
	// These modifications feed back into flSpread eventually.
	if ( self.AccuracyDivisor ~= -1 ) then
		local iShotsFired = pPlayer.m_iShotsFired
		
		if ( self.AccuracyQuadratic ~= 0 ) then
			iShotsFired = iShotsFired ^ 2
		else
			iShotsFired = iShotsFired ^ 3
		end
		
		self.m_flAccuracy = ( iShotsFired / self.AccuracyDivisor ) + self.AccuracyOffset
		
		if ( self.m_flAccuracy > self.MaxInaccuracy ) then
			self.m_flAccuracy = self.MaxInaccuracy
		end
	end
	
	// Out of ammo?
	if ( self:Clip1() <= 0 ) then
		if ( self.m_bFireOnEmpty ) then
			self:PlayEmptySound()
			self:SetNextPrimaryFire( CurTime() + 0.2 )
		end
		
		return false
	end
	
	self:_SendWeaponAnim( self:LookupActivity( "primary" ) )
	
	self:SetClip1( self:Clip1() - 1 )
	
	self:_FireBullets
	(
		pPlayer:GetShootPos(),
		pPlayer:EyeAngles() + 2.0 * pPlayer:GetPunchAngle(),
		-- We don't need to specify primary or secondary fire since no guns fire from secondary
		-- Silencer/zoomed cases are handled internally
		bit.band( pPlayer:GetPredictionRandomSeed(), 255 ),
		flSpread
	)
	
	// player "shoot" animation
	self:DoFireEffects()
	self:EmitSound( self:LookupSound( "primary" ) )
	
	self:SetWeaponIdleTime( CurTime() + self.TimeToIdle )
	
	flCycleTime = flCycleTime or self.Primary.Cooldown
	
	self:SetNextPrimaryFire( CurTime() + flCycleTime )
	self:SetNextSecondaryFire( CurTime() + flCycleTime )
	
	-- In-case FireBullets killed us, do validity check here instead of KickBack
	if ( not IsValid( pPlayer ) ) then
		return true
	end
	
	-- We could really fit the KickBack conditions in the PrimaryFire as well,
	-- but this allows for some cleaner separation and SWEP equivalent of the player method
	self:KickBack()
	
	return true
end

function SWEP:Reload() -- Fix; holstering during a reload, then pulling it back out and trying again won't work
	if ( not self:_DefaultReload( self.Primary.ClipSize, self.Secondary.ClipSize, self:GetReloadActivity() ) ) then 
		return false 
	end
	
	local pPlayer = self.Owner
	
	pPlayer:SetAnimation( pPlayer:LookupAnimation( "reload" ) ) -- Fix
	
	self.m_flAccuracy = self.BaseAccuracy
	pPlayer.m_iShotsFired = 0
	self.m_bDelayFire = false
	
	return true
end

function SWEP:_FireBullets( vOrigin, vAngles, iSeed, flSpread )
	local pPlayer = self.Owner
	
	if ( not IsValid( pPlayer ) ) then
		return
	end
	
	if ( not pPlayer:IsDormant() ) then
		if ( self.m_bSilenced ) then
			pPlayer:DoAnimationEvent( pPlayer:LookupAnimEvent( "secondary" ) )
		else
			pPlayer:DoAnimationEvent( pPlayer:LookupAnimEvent( "primary" ) )
		end
	end
	
	if ( SERVER ) then
		// if this is server code, send the effect over to client as temp entity
		// Dispatch one message for all the bullet impacts and sounds.
		bDoEffects = false // no effects on server

		// Let the player remember the usercmd he fired a weapon on. Assists in making decisions about lag compensation.
		--pPlayer:NoteWeaponFired() -- Fix
	end
	
	iSeed = iSeed + 1
	
	local iDamage = self.Damage
	local flRange = self.Range
	local iPenetration = self.Penetration
	local flRangeModifier = self.RangeModifier
	local sAmmoType = self.Primary.Ammo
	error"fix this"
	if ( self:IsSpecialActive() ) then
		print"special"
		iDamage = self.Special.Damage
		flRangeModifier = self.Special.RangeModifier
	end
	
	// Fire bullets, calculate impacts & effects

	if ( SERVER ) then
		// Move other players back to history positions based on local player's lag
		pPlayer:LagCompensation( true )
	end
	
	for iBullets = 0, self.Bullets - 1, 1 do
		random.SetSeed( iSeed ) // init random system with this seed
		
		// Get circular gaussian spread.
		local x = random.RandomFloat( -0.5, 0.5 ) + random.RandomFloat( -0.5, 0.5 )
		local y = random.RandomFloat( -0.5, 0.5 ) + random.RandomFloat( -0.5, 0.5 )
		
		iSeed = iSeed + 1 // use new seed for next bullet
		
		pPlayer:FireBullet(
			vOrigin,
			vAngles,
			flSpread,
			flRange,
			iPenetration,
			sAmmoType,
			iDamage,
			flRangeModifier,
			bDoEffects,
			x,
			y
		)
	end
	
	if ( SERVER ) then
		pPlayer:LagCompensation( false )
	end
end
