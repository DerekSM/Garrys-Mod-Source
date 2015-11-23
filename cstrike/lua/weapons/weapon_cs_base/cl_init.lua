DEFINE_BASECLASS( "basecombatweapon" )

function SWEP:DrawCrosshair()
end
	
	function SWEP:FireAnimationEvent( origin, angles, event, options )
		if ( event == 5001 ) then
			local pPlayer = self.Owner
			if ( self.m_bInZoom and self:HideWhenZoomed() ) then -- Fix
				return true
			end
			
			local data = EffectData()
			data:SetFlags( 0 )
			data:SetEntity( self.Owner:GetViewModel() )
			data:SetAttachment( 1 )
			data:SetScale( self.MuzzleFlashScale )
			-- Fix; set origin?
			
			if ( self.MuzzleFlashStyle:lower() == "cs_muzzleflash_x" ) then -- Fix; move all cases to basecombatweapon
				util.Effect( "CS_MuzzleFlash_X", data )
			elseif ( self.MuzzleFlashStyle:lower() == "cs_muzzleflash" ) then
				util.Effect( "CS_MuzzleFlash", data )
			end
			
			return true
		end
		
		return BaseClass.FireAnimationEvent( self, origin, angles, event, options )
	end
	
	function SWEP:GetMuzzleFlashStyle() -- Fix
		return self.MuzzleFlashStyle
	end
	