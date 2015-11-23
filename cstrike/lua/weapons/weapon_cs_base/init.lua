AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

DEFINE_BASECLASS( "basecombatweapon" )

function SWEP:KeyValue( sKeyName, sValue )
	if ( not BaseClass.KeyValue( self, szKeyName, szValue ) and
	sKeyName.lower() == "ammo" ) then
		sValue = tonumber( sValue )
		if ( sValue < 0 ) then
			return false
		end
		
		if ( self.Primary.ClipSize > 0 ) then
			self.Owner:GiveAmmo( sValue, self.Primary.Ammo )
		end
		
		return true
	end
	
	return false
end

