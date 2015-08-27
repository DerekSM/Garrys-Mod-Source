local _R = debug.getregistry()

function _R.Player:SetDormant( bDormant )
	self:SetNoDraw( bDormant ) -- updates the dormant state serverside and stops networking
end

function _R.ConVar:SetValue( arg ) -- Fix; does this metatable exist?
	RunConsoleCommand( self:GetName(), arg )
end

function swap( arg1, arg2 )
	return arg2, arg1
end