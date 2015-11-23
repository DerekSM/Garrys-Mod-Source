_R.Player.Animations =
{
	[ "primary" ] = PLAYER_ATTACK1
}

_R.Player.AnimEvents =
{
	[ "primary" ] = PLAYERANIMEVENT_ATTACK_PRIMARY,
	[ "secondary" ] = PLAYERANIMEVENT_ATTACK_SECONDARY,
}

function _R.Player:LookupAnimation( sAnim )
	return self.Animations[ sAnim:lower() ]
end

function _R.Player:LookupAnimEvent( sAnimEvent )
	return self.AnimEvents[ sAnimEvent:lower() ]
end

-- Fix; do the rest of these
-- Also, we could possibly patch SetAnimation to look for strings