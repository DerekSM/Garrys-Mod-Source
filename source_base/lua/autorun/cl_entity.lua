function _R.Entity:ObjectCaps()
	return 0
end

function _R.Entity:SetDormant( bDormant )
	self:AddEFlags( EFL_DORMANT )
	self:SetNoDraw( true )
	if ( IsValid( self:GetParent() ) ) then
		self:GetParent():SetDormant( bDormant )
	end
end