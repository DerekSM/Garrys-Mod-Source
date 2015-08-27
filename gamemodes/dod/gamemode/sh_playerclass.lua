local DODPlayerClassInfo = {}

function DODPlayerClassInfo:Init()
	self:SetTeam( TEAM_UNASSIGNED )
	--self:
end

-- Ally Support --

DODPlayerClassInfo = {}

DODPlayerClassInfo.DisplayName = "#class_allied_heavy"
--[[
DODPlayerClassInfo.WalkSpeed			= 400		-- How fast to move when not running
DODPlayerClassInfo.RunSpeed				= 600		-- How fast to move when running
DODPlayerClassInfo.MaxSpeed				= 600 --Custom!!
DODPlayerClassInfo.CrouchedWalkSpeed	= 0.3		-- Multiply move speed by this when crouching
DODPlayerClassInfo.DuckSpeed			= 0.3		-- How fast to go from not ducking, to ducking
DODPlayerClassInfo.UnDuckSpeed			= 0.3		-- How fast to go from ducking, to not ducking
DODPlayerClassInfo.JumpPower			= 200		-- How powerful our jump should be
DODPlayerClassInfo.CanUseFlashlight		= true		-- Can we use the flashlight
DODPlayerClassInfo.MaxHealth			= 100		-- Max health we can have
DODPlayerClassInfo.StartHealth			= 100		-- How much health we start with
DODPlayerClassInfo.StartArmor			= 0			-- How much armour we start with
DODPlayerClassInfo.DropWeaponOnDie		= false		-- Do we drop our weapon when we die
DODPlayerClassInfo.TeammateNoCollide	= true		-- Do we collide with teammates or run straight through them
DODPlayerClassInfo.AvoidPlayers			= true		-- Automatically swerves around other players
DODPlayerClassInfo.UseVMHands			= true		-- Uses viewmodel hands
]]

if ( CLIENT ) then

	DODPlayerClassInfo.ClassHealthImage = "cls_us_bar_active"
	DODPlayerClassInfo.ClassHealthImageBG = "cls_us_bar_active_bg"

else

	DODPlayerClassInfo.DropHelmet = HELMET_ALLIES -- Fix; needed?
	
	function DODPlayerClassInfo:Spawn()
		self.Player:SetTeam( TEAM_ALLIES )
	end

	function DODPlayerClassInfo:SetModel()
		-- Fix; do we need to precache here?
		self.Player:SetModel( "models/player/american_support.mdl" )
		self.Player:SetHitboxSet( 0 )
		self.Player:SetBodygroup( BODYGROUP_HELMET, "0" )
		self.Player:SetBodygroup( BODYGROUP_JUMPGEAR, BODYGROUP_JUMPGEAR_OFF )
		self.Player:SetBodygroup( hair_num_yeah, "1" )
	end
	
	function DODPlayerClassInfo:Loadout()
		self.Player:Give( "weapon_bar" ) -- Primary
		self.Player:Give( "amerknife" ) -- Melee
		self.Player:Give( "frag_us" ) -- Grenade
		self.Player:GiveAmmo( 2, "grenade_ammo" )
		self.Player:SelectWeapon( self.Primary ) -- Fix fix fix
	end

end

player_manager.RegisterClass( "playerclass_us_bar", DODPlayerClassInfo, "playerclass_default" ) -- Fix; should we have a default class?

-- Axis Support --

DODPlayerClassInfo = {}

DODPlayerClassInfo.DisplayName = "#class_axis_mp44"
--[[
DODPlayerClassInfo.WalkSpeed			= 400		-- How fast to move when not running
DODPlayerClassInfo.RunSpeed				= 600		-- How fast to move when running
DODPlayerClassInfo.CrouchedWalkSpeed	= 0.3		-- Multiply move speed by this when crouching
DODPlayerClassInfo.DuckSpeed			= 0.3		-- How fast to go from not ducking, to ducking
DODPlayerClassInfo.UnDuckSpeed			= 0.3		-- How fast to go from ducking, to not ducking
DODPlayerClassInfo.JumpPower			= 200		-- How powerful our jump should be
DODPlayerClassInfo.CanUseFlashlight		= true		-- Can we use the flashlight
DODPlayerClassInfo.MaxHealth			= 100		-- Max health we can have
DODPlayerClassInfo.StartHealth			= 100		-- How much health we start with
DODPlayerClassInfo.StartArmor			= 0			-- How much armour we start with
DODPlayerClassInfo.DropWeaponOnDie		= false		-- Do we drop our weapon when we die
DODPlayerClassInfo.TeammateNoCollide	= true		-- Do we collide with teammates or run straight through them
DODPlayerClassInfo.AvoidPlayers			= true		-- Automatically swerves around other players
DODPlayerClassInfo.UseVMHands			= true		-- Uses viewmodel hands
]]

if ( CLIENT ) then

	DODPlayerClassInfo.ClassHealthImage = "cls_ger_mp44_active"
	DODPlayerClassInfo.ClassHealthImageBG = "cls_ger_mp44_active_bg"

else

	DODPlayerClassInfo.DropHelmet = HELMET_AXIS -- Fix; needed?
	
	function DODPlayerClassInfo:Spawn()
		self.Player:SetTeam( TEAM_AXIS )
	end

	function DODPlayerClassInfo:SetModel()
		-- Fix; do we need to precache here?
		self.Player:SetModel( "models/player/german_support.mdl" )
		self.Player:SetBodygroup( helmet_num_yeah, "0" )
		self.Player:SetBodygroup( hair_num_yeah, "1" )
	end
	
	function DODPlayerClassInfo:Loadout()
		self.Player:Give( "weapon_mp44" ) -- Primary
		self.Player:Give( "spade" ) -- Melee
		self.Player:Give( "frag_ger" ) -- Grenade
		self.Player:GiveAmmo( 2, "grenade_ammo" )
	end

end

player_manager.RegisterClass( "playerclass_axis_mp44", DODPlayerClassInfo, "playerclass_default" ) -- Fix; should we have a default class?