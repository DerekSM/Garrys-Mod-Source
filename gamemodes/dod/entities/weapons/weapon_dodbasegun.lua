DEFINE_BASECLASS( "weapon_dodbase" )

SWEP.Base = "weapon_dodbase"
-- SWEP.m_bFireOnEmpty = true

function SWEP:SetupDataTables()
	BaseClass.SetupDataTables( self )
	self:NetworkVar( "Bool", 0, "Zoomed" )
end

function SWEP:Deploy()
	--self:SetZoomed( false ) -- Fix; crashes
	
	return BaseClass.Deploy( self )
end

function SWEP:Precache()
	BaseClass.Precache( self )

	// Precache all weapon ejections, since every weapon will appear in the game.
	util.PrecacheModel( "models/shells/shell_small.mdl" )
	util.PrecacheModel( "models/shells/shell_medium.mdl" )
	util.PrecacheModel( "models/shells/shell_large.mdl" )
	util.PrecacheModel( "models/shells/garand_clip.mdl" )
end

function SWEP:PrimaryAttack()
	local pPlayer = self.Owner
	
	if not IsValid( pPlayer ) then return end
	
	local iClip1 = self:Clip1()
	
	// Out of ammo?
	if ( iClip1 <= 0 ) then
		if ( self.m_bFireOnEmpty ) then
			self:PlayEmptySound()
			self:SetNextPrimaryFire( CurTime() + 0.2 )
		end
		
		return false
	end
	
	if ( pPlayer:WaterLevel() > 2 ) then
		self:PlayEmptySound()
		self:SetNextPrimaryFire( CurTime() + 1.0 )
		return false
	end
	
	// decrement before calling PlayPrimaryAttackAnim, so we can play the empty anim if necessary
	self:SetClip1( iClip1 - 1 )
	
	self:SendWeaponAnim( self:GetPrimaryAttackActivity() )
	
	// player "shoot" animation
	pPlayer:SetAnimation( PLAYER_ATTACK1 ) -- Fix
	
	fx.FireBullets( 
		pPlayer:EntIndex(),
		pPlayer:GetShootPos(),
		pPlayer:EyeAngles() + pPlayer:GetPunchAngle(),
		self:EntIndex(),
		Primary_Mode,
		bit.band( pPlayer:GetPredictionRandomSeed(), 255 ),
		self:GetWeaponAccuracy( pPlayer:GetAbsVelocity():Length2D() )
	)
	
	self:DoFireEffects()
	
	-- event shit
	
	self:SetNextPrimaryFire( CurTime() + self:GetFireDelay() )
	self:SetNextSecondaryFire( CurTime() + self:GetFireDelay() )
	self:SetWeaponIdleTime( CurTime() + self.IdleTimeAfterFire )
end

function SWEP:GetWeaponAccuracy( flPlayerSpeed )
	//snipers and deployable weapons inherit this and override when we need a different accuracy
	
	local flSpread = self.Accuracy
	
	if ( flPlayerSpeed > 45 ) then
		flSpread = flSpread + self.AccuracyMovePenalty
	end
	
	return flSpread
end

function SWEP:GetFireDelay()
	return self.FireDelay
end

function SWEP:DoFireEffects()
	local pPlayer = self.Owner
	
	if IsValid( pPlayer ) then
		pPlayer:MuzzleFlash()
	end
end

function SWEP:Reload()
	if ( self.m_bInReload ) then return false end
	
	local pPlayer = self.Owner
	local iClip1 = self:Clip1()
	
	if ( pPlayer:GetAmmoCount( self:GetPrimaryAmmoType() ) <= 0 and iClip1 <= 0 ) then
		pPlayer:HintMessage( HINT_AMMO_EXHAUSTED ) -- Fix; shared?
		return false
	end
	
	local iResult = self:_DefaultReload( self:GetMaxClip1(), self:GetMaxClip2(), self:GetReloadActivity() )
	if ( not iResult ) then
		return false
	end
	
	return true
end

function SWEP:IsSniperZoomed()
	return self:GetZoomed()
end
	