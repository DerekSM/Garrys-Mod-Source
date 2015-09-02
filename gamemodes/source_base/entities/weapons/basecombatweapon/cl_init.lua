include( "shared.lua" )

function SWEP:GetActiveWeapon()
	local player = LocalPlayer()

	if ( not IsValid( player ) ) then
		return
	end

	return player:GetActiveWeapon()
end

function SWEP:SetDormant( bDormant )
	// If I'm going from active to dormant and I'm carried by another player, holster me.
	if ( not self:IsDormant() and bDormant and not self:IsCarriedByLocalPlayer() ) then
		self:Holster()
	end
	
	self.BaseClass:SetDormant( bDormant ) -- Fix
end

function SWEP:OnRestore()
	self.BaseClass:OnRestore() -- Fix

	// if the player is holding this weapon, 
	// mark it as just restored so it won't show as a new pickup
	if ( self.Owner == LocalPlayer() ) then
		self.m_bJustRestored = true
	end
end

function SWEP:IsBeingCarred()
	return IsValid( self.Owner )
end

function SWEP:IsCarrierAlive()
	if ( not IsValid( self.Owner ) ) then
		return false
	end
	
	return self.Owner:Health() > 0
end

function SWEP:Redraw() -- Fix; needed?
	if ( self:ShouldDrawCrosshair() ) then
		self:DrawCrosshair()
	end

	// ammo drawing has been moved into hud_ammo.cpp -- Fix, file type?
end

function SWEP:DrawCrosshair()
	local player = LocalPlayer()

	if ( not IsValid( LocalPlayer() ) ) then
		return
	end

	local clr = gHUD.m_clrNormal -- Fix

/*

	// TEST: if the thing under your crosshair is on a different team, light the crosshair with a different color.
	Vector vShootPos, vShootAngles;
	GetShootPosition( vShootPos, vShootAngles );

	Vector vForward;
	AngleVectors( vShootAngles, &vForward );
	
	
	// Change the color depending on if we're looking at a friend or an enemy.
	CPartitionFilterListMask filter( PARTITION_ALL_CLIENT_EDICTS );	
	trace_t tr;
	traceline->TraceLine( vShootPos, vShootPos + vForward * 10000, COLLISION_GROUP_NONE, MASK_SHOT, &tr, true, ~0, &filter );

	if ( tr.index != 0 && tr.index != INVALID_CLIENTENTITY_HANDLE )
	{
		C_BaseEntity *pEnt = ClientEntityList().GetBaseEntityFromHandle( tr.index );
		if ( pEnt )
		{
			if ( pEnt->GetTeamNumber() != player->GetTeamNumber() )
			{
				g = b = 0;
			}
		}
	}		 
*/

	local crosshair = GET_HUDELEMENT( CHudCrosshair ) -- Fix
	if ( not crosshair ) then
		return
	end
	
	// Find out if this weapon's auto-aimed onto a target
	local bOnTarget = ( self.m_iState == WEAPON_IS_ONTARGET ) -- Fix; add states back?

	if ( player:GetFOV() >= 90 ) then
		// normal crosshairs
		if ( bOnTarget and self.iconAutoaim ) then
			clr.a = 255

			crosshair:SetCrosshair( self.iconAutoaim, clr )
		elseif ( self.iconCrosshair ) then
			clr.a = 255

			crosshair:SetCrosshair( self.iconCrosshair, clr )
		else
			crosshair:ResetCrosshair()
		end
	else
		local white = Color( 255, 255, 255, 255 )

		// zoomed crosshairs
		if ( bOnTarget and self.iconZoomedAutoaim ) then
			crosshair:SetCrosshair( self.iconZoomedAutoaim, white )
		elseif ( self.iconZoomedCrosshair ) then
			crosshair:SetCrosshair( self.iconZoomedCrosshair, white )
		else
			crosshair:ResetCrosshair()
		end
	end
end

function SWEP:ViewModelDrawn( pViewModel )
end

function SWEP:IsCarriedByLocalPlayer() -- Fix; Lua binding needed?
	if ( not IsValid( self.Owner ) ) then
		return false
	end

	return ( self.Owner == LocalPlayer() )
end

function SWEP:IsActiveByLocalPlayer()
	if ( self:IsCarriedByLocalPlayer() ) then
		return ( self.m_iState == WEAPON_IS_ACTIVE ) -- Fix
	end

	return false
end
--[[
function SWEP:GetShootPos()
	self:GetRenderAngles()
end
]]-- Fix; do we need a binding for this?

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

function SWEP:ShouldDrawPickup() -- Fix
	if ( bit.band( self:GetFlags(), ITEM_FLAG_NOITEMPICKUP ) ) then
		return false
	end

	if ( self.m_bJustRestored ) then
		return false
	end
	
	return true
end

--[[function SWEP:DrawModel() -- Fix, check if we need this
end]]