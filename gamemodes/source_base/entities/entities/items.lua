-- This is all supposed to be serverside only. What the fuck is this random header file. Fix

// Armor given by a battery
MAX_NORMAL_BATTERY = 100

// Ammo counts given by ammo items
SIZE_AMMO_PISTOL = 20
SIZE_AMMO_PISTOL_LARGE = 100
SIZE_AMMO_SMG1 = 45
SIZE_AMMO_SMG1_LARGE = 225
SIZE_AMMO_AR2 = 20
SIZE_AMMO_AR2_LARGE = 100
SIZE_AMMO_RPG_ROUND	= 1
SIZE_AMMO_SMG1_GRENADE = 1
SIZE_AMMO_BUCKSHOT = 20
SIZE_AMMO_357 = 6
SIZE_AMMO_357_LARGE	= 20
SIZE_AMMO_CROSSBOW = 6
SIZE_AMMO_AR2_ALTFIRE = 1

SF_ITEM_START_CONSTRAINED = 0x00000001

function ENT:ObjectCaps()
	return bit.bor( self.BaseClass:ObjectCaps(), FCAP_IMPULSE_USE, FCAP_WCEDIT_POSITION )
end

function ENT:GetOriginalSpawnOrigin()
	return self.m_vOriginalSpawnOrigin
end

function ENT:GetOriginalSpawnAngles()
	return self.m_vOriginalSpawnAngles
end

function ENT:SetOriginalSpawnAngles( origin )
	self.m_vOriginalSpawnOrigin = origin
end

function ENT:SetOriginalSpawnAngles( angles )
	self.m_vOriginalSpawnAngles = angles
end