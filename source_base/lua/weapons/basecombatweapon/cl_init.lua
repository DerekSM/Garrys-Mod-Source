include( "shared.lua" )

net.Receive( "Source Base - Clientside Deploy", function( len, ply )
	local wep = net.ReadEntity()
	print"recieved"
	if ( not IsValid( wep ) ) then
		wep = ply:GetActiveWeapon()
		if ( not IsValid( wep ) ) then
			return
		end
	end
	print( wep )
	wep:SharedDeploy()
end )

function SWEP:SetDormant( bDormant )
	// If I'm going from active to dormant and I'm carried by another player, holster me.
	if ( not self:IsDormant() and bDormant and not self:IsCarriedByLocalPlayer() ) then
		self:Holster( NULL )
	end
	
	debug.getregistry().Entity.SetDormant( self, bDormant )
end

function SWEP:IsCarriedByLocalPlayer()
	if ( not IsValid( self.Owner ) ) then
		return false
	end

	return ( self.Owner == LocalPlayer() )
end

function SWEP:ShouldDrawCrosshair()
	return self.DrawCrosshair
end

function SWEP:FireAnimationEvent( origin, angles, event, options )
	return false
end

function SWEP:GetShootPosition() -- Fix; named this to test if ShootPos and this return the same thing
	local vAngles = Angle()
	local vOrigin = self:GetRenderOrigin()
	
	// Get the entity because the weapon doesn't have the right angles
	local pEnt = self.Owner
	if ( IsValid( pEnt ) ) then
		if ( pEnt == LocalPlayer() ) then
			vAngles = pEnt:EyeAngles()
		else
			vAngles = pEnt:GetRenderAngles()
		end
	end
	
	if ( --self:IsActiveByLocalPlayer() and 
	not self:ShouldDrawLocalPlayer() ) then
		local vm = IsValid( pEnt ) and pEnt:GetViewModel() or NULL
		if ( IsValid( vm ) ) then
			local iAttachment = vm:LookupAttachment( "muzzle" )
			vOrigin = vm:GetAttachment( iAttachment ).Pos
		end
	else
		// Thirdperson
		local iAttachment = self:LookupAttachment( "muzzle" )
		vOrigin = self:GetAttachment( iAttachment ).Pos
	end
	
	return  { Ang = vAngles, Pos = vOrigin } -- AngPos struct; models Lua implementation of GetAttachment
end

--[[
-- NotifyShouldTransmit
-- Crosshair

function SWEP:OnRestore()
	self.BaseClass.OnRestore( self )

	// if the player is holding this weapon, 
	// mark it as just restored so it won't show as a new pickup
	if ( self.Owner == LocalPlayer() ) then
		self.m_bJustRestored = true
	end
end

function SWEP:IsActiveByLocalPlayer()
	if ( self:IsCarriedByLocalPlayer() ) then
		return ( self:GetState() == WEAPON_IS_ACTIVE )
	end

	return false
end


function SWEP:ShouldDraw()
	// FIXME: All weapons with owners are set to transmit in CBaseCombatWeapon::UpdateTransmitState,
	// even if they have EF_NODRAW set, so we have to check this here. Ideally they would never
	// transmit except for the weapons owned by the local player.
	if ( self:IsEffectActive( EF_NODRAW ) ) then
		return false
	end

	local pOwner = self.Owner

	// weapon has no owner, always draw it
	if ( not IsValid( pOwner ) ) then
		return true
	end

	local bIsActive = ( self.m_iState == WEAPON_IS_ACTIVE )

	local pLocalPlayer = LocalPlayer()

	 // carried by local player?
	if ( pOwner == pLocalPlayer ) then
		// Only ever show the active weapon
		if ( not bIsActive ) then
			return false
		end

		// 3rd person mode
		if ( self:ShouldDrawLocalPlayer() ) then
			return true
		end

		// don't draw active weapon if not in some kind of 3rd person mode, the viewmodel will do that
		return false;
	end

	// If it's a player, then only show active weapons
	if ( pOwner:IsPlayer() ) then
		// Show it if it's active...
		return bIsActive
	end

	// FIXME: We may want to only show active weapons on NPCs
	// These are carried by AIs; always show them
	return true
end

function SWEP:ShouldDrawPickup()
	if ( bit.band( self:GetFlags(), ITEM_FLAG_NOITEMPICKUP ) ) then
		return false
	end

	if ( self.m_bJustRestored ) then
		return false
	end
	
	return true
end
]]--