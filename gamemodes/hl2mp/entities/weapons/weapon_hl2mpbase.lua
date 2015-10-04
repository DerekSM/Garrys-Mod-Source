-- FIX: here for future reminder; make private variables into locals and do not attach them to the SWEP table. Start reading the header files before.
-- For protected, put them in the SWEP table for inheritance, but do not make accessors/modifiers. Hungarian notation = protected/private, not = public

DEFINE_BASECLASS( "basecombatweapon" )
SWEP.Base = "basecombatweapon"

SWEP.m_flNextResetCheckTime = 0
SWEP.m_flPrevAnimTime = 0 -- Fix; where are these used?

local m_vOriginalSpawnOrigin
local m_vOriginalSpawnAngles

function SWEP:Initialize()
	self.BaseClass:Initialize()
	
	m_vOriginalSpawnOrigin = self:GetPos()
	m_vOriginalSpawnAngles = self:GetAngles()
end

function SWEP:GetOriginalSpawnOrigin()
	return m_vOriginSpawnOrigin()
end

function SWEP:GetOriginalSpawnAngles()
	return m_vOriginSpawnAngles()
end

function SWEP:WeaponSound( sound_type, soundtime )
	local shootsound = self.ShootSounds[ sound_type ]
	if ( not shootsound or shootsound == "" ) then
		return
	end
	
	if ( CLIENT ) then
		self.Owner:EmitSound( shootsound )
	else
		self.BaseClass:WeaponSound( sound_type, soundtime )
	end
end

function SWEP:ObjectCaps()
	return bit.band( self.BaseClass:ObjectCaps(), bit.bnot( FCAP_IMPULSE_USE ) )
end

function SWEP:FireBullets( info )
	info:SetDamage( self.Damage ) -- FIX!
	
	self.BaseClass:FireBullets( info )
end