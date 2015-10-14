DEFINE_BASECLASS( "weapon_dodbasegun" )
SWEP.Base = "weapon_dodbasegun"

SWEP.m_iAltFireHint = HINT_USE_MELEE
SWEP.SecondaryDeathNoticeName = "punch"
SWEP.WeaponID = WEAPON_NONE

function SWEP:SecondaryAttack()
	local pPlayer = self.Owner
	
	if ( not IsValid( pPlayer ) ) then return end
	
	if ( self.m_bInReload ) then
		m_bInReload = false;
		pPlayer:SetNextAttack( CurTime() )
	elseif ( pPlayer:GetNextAttack() > CurTime() ) then
		return
	end

	self:Punch()

	// start calling ItemPostFrame
	self.Owner:SetNextAttack( CurTime() ) -- Fix; why are we setting this twice in the case of a punch?

	if ( SERVER ) then
		pPlayer:RemoveHintTimer( m_iAltFireHint )
	end
end

function SWEP:Reload()
	local bSuccess = BaseClass.Reload( self )

	if ( bSuccess ) then
		self:SetNextSecondaryFire( CurTime() )
	end

	return bSuccess
end