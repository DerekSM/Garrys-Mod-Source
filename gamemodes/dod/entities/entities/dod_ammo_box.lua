-- ALL SERVERSIDE! Fix

ENT.Base = "items"

function ENT:Initialize()
	self:Precache()
	-- self:SetModel( "models/ammo/ammo_us.mdl" )
	self.BaseClass:Initialize() -- Fix
	
	self:SetTrigger( true )
	
	self:SetAmmoTeam( self.m_hOldOwner:Team() )
	
	Timer( 2, self.SetOwner, self ) -- Fix
end

function ENT:Precache()
	util.PrecacheModel( "models/ammo/ammo_axis.mdl" )
	util.PrecacheModel( "models/ammo/ammo_us.mdl" )
end

function ENT:SetAmmoTeam( team )
	if ( team == TEAM_ALLIES ) then
		self:SetModel( "models/ammo/ammo_us.mdl" )
	elseif ( team == TEAM_AXIS ) then
		self:SetModel( "models/ammo/ammo_axis.mdl" )
	end
	
	self.m_iAmmoTeam = team -- Fix, needed? Maybe just set the team?
end

function ENT:Touch( pOther )

	if ( not ( IsValid( pOther ) or pOther:IsPlayer() or pOther:Alive() ) ) then -- Fix, stupid amount of checks here
		return
	end
	
	//Don't let the person who threw this ammo pick it up until it hits the ground.
	//This way we can throw ammo to people, but not touch it as soon as we throw it ourselves
	if ( self:GetOwner() == pOther ) then
		return
	end
	
	if ( pOther:Team() ~= self.m_iAmmoTeam ) then
		return
	end
	
	//See if they can use some ammo, if so, remove the box
	if ( pPlayer:GiveGenericAmmo() ) then
		self:Remove()
	end
	
	return true
end