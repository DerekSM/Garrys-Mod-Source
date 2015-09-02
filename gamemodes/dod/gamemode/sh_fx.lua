fx = fx or {}

// This runs on both the client and the server.
// On the server, it only does the damage calculations.
// On the client, it does all the effects.
function fx.FireBullets( iPlayerIndex, vOrigin, vAngles, iWeaponIndex, iMode, iSeed, flSpread )
	local bDoEffects = true
	
	local pPlayer = ents.GetByIndex( iPlayerIndex )
	
	local pWeaponInfo = ents.GetByIndex( iWeaponIndex )
	
	if ( CLIENT ) then
		if ( not pPlayer:IsDormant() ) then
			pPlayer:DoAnimationEvent( PLAYERANIMEVENT_ATTACK_PRIMARY )
		end
	else
		pPlayer:DoAnimationEvent( PLAYERANIMEVENT_ATTACK_PRIMARY ) -- Fix, was PLAYERANIMEVENT_FIRE_GUN
	end
	
	if ( not CLIENT ) then
		// if this is server code, send the effect over to client as temp entity
		// Dispatch one message for all the bullet impacts and sounds.
		bDoEffects = false // no effects on server

		// Let the player remember the usercmd he fired a weapon on. Assists in making decisions about lag compensation.
		pPlayer:NoteWeaponFired()
	end

	local sound_type = SINGLE

	if ( bDoEffects ) then
		--FX_WeaponSound( iPlayerIndex, sound_type, vOrigin, pWeaponInfo ) -- Fix
	end
	
	// Fire bullets, calculate impacts & effects

	if ( not CLIENT ) then
		// Move other players back to history positions based on local player's lag
		pPlayer:LagCompensation( true )
	end

	random.SetSeed( iSeed );

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
		Spread = Vector( flSpread, flSpread, 0/0 ), -- fix; used to be NAN for the FLOAT32_NAN; is this okay?
		Distance = MAX_COORD_RANGE, -- Fix
		AmmoType = iMode and pWeaponInfo.Secondary.Ammo or pWeaponInfo.Primary.Ammo, -- Fix; should be m_iAmmoType, however, I haven't done the BaseCombatWeapon yet
		Damage = pWeaponInfo.Damage,
		Attacker = pPlayer,
		-- m_nFlags = 0,
		-- m_pAdditionalIgnoreEnt = NULL,
		-- m_flDamageForceScale = 1.0,
		-- m_flLatency = 0.0
	}

	pPlayer:FireBullets( info )

	if CLIENT then		
		local tr = {}
		
		util.TraceLine( { 
			start = vOrigin, 
			endpos = vOrigin + vecDirShooting * 16384,
			mask = MASK_SOLID, 
			output = tr
		} )

		// if this is a local player, start at attachment on view model
		// else start on attachment on weapon model

		local iEntIndex = pPlayer:EntIndex() -- Fix, is this needed?
		local iAttachment = 1

		local vecStart = tr.StartPos 
		local angAttachment

		local pLocalPlayer = LocalPlayer()

		// try to align tracers to actual weapon barrel if possible
		if ( pPlayer == pLocalPlayer ) then
			local pViewModel = pPlayer:GetViewModel(0)
			
			if ( IsValid( pViewModel ) ) then
				iEntIndex = pViewModel:EntIndex()
				local angpos = pViewModel:GetAttachment( iAttachment )
				vecStart = angpos.Pos
				angAttachment = angpos.Ang
			end
		elseif ( pLocalPlayer:GetObserverTarget() == pPlayer and pLocaPlayer:GetObserverMode() == OBS_MODE_IN_EYE ) then
			// get our oberver target's view model
			
			local pViewModel = pLocalPlayer:GetViewModel(0)
			
			if ( IsValid( pViewModel ) ) then
				iEntIndex = pViewModel:EntIndex()
				local angpos = pViewModel:GetAttachment( iAttachment )
				vecStart = angpos.Pos
				angAttachment = angpos.Ang
			end
		elseif ( pPlayer:IsDormant() ) then
			// fill in with third person weapon model index
			-- Fix; we're doing jack here because we can't fuck around with model indices
			local pWeapon = pPlayer:GetActiveWeapon()
		end
		
		local iTracerType = pWeaponInfo.Tracer

		if ( iTracerType == 1 ) then 	// Machine gun, heavy tracer
			util.Tracer( vecStart, tr.endpos, iEntIndex, TRACER_DONT_USE_ATTACHMENT, 5000.0, true, "BrightTracer" )
		elseif ( iTracerType == 2 ) then	// rifle, smg, light tracer
			vecStart = vecStart + vecDirShooting * 150
			util.Tracer( vecStart, tr.endpos, iEntIndex, TRACER_DONT_USE_ATTACHMENT, 5000.0, true, "FaintTracer" )
		elseif ( iTracerType == 0 ) then	// pistols etc, just do the sound
			fx.TracerSound( vecStart, tr.endpos, TRACER_TYPE_DEFAULT ) -- Fix
		end
	end

	if SERVER then
		pPlayer:LagCompensation( false )
	end
end