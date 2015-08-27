MAX_RESPAWN_WAVES_TO_TRANSMIT = 5
MAX_PLAYERCLASSES_PER_TEAM = 16
DOD_RESPAWN_QUEUE_SIZE = 10

if ( SERVER ) then
	local dod_flagrespawnbonus = CreateConVar( "dod_flagrespawnbonus", "1.0", { FCVAR_GAMEDLL, FCVAR_CHEAT }, "How many seconds per advantage flag to decrease the respawn time" )
	local mp_warmup_time = CreateConVar( "mp_warmup_time", "0", FCVAR_GAMEDLL, "Warmup time length in seconds" )
	local mp_restartwarmup = CreateConVar( "mp_restartwarmup", "0", FCVAR_GAMEDLL, "Set to 1 to start or restart the warmup period." )
	local mp_cancelwarmup = CreateConVar( "mp_cancelwarmup", "0", FCVAR_GAMEDLL, "Set to 1 to end the warmup period." )
end

local dod_enableroundwaittime = CreateConVar( "dod_enableroundwaittime", "1", FCVAR_REPLICATED, "Enable timers to wait between rounds." )
local mp_allowrandomclass = CreateConVar( "mp_allowrandomclass", "1", FCVAR_REPLICATED, "Allow players to select random class" )

local dod_bonusroundtime = CreateConVar( "dod_bonusroundtime", "15", FCVAR_REPLICATED, "Time after round win until round restarts" ) --, true, 5, true, 15 ); -- Fix; what do these extra args do?

--[[static CDODViewVectors g_DODViewVectors(

	Vector( 0, 0, 58 ),			//VEC_VIEW (m_vView) 
								
	Vector(-16, -16, 0 ),		//VEC_HULL_MIN (m_vHullMin)
	Vector( 16,  16,  72 ),		//VEC_HULL_MAX (m_vHullMax)
													
	Vector(-16, -16, 0 ),		//VEC_DUCK_HULL_MIN (m_vDuckHullMin)
	Vector( 16,  16, 45 ),		//VEC_DUCK_HULL_MAX	(m_vDuckHullMax)
	Vector( 0, 0, 34 ),			//VEC_DUCK_VIEW		(m_vDuckView)
													
	Vector(-10, -10, -10 ),		//VEC_OBS_HULL_MIN	(m_vObsHullMin)
	Vector( 10,  10,  10 ),		//VEC_OBS_HULL_MAX	(m_vObsHullMax)
													
	Vector( 0, 0, 14 ),			//VEC_DEAD_VIEWHEIGHT (m_vDeadViewHeight)
								
	Vector(-16, -16, 0 ),		//VEC_PRONE_HULL_MIN (m_vProneHullMin)
	Vector( 16,  16, 24 )		//VEC_PRONE_HULL_MAX (m_vProneHullMax)
);]]-- Fix

STARTROUND_ATTACK = 0 -- Fix; array starting at 0
STARTROUND_DEFEND = 1
STARTROUND_BEACH = 2
STARTROUND_ATTACK_TIMED = 3
STARTROUND_DEFEND_TIMED = 4
STARTROUND_FLAGS = 5

