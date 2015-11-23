DEFINE_BASECLASS( "weapon_dodbase" )

SWEP.Base = "weapon_dodbase"
-- SWEP.m_bFireOnEmpty = true

function SWEP:SetupDataTables()
	BaseClass.SetupDataTables( self )
	self:NetworkVar( "Bool", 0, "Zoomed" )
end

function SWEP:SharedDeploy()
	--self:SetZoomed( false ) -- Fix; crashes
	
	return BaseClass.SharedDeploy( self )
end

function SWEP:Precache()
	BaseClass.Precache( self )

	// Precache all weapon ejections, since every weapon will appear in the game.
	util.PrecacheModel( "models/shells/shell_small.mdl" )
	util.PrecacheModel( "models/shells/shell_medium.mdl" )
	util.PrecacheModel( "models/shells/shell_large.mdl" )
	util.PrecacheModel( "models/shells/garand_clip.mdl" )
end

function SWEP:PrimaryAttack()
	local pPlayer = self.Owner
	
	if not IsValid( pPlayer ) then return end
	
	local iClip1 = self:Clip1()
	
	// Out of ammo?
	if ( iClip1 <= 0 ) then
		if ( self.m_bFireOnEmpty ) then
			self:PlayEmptySound()
			self:SetNextPrimaryFire( CurTime() + 0.2 )
		end
		
		return false
	end
	
	if ( pPlayer:WaterLevel() > 2 ) then
		self:PlayEmptySound()
		self:SetNextPrimaryFire( CurTime() + 1.0 )
		return false
	end
	
	// decrement before calling PlayPrimaryAttackAnim, so we can play the empty anim if necessary
	self:SetClip1( iClip1 - 1 )
	
	self:SendWeaponAnim( self:GetPrimaryAttackActivity() )
	
	// player "shoot" animation
	pPlayer:SetAnimation( PLAYER_ATTACK1 ) -- Fix
	
	self:FireBullets( 
		pPlayer:EyePos(),
		pPlayer:EyeAngles() + pPlayer:GetPunchAngle(),
		bit.band( pPlayer:GetPredictionRandomSeed(), 255 ),
		self:GetWeaponAccuracy( pPlayer:GetAbsVelocity():Length2D() )
	)
	
	self:DoFireEffects()
	
	-- event shit
	
	self:SetNextPrimaryFire( CurTime() + self:GetFireDelay() )
	self:SetNextSecondaryFire( CurTime() + self:GetFireDelay() )
	self:SetWeaponIdleTime( CurTime() + self.IdleTimeAfterFire )
end

function SWEP:GetWeaponAccuracy( flPlayerSpeed )
	//snipers and deployable weapons inherit this and override when we need a different accuracy
	
	local flSpread = self.Accuracy
	
	if ( flPlayerSpeed > 45 ) then
		flSpread = flSpread + self.AccuracyMovePenalty
	end
	
	return flSpread
end

function SWEP:GetFireDelay()
	return self.FireDelay
end

function SWEP:DoFireEffects()
	local pPlayer = self.Owner
	
	if IsValid( pPlayer ) then
		pPlayer:MuzzleFlash()
	end
end

function SWEP:Reload()
	if ( self.m_bInReload ) then return false end
	
	local pPlayer = self.Owner
	local iClip1 = self:Clip1()
	
	if ( pPlayer:GetAmmoCount( self:GetPrimaryAmmoType() ) <= 0 and iClip1 <= 0 ) then
		pPlayer:HintMessage( HINT_AMMO_EXHAUSTED ) -- Fix; shared?
		return false
	end
	
	local iResult = self:_DefaultReload( self:GetMaxClip1(), self:GetMaxClip2(), self:GetReloadActivity() )
	if ( not iResult ) then
		return false
	end
	
	return true
end

function SWEP:IsSniperZoomed()
	return self:GetZoomed()
end

// This runs on both the client and the server.
// On the server, it only does the damage calculations.
// On the client, it does all the effects.

