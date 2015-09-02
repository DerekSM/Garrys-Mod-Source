local function MatrixVecToYaw( matrix, vec )
	vec:Normalize()
	
	local x = matrix[1][1] * vec.x + matrix[2][1] * vec.y + matrix[3][1] * vec.z
	local y = matrix[1][2] * vec.x + matrix[2][2] * vec.y + matrix[3][2] * vec.z
	
	if ( x == 0.0 and y == 0.0 ) then
		return 0.0
	end
	
	local yaw = math.atan2( -y, x )
	
	yaw = math.deg( yaw )
	
	if ( yaw < 0 ) then
		yaw = yaw + 360
	end
	
	return yaw
end

local function MatrixVecToPitch( matrix, vec )
	vec:Normalize()
	
	local x = matrix[1][1] * vec.x + matrix[2][1] * vec.y + matrix[3][1] * vec.z
	local z = matrix[1][3] * vec.x + matrix[2][3] * vec.y + matrix[3][3] * vec.z
	
	if ( x == 0.0 and z == 0.0 ) then
		return 0.0
	end
	
	local pitch = math.atan2( z, x )
	
	pitch = math.deg( pitch )
	
	if ( pitch < 0 ) then
		pitch = pitch + 360
	end
	
	return pitch
end

function util.VecToYaw( vec, vec2 )
	-- RIP no polymorphism
	if ( ismatrix( vec ) ) then
		return MatrixVecToYaw( vec, vec2 )
	end
	
	if ( vec.y == 0 and vec.x == 0 ) then
		return 0
	end
	
	local yaw = math.atan2( vec.y, vec.x )
	
	yaw = math.deg( yaw )
	
	if ( yaw < 0 ) then
		yaw = yaw + 360
	end
	
	return yaw
end

function util.VecToPitch( vec, vec2 )
	if ( ismatrix( vec ) ) then
		return MatrixVecToPitch( vec, vec2 )
	end
	
	if ( vec.y == 0 and vec.x == 0 ) then
		if ( vec.z < 0 ) then
			return 180.0
		else
			return -180.0
		end
	end
	
	local dist = vec:Length2D()
	local pitch = math.atan2( -vec.z, dist )
	
	pitch = math.deg( pitch )
	
	return pitch
end

function util.YawToVector( yaw )
	local ret = Vector( 0, 0, 0 )
	
	local angle = math.rad( yaw )
	ret.y = math.sin( angle )
	ret.x = math.cos( angle )
	
	return ret
end
--[[
static int SeedFileLineHash( int seedvalue, const char *sharedname, int additionalSeed )
{
	CRC32_t retval;

	CRC32_Init( &retval );

	CRC32_ProcessBuffer( &retval, (void *)&seedvalue, sizeof( int ) );
	CRC32_ProcessBuffer( &retval, (void *)&additionalSeed, sizeof( int ) );
	CRC32_ProcessBuffer( &retval, (void *)sharedname, Q_strlen( sharedname ) );
	
	CRC32_Final( &retval );

	return (int)( retval );
}

float SharedRandomFloat( const char *sharedname, float flMinVal, float flMaxVal, int additionalSeed /*=0*/ )
{
	Assert( CBaseEntity::GetPredictionRandomSeed() != -1 );

	int seed = SeedFileLineHash( CBaseEntity::GetPredictionRandomSeed(), sharedname, additionalSeed );
	RandomSeed( seed );
	return RandomFloat( flMinVal, flMaxVal );
}

int SharedRandomInt( const char *sharedname, int iMinVal, int iMaxVal, int additionalSeed /*=0*/ )
{
	Assert( CBaseEntity::GetPredictionRandomSeed() != -1 );

	int seed = SeedFileLineHash( CBaseEntity::GetPredictionRandomSeed(), sharedname, additionalSeed );
	RandomSeed( seed );
	return RandomInt( iMinVal, iMaxVal );
}

Vector SharedRandomVector( const char *sharedname, float minVal, float maxVal, int additionalSeed /*=0*/ )
{
	Assert( CBaseEntity::GetPredictionRandomSeed() != -1 );

	int seed = SeedFileLineHash( CBaseEntity::GetPredictionRandomSeed(), sharedname, additionalSeed );
	RandomSeed( seed );
	// HACK:  Can't call RandomVector/Angle because it uses rand() not vstlib Random*() functions!
	// Get a random vector.
	Vector random;
	random.x = RandomFloat( minVal, maxVal );
	random.y = RandomFloat( minVal, maxVal );
	random.z = RandomFloat( minVal, maxVal );
	return random;
}

QAngle SharedRandomAngle( const char *sharedname, float minVal, float maxVal, int additionalSeed /*=0*/ )
{
	Assert( CBaseEntity::GetPredictionRandomSeed() != -1 );

	int seed = SeedFileLineHash( CBaseEntity::GetPredictionRandomSeed(), sharedname, additionalSeed );
	RandomSeed( seed );

	// HACK:  Can't call RandomVector/Angle because it uses rand() not vstlib Random*() functions!
	// Get a random vector.
	Vector random;
	random.x = RandomFloat( minVal, maxVal );
	random.y = RandomFloat( minVal, maxVal );
	random.z = RandomFloat( minVal, maxVal );
	return QAngle( random.x, random.y, random.z );
}]]--