if ( SERVER ) then
	function GM:PlayerCanHearPlayersVoice( pListener, pTalker )
		// Dead players can only be heard by other dead team mates
		if ( pTalker:Alive() == false ) then
			if ( pListener:Alive() == false ) then
				return ( pListener:InSameTeam( pTalker ) )
			end
			
			return false
		end
		
		return ( pListener:InSameTeam( pTalker ) )
	end
	
	sTeamNames =
	{
		[0] = "Unassigned",
		"Spectator",
		"Allies",
		"Axis"
	}
	
	s_PreserveEnts =
	{
		"player",
		"viewmodel",
		"worldspawn",
		"soundent",
		"ai_network",
		"ai_hint",
		"dod_gamerules",
		"dod_team_manager",
		"dod_player_manager",
		"dod_objective_resource",
		"env_soundscape",
		"env_soundscape_proxy",
		"env_soundscape_triggerable",
		"env_sprite",
		"env_sun",
		"env_wind",
		"env_fog_controller",
		"func_brush",
		"func_wall",
		"func_illusionary",
		"info_node",
		"info_target",
		"info_node_hint",
		"info_player_allies",
		"info_player_axis",
		"point_viewcontrol",
		"shadow_control",
		"sky_camera",
		"scene_manager",
		"trigger_soundscape",
		"info_dod_detect",
		"dod_team_allies",
		"dod_team_axis",
		"point_commentary_node",
		"dod_round_timer",
		"func_precipitation",
		"func_team_wall",
		"", // END Marker -- Fix
	}
	
	local function RestartRound_f()
		GAMEMODE:State_Transition( STATE_RESTART ) -- Fix
	end
	concommand.Add( "restartround", RestartRound_f, nil, "Restart the round", FCVAR_CHEAT ) -- Fix; is the nil needed?
	--[[
	function GM:CopyGamePlayLogic( otherGamePlay ) -- Fix; needed?
		self.m_GamePlayRules.CopyFrom( otherGamePlay )
	end]]
	
	// --------------------------------------------------------------------------------------------------- //
	// CDODGameRules implementation.
	// --------------------------------------------------------------------------------------------------- //
	
	function GM:Initialize() -- Fix! Serverside shit!
		self:InitTeams()
		
		self:RestartMapTime()
		
		self:RestartScores()
		
		self.m_bInWarmup = false
		self.m_bAwaitingReadyRestart = false
		self.m_flRestartRoundTime = -1
		
		self.m_iAlliesRespawnHead = 0
		self.m_iAlliesRespawnTail = 0
		self.m_iAxisRespawnHead = 0
		self.m_iAxisRespawnTail = 0
		self.m_iNumAlliesRespawnWaves = 0
		self.m_iNumAxisRespawnWaves = 0
		
		for i = 1, DOD_RESPAWN_QUEUE_SIZE do
			self.m_AlliesRespawnQueue[i] = 0
			self.m_AxisRespawnQueue[i] = 0
		end
		
		self.m_bLevelInitialized = false
		self.m_iSpawnPointCount_Allies = 0
		self.m_iSpawnPointCount_Axis = 0
		
		self.m_vecPlayerPositions = {} -- Fix; do we need to declare 0 inside of there?
		RunConsoleCommand( "exec " .. game.GetMap() .. ".cfg" ) -- Fix; string.format this shit up ( does this even work btw? )
		
		self.m_pCurStateInfo = nil
		self:State_Transition( STATE_PREGAME )
		
		self.m_iStatsKillsPerClass_Allies = {}
		self.m_iStatsKillsPerClass_Axis = {}
		
		self.m_iStatsSpawnsPerClass_Allies = {}
		self.m_iStatsSpawnsPerClass_Axis = {}
		
		self.m_iStatsCapsPerClass_Allies = {}
		self.m_iStatsCapsPerClass_Axis = {}
		
		self.m_iStatsDefensesPerClass_Allies = {}
		self.m_iStatsDefensesPerClass_Axis = {}
		
		self.m_iWeaponShotsFired = {}
		self.m_iWeaponShotsHit = {}
		self.m_iWeaponDistanceBuckets = {}
		
		self.m_flSecondsPlayedPerClass_Allies = {}
		self.m_flSecondsPlayedPerClass_Axis = {}
		
		m_bUsingTimer = false
		self.m_pRoundTimer = nil // created on first round spawn that requires a timer
		
		self.m_bAlliesAreBombing = false
		self.m_bAxisAreBombing = false
	end
	
	function GM:LevelShutdown() -- Fix; figure out where to call this
		self:UploadLevelStats()
		
		self.BaseClass:LevelShutdown()
	end
	
	MY_USHRT_MAX = 0xffff
	MY_UCHAR_MAX = 0xff
	
	function GM:UploadLevelStats()
		--Fix, Convert this shit; send it somewhere
	end
	
	function GM:Stats_PlayerKill( team, cls )
		if ( cls >= 0 and cls <= 5 ) then
			if ( team == TEAM_ALLIES ) then
				self.m_iStatsKillsPerClass_Allies[cls] = self.m_iStatsKillsPerClass_Allies[cls] + 1
			elseif ( team == TEAM_AXIS ) then
				self.m_iStatsKillsPerClass_Axis[cls] = self.m_iStatsKillsPerClass_Axis[cls] + 1
			end
		end
	end
	
	function GM:Stats_PlayerCap( team, cls )
		if ( cls >= 0 and cls <= 5 ) then
			if ( team == TEAM_ALLIES ) then
				self.m_iStatsCapsPerClass_Allies[cls] = self.m_iStatsCapsPerClass_Allies[cls] + 1
			elseif ( team == TEAM_AXIS ) then
				self.m_iStatsCapsPerClass_Axis[cls] = self.m_iStatsCapsPerClass_Axis[cls] + 1
			end
		end
	end
	
	function GM:Stats_PlayerDefended( team, cls )
		if ( cls >= 0 and cls <= 5 ) then
			if ( team == TEAM_ALLIES ) then
				self.m_iStatsDefensesPerClass_Allies[cls] = self.m_iStatsDefensesPerClass_Allies[cls] + 1
			elseif ( team == TEAM_AXIS ) then
				self.m_iStatsDefensesPerClass_Axis[cls] = self.m_iStatsDefensesPerClass_Axis[cls] + 1
			end
		end
	end
	
	function GM:Stats_WeaponFired( weaponID )
		self.m_iWeaponShotsFired[weaponID] = self.m_iWeaponShotsFired[weaponID] + 1
	end
	
	function GM:Stats_WeaponHit( weaponID, flDist )
		self.m_iWeaponShotsHit[weaponID] = self.m_iWeaponShotsHit[weaponID] + 1
		
		local bucket = self:Stats_WeaponDistanceToBucket( weaponID, flDist )
		self.m_iWeaponDistanceToBuckets[weaponID][bucket] = self.m_iWeaponDistanceToBuckets[weaponID][bucket] + 1
	end
	
	function GM:Stats_WeaponDistanceToBucket( weaponID, flDist )
		local bucket = 4
		local iDist = math.floor( flDist ) -- Fix; how does (int) round floats?
		
		for i = 1, DOD_NUM_WEAPON_DISTANCE_BUCKETS - 1 do -- Fix
			if ( iDist < iWeaponBucketDistances[i] ) then
				bucket = i
				break
			end
		end
		
		return bucket
	end
	
	function GM:ClientCommand( pEdict, args ) -- Fix
	end
	
	function GM:CheckChatForReadySignal( pPlayer, chatmsg ) -- Fix
	end
	
	function GM:AreAlliesReady()
		return self.m_bHeardAlliesReady
	end
	
	function GM:AreAxisReady()
		return self.m_bHeardAxisReady
	end
	
	function GM:SelectDefaultTeam() -- Fix; totally redo the team. system and make it allow custom shit
		local team = TEAM_UNASSIGNED
		
		local pAllies
	end
	
	function GM:TeamFull( team_id ) -- Fix
	end
	
	function GM:GetExplosionDamageAdjustment() -- Fix; convert all this boring shit later
	end
	
	function GM:Think()
		local curtime = CurTime()
		
		if ( g_fGameOver ) then 	// someone else quit the game already -- Fix; dumb variable name
			// check to see if we should change levels now
			if ( self.m_flIntermissionEndTime < curtime ) then
				self:ChangeLevel() // intermission is over
			end
			
			return
		end
		
		self:State_Think()
		
		if ( curtime > self.m_flNextPeriodicThink ) then
			if ( self:CheckTimeLimit() or self:CheckWinLimit() ) then
				return
			end
			
			self:CheckRestartRound()
			self:CheckWarmup()
			self:CheckPlayerPosition()
			
			self.m_flNextPeriodicThink = curtime + 1.0
		end
		
		self.BaseClass:Think() -- Fix; there seems to be something different than the baseclass here. CGameRules::Think();
	end
	
	function GM:GoToIntermission()
		self.BaseClass:GoToIntermission()
		
		// set all players to FL_FROZEN
		for i = 1, #player.GetAll() do
			local pPlayer = util.GetByIndex( i )
			
			if ( IsValid( pPlayer ) ) then
				pPlayer:AddFlags( FL_FROZEN )
			end
		end
		
		self:State_Enter( STATE_GAME_OVER )
	end
	
	function GM:SetInWarmup( bWarmup )
		if ( self.m_bInWarmup == bWarmup ) then
			return
		end
		
		self.m_bInWarmup = bWarmup
		
		if ( bWarmup ) then
			self.m_flWarmupTimeEnds = CurTime() + mp_warmup_time:GetFloat() -- Fix; did we declare the convar here?
			DevMsgN( "Warmup_Begin" )
			
			-- Fix; gameevent stuff here
		else
			self.m_flWarmupTimeEnds = -1
			DevMsgN( "Warmup_Ends" )
		end
	end
	
	function GM:CheckWarmup()
		if ( mp_restartwarmup:GetBool() ) then
			if ( self.m_bInWarmup ) then
				self.m_flWarmupTimeEnds = CurTime() + mp_warmup_time:GetFloat()
			else
				self:SetInWarmup( true )
			end
			
			mp_restartwarmup:SetValue( 0 )
		end
		
		if ( mp_cancelwarmup:GetBool() ) then
			self:SetInWarmup( false )
			mp_cancelwarmup:SetValue( 0 )
		end
		
		if ( self.m_bInWarmup ) then
			// only exit the warmup if the time is up, and we are not in a round
			// restart countdown already, and we are not waiting for a ready restart
			if ( CurTime() > self.m_flWarmupTimeEnds and self.m_flRestartRoundTime < 0 and not self.m_bAwaitingReadyRestart ) then
				// no need to end the warmup, the restart will end it automatically
				//SetInWarmup( false );
				
				self.m_flRestartRoundTime = CurTime() // reset asap
			end
		end
	end
	
	function GM:CheckRestartRound()
		if ( mp_clan_readyrestart:GetBool() ) then -- Fix
			self.m_bAwaitingReadyRestart = true
			self.m_bHeardAlliesReady = false
			self.m_bHeardAxisReady = false
			
			local pszReadyString = mp_clan_ready_signal:GetString() -- Fix
			
			// Don't let them put anything malicious in there
			if ( not pszReadyString or string.len( pszReadyString ) > 16 ) then -- Fix?
				pszReadyString = "ready"
			end
			
			util.ClientPrintAll( HUD_PRINTCONSOLE, "#clan_ready_rules", pszReadyString ) -- Fix
			util.ClientPrintAll( HUD_PRINTTALK, "#clan_ready_rules", pszReadyString )
			
			-- Gameevent shit here
			
			mp_clan_readyrestart:SetValue( 0 )
			
			// cancel any restart round in progress
			self.m_flRestartRoundTime = -1
		end
		
		// Restart the game if specified by the server
		local iRestartDelay = mp_clan_restartround:GetInt()
		
		if ( iRestartDelay > 0 ) then
			if ( iRestartDelay > 60 ) then
				iRestartDelay = 60
			end
			
			self.m_flRestartRoundTime = CurTime() + iRestartDelay
			
			-- Gameevent shit here
			
			mp_clan_restartround:SetValue( 0 )
			
			// cancel any ready restart in progress
			self.m_bAwaitingReadyRestart = false
		end
	end
	
	function GM:CheckTimeLimit()
		if ( self:IsGameUnderTimeLimit() ) then
			if ( self:GetTimeLeft() <= 0 ) then
				-- Gameevent shit
				
				self:SendTeamScoresEvent()
				
				self:GoToIntermission()
				return true
			end
		end
		
		return false
	end
	
	function GM:CheckWinLimit()
		// has one team won the specified number of rounds?
		
		local iWinLimit = mp_winlimit:GetInt()
		
		if ( iWinLimit > 0 ) then
			local pAllies = GetGlobalTeam( TEAM_ALLIES ) -- Fix!!!
			local pAxis = GetGlobalTeam( TEAM_AXIS )
			
			local bAlliesWin = pAllies:GetRoundsWon() >= iWinLimit
			local bAxisWin = pAxis:GetRoundsWon() >= iWinLimit
			
			if ( bAlliesWin or bAxisWin ) then
				-- Gameevent shit
				
				self:GoToIntermission()
				return true
			end
		end
		
		return false
	end
	
	function GM:CheckPlayerPositions()
		local bUpdatePlayer = {}
		
		// check all players
		for i = 1, #player.GetAll() do
			local pPlayer = ents.GetByIndex( i ) -- Fix; do we need to do this? Can we just loop through the table?
			
			if ( not IsValid( pPlayer ) ) then
				continue
			end
			
			local origin = pPlayer:GetPos() -- Fix, GetAbsOrigin vs GetPos
			
			local pos = Vector( (origin.x/4), (origin.y/4), 0 ):Length2D() -- Do we need a 3rd argument, or can we just leave it out?
			
			if ( pos == self.m_vecPlayerPositions[ i ] ) then -- Fix; index consistency
				continue
			end
			
			self.m_vecPlayerPositions[ i ] = pos
			
			bUpdatePlayer[ i ] = true // player position changed since last time
		end
		
		// ok, now send updates to all clients
		-- local playerbits
		
		for i = 1, #player.GetAll() do
			local pPlayer = ents.GetByIndex( i )
			
			if ( not IsValid( pPlayer ) or not pPlayer:IsConnected() ) then
				return
			end
			
			-- Fix; skip all this until I get the PVS I need
		end
	end
	
	local function DropToGround( pMainEnt, vPos, vMins, vMaxs )
		local trace = util.TraceHull( {
									start = vPos
									endpos = vPos + Vector( 0, 0, -500 ),
									mins = vMins,
									maxs = vMaxs,
									mask = MASK_SOLID,
									filter = pMainEnt,
									--collision = COLLISION_GROUP_NONE, -- Fix
									} )
		return trace.endpos
	end
	
	local function TestSpawnPointType( pEntClassName )
		// Find the next spawn spot.
		local pSpots = ents.FindByClass( pEntClassName )
		
		for _, pSpot in pairs( pSpots ) do -- Fix; iPairs?
			// check if pSpot is valid
			if ( GAMEMODE:IsSpawnPointValid( pSpot ) ) then -- Fix
				-- Fix; box shit on box shit
				local GroundPos = DropToGround( nil, pSpot:GetPos(), VEC_HULL_MIN, VEC_HULL_MAX )
				
				local spotAngles = pSpot:GetLocalAngles()
				local vecForward = AngleVectors( spotAngles ) -- Fix
			else
				-- More box shit
			end
		end
	end
	
	local function TestSpawns()
		self:TestSpawnPointType( "info_player_allies" )
		self:TestSpawnPointType( "info_player_axis" )
	end
	concommand.Add( "map_showspawnpoints", TestSpawns, nil, "Dev - test the spawn points, draws for 60 seconds", FCVAR_CHEAT ) -- Fix
	
	function GM:GetPlayerSpawnSpot( pPlayer )
		// get valid spawn point
		local pSpawnSpot = pPlayer:EntSelectSpawnPoint()
		
		// drop down to ground
		local GroundPos = DropToGround( pPlayer, pSpawnPoint:GetPos(), VEC_HULL_MIN, VEC_HULL_MAX )
		
		// Move the player to the place it said.
		pPlayer:Teleport( GroundPos, pSpawnSpot:GetLocalAngles(), vec3_origin ) -- Fix
		pPlayer:SetViewPunchAngles( vec3_angle ) -- Fix? How does this differ from pPlayer:ViewPunch?
		
		return pSpawnSpot
	end
	
	function GM:IsSpawnPointValid( pSpot, pPlayer ) -- Fix; should this be a global function? IsValidSpawnPoint?
		if ( not pSpot:IsTriggered( pPlayer ) ) then
			return false
		end
		
		// Check if it is disabled by Enable/Disable
		if ( pSpot:IsDisabled() ) then
			return false
		end
		
		local mins = self:GetViewVectors().m_vHullMin -- Fix, big time
		local maxs = self:GetViewVectors().m_vHullMax -- Fix, big time
		
		local vTestMins = pSpot:GetPos() + mins
		local vTestMaxs = pSpot:GetPos() + maxs
		
		// First test the starting origin
		util.IsSpaceEmpty( pPlayer, vTestMins, vTestMaxs )
	end
	
	function GM:PlayerSpawn( pPlayer )
		local team = pPlayer:Team()
		
		if ( team == TEAM_ALLIES or team == TEAM_AXIS ) then
			if ( pPlayer:DesiredPlayerClass() == PLAYERCLASS_RANDOM ) then
				self:ChooseRandomClass( pPlayer )
				util.ClientPrint( pPlayer, HUD_PRINTTALK, "#game_now_as", self:GetPlayerClassName( pPlayer:PlayerClass(), team ) ) -- Fix
			else
				pPlayer:SetPlayerClass( pPlayer:DesiredPlayerClass() )
			end
			
			local playerclass = pPlayer:PlayerClass()
			
			if ( playerclass ~= PLAYERCLASS_UNDEFINED ) then
				local pTeam = GetGlobalTeam( team ) -- Fix
				local pClassInfo = pTeam:GetPlayerClassInfo( playerclass )
				
				assert( pClassInfo.m_iTeam == team ) -- Eek, should we be doing this? Doesn't really matter anyway since the playerclass handles most of the shit
				-- Fix
				-- All of this stuff is handled by the playerclass!
				assert( playerclass >= 0 && playerclass <= 5 )
				if ( playerclass >= 0 and playerclass <= 5 )
					if ( team == TEAM_ALLIES ) then
						self.m_iStatsSpawnsPerClass_Allies[playerclass] = self.m_iStatsSpawnsPerClass_Allies[playerclass] + 1
					elseif ( team == TEAM_AXIS ) then
						self.m_iStatsSpawnsPerClass_Axis[playerclass] = self.m_iStatsSpawnsPerClass_Axis[playerclass] + 1
					end
				end
			else
				assert( false, "Player spawning with PLAYERCLASS_UNDEFINED" )
				pPlayer:SetModel( NULL ) -- Fix; should we be doing this?
			end
		end
	end
	
	function GM:GetPlayerClassName( cls, team )
		local pTeam = GetGlobalTeam( team )
		
		if ( cls == PLAYERCLASS_RANDOM ) then
			return "#class_random"
		end
		
		if ( cls < 0 or cls >= pTeam:GetNumPlayerClasses() ) then
			assert( false )
			return
		end
		
		local pClassInfo = pTeam:GetPlayerClassInfo( cls )
		
		return pClassInfo.PrintName
	end
	
	function GM:ChooseRandomClass( pPlayer )
		local i
		local numChoices = 0
		local choices = {}
		local firstclass = 0
		
		local pTeam = GetGlobalTeam( pPlayer:Team() )
		
		local lastclass = pTeam:GetNumPlayerClasses()
		
		local previousClass = pPlayer:PlayerClass()
		
		// Compile a list of the classes that aren't full
		for i = firstclass, lastclass do -- Do we need to do lastclass - 1? Fix; also, will i match with the local variable above?
			// don't join the same class twice in a row
			if ( i == previousClass ) then
				continue
			end
			
			if ( self:CanPlayerJoinClass( pPlayer, i ) ) then
				choices[numChoices] = i
				numChoices = numChoices + 1
			end
		end
		
		// If ALL the classes are full
		if ( numChoices == 0 ) then
			MsgN( "Random class found that all classes were full - ignoring class limits for this spawn" )
			
			pPlayer:SetPlayerClass( random.RandomFloat( firstclass, lastclass ) )
		else
			// Choose a slot randomly
			i = random.RandomInt( 0, numChoices - 1 )
			
			// We are now the class that was in that slot
			pPlayer:SetPlayerClass( choices[i] )
		end
	end
	
	//-----------------------------------------------------------------------------
	// Purpose: This function can be used to find a valid placement location for an entity.
	//			Given an origin to start looking from and a minimum radius to place the entity at,
	//			it will sweep out a circle around vOrigin and try to find a valid spot (on the ground)
	//			where mins and maxs will fit.
	// Input  : *pMainEnt - Entity to place
	//			&vOrigin - Point to search around
	//			fRadius - Radius to search within
	//			nTries - Number of tries to attempt
	//			&mins - mins of the Entity
	//			&maxs - maxs of the Entity
	//			&outPos - Return point
	// Output : Returns true and fills in outPos if it found a spot.
	//-----------------------------------------------------------------------------
	local function EntityPlacementTest( pMainEnt, vOrigin, outPos, bDropToGround ) -- Fix; investigate if pointers need to be returned here
		local mins, maxs = pMainEnt:WorldSpaceAABB( mins, max )
		mins = mins - pMainEnt:GetPos()
		maxs = maxs - pMainEnt:GetPos()
		
		// Put some padding on their bbox
		
		local vTestMins = mins -- Fix; since we're not doing pointers, is this needed?
		local vTestMaxs = maxs
		
		// First test the starting origin
		if ( util.IsSpaceEmpty( pMainEnt, vOrigin + vTestMins, vOrigin + vTestMaxs ) ) then
			if ( bDropToGround ) then
				outPos = DropToGround( pMainEnt, vOrigin, vTestMins, vTestMaxs )
			else
				outPos = vOrigin
			end
			
			return true
		end
		
		local vDims = vTestMaxs - vTestMins
		
		// Keep branching out until we get too far
		local iCurIteration = 0
		local nMaxIterations = 15
		
		local offset = 0
		repeat
			for iDim = 0, 1 do
				local flCurOffset = offset * vDims[iDim]
				
				for iSign = 0, 1 do
					local vBase = vOrigin
					vBase[iDim] = vBase[iDim] + (iSign*2-1) * flCurOffset
					
					if ( util.IsSpaceEmpty( pMainEnt, vBase + vTestMins, vBase + vTestMaxs ) ) then
						// Ensure that there is a clear line of sight from the spawnpoint entity to the actual spawn point.
						// (Useful for keeping things from spawning behind walls near a spawn point)
						local tr = util.TraceLine( {
												start = vOrigin,
												endpos = vBase,
												mask = MASK_SOLID,
												filter = pMainEnt,
												-- collision = COLLISION_GROUP_NONE -- Fix
												} )
						
						if ( tr.Fraction ~= 1.0 ) then
							continue
						end
						
						if ( bDropToGround ) then
							outPos = self:DropToGround( pMainEnt, vBase, vTestMins, vTestMaxs )
						else
							outPos = vBase
						end
						
						return true
					end
				end
			end
			
			offset = offset + 1
		until ( iCurIteration + 1 > nMaxIterations ) -- Fix; iCurIteration++ was used in the while statement. Does that mean is checks iCurIteration or iCurIteration + 1?
		
		//	Warning( "EntityPlacementTest for ent %d:%s failed!\n", pMainEnt->entindex(), pMainEnt->GetClassname() );
		return false
	end
	
	function GM:CanHavePlayerItem( pPlayer, pWeapon )
		//only allow one primary, one secondary and one melee
		if ( IsValid( pWeapon ) ) then
			local iType = pWeapon.Type
			
			if ( iType == WPN_TYPE_MELEE ) then
				if ( DEBUG ) then -- Fix, should we have this?
					local pMeleeWeapon = pPlayer:GetSlotWeapon( WPN_SLOT_MELEE ) -- Fix
					local bHasMelee = IsValid( pMeleeWeapon )
					
					if ( bHasMelee ) then
						assert( false, "Why are we trying to add another melee?" )
						return false
					end
				end
			elseif( iType == WPN_TYPE_SIDEARM ) then
				if ( DEBUG ) then -- Fix, should we have this?
					local pSecondaryWeapon = pPlayer:GetSlotWeapon( WPN_SLOT_SECONDARY ) -- Fix
					local bHasPistol = IsValid( pSecondaryWeapon )
					
					if ( bHasPistol ) then
						assert( false, "Why are we trying to add another pistol?" )
						return false
					end
				end
			elseif ( iType == WPN_TYPE_CAMERA ) then
				return true
			elseif ( iType == WPN_TYPE_BAZOOKA ) then
				// Don't pick up dropped weapons if we have one already
				local pPrimaryWeapon = pPlayer:GetSlotWeapon( WPN_SLOT_PRIMARY )
				local bHasPrimary = IsValid( pPrimaryWeapon )
				
				if ( bHasPrimary ) then
					return false
				end
			end
		end
		
		return self.BaseClass:CanHavePlayerItem( pPlayer, pWeapon )
	end
	
	function GM:ResetMapTime()
		self.m_flMapResetTime = CurTime()
		
		// send an event with the time remaining until the map change
		
		-- Gameevent shit
	end
