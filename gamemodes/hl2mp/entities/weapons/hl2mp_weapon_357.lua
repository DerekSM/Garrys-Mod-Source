DEFINE_BASECLASS( "weapon_hl2mpbasehlmpcombatweapon" )
SWEP.Base = "weapon_hl2mpbasehlmpcombatweapon"

SWEP.ReloadsSingly = false
SWEP.FiresUnderwater = false

function SWEP:PrimaryAttack()
	// Only the player fires this way so we can cast
	local pPlayer = self.Owner
	
	if ( not IsValid( pPlayer ) ) then
		return
	end
	
	local iClip1 = self:Clip1()
	
	if ( iClip <= 0 ) then
		if ( self.FireOnEmpty ) then
			self:Reload()
		else
			self:WeaponSound( EMPTY )
			self:SetNextPrimaryFire( 0.15 )
		end
		
		return
	end
	
	self:WeaponSound( SINGLE )
	pPlayer:DoMuzzleFlash()
	
	self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
	pPlayer:SetAnimation( PLAYER_ATTACK1 )
	
	self:SetNextPrimaryFire( CurTime() + 0.75 )
	self:SetNextSecondaryFire( CurTime() + 0.75 )
	
	iClip1 = iClip1 - 1
	self:SetClip1( iClip1 )
	
	local vecSrc = pPlayer:GetShootPos()
	local vecAiming = pPlayer:GetAutoaimVector( AUTOAIM_5DEGREES )
	
	// Fire the bullets, and force the first shot to be perfectly accuracy
	pPlayer:FireBullets( {
		Src = vecSrc,
		Dir = vecAiming,
		Spread = vec3_origin,
		-- Distance = MAX_TRACE_LENGTH,
		Attacker = pPlayer,
		AmmoType = self.Primary.Ammo
	} )
		
	
	//Disorient the player
	local angles = pPlayer:GetLocalAngles()
	
	angles.x = angles.x + random.RandomInt( -1, 1 )
	angles.y = angles.y + random.RandomInt( -1, 1 )
	angles.z = 0
	
	if ( SERVER ) then
		pPlayer:SnapEyeAngles( angles ) -- Fix
	end
	
	pPlayer:ViewPunch( Angle( -8, random.RandomFloat( -2, 2 ), 0 ) )
	
	if ( iClip1 and pPlayer:GetAmmoCount( self.Primary.Ammo ) <= 0 ) then
		// HEV suit - indicate out of ammo condition
		pPlayer:SetSuitUpdate( "!HEV_AMO0", false, 0 ) -- Fix
	end
end