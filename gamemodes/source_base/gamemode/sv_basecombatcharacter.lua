local _R = debug.getregistry()

function _R.Player:GetAttackSpread( pWeapon, pTarget )
	if ( pWeapon ) then
		return pWeapon:GetBulletSpread( self:GetCurrentWeaponProficiency() )
	end
	
	return VECTOR_CONE_15DEGREES
end

function _R.Player:GetCurrentWeaponProficiency()
	return self.m_CurrentWeaponProficiency
end

function _R.Player:SetCurrentWeaponProficiency( iProficiency )
	self.m_CurrentWeaponProficiency = iProficiency
end

function _R.Player:CalcWeaponProficiency( pWeapon )
	return WEAPON_PROFICIENCY_AVERAGE
end

function _R.Player:DoMuzzleFlash()
	local pWeapon = self:GetActiveWeapon()
	if ( IsValid( pWeapon ) ) then
		pWeapon:DoMuzzleFlash()
		// NOTENOTE: We do not chain to the base here
	else
		self.BaseClass:DoMuzzleFlash()
	end
end

function _R.Player:Weapon_Equip( pWeapon )
	// Weapon is now on my team
	pWeapon:SetTeam( self:Team() )
	
	// ----------------------
	//  Give Primary Ammo
	// ----------------------
	// If gun doesn't use clips, just give ammo
	if ( pWeapon:GetMaxClip1() == -1 ) then
		if ( GAMEMODE_NAME == "hl2" and game.GetMap() == "d3_c17_09" and pWeapon:GetClass() == "weapon_rpg" and pWeapon:NameMatches( "player_spawn_items" ) ) then -- Fix; NameMatches
			// !!!HACK - Don't give any ammo with the spawn equipment RPG in d3_c17_09. This is a chapter
			// start and the map is way to easy if you start with 3 RPG rounds. It's fine if a player conserves
			// them and uses them here, but it's not OK to start with enough ammo to bypass the snipers completely.
			self:GiveAmmo( 0, pWeapon.Primary.Ammo )
		else
			-- self:GiveAmmo( pWeapon:GetDefaultClip1(), pWeapon.Primary.Ammo )
		end
	--[[
	// If default ammo given is greater than clip
	// size, fill clips and give extra ammo
	elseif ( pWeapon:GetDefaultClip1() > pWeapon:GetMaxClip1() ) then
		pWeapon:SetClip1( pWeapon:GetMaxClip1() )
		self:GiveAmmo( ( pWeapon:GetDefaultClip1() - pWeapon:GetMaxClip1() ), pWeapon.Primary.Ammo )]]
	end
	
	--[[
	// ----------------------
	//  Give Secondary Ammo
	// ----------------------
	// If gun doesn't use clips, just give ammo
	if ( pWeapon:GetMaxClip2() == -1 ) then
		-- self:GiveAmmo( pWeapon:GetDefaultClip2(), pWeapon.Secondary.Ammo )
	// If default ammo given is greater than clip
	// size, fill clips and give extra ammo
	elseif ( pWeapon:GetDefaultClip2() > pWeapon:GetMaxClip2() ) then
		pWeapon:SetClip2( pWeapon:GetMaxClip2() )
		self:GiveAmmo( ( pWeapon:GetDefaultClip2() - pWeapon:GetMaxClip2() ), pWeapon.Secondary.Ammo )
	end
	
	pWeapon:Equip( pWeapon )]]
	
	local proficiency = self:CalcWeaponProficiency( pWeapon )
	
	if ( GetConVar( "weapon_showproficiency" ):GetBool() ) then
		Msg( "%s equipped with %s, proficiency is %s\n", self:GetClass(), pWeapon:GetClass(), self:GetWeaponProficiencyName( proficiency ) ) -- Fix; does Msg allow this shit?
	end
	
	self:SetCurrentWeaponProficiency( proficiency )
	
	// Pass the lighting origin over to the weapon if we have one
	-- pWeapon:SetLightingOriginRelative( self:GetLightingOriginRelative() ) -- Fix; request this on GitHub?
end