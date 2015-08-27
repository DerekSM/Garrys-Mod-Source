--[[virtual const Vector&	GetPlayerMins( void ) const; // uses local player
	virtual const Vector&	GetPlayerMaxs( void ) const; // uses local player

	// IGameMovement interface
	virtual const Vector&	GetPlayerMins( bool ducked ) const { return BaseClass::GetPlayerMins(ducked); }
	virtual const Vector&	GetPlayerMaxs( bool ducked ) const { return BaseClass::GetPlayerMaxs(ducked); }
	virtual const Vector&	GetPlayerViewOffset( bool ducked ) const { return BaseClass::GetPlayerViewOffset(ducked); }]]
	
function GM:SetPlayerSpeed