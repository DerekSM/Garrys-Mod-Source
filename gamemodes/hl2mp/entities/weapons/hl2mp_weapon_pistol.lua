DEFINE_BASECLASS( "weapon_hl2mpbasehlmpcombatweapon" )

SWEP.Base = "weapon_hl2mpbasehlmpcombatweapon"

PISTOL_FASTEST_REFIRE_TIME = 0.1
PISTOL_FASTEST_DRY_REFIRE_TIME = 0.2

PISTOL_ACCURACY_SHOT_PENALTY_TIME = 0.2		// Applied amount of time each shot adds to the time we must recover from
PISTOL_ACCURACY_MAXIMUM_PENALTY_TIME = 1.5	// Maximum penalty to deal out

SWEP.MinBurst = 1
SWEP.MaxBurst = 3
SWEP.FireRate = 0.5

SWEP.MinRange1 = 24
SWEP.MaxRange1 = 1500
SWEP.MinRange2 = 24
SWEP.MaxRange2 = 200

SWEP.FiresUnderwater = true -- Fix; is this a default SWEP variable?

function SWEP:GetBulletSpread()
	
	local ramp = RemapValClamped( self.m_flAccuracyPenalty, 0.0, PISTOL_ACCURACY_MAXIMUM_PENALTY_TIME, 0.0, 1.0 ) -- Fix
	
	// We lerp from very accurate to inaccurate over time
	-- Fix; make Vector lerp methods for mathlib consistency
	local cone = LerpVector( ramp, VECTOR_CONE_1DEGREES, VECTOR_CONE_6DEGREES )
	
	return cone
end

function SWEP:SetupDataTables()
	self:NetworkVar( "Float", 0, "SoonestPrimaryAttack" )
	self:NetworkVar( "Float", 1, "LastAttackTime" )
	self:NetworkVar( "Float", 2, "AccuracyPenalty" )
	self:NetworkVar( "Int", 0, "NumShotsFired" )
end

function SWEP:DryFire()
	self:WeaponSound( EMPTY )
	self:SendWeaponAnim( ACT_VM_DRYFIRE )
	
	self:SetSoonestPrimaryAttack( CurTime() + PISTOL_FASTEST_DRY_REFIRE_TIME )
	self:SetNextPrimaryFire( CurTime() + self:SequenceDuration() )
end

function SWEP:PrimaryAttack()
	if ( ( CurTime() - self:GetLastAttackTime() ) > 0.5 ) then
		self:SetNumShotsFired( 0 )
	else
		self:SetNumShotsFired( self:GetNumShotsFired() + 1 )
	end

	self:SetLastAttackTime( CurTime() )
	self:SetSoonestPrimaryAttack( CurTime() + PISTOL_FASTEST_REFIRE_TIME )

	pOwner = self.Owner

	if( IsValid( pOwner ) ) then
		// Each time the player fires the pistol, reset the view punch. This prevents
		// the aim from 'drifting off' when the player fires very quickly. This may
		// not be the ideal way to achieve this, but it's cheap and it works, which is
		// great for a feature we're evaluating. (sjb)
		pOwner:ViewPunchReset()
	end

	self.BaseClass:PrimaryAttack()

	// Add an accuracy penalty which can move past our maximum penalty time if we're really spastic
	self:SetAccuracyPenalty( self:GetAccuracyPenalty + PISTOL_ACCURACY_SHOT_PENALTY_TIME )
end

function SWEP:UpdatePenaltyTime()
	local pOwner = self.Owner
	
	if ( not IsValid( pOwner ) ) then
		return
	end
	
	// Check our penalty time decay
	if ( not pOwner:KeyDown( IN_ATTACK ) and self:GetSoonestPrimaryAttack() < CurTime() ) then
		self:SetAccuracyPenalty( self:GetAccuracyPenalty() - FrameTime() )
		self:SetAccuracyPenalty( math.Clamp( self:GetAccuracyPenalty() - FrameTime(), 0.0, PISTOL_ACCURACY_MAXIMUM_PENALTY_TIME ) )
	end
end

function SWEP:Think()
	self:UpdatePenaltyTime() -- Called earlier with pre/busy frame
	self.BaseClass:Think()
	
	if ( self.m_bInReload ) then
		return
	end
	
	local pOwner = self.Owner
	
	if ( not IsValid( pOwner ) ) then
		return
	end
	
	if ( pOwner:KeyDown( IN_ATTACK2 ) ) then
		local iDelay = CurTime() + PISTOL_FASTEST_REFIRE_TIME
		self:SetLastAttackTime( iDelay )
		self:SetSoonestPrimaryAttack( iDelay )
		self:SetNextPrimaryFire( iDelay )
	end
	
	//Allow a refire as fast as the player can click
	if ( not pOwner:KeyDown( IN_ATTACK ) and self:GetSoonestPrimaryAttack() < CurTime() ) then
		self:SetNextPrimaryFire( CurTime() - 0.1 )
	elseif ( pOwner:KeyDown( IN_ATTACK ) and self:GetNextPrimaryFire() < CurTime() and self:Clip1() <= 0 )
		self:DryFire()
	end
end

function SWEP:GetPrimaryAttackActivity()
	local iShots = self:GetNumShotsFired()
	
	if ( iShots < 1 ) then
		return ACT_VM_PRIMARYATTACK
	elseif ( iShots < 2 ) then
		return ACT_VM_RECOIL1
	elseif ( iShots < 3 ) then
		return ACT_VM_RECOIL2
	end
	
	return ACT_VM_RECOIL3
end

function SWEP:Reload()
	local fRet = self:_DefaultReload( self:GetMaxClip1(), self:GetMaxClip2(), ACT_VM_RELOAD )
	if ( fRet ) then
		self:WeaponSound( RELOAD )
		self:SetAccuracyPenalty( 0.0 )
	end
	return fRet
end

function SWEP:AddViewKick()
	local pPlayer = self.Owner
	
	if ( not IsValid( pPlayer ) ) then
		return
	end
	
	local viewPunch = Angle( self:SharedRandomFloat( "pistolpax", 0.25, 0.5 ),
							self:SharedRandomFloat( "pistolpay", -.6, .6 ),
							0.0 )
							
	pPlayer:ViewPunch( viewPunch )
end