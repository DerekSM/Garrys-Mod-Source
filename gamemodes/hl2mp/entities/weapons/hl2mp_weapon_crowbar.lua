DEFINE_BASECLASS( "weapon_hl2mpbasebasebludgeon" )
SWEP.Base = "weapon_hl2mpbasebasebludgeon"

CROWBAR_RANGE = 75.0
CROWBAR_REFIRE = 0.4

function SWEP:GetDamageForActivity( hitActivity )
	return 25.0
end

function SWEP:AddViewKick()
	local pPlayer = self.Owner
	
	if ( IsValid( pPlayer ) ) then
		return
	end
	
	local punchAng = Angle( pPlayer:SharedRandomFloat( "crowbarpax", 1.0, 2.0 ),
							pPlayer:SharedRandomFloat( "crowbarpay", -2.0, -1.0 ),
							0.0 )
							
	pPlayer:ViewPunch( punchAng )
end

if ( SERVER ) then
	--[[
	function SWEP:HandleAnimEventMeleeHit( pEvent, pOperator )
		// Trace up or down based on where the enemy is...
		// But only if we're basically facing that direction
		local vecDirection = AngleVectors( self:GetAngles() )
		
		vecDirection:MA( pOperator:GetShootPos(), 50 ) -- Fix
		local pHurt = pOperator:CheckTraceHullAttack( pOperator:GetShootPos(), vecDirection, Vector( -16, -16, -16 ), 
			Vector( 36, 36, 36 ), self:GetDamageForActivity( self:GetActivity() ), DMG_CLUB, 0.75 ) -- Fix
		
		// did I hit someone?
		if ( IsValid( pHurt ) ) then
			// play sound
			self:WeaponSound( MELEE_HIT )
			
			// Fake a trace impact, so the effects work out like a player's crowbaw
			local traceHit = util.TraceLine( {
				start = pOperator:GetShootPos(),
				endpos = pHurt:GetPos(),
				mask = MASK_SHOT_HULL,
				--collision = COLLISION_GROUP_NONE,
				--ignore = pOperator
			} )
			-- ImpactEffect -- Fix
		else
			self:WeaponSound( MELEE_MISS )
		end
	end
	
	function SWEP:HandleAnimEvent
	]]
	
	-- Fix; condition
end

function SWEP:Drop( vecVelocity )
	self:Remove() -- Fix; what
end
-- Fix; attach to SWEP variables?
function SWEP:GetRange()
	return CROWBAR_RANGE
end

function SWEP:GetFireRate()
	return CROWBAR_REFIRE
end