end

function GM:ShouldCollide( collisionGroup0, collisionGroup1 )
	if ( collisionGroup0 > collisionGroup1 ) then
		collisionGroup0, collisionGroup1 = swap( collisionGroup0, collisionGroup1 )
	end
	
	//Don't stand on COLLISION_GROUP_WEAPONs
	if ( collisionGroup0 == COLLISION_GROUP_PLAYER_MOVEMENT and
		collisionGroup1 == COLLISION_GROUP_WEAPON ) then
		return false
	end
	
	// TE shells don't collide with the player
	if ( collisionGroup0 == COLLISION_GROUP_PLAYER and
		collisionGroup1 == DOD_COLLISIONGROUP_SHELLS ) then -- Fix
		return false
	end
	
	return self.BaseClass:ShouldCollide( collisionGroup0, collisionGroup1 )
end	

function GM:State_Get()
	return self.m_iRoundState
end

function GM:GetSubTeam( team )
	return SUBTEAM_NORMAL
end

function GM:IsGameUnderTimeLimit()
	return ( mp_timelimit:GetInt() > 0 )
end

function GM:GetTimeLeft()
	local flTimeLimit = mp_timelimit:GetInt() * 60
	
	assert( flTimeLimit > 0, "Should not call this function when !IsGameUnderTimeLimit" )
	
	local flMapChangeTime = self.m_flMapResetTime + flTimeLimit

	if ( SERVER ) then
		// If the round timer is longer, let the round complete
		if ( self.m_bUsingTimer and self.m_pRoundTimer ) then
			local flTimerSeconds = self.m_pRoundtimer:GetTimeRemaining()
			local flMapChangeSeconds = flMapChangeTime - CurTime()
			
			// if the map timer is less than the round timer
			// AND
			// the round timer is less than 2 minutes
			
			
			// If the map time for any reason goes beyond the end of the round, remove the flag
			if ( flMapChangeSeconds > flTimerSeconds ) then
				self.m_bChangeLevelOnRoundEnd = false
			elseif ( self.m_bChangeLevelOnRoundEnd or flTimerSeconds < 120 ) then
				// once this happens once in a round, use this until the round ends
				// or else the round will end when a team captures an objective and adds time to above 120
				self.m_bChangeLevelOnRoundEnd = true
				
				return flTimerSeconds -- Fix; check (int) rounding method
			end
		end
	end
	
	return ( flMapChangeTime - CurTime() )
end

function GM:GetReinforcementTimerSeconds( team, flSpawnEligibleTime )
	// find the first wave that this player can fit in
	
	local flWaveTime = -1
	
	if ( team == TEAM_ALLIES ) then
		local i = self.m_iAlliesRespawnHead
		
		while ( i ~= self.m_iAlliesRespawnTail ) do
			if ( flSpawnEligibleTime < self.m_AlliesRespawnQueue[i + 1] ) then -- Fix; should it be i+1?
				flWaveTime = self.m_AlliesRespawnQueue[i + 1]
				break
			end
			
			i = ( i+1 ) % DOD_RESPAWN_QUEUE_SIZE
		end
	elseif ( team == TEAM_ALLIES ) then
		local i = self.m_iAxisRespawnHead
		
		while ( i ~= self.m_iAxisRespawnTail ) do
			if ( flSpawnEligibleTime < self.m_AxisRespawnQueue[i + 1] ) then
				flWaveTime = self.m_AxisRespawnQueue[i + 1]
				break
			end
			
			i = ( i+1 ) % DOD_RESPAWN_QUEUE_SIZE
		end
	else
		return -1
	end
	
	return math.max( 0, ( flWaveTime - CurTime() ) )
end

function GM:GetViewVectors()
	return g_DODViewVectors -- Fix; should it be global? Or nah
end

function GM:AwaitingReadyRestart()
	return self.m_bAwaitingReadyRestart
end

function GM:GetRoundRestartTime()
	return self.m_flRestartRoundTime
end

function GM:IsInWarmup()
	return self.m_bInWarmup
end

