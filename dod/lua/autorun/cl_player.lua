local _R = debug.getregistry()

local cl_autoreload = CreateClientConVar( "cl_autoreload", "1", { FCVAR_USERINFO, FCVAR_ARCHIVE }, "Set to 1 to auto reload your weapon when it is empty" )
local cl_autorezoom = CreateClientConVar( "cl_autorezoom", "1", { FCVAR_USERINFO, FCVAR_ARCHIVE }, "When set to 1, sniper rifles and bazooka weapons will automatically raise after each shot" )

function _R.Player:ShouldAutoReload()
	return cl_autoreload:GetBool()
end

local cl_muzzleflash_dlight_3rd = CreateClientConVar( "cl_muzzleflash_dlight_3rd", "1" )

function _R.Player:ProcessMuzzleFlashEvent()
	local pLocalPlayer = LocalPlayer()
	
	// Reenable when the weapons have muzzle flash attachments in the right spot
	if ( self == pLocalPlayer ) then
		return // don't show own world muzzle flashs in for localplayer
	end
	
	if ( IsValid( pLocalPlayer ) and pLocalPlayer:GetObserverMode() == OBS_MODE_IN_EYE and pLocalPlayer:GetObserverTarget() == self ) then
		// also don't show in 1st person spec mode
		return
	end
	
	local pWeapon = self:GetActiveWeapon()
	if ( not IsValid( pWeapon ) ) then
		return
	end
	
	local iMuzzleFlashAttachment = 1
	local iEjectBrassAttachment = 2
	
	// If we have an attachment, then stick a light on it
	if ( cl_muzzleflash_dlight_3rd:GetBool() and pWeapon:GetAttachment( iMuzzleFlashAttachment ) ) then
	end
end