function SWEP:FireBullets( vOrigin, vAngles, iSeed, flSpread )
	local bDoEffects = true
	
	local pPlayer = self.Owner
	
	if ( not IsValid( pPlayer ) ) then
		return
	end
	
	if ( CLIENT and not pPlayer:IsDormant() ) then
		pPlayer:DoAnimationEvent( PLAYERANIMEVENT_ATTACK_PRIMARY )
	else
		pPlayer:DoAnimationEvent( PLAYERANIMEVENT_ATTACK_PRIMARY ) -- Fix, was PLAYERANIMEVENT_FIRE_GUN
		
		// if this is server code, send the effect over to client as temp entity
		// Dispatch one message for all the bullet impacts and sounds.
		bDoEffects = false // no effects on server

		// Let the player remember the usercmd he fired a weapon on. Assists in making decisions about lag compensation.
		pPlayer:NoteWeaponFired()
	end

	if ( bDoEffects ) then
		--FX_WeaponSound( iPlayerIndex, iMode, vOrigin, pWeaponInfo ) -- Fix
	end
	
	// Fire bullets, calculate impacts & effects

	if ( SERVER ) then
		// Move other players back to history positions based on local player's lag
		pPlayer:LagCompensation( true )
	end

	random.SetSeed( iSeed )

	local x, y
	repeat
		x = random.RandomFloat( -0.5, 0.5 ) + random.RandomFloat( -0.5, 0.5 )
		y = random.RandomFloat( -0.5, 0.5 ) + random.RandomFloat( -0.5, 0.5 )
	until ( (x * x + y * y) < 1.0 )

	local vecForward, vecRight, vecUp = AngleVectors( vAngles )

	local vecDirShooting = vecForward +
				x * flSpread * vecRight +
				y * flSpread * vecUp

	vecDirShooting:Normalize()

	local info = { 
		Num = 1, /*shots*/
		Src = vOrigin,
		Dir = vecDirShooting,
		Spread = Vector( flSpread, flSpread, 0/0 ), -- fix
		Distance = MAX_COORD_RANGE,
		AmmoType = pWeaponInfo.Primary.Ammo,
		Damage = pWeaponInfo.Damage,
		Attacker = pPlayer,
		-- m_nFlags = 0,
		-- m_pAdditionalIgnoreEnt = NULL,
		-- m_flDamageForceScale = 1.0,
		-- m_flLatency = 0.0
	}

	pPlayer:FireBullets( info )

	if ( CLIENT ) then		
		local tr = util.TraceLine( { 
			start = vOrigin, 
			endpos = vOrigin + vecDirShooting * 16384,
			mask = MASK_SOLID, 
		} )

		// if this is a local player, start at attachment on view model
		// else start on attachment on weapon model

		local iEntIndex = pPlayer:EntIndex()
		local iAttachment = 1

		local vecStart = tr.StartPos 
		local angAttachment

		local pLocalPlayer = LocalPlayer()

		// try to align tracers to actual weapon barrel if possible
		if ( pPlayer == pLocalPlayer ) then
			local pViewModel = pPlayer:GetViewModel()
			
			if ( IsValid( pViewModel ) ) then
				iEntIndex = pViewModel:EntIndex()
				local angpos = pViewModel:GetAttachment( iAttachment )
				vecStart = angpos.Pos
				angAttachment = angpos.Ang
			end
		elseif ( pLocalPlayer:GetObserverTarget() == pPlayer and pLocaPlayer:GetObserverMode() == OBS_MODE_IN_EYE ) then
			// get our oberver target's view model
			
			local pViewModel = pLocalPlayer:GetViewModel()
			
			if ( IsValid( pViewModel ) ) then
				iEntIndex = pViewModel:EntIndex()
				local angpos = pViewModel:GetAttachment( iAttachment )
				vecStart = angpos.Pos
				angAttachment = angpos.Ang
			end
		end
		
		local iTracerType = pWeaponInfo.Tracer

		if ( iTracerType == 1 ) then 	// Machine gun, heavy tracer
			util.Tracer( vecStart, tr.HitPos, iEntIndex, TRACER_DONT_USE_ATTACHMENT, 5000.0, true, "BrightTracer" )
		elseif ( iTracerType == 2 ) then	// rifle, smg, light tracer
			vecStart = vecStart + vecDirShooting * 150
			util.Tracer( vecStart, tr.HitPos, iEntIndex, TRACER_DONT_USE_ATTACHMENT, 5000.0, true, "FaintTracer" )
		elseif ( iTracerType == 0 ) then	// pistols etc, just do the sound
			--fx.TracerSound( vecStart, tr.HitPos, TRACER_TYPE_DEFAULT ) -- Fix
		end
	else
		pPlayer:LagCompensation( false )
	end
end
	