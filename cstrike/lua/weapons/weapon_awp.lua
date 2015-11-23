DEFINE_BASECLASS( "weapon_csbase_scoped" )

SWEP.Base = "weapon_csbase_scoped"

function SWEP:PrimaryAttack()
	local pPlayer = self.Owner
	
	if ( not IsValid( pPlayer ) ) then
		return false
	end
	
	local flSpread = 0.001
	
	if ( pPlayer:IsFlagSet( FL_ONGROUND ) ) then
		flSpread = 0.85
	elseif ( pPlayer:GetAbsVelocity():Length2D() > 140 ) then
		flSpread = 0.25
	elseif ( pPlayer:GetAbsVelocity():Length2D() > 10 ) then
		flSpread = 0.10
	elseif ( pPlayer:IsFlagSet( FL_DUCKING ) ) then
		flSpread = 0
	end
	
	// If we are not zoomed in, or we have very recently zoomed and are still transitioning, the bullet diverts more.
	if ( not self.m_bInZoom or CurTime() < self.m_zoomFullyActiveTime ) then
		flSpread = flSpread + 0.08
	end
	
	if ( self.m_bInZoom ) then
		-- pPlayer.m_iLastZoom = pPlayer:GetFOV()
		
		if ( SERVER ) then
			-- FIX; set up contextual thinking system; table of funcs to run in a think hook; destroy themselves on complete
			self:Zoom( 0 )
		end
	end
	
	if ( not self:Shoot( flSpread ) ) then
		return
	end
	
	local angle = pPlayer:GetPunchAngle()
	angle.x = angle.x - 2
	pPlayer:SetPunchAngle( angle )
end

function SWEP:SecondaryAttack()
	self:Zoom()
	
	if ( SERVER ) then
		self:EmitSound( "Default.Zoom" )
	end
end
