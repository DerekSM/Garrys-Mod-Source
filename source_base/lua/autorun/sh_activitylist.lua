local _R = debug.getregistry()

local AnimDerive =
{
	[ "models/player/american_assault.mdl" ] = "dod",
}

local DerivedActivities =
{
	dod = -- Fix; automate
	{
		extensions =
		{
			"TOMMY",
			"C96",
		},
		sequences =
		{
			[ "ACT_DOD_STAND_IDLE" ] = "StandIdle",
			[ "ACT_DOD_CROUCH_IDLE" ] = "CrouchIdle",
			[ "ACT_DOD_PRONEWALK_IDLE" ] = "ProneWalkIdle",
			[ "ACT_DOD_WALK_IDLE" ] = "w_WalkIdle",
			[ "ACT_DOD_CROUCHWALK_IDLE" ] = "c_CrouchWalkIdle",
			[ "ACT_DOD_RUN_IDLE" ] = "r_RunIdle",
			[ "ACT_DOD_SPRINT_IDLE" ] = "s_SprintIdle",
			[ "ACT_DOD_STAND_AIM" ] = "StandAim",
			[ "ACT_DOD_CROUCH_AIM" ] = "CrouchAim",
			[ "ACT_DOD_PRONE_AIM" ] = "ProneAim",
			[ "ACT_DOD_WALK_AIM" ] = "w_WalkAim",
			[ "ACT_DOD_CROUCHWALK_AIM" ] = "cw_CrouchWalkAim",
			[ "ACT_DOD_RUN_AIM" ] = "r_RunAim",
			[ "ACT_DOD_PRIMARYATTACK" ] = "Attack",
			[ "ACT_DOD_PRIMARYATTACK_PRONE" ] = "AttackProne",
			[ "ACT_DOD_RELOAD" ] = "Reload",
			[ "ACT_DOD_RELOAD_CROUCH" ] = "ReloadCrouch",
			[ "ACT_DOD_RELOAD_PRONE" ] = "ReloadProne",
			[ "ACT_DOD_SECONDARYATTACK" ] = "SecondaryAttack",
			[ "ACT_DOD_SECONDARYATTACK_CROUCH" ] = "SecondaryAttackCrouch",
			[ "ACT_DOD_SECONDARYATTACK_PRONE" ] = "SecondaryAttackProne",
		}
	},
	css = {},
}

local _SetModel = _R.Entity.SetModel
_R.Player.ActivityList =
{
	
}

if ( SERVER ) then
	util.AddNetworkString( "DOD - ActTable" )
end

function _R.Player:UpdateActivities()
	local game = AnimDerive[ self:GetModel() ]
	self.AnimSet = game or "hl2mp" -- NetworkVar
	local newseq = -1
	
	for _, ext in ipairs( DerivedActivities[ game ].extensions ) do
		for act, seq in pairs( DerivedActivities[ game ].sequences ) do
			timer.Simple( 0, function()
				newseq = self:GetSequenceActivity( self:LookupSequence( seq .. "_" .. ext ) ) or -1
				
				if ( newseq > 0 ) then
					self.ActivityList[ act .. "_" .. ext ] = newseq
				end
			end )
		end
	end
	
	timer.Simple( 0, function()
		net.Start( "DOD - ActTable" )
			net.WriteTable( self.ActivityList )
		if ( SERVER ) then
			net.WriteEntity( self )
			net.Send( self ) -- Send to self or broadcast?
		else
			net.SendToServer()
		end
	end )
end
-- Fix; note to self, do pose parameters
net.Receive( "DOD - ActTable", function()
	local pPlayer = ( SERVER and net.ReadEntity() ) or ( CLIENT and LocalPlayer() )
	
	if ( IsValid( pPlayer ) ) then
		-- Hack to fix the LocalPlayer table resetting for no reason
		pPlayer.ActivityList = table.Merge( pPlayer.ActivityList, net.ReadTable() )
	end
end )


function _R.Player:SetActivityList( ActivityList )
	self.ActivityList = ActivityList
end

--[[
net.Receive( "DOD - ActTable", function()
	local pPlayer = ( SERVER and ents.FindByIndex( net.ReadInt( 32 ) ) ) or ( CLIENT and LocalPlayer() )
	
	if ( IsValid( pPlayer ) ) then
		pPlayer:UpdateActivities( pPlayer:GetModel() )
	end
end )]]

_R.Entity.OldModel = ""

function _R.Entity:SetModel( sModel )
	local sOldModel = self:GetModel()
	
	if ( sOldModel == sModel ) then
		return
	end
	
	_SetModel( self, sModel )
	
	if ( not self:IsPlayer() ) then
		return
	end
	
	local game = AnimDerive[ sModel ]
	
	if ( game and game ~= AnimDerive[ sOldModel ] and DerivedActivities[ game ] ) then
		self:UpdateActivities()
	end
	--[[
	net.Start( "Source Base - SetModel" )
	if ( SERVER ) then
		net.Send( self ) -- Send to self or broadcast?
	else
		net.WriteInt( self:EntIndex(), 32 )
		net.SendToServer()
	end]]
end

--[[
function _R.Entity:SetModel( sModel )
	if ( self:IsPlayer() ) then
		self.AnimSet = AnimDerive[ sModel ] or "hl2mp"
	end
	
	_SetModel( self, sModel )
end]]

function _R.Player:TranslateActTable( ActTable ) -- Player or Entity?
	local TranslatedTable = {}
	
	for parent, child in pairs( ActTable ) do
		if ( self.ActivityList[ parent ] ) then
			TranslatedTable[ self.ActivityList[ parent ] ] = ( isnumber( child ) and child or self.ActivityList[ child ] ) or -1
		end
	end
	
	return TranslatedTable
end
--[[
gameevent.Listen( "player_spawn" )
hook.Add( "player_spawn", "testtt", function( data )
	timer.Simple( 1, function() Player( data.userid ):SetModel( "models/player/american_assault.mdl" ) end )
end )]]

hook.Add( "PlayerSay", "Modeltest", function( ply )
	ply:SetModel( "models/player/american_assault.mdl" )
end )
