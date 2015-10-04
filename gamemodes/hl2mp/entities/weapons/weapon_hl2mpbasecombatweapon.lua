DEFINE_BASECLASS( "weapon_hl2mpbaseweapon" )

SWEP.Base = "weapon_hl2mpbaseweapon"

local sk_auto_reload_time = CreateConVar( "sk_auto_reload_time", "3", FCVAR_REPLICATED )

-- Fix; holster frame

ACTIVITY_NOT_AVAILABLE = -1 -- Fix; move to proper place

function SWEP:Lower()
	// Don't bother if we don't have the animation
	if ( self:SelectWeightedSequence( ACT_VM_IDLE_LOWERED ) == ACTIVITY_NOT_AVAILABLE ) then
		return false
	end
	
	self.m_bLowered = true
	return true
end

function SWEP:Ready()
	// Don't bother if we don't have the animation
	if ( self:SelectWeightedSequence( ACT_VM_LOWERED_TO_IDLE ) == ACTIVITY_NOT_AVAILABLE ) then
		return false
	end
	
	self.m_bLowered = false
	self.m_flRaiseTime = CurTime() + 0.5
	return true
end

function SWEP:Deploy()
	// If we should be lowered, deploy in the lowered position
	// We have to ask the player if the last time it checked, the weapon was lowered
	local pPlayer = self.Owner
	if ( IsValid( pPlayer ) and pPlayer:IsPlayer() and 
		pPlayer:IsWeaponLowered() and
		self:SelectWeightedSequence( ACT_VM_IDLE_LOWERED ) ~= ACTIVITY_NOT_AVALIABLE and
		self:DefaultDeploy( ACT_VM_IDLE_LOWERED, self:GetAnimPrefix() ) ) then
			
		self.m_bLowered = true
			
		// Stomp the next attack time to fix the fact that the lower idles are long
		pPlayer:SetNextAttack( CurTime() + 1.0 ) -- Fix; it would be much better to get lua exposure for this to prevent hacky command shit
		self:SetNextPrimaryFire( CurTime() + 1.0 )
		self:SetNextSecondaryFire( CurTime() + 1.0 )
		return true
	end
	
	self.m_bLowered = false
	return self.BaseClass:Deploy()
end

function SWEP:ItemHolsterFrame()
	-- Fix; setup contextual think instead of hacky timers
end

function SWEP:Holster( pSwitchingTo )
	if ( self.BaseClass:Holster( pSwitchingTo ) ) then
		self:SetWeaponVisible( false ) -- Fix; check if this was already made
		self.m_flHolsterTime = CurTime()
		return true
	end
	
	return false
end

function SWEP:WeaponShouldBeLowered()
	local act = self:GetIdealActivity()
	
	if ( act ~= ACT_VM_IDLE_LOWERED and act ~= ACT_VM_IDLE_LOWERED and 
		act ~= ACT_VM_IDLE_LOWERED and act ~= ACT_VM_IDLE_LOWERED and 