if ( SERVER ) then
	local dod_bonusround = GetConVar( "dod_bonusround" )
	
	function GM:IsFriendlyFireOn()
		// Never friendly fire in bonus round
		if ( self:IsInBonusRound() ) then
			return false
		end
		
		return friendlyfire:GetBool() -- Fix
	end
	
	function GM:IsInBonusRound()
		return ( dod_bonusround:GetBool() and ( self:State_Get() == STATE_ALLIES_WIN or self:State_Get() == STATE_AXIS_WIN ) )
	end
	
	local dod_showroundtransitions = CreateConVar( "dod_showroundtransitions", "0", 0, "Show gamestate round transitions" )
	
	function GM:State_Transition( newState )
		self:State_Leave()
		self:State_Enter( newState )
	end
	
	function GM:State_Enter( newState )
		self.m_iRoundState = newState
		self.m_pCurStateInfo = self:State_LookupInfo( newState )
		
		if ( dod_showroundtransitions:GetInt() > 0 ) then
			if ( self.m_pCurStateInfo ) then
				MsgN( "DODRoundState: entering '%s'", self.m_pCurStateInfo.m_pStateName )
			else
				MsgN( "DODRoundState: entering #%d", newState )
			end
		end
		
		// Initialize the new state.
		if ( self.m_pCurStateInfo and self.m_pCurStateInfo.pfnEnterState ) then
			(self.m_pCurStateInfo.pfnEnterState)()
		end
	end
	
	function GM:State_Leave()
		if ( self.m_pCurStateInfo and self.m_pCurStateInfo.pfnLeaveState ) then
			(self.m_pCurStateInfo.pfnLeaveState)()
		end
	end
	
	function GM:State_Think()
		if ( self.m_pCurStateInfo and self.m_pCurStateInfo.pfnThink ) then
			(self.m_pCurStateInfo.pfnThink)()
		end
	end
	
	local playerStateInfos =
	{
		{ m_iRoundState = STATE_INIT, m_pStateName = "STATE_INIT", self:State_Enter_INIT, nil, self:State_Think_INIT },
		{ m_iRoundState = STATE_PREGAME, m_pStateName = "STATE_PREGAME", self:State_Enter_PREGAME, nil, self:State_Think_PREGAME },
		{ m_iRoundState = STATE_STARTGAME, m_pStateName = "STATE_STARTGAME", self:State_Enter_STARTGAME, nil, self:State_Think_STARTGAME },
		{ m_iRoundState = STATE_PREROUND, m_pStateName = "STATE_PREROUND", self:State_Enter_PREROUND, nil, self:State_Think_PREROUND },
		{ m_iRoundState = STATE_RND_RUNNING, m_pStateName = "STATE_RND_RUNNING", self:State_Enter_RND_RUNNING, nil, self:State_Think_RND_RUNNING },
		{ m_iRoundState = STATE_ALLIES_WIN, m_pStateName = "STATE_ALLIES_WIN", self:State_Enter_ALLIES_WIN, nil, self:State_Think_ALLIES_WIN },
		{ m_iRoundState = STATE_AXIS_WIN, m_pStateName = "STATE_AXIS_WIN", self:State_Enter_AXIS_WIN, nil, self:State_Think_AXIS_WIN },
		{ m_iRoundState = STATE_RESTART, m_pStateName = "STATE_RESTART", self:State_Enter_RESTART, nil, self:State_Think_RESTART },
		{ m_iRoundState = STATE_ALLIES_WIN, m_pStateName = "STATE_ALLIES_WIN", nil, nil, nil },
	}
	
	function GM:State_LookupInfo( state )
		for _, StateInfo in ipairs( playerStateInfos ) do
			if ( StateInfo.m_iRoundState == state ) then
				return StateInfo
			end
		end
		
		return
	end
	
	local sv_stopspeed = GetConVar( "sv_stopspeed" )
	local sv_friction = GetConVar( "sv_friction" )
	
	function GM:State_Enter_INIT()
		self:InitTeams()
		
		sv_stopspeed:SetValue( 50.0 )
		sv_friction:SetValue( 8.0 )
		
		self:ResetMapTime()
	end
	
	function GM:State_Think_INIT()
		self:State_Transition( STATE_PREGAME )
	end
	
	function GM:InitTeams()
		assert( #g_Teams == 0 ) -- Fix
		
		g_Teams = {}	// just in case -- Why
		
		// Create the team managers
		
		for i = 1, 2 do		// Unassigned and Spectators
			local pTeam = Team( self.sTeamNames[i], i )
			
			table.insert( g_Teams, pTeam )
		end
		
		// clear the player class data
		self:ResetFilePlayerClassInfoDatabase() -- Fix
		
		-- FIX AF. WE'RE NOT MAKING TEAM ENTITIES
		local pAllies = Team( self.sTeamNames[TEAM_ALLIES], TEAM_ALLIES )
		table.insert( g_Teams, pAllies )
		
		local pAxis = Team( self.sTeamNames[TEAM_AXIS], TEAM_AXIS )
		table.insert( g_Teams, pAxis )
	end
	
	// dod_control_point_master can take inputs to add time to the round timer
	function GM:AddTimerSeconds( iSecondsToAdd )
		if ( self.m_bUsingTimer and self.m_pRoundTimer ) then
			self.m_pRoundTimer:AddTimerSeconds( iSecondsToAdd )
			
			local flTimerSeconds = self.m_pRoundTimer:GetTimeRemaining() -- Fix; GetTimeRemaining or GetRemaining?
			
			self.m_bPlayTimerWarning_1Minute = ( flTimerSeconds > 60 )
			self.m_bPlayTimerWarning_2Minute = ( flTimerSeconds > 120 )
			
			-- Gameevent
		end
	end
	
	function GM:GetTimerSeconds()
		if ( self.m_bUsingTimer and self.m_pRoundTimer ) then
			return self.m_pRoundTimer:GetTimeRemaining()
		else
			return 0
		end
	end
	
	// PREGAME - the server is idle and waiting for enough
	// players to start up again. When we find an active player
	// go to STATE_STARTGAME
	function GM:State_Enter_PREGAME()
		self.m_flNextPeriodicThink = CurTime() + 0.1
		
		self:Load_EntText()
	end
	
	function GM:State_Think_PREGAME()
		self:CheckLevelInitialized()
		
		if ( self:CountActivePlayers() > 0 ) then
			self:State_Transition( STATE_STARTGAME )
		end
	end
	
	// STARTGAME - wait a bit and then spawn everyone into the 
	// preround
	function GM:State_Enter_STARTGAME()
		self.m_flStateTransitionTime = CurTime() + 5 * dod_enableroundwaittime:GetFloat()
		
		self.m_bInitialSpawn = true
	end
	
	function GM:State_Think_STARTGAME()
		if ( CurTime() > self.m_flStateTransitionTime ) then
			if ( mp_warmup_time:GetFloat() > 0 ) then
				// go into warmup, reset at the end of it
				self:SetInWarmup( true )
			end
			
			self:State_Transition( STATE_PREROUND )
		end
	end
	
	function GM:State_Enter_PREROUND()
		// Longer wait time if its the first round, let people join
		if ( self.m_bInitialSpawn ) then
			self.m_flStateTransitionTime = CurTime() + 10 * dod_enableroundwaittime:GetFloat()
			self.m_bInitialSpawn = false
		else
			self.m_flTransitionTime = CurTime() + 5 * dod_enableroundwaittime:GetFloat()
		end
		
		//Game rules may change, if a new one becomes mastered at the end of the last round
		self:DetectGameRules()
		
		//reset everything in the level
		self:RoundRespawn()
		
		// reset this now! If its reset at round restart, we lost all players that died
		// during the preround
		self.m_iAlliesRespawnHead = 0
		self.m_iAlliesRespawnTail = 0
		self.m_iAxisRespawnHead = 0
		self.m_iAxisRespawnTail = 0
		self.m_iNumAlliesRespawnWaves = 0
		self.m_iNumAxisRespawnWaves = 0
		
		self.m_iLastAlliesCapEvent = CAP_EVENT_NONE
		self.m_iLastAxisCapEvent = CAP_EVENT_NONE
		
		//find all the control points, init the timer
		local pEnts = ents.FindByClass( "dod_control_point_master" )
		
		if ( not pEnts or pEnts == {} ) then
			Error( "No dod_control_point_master found in level - control points will not work as expected." ) -- Fix
		end
		
		local bFoundTimer = false
		
		for _, pMaster in pairs( pEnts ) do -- Fix, iPairs?
			pMaster:AcceptInput( "RoundInit", nil, nil, "" ) -- Fix? What is the data string supposed to be?
			
			if ( pEnt:IsActive() and pMaster:IsUsingRoundTimer() ) then
				bFoundTimer = true
				
				self.m_bUsingTimer = true
				
				local iTimerSeconds = pMaster:GetTimerData( self.m_iTimerWinTeam ) -- Fix; iTimerSeconds is pointer value to something
				
				if ( self.m_iTimerWinTeam ~= TEAM_ALLIES and self.m_iTimerWinTeam ~= TEAM_AXIS ) then
					assert( false, "Round timer win team can only be allies or axis" )
				end
				
				// Timer starts paused
				if ( not self.m_pRoundTimer ) then
					self.m_pRoundTimer = Timer() -- Fix
					self.m_pRoundTimer:SetTimeRemaining( iTimerSeconds )
					self.m_pRoundTimer:Pause()
					
					self.m_bPlayTimerWarning_1Minute = ( iTimerSeconds > 60 )
					self.m_bPlayTimerWarning_2Minute = ( iTimerSeconds > 120 )
				end
			end
		end
		
		if ( not bFoundTimer ) then
			// No masters are active that require the round timer, destroy it
			self.m_pRoundTimer:Remove()
			self.m_pRoundTimer = nil
		end
		
		//init the cap areas
		pEnts = ents.FindByClass( "dod_capture_area" )
		for _, pEnt in pairs( pEnts ) do
			pEnt:AcceptInput( "RoundInit", nil, nil, "" ) -- Fix
		end
		
		-- Gameevent
		
		self.m_bAlliesAreBombing = false
		self.m_bAxisAreBombing = false
		
		pEnts = ents.FindByClass( "dod_bomb_target" )
		for _, pTarget in pairs( pEnts ) do
			if ( IsValid( pTarget ) and pTarget:State_Get() == BOMB_TARGET_ACTIVE ) then
				local team = pTarget:GetBombingTeam()
				
				if ( team == TEAM_ALLIES ) then
					self.m_bAlliesAreBombing = true
				elseif ( team == TEAM_AXIS ) then
					self.m_bAxisAreBombing = true
				end
			end
		end
	end
	
	function GM:State_Think_PREROUND()
		if ( CurTime() > self.m_flStateTransitionTime ) then
			self:State_Transition( STATE_RND_RUNNING )
		end
		
		self:CheckRespawnWaves()
	end
	
	function GM:State_Enter_RND_RUNNING()
		//find all the control points, init the timer
		local pEnts = ents.FindByClass( "dod_control_point_master" )
		
		for _, pEnt in pairs( pEnts ) do
			pEnt:AcceptInput( "RoundStart", nil, nil, "" )
		end
		
		-- Gameevent
		
		if ( not self:IsInWarmup() ) then
			self:PlayStartRoundVoice()
		end
		
		if ( self.m_bUsingTimer and IsValid( self.m_pRoundTimer ) ) then
			self.m_pRoundTimer:Resume()
		end
		
		self.m_bChangeLevelOnRoundEnd = false
	end
	
	function GM:State_Think_RND_RUNNING()
		// Where the magic happens
		
		if ( self.m_bUsingTimer and self.m_pRoundTimer ) then
			local flSecondsRemaining = self.m_pRoundTimer:GetTimeRemaining()
			
			if ( flSecondsRemaining <= 0 ) then
				// if there is a bomb still on a timer, and that bomb has
				// the potential to add time, then we don't end the game
				
				local bBombBlocksWin = false
				
				// find all the control points, init the timer
				local pEnts = ents.FindByClass( "dod_bomb_target" )
				local pMasters = ents.FindByClass( "dod_control_point_master" ) -- Fix; this is supposed to be pEnts but reinitialized
				
				for _, pBomb in pairs( pEnts ) do
					// Find active bombs that have the potential to add round time
					if ( IsValid( pBomb ) and pBomb:State_Get() == BOMB_TARGET_ARMED ) then
						if ( pBomb:GetTimerAddSeconds() > 0 ) then
							// don't end the round until this bomb goes off or is disarmed
							bBombBlocksWin = true
							break
						end
						
						local pPoint = pBomb:GetControlPoint()
						local iBombingTeam = pBomb:GetBombingTeam()
						
						if ( pPoint and pPoint:GetBombsRamining() <= 1 ) then
							// find active dod_control_point_masters, ask them if this flag capping 
							// would end the game
							
							for _, pMaster in pairs( pMasters ) do
								if ( pMaster:IsActive() ) then
									// Check TeamOwnsAllPoints, while overriding this particular flag's owner
									if ( pMaster:WouldNewCPOwnerWinGame( pPoint, iBombingTeam ) then
										// This bomb may win the game, don't end the round
										bBombBlocksWin = true
										break
									end
								end
							end
						end
					end
				end
				
				if ( not bBombBlocksWin ) then
					self:SetWinningTeam( self.m_iTimerWinTeam )
					
					// tell the dod_control_point_master to fire its outputs for the winning team!
					// minor hackage - dod_gamerules should be responsible for team win events, not dod_cpm

					//find all the control points, init the timer
					for _, pMaster in pairs( pMasters ) do
						if ( pMaster:IsActive() ) then
							pMaster:FireTeamWinOutput( self.m_iTimerWinTeam ) -- Fix
						end
					end
				end
			elseif ( flSecondsRemaining < 60.0 and self.m_bPlayTimerWarning_1Minute ) then
				// play one minute warning
				DevMsgN( 1, "Timer Warning: 1 Minute Remaining" )
				
				-- Gameevent
				
				self.m_bPlayTimerWarning_1Minute = false
			elseif ( flSecondsRemaining < 120.0 and self.m_bPlayTimerWarning_2Minute ) then
				// play two minute warning
				DevMsgN( 1, "Timer Warning: 2 Minutes Remaining" )
				
				-- Gameevent
				
				self.m_bPlayTimerWarning_2Minute = false
			end
		end
		
		//if we don't find any active players, return to STATE_PREGAME
		if ( self:CountActivePlayers() <= 0 ) then
			self:State_Transition( STATE_PREGAME )
			return
		end
		
		self:CheckRespawnWaves()
		
		// check round restart
		if ( self.m_flRestartRoundTime > 0 and self.m_flRestartRoundTime < CurTime() ) then
			// time to restart!
			self:State_Transition( STATE_RESTART )
			self.m_flRestartRoundTime = -1
		end
		
		// check ready restart
		if ( self.m_bAwaitingReadyRestart and self.m_bHeardAlliesReady and self.m_bHeardAxisReady ) then
			//self:State_Transition( STATE_RESTART )
			self.m_flRestartRoundTime = CurTime() + 5
			self.m_bAwaitingReadyRestart = false
		end
	end
	
	function GM:CheckRespawnWaves()
		//Respawn Timers
		if ( self.m_iNumAlliesRespawnWaves > 0 and self.m_AlliesRespawnQueue[self.m_iAlliesRespawnHead + 1] < CurTime() ) then -- Fix; +1, right?
			DevMsgN( "Wave: Respawning Allies" )
			
			self:RespawnTeam( TEAM_ALLIES )
			
			self:PopWaveTime( TEAM_ALLIES )
		end
		
		if ( self.m_iNumAxisRespawnWaves > 0 and self.m_AxisRespawnQueue[self.m_iAxisRespawnHead] < CurTime() ) then
			DevMsgN( "Wave: Respawning Axis" )
			
			self:RespawnTeam( TEAM_AXIS )
			
			self:PopWaveTime( TEAM_AXIS )
		end
	end
	
	//ALLIES WIN
	function GM:State_Enter_ALLIES_WIN()
		local flTime = math.max( 5, dod_bonusroundtime:GetFloat() )
		
		self.m_flStateTransitionTime = CurTime() + flTime * dod_enableroundwaittime:GetFloat()
		
		if ( self.m_bUsingTimer and self.m_pRoundTimer ) then
			self.m_pRoundTimer:Pause()
		end
	end
	
	function GM:State_Think_ALLIES_WIN()
		if ( CurTime() > self.m_flStateTransitionTime ) then
			self:State_Transition( STATE_PREROUND )
		end
	end
	
	//AXIS WIN
	function GM:State_Enter_ALLIES_WIN()
		local flTime = math.max( 5, dod_bonusroundtime:GetFloat() )
		
		self.m_flStateTransitionTime = CurTime() + flTime * dod_enableroundwaittime:GetFloat()
		
		if ( self.m_bUsingTimer and self.m_pRoundTimer ) then
			self.m_pRoundTimer:Pause()
		end
	end
	
	function GM:State_Think_ALLIES_WIN()
		if ( CurTime() > self.m_flStateTransitionTime ) then
			self:State_Transition( STATE_PREROUND )
		end
	end
	
	function GM:State_Enter_RESTART()
		// send scores
		self:SendTeamScoresEvent()
		
		// send restart event
		-- Gameevent
		
		self:SetInWarmup( false )
		
		self:ResetScores()
		
		// reset the round time
		self:ResetMapTime()
		
		self:State_Transition( STATE_PREROUND )
	end
	
	function GM:SendTeamScoresEvent()
		// send scores
		-- Gameevent
	end
	
	function GM:State_Think_RESTART()
		assert( 0 ) // should never get here, State_Enter_RESTART sets us into a different state -- Then WHY THE FUCK IS IT HERE. Fix
	end
	
	function GM:ResetScores()
		GetGlobalTeam( TEAM_ALLIES ):ResetScores()
		GetGlobalTeam( TEAM_AXIS ):ResetScores()
		
		for _, pDODPlayer in pairs( player.GetAll() ) do -- iPairs? Fix
			if ( not IsValid( pDODPlayer ) ) then
				continue
			end
			
			-- Fix; should we be checking if the player is a spectator or not?
			
			pDODPlayer:ResetScores()
		end
	end
	
	// Respawn everyone regardless of state - round reset
	function GM:RespawnAllPlayers()
		self:RespawnPlayers( true )
	end
	
	// Respawn only one team, players that are ready to spawn - wave reset
	function GM:RespawnTeam( iTeam )
		self:RespawnPlayers( false, true, iTeam )
	end
	
	-- local dod_showcleanedupents = CreateConVar( "dod_showcleanedupents", "0", 0, "Show entities that are removed on round respawn" )
	
	function GM:CleanUpMap()
		game.CleanUpMap() -- Fix; should this function even exist?
	end
	
	function GM:CountActivePlayers()
		local count = 0
		
		for _, pDODPlayer in pairs( player.GetAll() ) do -- iPairs? Fix
			if ( IsValid( pDODPlayer ) and pDODPlayer:IsReadyToPlay() ) then
				count = count + 1
			end
		end
		
		return count
	end
	
	function GM:RoundRespawn()
		self:CleanUpMap()
		self:RespawnAllPlayers()
		
		// reset per-round scores for each player
		for _, pPlayer in pairs( player.GetAll() ) do
			if ( IsValid( pPlayer ) ) then
				pPlayer:ResetPerRoundStats()
			end
		end
	end
	
	-- FIX! Go through and replace all instances of for i=0, #player.GetAll with just a player.GetAll loop
	
	--[[ playerscore_t structure:
		- integer iPlayerIndex
		- integer iScore
	]]--
	
	local function PlayerScoreInfoSort( p1, p2 )
		// check frags
		if ( p1.iScore > p2.iScore ) then
			return -1
		elseif ( p2.iScore > p1.iScore ) then
			return 1
		elseif ( p1.iPlayerIndex < p2.iPlayerIndex ) then
			return -1
		end
		
		return 1
	end
	
	// Store which event happened most recently, flag cap or bomb explode
	function GM:CapEvent( event, team )
		if ( team == TEAM_ALLIES ) then
			self.m_iLastAlliesCapEvent = event
		elseif ( team == TEAM_AXIS ) then
			self.m_iLastAxisCapEvent = event
		end
	end
	
	local function FillEventCategory()
		-- So much gameevent shit jesus christ
	end
	
	//Input for other entities to declare a round winner.
	//Most often a dod_control_point_master saying that the
	//round timer expired or that someone capped all the flags
	function GM:SetWinningTeam( team )
		if ( team ~= TEAM_ALLIES and team ~= TEAM_AXIS ) then
			assert( false, "bad winning team set" )
			return
		end
		
		self:PlayWinSong( team )
		
		GetGlobalTeam( team ):IncrementRoundsWon()
		
		if ( team == TEAM_ALLIES ) then
			self:State_Transition( STATE_ALLIES_WIN )
		elseif ( team == TEAM_AXIS ) then
			self:State_Transition( STATE_AXIS_WIN )
		end
		
		-- Gameevent
		
		// if this was in colmar, and the losing team did not cap any points,
		// the winners may have gotten an achievement
		-- Fix; do this shit later when you give a fuck
		
		
		// send team scores
		self:SendTeamScoresEvent()
		
		-- Gameevent AGAIN
		
	end
	
	local function TestWinpanel()
		-- all GAMEEVENT SHIT
	end
	concommand.Add( "dod_test_winpanel", TestWinpanel, , nil, "", FCVAR_CHEAT )
	
	// bForceRespawn - respawn player even if dead or dying
	// bTeam - if true, only respawn the passed team
	// iTeam  - team to respawn
	function GM:RespawnPlayers( bForceRespawn, bTeam, iTeam )
		if ( bTeam ) then
			if ( iTeam == TEAM_ALLIES ) then
				DevMsgN( 2, "Respawning Allies" )
			elseif ( iTeam == TEAM_AXIS ) then
				DevMsgN( 2, "Respawning Axis" )
			else
				assert( false, "Trying to respawn a strange team" )
			end
		end
		
		for _, pPlayer in pairs( player.GetAll() ) do
			if ( not IsValid( pPlayer ) ) then
				continue
			end
			-- Fix; elseif?
			// Check for team specific spawn
			if ( bTeam and pPlayer:Team() ~= iTeam ) then
				continue
			end
			
			// players that haven't chosen a class can never spawn
			if ( pPlayer:DesiredPlayerClass() == PLAYERCLASS_UNDEFINED ) then
				util.ClientPrint( pPlayer, HUD_PRINTTALK, "#game_will_spawn" )
				continue
			end
			
			if ( pPlayer:IsClassMenuOpen() and not pPlayer:Alive() ) then
				self:CreateOrJoinRespawnWave( pPlayer )
				continue
			end
			
			// If we aren't force respawning, don't respawn players that:
			// - are alive
			// - are still in the death anim stage of dying
			if ( not bForceRespawn ) then
				if ( pPlayer:Alive() ) then
					continue
				end
				
				if ( self:State_Get() ~= STATE_PREROUND and pPlayer:State_Get() == STATE_DEATH_ANIM ) then
					continue
				end
			end
			
			// Respawn this player
			pPlayer:DODRespawn() -- Fix; should we have a specific respawn function for DOD?
		end
	end
	
	function GM:IsPlayerClassOnTeam( cls, team )
		if ( cls == PLAYERCLASS_RANDOM ) then
			return true
		end
		
		local pTeam = GetGlobalTeam( team )
		
		return ( cls >= 0 and cls < pTeam:GetNumPlayerClasses() ) -- Fix; this is a shitty comparison
	end
	
	function GM:CanPlayerJoinClass( pPlayer, cls )
		if ( cls == PLAYERCLASS_RANDOM ) then
			return mp_allowrandomclass:GetBool()
		end
		
		if ( self:ReachedClassLimit( pPlayer:Team(), cls ) ) then
			return false
		end
		
		return true
	end
	
	function GM:ReachedClassLimit( team, cls )
		assert( cls ~= PLAYERCLASS_UNDEFINED )
		assert( cls ~= PLAYERCLASS_RANDOM )
		
		// get the cvar
		local iClassLimit = self:GetClassLimit( team, cls )
		
		// count how many are active
		local iClassExisting = self:CountPlayerClass( team, cls )
		
		local pTeam = GetGlobalTeam( team )
		local pThisClassInfo = pTeam:GetPlayerClassInfo( cls )
		
		if ( mp_combinemglimits:GetBool() and pThisClassInfo.m_bClassLimitMGMerge ) then
			// find the other classes that have "mergemgclasses"
			
			for i = 1, pTeam:GetNumPlayerClasses() do
				if ( i ~= cls ) then
					local pClassInfo = pTeam:GetPlayerClassInfo( i )
					if ( pClassInfo.m_bClassLimitMGMerge ) then
						// add the class' limits and counts
						iClassLimit = iClassLimit + self:GetClassLimit( team, i )
						iClassExisting = iClassExisting + self:CountPlayerClass( team, i )
					end
				end
			end
		end
		
		if ( iClassLimit > -1 and iClassExisting >= iClassLimit ) then
			return true
		end
		
		return false
	end
	
	function GM:CountPlayerClass( team, cls )
		local num = 0
		
		for _, pDODPlayer in pairs( player.GetAll() ) do
			if ( not IsValid( pDODPlayer ) ) then
				continue
			-- Fix; check for edicts!
			elseif ( pDODPlayer:Team() ~= team ) then
				continue
			elseif ( pDODPlayer:DesiredPlayerClass() == cls ) then
				num = num + 1
			end
		end
		
		return num
	end
	
	function GM:GetClassLimit( team, cls )
		local pTeam = GetGlobalTeam( team )
		
		assert( pTeam )
		
		local pClassInfo = pTeam:GetPlayerClassInfo( cls )
		
		local iClassLimit
		
		local pLimitCvar = pClassInfo.m_szLimitCvar and GetConVar( pClassInfo.m_szLimitCvar ) -- Fix; check for any classes that don't have this CVAR
		
		if ( pLimitCvar ) then
			iClassLimit = pLimitCvar:GetInt()
		else
			iClassLimit = -1
		end
		
		return iClassLimit
	end
	
	function GM:CheckLevelInitialized()
		if ( not self.m_bLevelInitialized ) then
			// Count the number of spawn points for each team
			// This determines the maximum number of players allowed on each
			
			self.m_iSpawnPointCount_Allies = 0
			self.m_iSpawnPointCount_Axis = 0
			
			local ent = ents.FindByClass( "info_player_allies" )
			
			for _, point in pairs( ent ) do
				if ( self:IsSpawnPointValid( ent, NULL ) ) then -- Fix af; check that all NULL players aren't defined by nil
					self.m_iSpawnPointCount_Allies = self.m_iSpawnPointCount_Allies + 1
				else
					Error( "Invalid allies spawnpoint at (%.1f, %.1f, %.1f)", ent:GetPos().x, ent:GetPos().y, ent:GetPos().z ) -- Fix; this was .z, .z before. Why not display y?
				end
			end
			
			self.m_bLevelInitialized = true
		end
	end
	
	function GM:Precache()
	end
	
	/* create some proxy entities that we use for transmitting data */
	function GM:CreateStandardEntities()
		-- Fix; do we need this?
	end
	
	local dod_waverespawnfactor = CreateConVar( "dod_waverespawnfactor", "1.0", { FCVAR_REPLICATED, FCVAR_CHEAT }, "Factor for respawn wave timers" )
	
	function GM:GetWaveTime( iTeam )
		local flRespawnTime = 0.0
		
		if ( iTeam == TEAM_ALLIES ) then
			flRespawnTime = ( self.m_iNumAlliesRespawnWaves > 0 ) and self.m_AlliesRespawnQueue[self.m_iAlliesRespawnHead] or -1
		elseif ( iTeam == TEAM_AXIS ) then
			flRespawnTime = ( self.m_iNumAxisRespawnWaves > 0 ) and self.m_AxisRespawnQueue[self.m_iAxisRespawnHead] or -1
		else
			assert( false, "Why are you trying to get the wave time for a non-team?" )
		end
		
		return flRespawnTime
	end
	
	function GM:GetMaxWaveTime( nTeam )
		local fTime = 0
		
		// Quick waves to get everyone in if we are PREROUND
		if ( self:State_Get() == STATE_PREROUND ) then
			return 1.0
		end
		
		local nNumPlayers = game.GetGlobalTeam( nTeam ):GetNumPlayers() -- Fix!!! Make GetGlobalTeam() a game library function
		
		if ( nNumPlayers < 3 ) then
			fTime = 6. -- Fix; does this work in Lua?
		elseif ( nNumPlayers < 6 ) then
			fTime = 8.
		elseif ( nNumPlayers < 8 ) then
			fTime = 10.
		elseif ( nNumPlayers < 10 ) then
			fTime = 11.
		elseif ( nNumPlayers < 12 ) then
			fTime = 12.
		elseif ( nNumPlayers < 14 ) then
			fTime = 13.
		else
			fTime = 14.
		end
		
		-- Fix; convert above to a sequence?
		
		//adjust wave time based on mapper settings
		//they can adjust the factor ( default 1.0 ) 
		// to give longer or shorter wait times for 
		// either team
		if ( nTeam == TEAM_ALLIES ) then
			fTime = fTime * self.m_fAlliesRespawnFactor -- FIX! What the fuck is m_GamePlayRules and why is that a member table of GM?
		elseif ( nTeam == TEAM_AXIS ) then
			fTime = fTime * self.m_fAxisRespawnFactor
		end
		
		// Finally, adjust the respawn time based on how well the team is doing
		// a team with more flags should respawn faster.
		// Give a bonus to respawn time for each flag that we own that we 
		// don't own by default.
		
		local pMaster = ents.FindByClass( "dod_control_point_master" )[1]
		
		if ( IsValid( pMaster ) ) then
			local advantageFlags = pMaster:CountAdvantageFlags( nTeam )
			
			// this can be negative if we are losing, this will add time!
			
			fTime = fTime - advantageFlags * dod_flagrespawnbonus:GetFloat()
		end
		
		fTime = fTime * dod_waverespawnfactor:GetFloat()
		
		// Minimum 5 seconds
		if ( fTime <= DEATH_CAM_TIME ) then
			fTime = DEATH_CAM_TIME
		// Maximum 20 seconds
		elseif ( fTime > MAX_WAVE_RESPAWN_TIME ) then
			fTime = MAX_WAVE_RESPAWN_TIME
		end
		
		return fTime
	end
	
	function GM:CreateOrJoinRespawnWave( pPlayer )
		local team = pPlayer:Team()
		local flWaveTime = self:GetWaveTime( team ) - CurTime()
		
		if ( flWaveTime <= 0 ) then
			// start a new wave
			
			DevMsgN( "Wave: Starting a new wave for team %d, time %.1f", team, self:GetMaxWave( team ) )
			
			//start a new wave with this player
			self:AddWaveTime( team, self:GetMaxWaveTime( team ) )
		else
			// see if this player needs to start a new wave
			
			local team = pPlayer:Team()
			local flSpawnEligibleTime = CurTime() + DEATH_CAM_TIME
			
			if ( team == TEAM_ALLIES ) then
				local bFoundWave = false
				
				local i = self.m_iAlliesRespawnHead
				
				while ( i ~= self.m_iAlliesRespawnTail ) do
					// if the player can fit in this wave, set bFound = true
					if ( flSpawnEligibleTime < self.m_AlliesRespawnQueue[i] ) then
						bFoundWave = true
						break
					end
					
					i = ( i+1 ) % DOD_RESPAWN_QUEUE_SIZE
				end
				
				if ( not bFoundWave ) then
					// add a new wave to the end
					self:AddWaveTime( team, self:GetMaxWaveTime( team ) )
				end
			elseif ( team == TEAM_AXIS ) then
				local bFoundWave = false
				
				local i = self.m_iAxisRespawnHead
				
				while ( i ~= self.m_iAxisRespawnTail ) do
					// if the player can fit in this wave, set bFound = true
					if ( flSpawnEligibleTime < self.m_AxisRespawnQueue[i] ) then -- Fix; make sure i doesn't need i + 1
						bFoundWave = true
						break
					end
					
					i = ( i+1 ) % DOD_RESPAWN_QUEUE_SIZE
				end
				
				if ( not bFoundWave ) then
					// add a new wave to the end
					self:AddWaveTime( team, self:GetMaxWaveTime( team ) )
				end
			else
				assert( 0 )
			end
		end
	end
	
	function GM:InRoundRestart()
		if ( self:State_Get() == STATE_PREROUND ) then
			return true
		end
		
		return false
	end
	
	function GM:DoPlayerDeath( pVictim, pKiller, info )--pVictim, pInflictor, pKiller )
		local bPlayed = pVictim:HintMessage( HINT_PLAYER_KILLED_WAVETIME ) -- So HintMessage is called a lot serverside. Let's network it clientside in a new file. Fix
		
		// If we already played the killed hint, play the deathcam hint
		if ( not bPlayed ) then
			pVictim:HintMessage( HINT_DEATHCAM )
		end
		
		local pInflictor = info:GetInflictor()
		local pScorer = self:GetDeathScorer( pKiller, pInflictor )
		
		if ( IsValid( pScorer ) and pScorer:IsPlayer() and pScorer ~= pVictim ) then
			if ( pVictim:Team() == pScorer:Team() ) then
				pScorer:HintMessage( HINT_FRIEND_KILLED, true ) 	//force this -- so that we can be sure that dirty team killer knows how much of a terrible person he is
			else
				pScorer:HintMessage( HINT_ENEMY_KILLED )
			end
		end
		
		self:DeathNotice( pVictim, info )
		
		// dvsents2: uncomment when removing all FireTargets
		// variant_t value;
		// g_EventQueue.AddEvent( "game_playerdie", "Use", value, 0, pVictim, pVictim );
		self:FireTargets( "game_playerdie", pVictim, pVictim, USE_TOGGLE, 0 ) -- Fix; gameevent
		
		local bScoring = not self:IsInWarmup()
		
		if ( bScoring ) then
			pVictim:IncrementDeathCount( 1 ) -- Fix; doesn't GMod have a frags system or some shit
		end
		
		// Did the player kill himself?
		if ( pVictim == pScorer ) then
			// Players lose a frag for killing themselves
			if ( bScoring ) then
				pVictim:IncrementFragCount( -1 )
			end
		elseif ( pScorer ) then -- Fix; figure our the returns from GetDeathScorer; what it returns for the world
			// if a player dies in a deathmatch game and the killer is a client, award the killer some points
			if( bScoring ) then
				pScorer:IncrementFragCount( self:DODPointsForKill( pVictim, info ) )
			end

			// Allow the scorer to immediately paint a decal
			pScorer:AllowImmediateDecalPainting()

			// dvsents2: uncomment when removing all FireTargets
			//variant_t value;
			//g_EventQueue.AddEvent( "game_playerkill", "Use", value, 0, pScorer, pScorer );
			self:FireTargets( "game_playerkill", pScorer, pScorer, USE_TOGGLE, 0 ) -- Fix GAMEEVENT UGH

			// see if this saved a capture
			if ( bit.band( pVictim:GetState(), SIGNAL_CAPTUREAREA ) ) then
				//find the area the player is in and see if his death causes a block
				local pAreas = ents.FindByClass( "dod_capture_area" )
				for _, pArea in pairs( pAreas ) do -- Fix, ipairs?
					if ( pArea:CheckIfDeathCausesBlock( pVictim, pScorer ) ) then -- Fix WE'RE NOT DOING JACK SHIT
						break
					end
				end
			end
			
			if ( pVictim.m_bIsDefusing and pVictim.m_pDefuseTarget and pScorer:Team() ~= pVictim:Team() )
				local pTarget = pVictim.m_pDefuseTarget

				pTarget:DefuseBlocked( pScorer )

				-- Gameevent
			end
		else
			// Players lose a frag for letting the world kill them
			if ( bScoring ) then
				pVictim:IncrementFragCount( -1 )
			end
		end
	end
	
	function GM:PlayWinSong( team )
		if ( team == TEAM_ALLIES ) then
			self:BroadcastSound( "Game.USWin" )
		elseif ( team == TEAM_AXIS ) then
			self:BroadcastSound( "Game.GermanWin" )
		else
			assert(0)
		end
	end
	
	function GM:BroadcastSound( sound )
		// send it to everyone
		-- Gameevent ugh
	end
	
	function GM:PlayStartRoundVoice()
		// One for the Allies..
		local iAlliesStartRoundVoice = self.m_iAlliesStartRoundVoice
		
		if ( iAlliesStartRoundVoice == STARTROUND_ATTACK ) then
			self:PlaySpawnSoundToTeam( "Voice.US_ObjectivesAttack", TEAM_ALLIES )
		elseif ( iAlliesStartRoundVoice == STARTROUND_DEFEND ) then
			self:PlaySpawnSoundToTeam( "Voice.US_ObjectivesDefend", TEAM_ALLIES )
		elseif ( iAlliesStartRoundVoice == STARTROUND_BEACH ) then
			self:PlaySpawnSoundToTeam( "Voice.US_Beach", TEAM_ALLIES )
		elseif ( iAlliesStartRoundVoice == STARTROUND_ATTACK_TIMED ) then
			self:PlaySpawnSoundToTeam( "Voice.US_ObjectivesAttackTimed", TEAM_ALLIES )
		elseif ( iAlliesStartRoundVoice == STARTROUND_DEFEND_TIMED ) then
			self:PlaySpawnSoundToTeam( "Voice.US_ObjectivesDefendTimed", TEAM_ALLIES )
		else
			self:PlaySpawnSoundToTeam( "Voice.US_Flags", TEAM_ALLIES )
		end
		
		local iAxisStartRoundVoice = self.m_iAxisStartRoundVoice
		
		if ( iAxisStartRoundVoice == STARTROUND_ATTACK ) then
			self:PlaySpawnSoundToTeam( "Voice.German_ObjectivesAttack", TEAM_AXIS )
		elseif ( iAxisStartRoundVoice == STARTROUND_DEFEND ) then
			self:PlaySpawnSoundToTeam( "Voice.German_ObjectivesDefend", TEAM_AXIS )
		elseif ( iAxisStartRoundVoice == STARTROUND_BEACH ) then
			self:PlaySpawnSoundToTeam( "Voice.German_Beach", TEAM_AXIS )
		elseif ( iAxisStartRoundVoice == STARTROUND_ATTACK_TIMED ) then
			self:PlaySpawnSoundToTeam( "Voice.German_ObjectivesAttackTimed", TEAM_AXIS )
		elseif ( iAxisStartRoundVoice == STARTROUND_DEFEND_TIMED ) then
			self:PlaySpawnSoundToTeam( "Voice.German_ObjectivesDefendTimed", TEAM_AXIS )
		else
			self:PlaySpawnSoundToTeam( "Voice.German_Flags", TEAM_AXIS )
		end
	end
	
	function GM:PlaySpawnSoundToTeam( sound, team )
		// find the first valid player and make them do it as a voice command
		-- Fix; let's network a really nice surface.PlaySound here
	end
	
	function GM:PlayerDisconnected( pPlayer )
		if ( IsValid( pPlayer ) ) then -- Fix; will this ever be valid
			pPlayer:DestroyRagdoll() -- Fix
		end
		
		// Tally the latest time for this player
		pPlayer:TallyLatestTimePlayedForClass( pPlayer:Team(), pPlayer:DesiredPlayerClass() )
		
		for j = 1, 7 do
			self.m_flSecondsPlayedPerClass_Allies[j] = self.m_flSecondsPlayedPerClass_Allies[j] + pPlayer.m_flTimePlayedPerClass_Allies[j]
			self.m_flSecondsPlayedPerClass_Axis[j] = self.m_flSecondsPlayedPerClass_Axis[j] + pPlayer.m_flTimePlayedPerClass_Axis[j]
		end
		
		self.BaseClass:PlayerDisconnected( pPlayer )
	end
	
	function GM:DeathNotice( pVictim, info )
		-- Fix
	end
	
	-- Fix; map entity shit
	
	//checks to see if the desired team is stacked, returns true if it is
	function GM:TeamStacked( iNewTeam, iCurTeam )
		//players are allowed to change to their own team
		if ( iNewTeam == iCurTeam ) then
			return false
		end
		
		local iTeamLimit = mp_limitteams:GetInt()
		
		// Tabulate the number of players on each team.
		local iNumAllies = game.GetGlobalTeam( TEAM_ALLIES ):GetNumPlayers()
		local iNumAxis = game.GetGlobalTeam( TEAM_AXIS ):GetNumPlayers()
		
		if ( iNewTeam == TEAM_ALLIES ) then
			if ( iCurTime ~= TEAM_UNASSIGNED and iCurTime ~= TEAM_SPECTATOR ) then
				if ( (iNumAllies + 1) > (iNumAxis + iTeamLimit - 1) ) then
					return true
				else
					return false
				end
			else
				if ( (iNumAllies + 1) > (iNumAxis + iTeamLimit) ) then
					return true
				else
					return false
				end
			end
		elseif ( iNewTeam == TEAM_AXIS ) then
			if ( iCurTeam ~= TEAM_UNASSIGNED and iCurTeam ~= TEAM_SPECTATOR ) then
				if ( (iNumAxis + 1) > (iNumAllies + iTeamLimit - 1) ) then
					return true
				else
					return false
				end
			else
				if ( (iNumAxis + 1) > (iNumAllies + iTeamLimit) ) then
					return true
				else
					return false
				end
			end
		end
		
		return false
		
	end
	
	// Falling damage stuff.
	DOD_PLAYER_FATAL_FALL_SPEED 	= 900	// approx 60 feet
	DOD_PLAYER_MAX_SAFE_FALL_SPEED 	= 500	// approx 20 feet
	DOD_DAMAGE_FOR_FALL_SPEED		= (100.0 / ( DOD_PLAYER_FATAL_FALL_SPEED - DOD_PLAYER_MAX_SAFE_FALL_SPEED )) // damage per unit per second.
	
	--[[
	PLAYER_FALL_PUNCH_THRESHHOLD 	= 350.0 // won't punch player's screen/make scrape noise unless player falling at least this fast.
	]]--
	
	function GM:GetFallDamage( pPlayer, flFallVelocity )
		flFallVelocity = flFallVelocity - DOD_PLAYER_MAX_SAFE_FALL_SPEED
		return flFallVelocity * DOD_DAMAGE_FOR_FALL_SPEED
	end
	
	function GM:GetGameDescription()
		return "Day of Defeat: Source"
	end
	
end

//-----------------------------------------------------------------------------
// Purpose: Init CS ammo definitions
//-----------------------------------------------------------------------------

// shared ammo definition
// JAY: Trying to make a more physical bullet response

function BULLET_MASS_GRAINS_TO_LB(grains)
	return (0.002285*(grains)/16.0)
end

function BULLET_MASS_GRAINS_TO_KG(grains)
	return util.lbs2kg(BULLET_MAXX_GRAINS_TO_LB(grains)) -- Fix
end

// exaggerate all of the forces, but use real numbers to keep them consistent
local BULLET_IMPULSE_EXAGGERATION = 1

// convert a velocity in ft/sec and a mass in grains to an impulse in kg in/s
function BULLET_IMPULSE(grains, ftpersec)
	return ((ftpersec)*12*BULLET_MASS_GRAINS_TO_KG(grains)*BULLET_IMPULSE_EXAGGERATION)
end

local def = {}
local bInitted = false

function GM:GetAmmoDef() -- Fix; remove function. Useless with the new shit added
	
	if ( not bInitted ) then
		bInitted = true

		//pistol ammo
		table.insert( def, ammo.AddAmmoType( DOD_AMMO_COLT,	DMG_BULLET, TRACER_NONE,	0, 0, 21,	5000, 10, 14 ) )
		table.insert( def, ammo.AddAmmoType( DOD_AMMO_P38,		DMG_BULLET, TRACER_NONE,	0, 0, 24,	5000, 10, 14 ) )
		table.insert( def, ammo.AddAmmoType( DOD_AMMO_C96,		DMG_BULLET, TRACER_NONE,	0, 0, 60,	5000, 10, 14 ) )
		
		//rifles
		table.insert( def, ammo.AddAmmoType( DOD_AMMO_GARAND,		DMG_BULLET, TRACER_NONE,	0, 0, 88,		9000, 10, 14 ) )
		table.insert( def, ammo.AddAmmoType( DOD_AMMO_K98,			DMG_BULLET, TRACER_NONE,	0, 0, 65,		9000, 10, 14 ) )
		table.insert( def, ammo.AddAmmoType( DOD_AMMO_M1CARBINE,	DMG_BULLET, TRACER_NONE,	0, 0, 165,		9000, 10, 14 ) )
		table.insert( def, ammo.AddAmmoType( DOD_AMMO_SPRING,		DMG_BULLET, TRACER_NONE,	0, 0, 55,		9000, 10, 14 ) )

		//submg
		table.insert( def, ammo.AddAmmoType( DOD_AMMO_SUBMG,		DMG_BULLET, TRACER_NONE,			0, 0, 210,		7000, 10, 14 ) )
		table.insert( def, ammo.AddAmmoType( DOD_AMMO_BAR,			DMG_BULLET, TRACER_LINE_AND_WHIZ,	0, 0, 260,		9000, 10, 14 ) )

		//mg
		table.insert( def, ammo.AddAmmoType( DOD_AMMO_30CAL,		DMG_BULLET | DMG_MACHINEGUN, TRACER_LINE_AND_WHIZ,	0, 0, 300,		9000, 10, 14 ) )	-- Fix; convert all this shit to game.AddAmmoType
		table.insert( def, ammo.AddAmmoType( DOD_AMMO_MG42,			DMG_BULLET | DMG_MACHINEGUN, TRACER_LINE_AND_WHIZ,	0, 0, 500,		9000, 10, 14 ) )

		//rockets
		table.insert( def, ammo.AddAmmoType( DOD_AMMO_ROCKET,		DMG_BLAST,	TRACER_NONE,			0, 0, 5,	9000, 10, 14 ) )

		//grenades
		table.insert( def, ammo.AddAmmoType( DOD_AMMO_HANDGRENADE,		DMG_BLAST,	TRACER_NONE,		0, 0, 2, 1, 4, 8 ) )
		table.insert( def, ammo.AddAmmoType( DOD_AMMO_STICKGRENADE,		DMG_BLAST,	TRACER_NONE,		0, 0, 2, 1, 4, 8 ) )	
		table.insert( def, ammo.AddAmmoType( DOD_AMMO_HANDGRENADE_EX,	DMG_BLAST,	TRACER_NONE,		0, 0, 1, 1, 4, 8 ) )
		table.insert( def, ammo.AddAmmoType( DOD_AMMO_STICKGRENADE_EX,	DMG_BLAST,	TRACER_NONE,		0, 0, 1, 1, 4, 8 ) )

		// smoke grenades
		table.insert( def, ammo.AddAmmoType( DOD_AMMO_SMOKEGRENADE_US,		DMG_BLAST,	TRACER_NONE,	0, 0, 2, 1, 4, 8 ) )
		table.insert( def, ammo.AddAmmoType( DOD_AMMO_SMOKEGRENADE_GER,		DMG_BLAST,	TRACER_NONE,	0, 0, 2, 1, 4, 8 ) )
		table.insert( def, ammo.AddAmmoType( DOD_AMMO_SMOKEGRENADE_US_LIVE,	DMG_BLAST,	TRACER_NONE,	0, 0, 2, 1, 4, 8 ) )
		table.insert( def, ammo.AddAmmoType( DOD_AMMO_SMOKEGRENADE_GER_LIVE,DMG_BLAST,	TRACER_NONE,	0, 0, 2, 1, 4, 8 ) )

		// rifle grenades
		table.insert( def, ammo.AddAmmoType( DOD_AMMO_RIFLEGRENADE_US,		DMG_BLAST,	TRACER_NONE,	0, 0, 2, 1, 4, 8 ) )
		table.insert( def, ammo.AddAmmoType( DOD_AMMO_RIFLEGRENADE_GER,		DMG_BLAST,	TRACER_NONE,	0, 0, 2, 1, 4, 8 ) )
		table.insert( def, ammo.AddAmmoType( DOD_AMMO_RIFLEGRENADE_US_LIVE,	DMG_BLAST,	TRACER_NONE,	0, 0, 2, 1, 4, 8 ) )
		table.insert( def, ammo.AddAmmoType( DOD_AMMO_RIFLEGRENADE_GER_LIVE,DMG_BLAST,	TRACER_NONE,	0, 0, 2, 1, 4, 8 ) )
	end

	return def
end

game.AddAmmoType( { 
	name = DOD_AMMO_SUBMG,		
	dmgtype = DMG_BULLET, 
	tracer = TRACER_NONE,
	plydmg = 0, 
	npcdmg = 0, 
	-- carry_cvar = 210,
	physicsForceImpulse = 7000,
	-- nFlags = 10
	--minsplash = 14, 
	-- maxsplash = fix? 
	} )

if ( SERVER ) then
	function GM:AddWaveTime( team, flTime )
		if ( team == TEAM_ALLIES ) then
			assert( self.m_numAlliesRespawnWaves < DOD_RESPAWN_QUEUE_SIZE, "Trying to add too many allies respawn waves" ) -- Fix
			
			self.m_AlliesRespawnQueue.Set( self.m_iAlliesRespawnTail + 1, CurTime() + flTime )
			self.m_iNumAlliesRespawnWaves = self.m_iNumAlliesRespawnWaves + 1
			
			self.m_iAlliesRespawnTail = ( self.m_iAlliesRespawnTail + 1 ) % DOD_RESPAWN_QUEUE_SIZE
			
			DevMsgN( 1, "AddWaveTime ALLIES head %d tail %d numtotal %d time %.1f",
				self.m_iAlliesRespawnHead,
				self.m_iAlliesRespawnTail,
				self.m_iNumAlliesRespawnWaves,
				CurTime() + flTime )
		elseif ( team == TEAM_AXIS ) then
			assert( self.m_numAxisRespawnWaves < DOD_RESPAWN_QUEUE_SIZE, "Trying to add too many allies respawn waves" ) -- Fix
			
			list.Set( self.m_AxisRespawnQueue, self.m_iAxisRespawnTail + 1, CurTime() + flTime ) -- Fix; this was just a guess on functionality
			self.m_iNumAxisRespawnWaves = self.m_iNumAxisRespawnWaves + 1
			
			self.m_iAxisRespawnTail = ( self.m_iAxisRespawnTail + 1 ) % DOD_RESPAWN_QUEUE_SIZE
			
			DevMsgN( 1, "AddWaveTime AXIS head %d tail %d numtotal %d time %.1f",
				self.m_iAxisRespawnHead,
				self.m_iAxisRespawnTail,
				self.m_iNumAxisRespawnWaves,
				CurTime() + flTime )
		else
			assert(0)
		end
	end
	
	function GM:PopWaveTime( team )
		if ( team == TEAM_ALLIES ) then
			assert( self.m_numAlliesRespawnWaves > 0 )
			
			self.m_iAlliesRespawnHead = ( self.m_iAlliesRespawnHead + 1 ) % DOD_RESPAWN_QUEUE_SIZE
			self.m_iNumAlliesRespawnWaves = self.m_iNumAlliesRespawnWaves - 1
			
			DevMsgN( 1, "PopWaveTime ALLIES head %d tail %d numtotal %d time %.1f",
				self.m_iAlliesRespawnHead,
				self.m_iAlliesRespawnTail,
				self.m_iNumAlliesRespawnWaves,
				CurTime() )
		elseif ( team == TEAM_AXIS ) then
			assert( self.m_numAxisRespawnWaves > 0 )
			
			self.m_iAxisRespawnHead = ( self.m_iAxisRespawnHead + 1 ) % DOD_RESPAWN_QUEUE_SIZE
			self.m_iNumAxisRespawnWaves = self.m_iNumAxisRespawnWaves - 1
			
			DevMsgN( 1, "PopWaveTime AXIS head %d tail %d numtotal %d time %.1f",
				self.m_iAxisRespawnHead,
				self.m_iAxisRespawnTail,
				self.m_iNumAxisRespawnWaves,
				CurTime() )
		else
			assert(0)
		end
	end
end

if ( SERVER ) then -- Fix; why does the stupid gamerules file do this again?

	function GM::GetChatPrefix( bTeamOnly, pPlayer ) -- Fix
		local pszPrefix = ""
		
		if ( IsValid( pPlayer ) ) then 	// dedicated server output
			if ( pPlayer:Team() == TEAM_SPECTATOR )
				return ""
			end
			
			// don't show dead prefix if in the bonus round or at round end
			// because we can chat at these times.
			local bShowDeadPrefix = ( not pPlayer:Alive() ) and ( not self:IsInBonusRound() ) and
				( self:State_Get() ~= STATE_GAME_OVER )
			
			if ( bTeamOnly )
				if ( bShowDeadPrefix ) then
					pszPrefix =	"(Dead)(Team)";	//#chatprefix_deadteam";
				else
					//MATTTODO: localize chat prefixes
					pszPrefix = "(Team)";	//"#chatprefix_team"; 
				end
			// everyone
			else
				if ( bShowDeadPrefix ) then
					pszPrefix = "(Dead)"	//"#chatprefix_dead";
				end
			end
		end
		
		return pszPrefix
	end
	
	function GM:ClientSettingsChanged( pPlayer, pszConVar, iNew ) -- Fix; so we're going to have to use cvars.GetConVarChanged and network it
		if ( pszConVar == "cl_autoreload" ) then
			pPlayer:SetAutoReload( iNew )
		elseif ( pszConVar == "cl_showhelp" ) then
			pPlayer:SetShowHints( iNew )
		elseif ( pszConVar == "cl_autorezoom" ) then
			pPlayer:SetAutoRezoom( iNew )
		end
		
		self.BaseClass:ClientSettingsChanged( pPlayer )
	end
	
	function GM:DODPointsForKill( pVictim, info ) -- Fix; find a way to feed the DamageInfo
		if ( self:IsInWarmup() )
			return 0
		end
		
		local pInflictor = info:GetInflictor()
		local pKiller = info:GetAttacker()
		local pScorer = self:GetDeathScorer( pKilled, pInflictor )
		
		// Don't give -1 points for killing a teammate with the bomb.
		// It was their fault for standing too close really.
		if ( pVictim:Team() == pScorer:Team() and bit.band( info:GetDamageType(), DMG_BOMB ) ) then
			return 0
		end
		
		return self.BaseClass:IPointsForKill( pScorer, pVictim )
	end
end

//-----------------------------------------------------------------------------
// Purpose: Returns the weapon in the player's inventory that would be better than
//			the given weapon.
// Note, this version allows us to switch to a weapon that has no ammo as a last
// resort.
//-----------------------------------------------------------------------------
function GM:GetNextBestWeapon( pPlayer, pCurrentWeapon )
	local pBest	// this will be used in the event we don't find a weapon in the same category
	
	local iCurrentWeight = -1
	local iBestWeight = -1	// no weapon lower than -1 can be autoswitched to
	
	local bCurrentValid = IsValid( pCurrentWeapon )
	
	// If I have a weapon, make sure I'm allowed to holster it
	if ( bCurrentValid ) then
		if ( not pCurrentWeapon:AllowsAutoSwitchFrom() or pCurrentWeapon:CanHolster() ) then
			// Either this weapon doesn't allow autoswitching away from it or I
			// can't put this weapon away right now, so I can't switch
			return NULL
		end
		
		iCurrentWeight = pCurrentWeapon:GetWeight()
	end
	
	for _, pCheck in pairs( pPlayer:GetWeapons() ) do -- Fix; ipairs?
		if ( not IsValid( pCheck ) ) then
			continue
		end
		
		// If we have an active weapon and this weapon doesn't allow autoswitching away
		// from another weapon, skip it.
		if ( bCurrentValid and not pCheck:AllowsAutoSwitchTo() ) then
			continue
		end
		
		local iWeight = pCheck:GetWeight()
		
		// Empty weapons are lowest priority
		if ( not pCheck:HasAnyAmmo() ) then
			iWeight = 0
		end
		
		if ( iWeight > -1 and iWeight == iCurrentWeight and pCheck ~= pCurrentWeapon ) then
			// this weapon is from the same category
			if ( pPlayer:Weapon_CanSwitchTo( pCheck ) ) then -- Fix; awful function name
				return pCheck
			end
		elseif ( iWeight > iBestWeight and pCheck ~= pCurrentWeapon ) then	// don't reselect the weapon we're trying to get rid of
			//Msg( "Considering %s\n", STRING( pCheck->GetClassname() );
			// we keep updating the 'best' weapon just in case we can't find a weapon of the same weight
			// that the player was using. This will end up leaving the player with his heaviest-weighted 
			// weapon. 

			// if this weapon is useable, flag it as the best
			iBestWeight = pCheck:GetWeight()
			pBest = pCheck
		end
	end
	
	// if we make it here, we've checked all the weapons and found no useable 
	// weapon in the same catagory as the current weapon. 

	// if pBest is null, we didn't find ANYTHING. Shouldn't be possible- should always 
	// at least get the crowbar, but ya never know.
	return pBest

	local szHitgroupNames =
	{
		"generic",
		"head",
		"chest",
		"stomach",
		"arm_left",
		"arm_right",
		"leg_left",
		"leg_right"
	}

	function GM:WriteStatsFile( pszLogName )
		-- Fix
	end

	//==========================================================
	// Called on physics entities that the player +uses ( if sv_turbophysics is on )
	// Here we want to exclude grenades
	//==========================================================
	function GM:CanEntityBeUsePushed( pEnt )
		if ( not IsValid( pEnt ) or pEnt.Type = "grenade" ) then -- Let's not touch invalid entities -- Fix
			return false
		end
		
		return true
	end
end

if ( CLIENT ) then	
	function GM:SetRoundState( iRoundState )
		self.m_iRoundState = iRoundState -- Fix; does this network?
		
		self.m_flLastRoundStateChangeTime = CurTime()
	end
end

function GM:IsBombingTeam( team )
	if ( team == TEAM_ALLIES ) then
		return self.m_bAlliesAreBombing
	elseif ( team == TEAM_AXIS ) then
		return self.m_bAxisAreBombing
	end
	
	return false
end

-- Fix; CFuncTeamWall

concommand.Add( "drop", function( pPlayer ) -- Detour drop to allow us to check if it can be -- Fix; put this somewhere better
	if IsValid( pPlayer ) then
		local pWeapon = pPlayer:GetActiveWeapon()
		if SERVER and IsValid( pWeapon ) and isfunction( pWeapon.CanDrop ) and pWeapon:CanDrop() then -- Fix; fucking idiot checking
			pPlayer:DropWeapon( pWeapon )
		end
	end
end )