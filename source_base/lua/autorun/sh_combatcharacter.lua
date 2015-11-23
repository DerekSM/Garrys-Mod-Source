local _R = debug.getregistry()

function _R.Player:SwitchToNextBestWeapon( pCurrent )
	local pNewWeapon = GAMEMODE:GetNextBestWeapon( self, pCurrent )
	
	if ( ( IsValid( pNewWeapon ) ) and ( pNewWeapon ~= pCurrent ) ) then
		return self:SwitchToWeapon( pNewWeapon )
	end
	
	return false
end
-- HUGE FIX! Replace all of these with the 2013 versions across all files
function _R.Player:SwitchWeapon( pWeapon )
	if ( isentity( pWeapon ) ) then
		if ( not IsValid( pWeapon ) ) then
			return
		end
		
		pWeapon = pWeapon:GetClass()
	end
	
	local hActiveWeapon = self:GetActiveWeapon()
	
	if ( not IsValid( hActiveWeapon ) ) then
		return
	// Already have it out?
	elseif ( hActiveWeapon:GetClass() == pWeapon ) then
		if ( not hActiveWeapon:IsWeaponVisible() ) then
			return hActiveWeapon:SharedDeploy() -- Fix; do we need to initialize? Do we need to call both? This is a really hacky func
		end
		
		return false
	elseif ( not self:CanSwitchToWeapon( pWeapon ) ) then
		return false
	elseif ( not hActiveWeapon:Holster() ) then -- Fix; we made a copy
		return false
	end
	
	self:SetActiveWeapon( pWeapon )
	return pWeapon:SharedDeploy() -- Fix; need to initialize
end

function _R.Player:CanSwitchToWeapon( pWeapon )
	local pVehicle = self:GetVehicle()
	local pActiveWeapon = self:GetActiveWeapon()
	
	if ( IsValid( pVehicle ) and not pPlayer:UsingStandardWeaponsInVehicle() ) then -- Fix; fucking awful function name
		return false
	elseif ( not pWeapon:HasAnyAmmo() and not self:GetAmmoCount( pWeapon.Primary.Ammo ) ) then -- Fix; not using an accessor
		return false
	elseif ( not pWeapon:CanDeploy() ) then -- Fix; I don't remember making this function
		return false
	elseif ( IsValid( pActiveWeapon ) and not pActiveWeapon:CanHolster() ) then
		return false
	end
	
	return true
end

function _R.Player:OwnsWeaponType( pszWeapon, iSubType ) -- Fix, will HasWeapon work?
	// Check for duplicated
	for _, pWeapon in ipairs( self:GetWeapons() ) do
		// Make sure it matches the subtype
		if ( pWeapon:GetClass() == pszWeapon and pWeapon:GetSubType() == iSubType ) then
			return pWeapon
		end
	end
	
	return NULL
end