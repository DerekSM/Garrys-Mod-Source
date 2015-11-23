DEFINE_BASECLASS( "weapon_csbase_gun" )

SWEP.Base = "weapon_csbase_gun"

SWEP.ZoomLevels = 2

SWEP.ZoomFOV =
{
	[0] = 0,
	[1] = 40,
	[2] = 10
}

SWEP.ZoomTime =
{
	[-1] = 0.05 -- Our reload rezoom time
	[0] = 0.1, -- Fix?
	[1] = 0.15,
	[2] = 0.08
}
SWEP.Secondary.Automatic = false

SWEP.ZoomMaxSpeed = 150

SWEP.m_iZoomLevel = 0

SWEP.ZoomAfterReload = true

SWEP.m_iLastZoomLevel = 0

SWEP.m_zoomFullyActiveTime = -1.0

function SWEP:SharedDeploy()
	self.m_zoomFullyActiveTime = -1.0
	
	return BaseClass.SharedDeploy( self )
end

function SWEP:SecondaryAttack()
	if ( self.m_bInReload ) then
		return
	end
	
	if ( self.m_iZoomLevel < self.ZoomLevels ) then
		self:Zoom( self.m_iZoomLevel + 1 )
	else
		self:Zoom( 0 )
	end
end

function SWEP:Zoom( iLevel )
	self.m_iZoomLevel = iLevel
	
	if ( SERVER ) then
		local pPlayer = self.Owner
		
		if ( not IsValid( pPlayer ) ) then
			return
		end
		
		pPlayer:SetFOV( self.ZoomFOV[iLevel], self.ZoomTime[iLevel] )
		
		pPlayer:ResetMaxSpeed()
	end
	
	hook.Run( "weapon_zoom", pPlayer ) -- fix; serverside?
	-- Fix; hide weapon
	
	self:SetNextSecondaryFire( CurTime() + self.Secondary.Cooldown )
	
	if ( not self.m_iWorstZoomTime ) then -- Cache the longest zoom time
		self.m_iWorstZoomTime = 0
		
		for i = 0, self.ZoomLevels, 1 do
			if ( self.ZoomTime[i] > self.m_iWorstZoomTime ) then
				self.iWorstZoomTime = self.ZoomTime[i]
			end
		end
	end
	
	self.m_zoomFullyActiveTime = CurTime() + self.m_iWorstZoomTime // The worst time from above
end

function SWEP:GetMaxSpeed()
	local pPlayer = self.Owner
	
	if ( self.m_iZoomLevel > 0 ) then
		return self.ZoomMaxSpeed
	end
	
	return BaseClass.GetMaxSpeed( self )
end

function SWEP:Reload()
	if ( BaseClass.Reload( self ) and self.m_iZoomLevel > 0 ) then
		self.m_iLastZoomLevel = self.m_iZoomLevel
		self:Zoom( 0 )
	end
end

function SWEP:FinishReload()
	BaseClass.FinishReload( self )
	
	if ( self.ZoomAfterReload ) then
		self:Zoom( self.m_iLastZoomLevel )
		// Make sure we think that we are zooming on the server so we don't get instant acc bonus
		self.zoomFullyActiveTime = CurTime() + self.ZoomTime[-1]
	end
end
