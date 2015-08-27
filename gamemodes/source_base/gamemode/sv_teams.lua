local _R = debug.getregistry()

_R.Team = {}
_R.Team.__index = _R.Team

-- Fix; find a way to set a metatable base to inherit correctly

function GetGlobalTeam( iIndex )
	if ( iIndex < 0 or iIndex >= GetNumberOfTeams() ) then
		return
	end
	
	return g_Teams[ iIndex ]
end

function GetNumberofTeams()
	return #g_Teams
end

function _R.Team:UpdateTransmitState()
	return self:SetTransmitState( FL_EDICT_ALWAYS ) -- Fix; we need to request this
end

function _R.Team:ShouldTransmitToPlayer( pRecipient, pEntity )
	// Always transmit the observer target to players
	if ( IsValid( pRecipient ) and pRecipient:IsObserver() and pRecipient:GetObserverTarget() == pEntity ) then
		return true
	end
	
	return false
end

-- Fix; make a Team() function
-- Find a way to also convert player list to indexes, as per SendProxy

function Team( pName, iNumber ) -- This will currently overwrite everything. Figure out how to use SetMetaTable
	_R.Team:InitializeSpawnpoints()
	_R.Team:InitializePlayers()
	
	_R.Team:SetScore(0)
	-- Fix; check and chop string length
	_R.Team.m_iTeamNum = iNumber
	
	return _R.Team
end

function _R.Team:SetupDataTables()
	self:NetworkVar( "String", 0, "Teamname" )
	self:NetworkVar( "Int", 0, "Score" )
	self:NetworkVar( "Int", 1, "RoundsWon" )

function _R.Team:GetTeamNumber() -- Fix; I've seen this function all around the codebase used on entities. How are these inherited?
	return self.m_iTeamNum
end

function _R.Team:UpdateClientData( pPlayer )
end

function _R.Team:InitializeSpawnpoints()
	self.m_iLastSpawn = 0
end

function _R.Team:AddSpawnpoint( pSpawnpoint )
	table.insert( self.m_aSpawnPoints, pSpawnpoint )
end

function _R.Team:RemoveSpawnpoint( pSpawnPoint )
	for i = 1, #self.m_aSpawnPoints do -- + 1 needed?
		if ( self.m_aSpawnPoints[i] == pSpawnPoint ) then
			table.remove( self.m_aSpawnPoints, i )
			return
		end
	end
end

function _R.Team:SpawnPlayer( pPlayer )
	if ( #self.m_aSpawnPoints == 0 ) then
		return
	end
	
	// Randomize the start spot
	local iSpawn = self.m_iLastSpawn + random.RandomInt( 1, 3 )
	if ( iSpawn >= #self.m_aSpawnPoints ) then
		iSpawn = iSpawn - #self.m_aSpawnPoints
	end
	
	local iStartingSpawn = iSpawn
	
	// Now loop through spawnpoints and pick one
	local loopCount = 0
	repeat
		if ( iSpawn >= #self.m_aSpawnPoints ) then
			loopCount = loopCount + 1
			iSpawn = 0
		end
		
		// check if pSpot is valid, and that the player is on the right team
		if ( (loopCount > 3) or self.m_aSpawnPoints[iSpawn]:IsValid( pPlayer ) ) then -- Fix
			// DevMsgN( 1, "player: spawning at (%s)", self.m_aSpawnPoints[iSpawn].m_iName )
			self.m_aSpawnPoints[iSpawn].m_OnPlayerSpawn:FireOutput( pPlayer, m_aSpawnPoints[iSpawn] ) -- Fix, big time
			
			self.m_iLastSpawn = iSpawn
			return self.m_aSpawnPoints[iSpawn]
		end
		
		iSpawn = iSpawn + 1
	until ( iSpawn ~= iStartingSpawn ) // loop if we're not back to the start
	
	return
	
end

function _R.Team:InitializePlayers()
end

function _R.Team:AddPlayer( pPlayer )
	table.insert( self.m_aPlayers, pPlayer )
	self:NetworkStateChanged() -- Fix
end

function _R.Team:RemovePlayer( pPlayer )
	table.remove( self.m_aPlayers, pPlayer )
	self:NetworkStateChanged()
end

function _R.Team:GetNumPlayers()
	return #self.m_aPlayers
end

function _R.Team:GetPlayer( iIndex )
	assert( iIndex >= 0 and iIndex <= #self.m_aPlayers ) -- <=?
	return self.m_aPlayers[ iIndex ]
end

function _R.Team:AddScore( iScore )
	self:SetScore( self:GetScore() + iScore )
end

function _R.Team:ResetScores()
	self:SetScore(0)
end

function _R.Team:IncrementRoundsWon()
	self.m_iRoundsWon = self.m_iRoundsWon + 1
end

function _R.Team:AwardAchievement( iAchivement )
	assert( iAchievement >= 0 and iAchivement < 255 )	// must fit in byte
	
	local filter = {}
	
	local iNumPlayers = self:GetNumPlayers()
	
	for i = 1, iNumPlayers do
		local pPlayer = self:GetPlayer(i)
		if ( IsValid( pPlayer ) ) then
			table.insert( filter, pPlayer )
		end
	end
	
	net.Start( "AchivementEvent" )
		net.WriteByte( iAchivement )
	net.Send( filter ) -- Fix! Let's receive this in the correct place
end
