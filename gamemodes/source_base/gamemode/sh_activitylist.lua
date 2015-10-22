local _R = debug.getregistry()

local AnimDerive =
{
	[ "models/player/american_assault.mdl" ] = "dod",
}

local DerivedActivities =
{
	[ "dod" ] = 
	{
		[ "ACT_DOD_STAND_IDLE_TOMMY" ] = "StandIdle_TOMMY",
		[ "ACT_DOD_CROUCH_IDLE_TOMMY" ] = "CrouchIdle_TOMMY",
		[ "ACT_DOD_PRONEWALK_IDLE_TOMMY" ] = "ProneWalkIdle_TOMMY",
		[ "ACT_DOD_WALK_IDLE_TOMMY" ] = "w_WalkIdle_TOMMY",
		[ "ACT_DOD_CROUCHWALK_IDLE_TOMMY" ] = "c_CrouchWalkIdle_TOMMY",
		[ "ACT_DOD_RUN_IDLE_TOMMY" ] = "r_RunIdle_TOMMY",
		[ "ACT_DOD_SPRINT_IDLE_TOMMY" ] = "s_SprintIdle_TOMMY",
		[ "ACT_DOD_STAND_AIM_TOMMY" ] = "StandAim_TOMMY",
		[ "ACT_DOD_CROUCH_AIM_TOMMY" ] = "CrouchAim_TOMMY",
		[ "ACT_DOD_PRONE_AIM_TOMMY" ] = "ProneAim_TOMMY",
		[ "ACT_DOD_WALK_AIM_TOMMY" ] = "w_WalkAim_TOMMY",
		[ "ACT_DOD_CROUCHWALK_AIM_TOMMY" ] = "cw_CrouchWalkAim_TOMMY",
		[ "ACT_DOD_RUN_AIM_TOMMY" ] = "r_RunAim_TOMMY",
		[ "ACT_DOD_PRIMARYATTACK_TOMMY" ] = "Attack_TOMMY",
		[ "ACT_DOD_PRIMARYATTACK_PRONE_TOMMY" ] = "AttackProne_TOMMY",
		[ "ACT_DOD_RELOAD_TOMMY" ] = "Reload_TOMMY",
		[ "ACT_DOD_RELOAD_CROUCH_TOMMY" ] = "ReloadCrouch_TOMMY",
		[ "ACT_DOD_RELOAD_PRONE_TOMMY" ] = "ReloadProne_TOMMY",
		[ "ACT_DOD_SECONDARYATTACK_TOMMY" ] = "SecondaryAttack_TOMMY",
		[ "ACT_DOD_SECONDARYATTACK_CROUCH_TOMMY" ] = "SecondaryAttackCrouch_TOMMY",
		[ "ACT_DOD_SECONDARYATTACK_PRONE_TOMMY" ] = "SecondaryAttackProne_TOMMY"
	},
	[ "css" ] = {},
}

local _SetModel = _R.Entity.SetModel
_R.Entity.ActivityList =
{
	
}

if ( SERVER ) then
	util.AddNetworkString( "DOD - ActTable" )
end

function _R.Player:UpdateActivities( sModel )
	local game = AnimDerive[ sModel ]
	self.AnimSet = game or "hl2mp" -- NetworkVar
	
	if ( game --and AnimDerive[ self:GetModel() ] ~= game -- Fix
	and DerivedActivities[ game ] ) then
		for act, seq in pairs( DerivedActivities[ game ] ) do
			--timer.Simple( 0, function() print( self:GetSequenceActivity( self:LookupSequence( seq ) ) ) end )
			timer.Simple( 0, function() 
			self.ActivityList[ act ] = self:GetSequenceActivity( self:LookupSequence( seq ) ) 
			end )
		end
		
		local SWEP = self:GetActiveWeapon()
		if ( IsValid( SWEP ) ) then
			timer.Simple( 0, function() SWEP.ActTable = SWEP:GetActTable( self.AnimSet == "dod" and SWEP.AnimHoldType or SWEP.HoldType ) end)
		end
		
	end
end

net.Receive( "DOD - ActTable", function()
	LocalPlayer():UpdateActivities( net.ReadString() )
end )

function _R.Entity:SetModel( sModel )
	if ( self:IsPlayer() ) then
		if ( SERVER ) then
			self:UpdateActivities( sModel )
			net.Start( "DOD - ActTable" )
				net.WriteString( sModel )
			net.Send( self )
		end
	end
	
	_SetModel( self, sModel )
end

--[[
function _R.Entity:SetModel( sModel )
	if ( self:IsPlayer() ) then
		self.AnimSet = AnimDerive[ sModel ] or "hl2mp"
	end
	
	_SetModel( self, sModel )
end]]

function _R.Entity:TranslateActTable( ActTable ) -- Player or Entity?
	local TranslatedTable = {}
	
	for parent, child in pairs( ActTable ) do
		if ( isnumber( parent ) ) then
			TranslatedTable[ parent ] = ( isnumber( child ) and child or self.ActivityList[ child ] ) or -1
			continue
		elseif ( self.ActivityList[ parent ] ) then
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
