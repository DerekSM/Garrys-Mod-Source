DEFINE_BASECLASS( "basecombatweapon" )

SWEP.Base = "basecombatweapon"

SWEP.Category 				= "Counter-Strike: Source"
SWEP.HoldType				= "ar2"
SWEP.CSMuzzleFlashes		= true

-- SWEP.FireOnEmpty = true
SWEP.HideWhenZoomed = false
SWEP.MaxSpeed = 250
SWEP.Price = -1
-- Black market prices?
-- Fix; move some of these to csbase_gun
SWEP.ArmorRatio = 1
SWEP.MuzzleFlashScale = 1
SWEP.MuzzleFlashStyle = "CS_MUZZLEFLASH_NORM"

SWEP.Penetration = 1
SWEP.Damage = 42	// Douglas Adams 1952 - 2001
SWEP.Range = 8192.0
SWEP.RangeModifier = 0.98
SWEP.Bullets = 1
SWEP.Primary.Cooldown = 0.15
SWEP.AccuracyQuadratic = 0
SWEP.AccuracyDivisor = -1 	// -1 = off
SWEP.AccuracyOffset = 0
SWEP.MaxInaccuracy = 0
SWEP.TimeToIdle = 2
SWEP.IdleInterval = 20
SWEP.Team = TEAM_UNASSIGNED
SWEP.WrongTeamMsg = ""

SWEP.ViewModelFlip = false
SWEP.HoldType = "ar2"

SWEP.BulletSpread = VECTOR_CONE_8DEGREES

SWEP.IdleOnEmpty = false

-- Fix; shells

function SWEP:Initialize()
	BaseClass.Initialize( self )
	
	self:SetHoldType( self.HoldType )
	
	self.m_bDelayFire = true
end

function SWEP:PlayEmptySound()
	self:EmitSound( "Default.ClipEmpty_Rifle" )
end

function SWEP:_SendWeaponAnim( iActivity )
	self:SendWeaponAnim( iActivity )
end

function SWEP:WeaponIdle()
	if ( BaseClass.WeaponIdle( self ) ) then
		self:SetWeaponIdleTime( CurTime() + self.IdleInterval )
	end
end

-- ItemPostFrame

function SWEP:GetMaxSpeed() -- Fix; move to basecombatweapon?
	return self.MaxSpeed
end

function SWEP:Precache()
	BaseClass.Precache( self )
	
	util.PrecacheSound( "Default.ClipEmpty_Rifle" )
	util.PrecacheSound( "Default.Zoom" )
end
--[[
function SWEP:UpdateShieldState()
	//empty by default.
	local pOwner = self.Owner
	
	if ( not IsValid( pOwner ) ) then
		return
	end
	
	if ( not pOwner:HasShield() ) then
		pOwner:SetShieldDrawnState( false )
		-- Fix; hitbox sets
	end
end

function SWEP:CanBeSelected()
	if ( not self:VisibleInWeaponSelection() ) then
		return false
	end
	
	return true
end

function SWEP:CanDeploy()
	local pPlayer = self.Owner
	if ( not IsValid( pPlayer ) or ( pPlayer:HasShield() and not self.CanUseWithShield )) then
		return false
	end
	
	return BaseClass.CanDeploy( self )
end]]

function SWEP:Holster( pSwitchingTo )
	local pPlayer = self.Owner
	
	if ( not IsValid( pPlayer ) ) then
		return false
	end
	
	return self:DefaultHolster( pSwitchingTo, self:GetHolsterActivity() )
end

function SWEP:SharedDeploy()
	-- Alpha
	
	self.m_flDecreaseShotsFired = CurTime()
	
	local pPlayer = self.Owner
	
	if ( IsValid( pPlayer ) ) then
		pPlayer.m_iShotsFired = 0
		pPlayer.m_bResumeZoom = false -- Fix
		pPlayer.m_iLastZoom = 0
		pPlayer:SetFOV( 0, 0 )
	end
	
	self:SetWeaponVisible( true )
	
	-- Fix; start using anim extensions?
	
	return self:DefaultDeploy( self:GetDeployActivity() )
end

function SWEP:GetBulletSpread() -- Fix; should this just be a variable? Check all weapons
	return self.BulletSpread
end
	
-- Fix; shouldremoveonround

function SWEP:Reload()
	error"This is a test to see if this is used anywhere"
end
	
function SWEP:_DefaultReload( iClipSize1, iClipSize2, iActivity ) -- Fix
	if ( BaseClass._DefaultReload( self, iClipSize1, iClipSize2, iActivity ) ) then
		-- SendReloadEvents() -- Fix; if we aren't doing this, then this func isn't needed
		self.Owner:DoAnimationEvent( PLAYERANIMEVENT_RELOAD )
		return true
	else
		return false
	end
end

function SWEP:PistolReload() -- Fix
	if ( not self:_DefaultReload( self.Primary.ClipSize, self.Secondary.ClipSize, self:GetReloadActivity() ) ) then
		return false
	end
	
	local pPlayer = self.Owner
	
	pPlayer.m_iShotsFired = 0
	
	return true
end

function SWEP:IsUseable()
	local pPlayer = self.Owner
	if ( not IsValid( pPlayer ) ) then
		return false
	end
	
	if ( self:Clip1() <= 0 and pPlayer:GetAmmoCount( self.Primary.Ammo ) <= 0 and self.Primary.ClipSize ~= -1 ) then
		return false
	end
	
	return true
end

function SWEP:ItemFrame()

	local pPlayer = self.Owner
	
	if ( not IsValid( pPlayer ) ) then 
		return 
	end
	
	if ( not pPlayer:KeyDown( IN_ATTACK ) and not pPlayer:KeyDown( IN_ATTACK2 ) ) then
		// no fire buttons down

		// The following code prevents the player from tapping the firebutton repeatedly 
		// to simulate full auto and retaining the single shot accuracy of single fire
		if ( self.m_bDelayFire ) then
			self.m_bDelayFire = false

			if ( pPlayer.m_iShotsFired > 15 ) then
				pPlayer.m_iShotsFired = 15
			end
			
			self.m_flDecreaseShotsFired = CurTime() + 0.4
		end

		// if it's a pistol then set the shots fired to 0 after the player releases a button
		if ( self:IsPistol() ) then
			pPlayer.m_iShotsFired = 0
		else
			if ( pPlayer.m_iShotsFired > 0 and self.m_flDecreaseShotsFired < CurTime() ) then
				self.m_flDecreaseShotsFired = CurTime() + 0.0225
				pPlayer.m_iShotsFired = pPlayer.m_iShotsFired - 1
			end
		end
	end
	
	BaseClass.ItemFrame( self )
end

-- Fix; bob, crosshairs, and PhysicsSplash