function PassServerEntityFilter( pTouch, pPass ) -- Fix; no table. Just a plain function
	if ( pPass == nil ) then
		return true
	end
	
	if ( pTouch == pPass ) then
		return false
	end
	
	local pEntTouch = ents.GetByIndex( pTouch )
	local pEntPass = ents.GetByIndex( pPass )
	
	if ( not IsValid( pEntTouch ) or not IsValid( pEntPass ) ) then
		return true
	// don't clip against own missiles
	elseif ( pEntTouch:GetOwner() == pEntPass ) then
		return false
	// don't clip against owner
	elseif ( pEntPass:GetOwner() == pEntTouch ) then
		return false
	end
	
	return true
end

function StandardFilterRules( pHandleEntity, fContentsMask ) -- Fix; allow entities to be sent through? Not just indicies?
	local pCollide = ents.GetByIndex( pHandleEntity )
	
	// Static prop case...
	if ( not IsValid( pCollide ) ) then
		return true
	end
	
	local solid = pCollide:GetSolid()
	local pModel = pCollide:GetModel()
	
	if ( ( modelinfo.GetModelType( pModel ) ~= mod_brush ) or ( solid ~= SOLID_BSP and solid ~= SOLID_VPHYSICS ) ) then -- FIX THIS SHIT
		if ( bit.band( fContentsMask, CONTENTS_MONSTER ) == 0 ) then
			return false
		end
	end
	
	// This code is used to cull out tests against see-thru entities
	if ( not bit.band( fContentsMask, CONTENTS_WINDOW ) and pCollide:IsTransparent() ) then -- FIX HARDCORE
		return false
	end
	
	// FIXME: this is to skip BSP models that are entities that can be 
	// potentially moved/deleted, similar to a monster but doors don't seem to 
	// be flagged as monsters
	// FIXME: the FL_WORLDBRUSH looked promising, but it needs to be set on 
	// everything that's actually a worldbrush and it currently isn't
	if ( not bit.band( fContentsMask, CONTENTS_MOVEABLE ) and ( pCollide:GetMoveType() == MOVETYPE_PUSH ) ) then // !(touch->flags & FL_WORLDBRUSH) )
		return false
	end
	
	return true
end

-- Fix; CTraceFilter stuff here

TRACER_FLAG_WHIZ = 0x0001
TRACER_FLAG_USEATTACHMENT = 0x0002
TRACER_DONT_USE_ATTACHMENT = -1

function util.Tracer( vecStart, vecEnd, iEntIndex, iAttachment, flVelocity, bWhiz, pCustomTracerName, iParticleID )

	local data = EffectData()
	data:SetStart( vecStart )
	data:SetOrigin( vecEnd )
	
	if CLIENT then
		data:SetEntity( ents.GetByIndex( iEntIndex ) )
	else
		data:SetEntIndex( iEntIndex )
	end
	
	data:SetScale( flVelocity )
	if ( iParticleID ) then
		data:SetHitBox( iParticleID )
	end
	--data:SetRadius( 0.1 )
	
	local flags = data:GetFlags()

	-- Flags
	if ( bWhiz ) then
		flags = bit.bor( flags, TRACER_FLAG_WHIZ )
	end

	if ( iAttachment ~= TRACER_DONT_USE_ATTACHMENT ) then
		flags = bit.bor( flags, TRACER_FLAG_USEATTACHMENT )
		data:SetAttachment( iAttachment )
	end
	
	data:SetFlags( flags )
	
	if ( pCustomTracerName ) then
		util.Effect( pCustomTracerName, data )
	else
		util.Effect( "Tracer", data )
	end

end