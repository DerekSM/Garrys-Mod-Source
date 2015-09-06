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

function _R.Player:IsJumping() -- Fix; hook this into usercmds instead
	return ( not self:IsOnGround() )
end

function _R.Player:SetNextAttack()
	-- Placeholder to stop errors
end

ITEM_FLAG_SELECTONEMPTY	= bit.lshift( 1, 0 )
ITEM_FLAG_NOAUTORELOAD		= bit.lshift( 1, 1 )
ITEM_FLAG_NOAUTOSWITCHEMPTY	= bit.lshift( 1, 2 )
ITEM_FLAG_LIMITINWORLD		= bit.lshift( 1, 3 )
ITEM_FLAG_EXHAUSTIBLE		= bit.lshift( 1, 4 )	// A player can totally exhaust their ammo supply and lose this weapon
ITEM_FLAG_DOHITLOCATIONDMG	= bit.lshift( 1, 5 )	// This weapon take hit location into account when applying damage
ITEM_FLAG_NOAMMOPICKUPS		= bit.lshift( 1, 6 )	// Don't draw ammo pickup sprites/sounds when ammo is received
ITEM_FLAG_NOITEMPICKUP		= bit.lshift( 1, 7 )	// Don't draw weapon pickup when this weapon is picked up by the player
// NOTE: KEEP g_ItemFlags IN WEAPON_PARSE.CPP UPDATED WITH THESE