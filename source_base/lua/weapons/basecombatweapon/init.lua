AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

-- Fix; precache stuff

util.AddNetworkString( "Source Base - Clientside Deploy" )

function SWEP:ObjectCaps()
	local caps = debug.getregistry().Entity.ObjectCaps( self )
	if ( not self:IsFollowingEntity() and not self:HasSpawnFlags( SF_WEAPON_NO_PLAYER_PICKUP ) ) then -- Fix
		caps = bit.bor( caps, FCAP_IMPULSE_USE )
	end
	
	return caps
end

function SWEP:GetCapabilities()
	return 0
end

function SWEP:KeyValue( key, value )
	print( "CBaseCombatWeapon output: " .. name )
end
	
function SWEP:AcceptInput( name )
	print( "CBaseCombatWeapon input: " .. name )
	if ( name == "HideWeapon" ) then
		self:SetWeaponVisible( false )
	end
end
