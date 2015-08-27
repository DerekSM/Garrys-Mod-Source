do return end

-- Fix this one day instead of doing a bunch of shitty overrides

ammo = {}

local AmmoTypes = {}

function ammo.GetByIndex( nAmmoIndex )
	return AmmoTypes[ nAmmoIndex ]
end

function ammo.Index( psz )
	local i

	if ( not psz ) then
		return -1
	end
	
	for i = 1, #AmmoTypes do
		if ( psz == AmmoTypes[i].name ) then
			return i
		end
	end
	
	return -1
end

function ammo.PlayerDamage( nAmmoIndex )
	if ( nAmmoIndex < 1 or nAmmoIndex > #AmmoTypes ) then
		return 0
	end
	
	return AmmoTypes[nAmmoIndex].plydmg
end

function ammo.NPCDamage( nAmmoIndex )
	if ( nAmmoIndex < 1 or nAmmoIndex > #AmmoTypes ) then
		return 0
	end
	
	return AmmoTypes[nAmmoIndex].npcdmg
end

function ammo.MaxCarry( nAmmoIndex )
	if ( nAmmoIndex < 1 or nAmmoIndex > #AmmoTypes ) then
		return 0
	end
	
	return AmmoTypes[nAmmoIndex].maxcarry
end

function ammo.DamageType( nAmmoIndex )
	if ( nAmmoIndex < 1 or nAmmoIndex > #AmmoTypes ) then
		return 0
	end
	
	return AmmoTypes[nAmmoIndex].dmgtype
end

function ammo.MinSplashSize( nAmmoIndex )
	if ( nAmmoIndex < 1 or nAmmoIndex > #AmmoTypes ) then
		return 0
	end
	
	return AmmoTypes[nAmmoIndex].minsplash
end

function ammo.MaxSplashSize( nAmmoIndex )
	if ( nAmmoIndex < 1 or nAmmoIndex > #AmmoTypes ) then
		return 0
	end
	
	return AmmoTypes[nAmmoIndex].maxsplash
end

function ammo.TracerType( nAmmoIndex )
	if ( nAmmoIndex < 1 or nAmmoIndex > #AmmoTypes ) then
		return 0
	end
	
	return AmmoTypes[nAmmoIndex].tracer
end

function ammo.DamageForce( nAmmoIndex )
	if ( nAmmoIndex < 1 or nAmmoIndex > #AmmoTypes ) then
		return 0
	end
	
	return AmmoTypes[nAmmoIndex].minsplash
end