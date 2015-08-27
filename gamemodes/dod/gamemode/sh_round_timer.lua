local _R = debug.getregistry()

local timers = {}

TIMER_PAUSED = -1
TIMER_STOPPED = 0
TIMER_RUNNING = 1

_R.Timer = {}
_R.Timer.__index = _R.Timer

function Timer( delay, callback, ... )
	local timer = setmetatable( {
		m_fDelay = delay,
		m_iStatus = TIMER_PAUSED,
		m_funcCallback = callback,
		m_funcCallbackArgs = {...},
		m_funcSystem = CurTime,
	}, _R.Timer )
	table.insert( timers, timer )
	return timer
end

if ( SERVER ) then
	function _R.Timer:UpdateTransmitState()
		// ALWAYS transmit to all clients
		return self:SetTransmitState( FL_EDICT_ALWAYS )
	end
else
	local function TimerPaused() -- Fix; find a way to add this to the HUD
	end
end

function _R.Timer:SetupDataTables() -- Fix; make sure this gets run
	self:NetworkVar( "Bool", 0, "TimerPaused" )
	self:NetworkVar( "Float", 0, "TimeRemaining" )
	self:NetworkVar( "Float", 1, "TimerEndTime" )
end
--[[
function _R.Timer:SetTimeRemaining( iTimerSeconds ) -- Fix?
	self:SetTimeRemaining( iTimerSeconds )
	self:SetTimerEndTime( CurTime() + self:GetTimeRemaining )
	self.m_iTimerMaxLength = iTimerSeconds
end
]]
function _R.Timer:Pause()
	if ( not self:GetTimerPaused() ) then
		self:SetTimerPaused( true )
		self:SetTimeRemaining( self:GetTimerEndTime() - CurTime() )
	end
end

function _R.Timer:Resume()
	if ( self:GetTimerPaused() ) then
		self:SetTimerPaused( false )
		self:SetTimerEndTime( CurTime() + self:GetTimeRemaining() )
	end
end

function _R.Timer:AddSeconds( iSecondsToAdd )
	// do a hud animation indicating time has been added
	
	if ( self:GetTimerPaused() ) then
		self:SetTimeRemaining( self:GetTimeRemaining() + iSecondsToAdd ) -- Fix; stupidly inefficient
	else
		self:SetTimerEndTime( self:GetTimerEndTime() + iSecondsToAdd )
	end
	
	self.m_iTimerMaxLength = self.m_iTimerMaxLength + iSecondsToAdd
end

function _R.Timer:GetMaxLength() -- Fix; compare with TimeRemaining
	return self.m_iTimerMaxLength
end

function _R.Timer:Remove()
	table.remove( timers, timer )
end