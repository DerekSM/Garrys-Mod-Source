ENT.Type = "point"
ENT.Base = "basetrigger" -- Fix

function ENT:Initialize()
	self.BaseClass:Initialize()
	
	self:InitTrigger()
	
	self:Precache()
	
	self.m_iAreaIndex = -1
	
	-- self:SetTouch( self:AreaTouch )
	
	self.m_bCapturing = false
	self.m_nCapturingTeam = TEAM_UNASSIGNED
	self.m_nOwningTeam = TEAM_UNASSIGNED
	self.m_flTimeRemaining = 0.0
	
	self:SetNextThink( CurTime() + AREA_THINK_TIME )
	
	if ( self.m_nAlliesNumCap < 1 ) then -- Fix; where do we initialize this?
		self.m_nAlliesNumCap = 1
	end
	
	if ( self.m_nAxisNumCap < 1 ) then
		self.m_nAxisNumCap = 1
	end
	
	self.m_bDisabled = false
	
	self.m_iCapAttemptNumber = 0
end

function ENT:Precache()
end

//sends to all players at the start of the round
//needed?
function ENT:area_SetIndex( index )
	self.m_iAreaIndex = index
end

function ENT:IsActive()
	return not self.m_bDisabled
end

function ENT:Touch( pOther )
{
	//if they are touching, set their SIGNAL flag on, and their m_iCapAreaNum to ours
	//then in think do all the scoring

	if ( not self:IsActive() )
		return
	end

	//Don't cap areas unless the round is running
	if ( GAMEMODE:State_Get() ~= STATE_RND_RUNNING or GAMEMODE:IsInWarmup() ) then
		return
	end
	
	if ( self.m_iAreaIndex == -1 ) then
		return
	end

	if ( self.m_pPoint ) then
		self.m_nOwningTeam = self.m_pPoint:GetOwner() -- Fix; what is this? Do we need to check validity
	end
	
	//dont touch for non-alive or non-players
	if ( not ( IsValid( pOther ) or pOther:IsPlayer() or pOther:Alive() ) ) then
		return
	end

	if ( pOther:Team() ~= self.m_nOwningTeam ) then
		local bAbleToCap = ( pOther:Team() == TEAM_ALLIES and self.m_bAlliesCanCap ) or
							( pOther:Team() == TEAM_AXIS and self.m_bAxisCanCap )

		if ( bAbleToCap ) then
            pOther:HintMessage( HINT_IN_AREA_CAP ) -- Yeah; let's just run a clientside function serverside. Thanks Valve! Fix
		end
	end

	pOther:m_signals.Signal( SIGNAL_CAPTUREAREA ) -- Fix

	//add them to this area
	pOther:SetCapAreaIndex( self.m_iAreaIndex )

	if ( self.m_pPoint ) then
		pOther:SetCPIndex( self.m_pPoint:GetPointIndex() )
	end
end

/* three ways to be capturing a cap area
 * 1) have the required number of people in the area
 * 2) have less than the required number on your team, new required num is everyone
 * 3) have less than the required number alive, new required is numAlive, but time is lengthened
 */

local dod_simulatemultiplecappers =  CreateConVar( "dod_simulatemultiplecappers", "1", FCVAR_CHEAT )

function ENT:Think()
	self:SetNextThink( CurTime() + AREA_THINK_TIME ) -- Fix; do we need to this every time?
	
	if ( GAMEMODE:State_Get() ~= STATE_RND_RUNNING ) then
		// If we were being capped, cancel it
		if ( self.m_nNumAllies > 0 or self.m_nNumAxis > 0 ) then
			self.m_nNumAllies = 0
			self.m_nNumAxis = 0
			self:SendNumPlayers()
			
			if ( self.m_pPoint ) then
				-- g_pObjectiveResource->SetCappingTeam( m_pPoint->GetPointIndex(), TEAM_UNASSIGNED ); -- Fix; what the fuck is this fucking shit
			end
		end
		return
	end
	
	// go through our list of players
	
	local iNumAllies = 0
	local iNumAxis = 0
	
	local pFirstAlliedTouching
	local pFirstAxisTouching
	
	for i = 1, #player.GetAll() do -- This is really dumb. I don't care if it's default code, it's shit. Fix
		local pPlayer = ents.GetByIndex( i )
		if ( IsValid( ent ) ) then
			//First check if the player is in fact in this area
			if ( bit.band( pPlayer:m_signals.GetState(), SIGNAL_CAPTUREAREA ) and -- Fix
				pPlayer:GetCapAreaIndex() == self.m_iAreaIndex and
				pPlayer:IsAlive() ) then	// alive check is kinda unnecessary, but there is some
											// case where non-present people are messing up this count
				if ( pPlayer:Team() == TEAM_ALLIES ) then
					if ( iNumAllies == 0 ) then
						pFirstAlliedTouching = pPlayer
					end
					
					iNumAllies = iNumAllies + 1
				elseif ( pPlayer:Team() == TEAM_AXIS ) then
					if ( iNumAxis == 0 ) then
						pFirstAxisTouching = pPlayer
					end
					
					iNumAxis = iNumAxis + 1
				end
			end
		end
	end
	
	iNumAllies = iNumAllies * dod_simulatemultiplecappters:GetInt()
	iNumAxis = iNumAxis * dod_simulatemultiplecappers:GetInt()
	
	if ( iNumAllies ~= self.m_nNumAllies or iNumAxis ~= self.m_nNumAxis ) then
		self.m_nNumAllies = iNumAllies
		self.m_nNumAxis = iNumAxis
		self:SendNumPlayers()
	end -- This is dumb too. Fix
	
	// when a player blocks, tell them the cap index and attempt number
	// only give successive blocks to them if the attempt number is different
	
	if ( self.m_bCapturing ) then
		//its a regular cap
		//Subtract some time from the cap
		self.m_fTimeRemaining = self.m_fTimeRemaining - AREA_THINK_TIME
		
		//if both teams are in the area
		if ( iNumAllies > 0 and iNumAxis > 0 ) then
			// See if anyone gets credit for the block
			local flPercentToGo = self.m_fTimeRemaining / self.m_flCapTime
			if ( flPercentToGo <= 0.5 and self.m_pPoint ) then
				// find the first player that is not on the capturing team
				// they have just broken a cap and should be rewarded		
				// tell the player the capture attempt number, for checking later
				local pBlockingPlayer = ( self.m_nCapturingTeam == TEAM_ALLIES ) and pFirstAxisTouching or pFirstAlliedTouching
				
				if ( IsValid( pBlockingPlayer ) ) then -- Validity check needed?
					if ( pBlockingPlayer:GetCapAreaIndex() == self.m_iAreaIndex and
						pBlockingPlayer:GetLastBlockCapAttempt() == self.m_iCapAttemptNumber ) then
						// this is a repeat block on the same cap, ignore it
						-- Fix
					else
						self.m_pPoint:CaptureBlocked( pBlockingPlayer )
						pBlockingPlayer:StoreCaptureBlock( self.m_iAreaIndex, m_iCapAttemptNumber )
					end
				end
			end
			
			self:BreakCapture( false )
			return
		end
		
		//if no-one is in the area
		if ( iNumAllies == 0 and iNumAxis == 0 ) then
			self:BreakCapture( true )
			return
		end
		
		if ( self.m_nCapturingTeam == TEAM_ALLIES ) then
			if ( iNumAllies < self.m_nAlliesNumCap ) then
				self:BreakCapture( true )
			end
		elseif ( self.m_nCapturingTeam == TEAM_AXIS ) then
			if ( iNumAxis < self.m_nAxisNumCap ) then
				self:BreakCapture( true )
			end
		end
		
		//if the cap is done
		if ( self.m_fTimeRemaining <= 0 ) then -- Uh, how is time being tracked again? Fix?
			self:EndCapture( self.m_nCapturingTeam )
			return		//we're done
		end
	else	//not capturing yet
		local bStarted = false
		
		if ( iNumAllies > 0 and iNumAxis <= 0 and self.m_bAlliesCanCap and self.m_nOwningTeam ~= TEAM_ALLIES ) then
			if ( iNumAllies >= self.m_nAlliesNumCap ) then
				self.m_iCappingRequired = self.m_nAlliesNumCap
				self.m_iCappingPlayers = iNumAllies
				self:StartCapture( TEAM_ALLIES, CAPTURE_NORMAL )
				bStarted = true
			end
		elseif ( iNumAxis > 0 and iNumAllies <= 0 and self.m_bAxisCanCap and self.m_nOwningTeam ~= TEAM_AXIS ) then
			if ( iNumAxis >= self.m_nAxisNumCap ) then
				self.m_iCappingRequired = self.m_nAxisNumCap
				self.m_iCappingPlayers = iNumAxis
				self:StartCapture( TEAM_AXIS, CAPTURE_NORMAL )
				bStarted = true
			end
		end
	end
end

function ENT:SetOwner( team )
	//break any current capturing
	self:BreakCapture( false )
	
	//set the owner to the passed value
	self.m_nOwningTeam = team
	-- g_pObjectiveResource->SetOwningTeam( m_pPoint->GetPointIndex(), m_nOwningTeam ); -- Fix
end

function ENT:SendNumPlayers( pPlayer )
	if ( not self.m_pPoint ) then
		return
	end
	
	local index = self.m_pPoint:GetPointIndex()
	
	-- g_pObjectiveResource->SetNumPlayers( index, TEAM_ALLIES, m_nNumAllies ); -- Fix
	-- g_pObjectiveResource->SetNumPlayers( index, TEAM_AXIS, m_nNumAxis );
end

function ENT:StartCapture( team, capmode )
	MsgN( "Starting Cap ( %d )", self.m_iCapAttemptNumber ) -- Fix; let's rewrite MSG to not be shit
	
	local iNumCappers = 0
	
	//trigger start
	if ( team == TEAM_ALLIES ) then
		self.m_AlliesStartOutput:FireOutput( self, self ) -- Fix, what
		iNumCappers = self.m_nAlliesNumCap
	elseif ( team == TEAM_AXIS )
		self.m_AxisStartOutput:FireOutput( self, self )
		iNumCappers = self.m_nAxisNumCap
	end
	
	m_StartOutput:FireOutput( self, self ) -- I think this might be a hook call thing? idk, fix
	
	self.m_nCapturingTeam = team
	self.m_fTimeRemaining = self.m_flCapTime
	self.m_bCapturing = true
	self.m_iCapMode = capmode
	
	if ( self.m_pPoint ) then
		//send a message that we're starting to cap this area
		-- g_pObjectiveResource->SetCappingTeam( m_pPoint->GetPointIndex(), m_nCapturingTeam );
	end
end