include( "shared.lua" )

SWEP.DrawCrosshair

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

function SWEP:IsBeingCarred() -- Fix; is this useful?
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

	// ammo drawing has been moved into hud_ammo.cpp -- Fix
end

function SWEP:DrawCrosshair()
	local player = LocalPlayer()

	if ( not IsValid( player ) ) then
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
	local bOnTarget = ( self:GetState() == WEAPON_IS_ONTARGET ) -- Fix; add states back?

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
		return ( self:GetState() == WEAPON_IS_ACTIVE ) -- Fix
	end

	return false
end

function SWEP:GetShootPosition() -- Fix; named this to test if ShootPos and this return the same thing
	local vAngles = Angle( 0, 0, 0 )
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
	
	if ( self:IsActiveByLocalPlayer() and not self:ShouldDrawLocalPlayer() ) then
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

function SWEP:ShouldDrawCrosshair()
	return self.DrawCrosshair
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
