local _R = debug.getregistry()

function _R.Entity:IsFollowingEntity()
	return self:IsEffectActive( EF_BONEMERGE ) and (self:GetMoveType() == MOVETYPE_NONE) and IsValid( self:GetMoveParent() )
end

function _R.Entity:StopFollowingEntity()
	if ( not self:IsFollowingEntity() ) then
		return
	end
	
	self:SetParent( NULL )
	self:RemoveEffects( EF_BONEMERGE )
	self:RemoveSolidFlags( FSOLID_NOT_SOLID )
	self:SetMoveType( MOVETYPE_NONE )
	self:CollisionRulesChanged()
end

function _R.Entity:GetFollowedEntity()
	if ( not self:IsFollowingEntity() ) then
		return NULL
	end
	
	return self:GetMoveParent()
end

function _R.Entity:BodyTarget( posSrc, bNoisy )
	return self:WorldSpaceCenter()
end

function _R.Entity:HeadTarget( posSrc )
	return self:EyePos()
end

-- ObjectCaps

function _R.Entity:IsInWorld()
	// position
	local pos = self:GetPos()
	if ( pos.x >= MAX_COORD or pos.x <= MIN_COORD ) then return false
	elseif ( pos.y >= MAX_COORD or pos.y <= MIN_COORD ) then return false
	elseif ( pos.z >= MAX_COORD or pos.z <= MIN_COORD ) then return false end
	// speed
	local vel = self:GetAbsVelocity()
	if ( vel.x >= 2000 or vel.x <= -2000 ) then return false
	elseif ( vel.y >= 2000 or vel.y <= -2000 ) then return false
	elseif ( vel.z >= 2000 or vel.z <= -2000 ) then return false end
	
	return true
end

function _R.Entity:TestCollision( ray, mask, trace )
	return false
end

function _R.Entity:TestHitboxes( ray, fContentsMask, tr )
	return false
end

function _R.Entity:EnableDamageForces()
	self:RemoveEFlags( EFL_NO_DAMAGE_FORCES )
end

function _R.Entity:DisableDamageForces()
	self:AddEFlags( EFL_NO_DAMAGE_FORCES )
end

function _R.Entity:SetDamageFilter( filter )
	filter = ents.FindByName( filter ) or ents.FindByClass( filter )
	if ( filter ) then
		self.m_hDamageFilter = filter[1]
	else
		self.m_hDamageFilter = NULL
	end
end

function _R.Entity:PassesDamageFilter( info )
	if ( IsValid( self.m_hDamageFilter ) ) then
		return self.m_hDamageFilter:PassesDamageFilter( info )
	end
	
	return true
end

function _R.Entity:DispatchEffect( sEffect )
	local data = EffectData()
	local temp = self:GetDispatchEffectPosition( sEffect )
	data:SetOrigin( temp.Pos )
	data:SetStart( temp.Pos )
	temp = AngleVectors( temp.Ang )	-- Multiple returns; rip
	data:SetNormal( temp )
	data:SetEntIndex( self:EntIndex() )
	
	util.Effect( sEffect, data )
end

function _R.Entity:GetDispatchEffectPosition( sInput )
	return { Ang = self:GetAngles(), Pos = self:GetPos() }
end

function _R.Entity:IsMoving()
	return self:GetVelocity() ~= vector_origin
end

function _R.Entity:GetAngularVelocity()
	return QAngleToAngularImpulse( self:GetLocalAngularVelocity() ) -- Fix
end

-- GetVectors

function _R.Entity:InSameTeam( pEntity )
	if ( not IsValid( pEntity ) ) then
		return false
	end
	
	return ( pEntity:Team() == self:Team() )
end

function _R.Entity:GetDamageType()
	return DMG_GENERIC
end

-- Teleport

-- Skybox?



-- Left off on CalcAbsoluteVelocity