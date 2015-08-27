-- Valve's pseudo-random functions ported directly to Lua :)

local _R = debug.getregistry()

random = {}

local NTAB = 32
local IA = 16807
local IM = 2147483647
local IQ = 127773
local IR = 2836
local NDIV = math.floor(1+(IM-1)/NTAB)
local MAX_RANDOM_RANGE = 0x7FFFFFFF

// fran1 -- return a random floating-point number on the interval [0,1)

local AM = (1.0/IM)
local EPS = 1.2e-7
local RNMX = (1.0-EPS)

local idum = 0
local iy = 0
local iv = {}

function random.SetSeed( iSeed )
	idum = ( ( iSeed < 0 ) and iSeed or -iSeed )
	iy = 0
end

random.SetSeed( 0 ) -- CUniformRandomStream implementation; fix

function random.GenerateRandomNumber()
	local j = 0
	local k = 0
	
	if ( m_idum <= 0 or not iy ) then
		if ( -(idum) < 1 ) then
			idum = 1
		else
			idum = -(idum)
		end
			
		for ( j = NTAB + 7, 0, -1 ) do
			-- Have to round because k is predicted to be an int
			k = math.floor( idum/IQ )
			idum = IA * (idum - k * IQ) - IR * k
			if ( idum < 0 ) then
				idum = idum + IM
			end
			if ( j < NTAB ) then
				iv[j] = idum
			end
		end
		
		iy = iv[0]
	end
	k = math.floor( idum/IQ )
	idum = IA * (idum - k * IQ) - IR * k
	if ( idum < 0 ) then
		idum = idum + IM
	end
	j = math.floor( iy/NDIV )
	
	-- Fix; temporary
	if ( j >= NTAB or j < 0 ) then
		error( "CUniformRandomStream had an array overrun: tried to write to element " .. j .. " of 0..31." )
	end
	
	m_iy=m_iv[j]
	m_iv[j] = m_idum

	return m_iy
end

function random.RandomFloat( flLow, flHigh )
	-- Replicate standard math.random implementation
	flLow = flLow or 0
	flHigh = flHigh or 1
	
	// float in [0,1)
	local fl = AM * random.GenerateRandomNumber()
	if ( fl > RNMX ) then 
		fl = RNMX
	end
	return ( fl * ( flHigh - flLow ) ) + flLow // float in [low,high)
end

function random.RandomFloatExp( flMinVal, flMaxVal, flExponent )
	flMinVal = flMinVal or 0
	flMaxVal = flMaxVal or 1

	// float in [0,1)
	local fl = AM * random.GenerateRandomNumber()
	if ( fl > RNMX ) then
		fl = RNMX
	end
	if ( flExponent ~= 1.0 ) then
		fl = math.pow( fl, flExponent )
	end
	return ( fl * ( flMaxVal - flMinVal ) ) + flMinVal -- float in [low,high)
end

function random.RandomInt( iLow, iHigh )
	//ASSERT(lLow <= lHigh);
	local maxAcceptable
	local x = iHigh - iLow + 1
	local n = 0
	if ( x <= 1 or MAX_RANDOM_RANGE < x-1 ) then
		return iLow
	end

	// The following maps a uniform distribution on the interval [0,MAX_RANDOM_RANGE]
	// to a smaller, client-specified range of [0,x-1] in a way that doesn't bias
	// the uniform distribution unfavorably. Even for a worst case x, the loop is
	// guaranteed to be taken no more than half the time, so for that worst case x,
	// the average number of times through the loop is 2. For cases where x is
	// much smaller than MAX_RANDOM_RANGE, the average number of times through the
	// loop is very close to 1.

	maxAcceptable = MAX_RANDOM_RANGE - ((MAX_RANDOM_RANGE+1) % x )
	repeat
		n = random.GenerateRandomNumber()
	until (n <= maxAcceptable)

	return iLow + (n % x)
end


//-----------------------------------------------------------------------------
//
// Implementation of the gaussian random number stream
// We're gonna use the Box-Muller method (which actually generates 2
// gaussian-distributed numbers at once)
//
//-----------------------------------------------------------------------------
local bHaveValue = false
local flRandomValue = 0

function random.RandomGaussianFloat( flMean, flStdDev )
	local fac, rsq, v1, v2 = 0, 0, 0, 0

	if ( not m_bHaveValue ) then
		// Pick 2 random #s from -1 to 1
		// Make sure they lie inside the unit circle. If they don't, try again
		repeat
			v1 = 2.0 * random.RandomFloat() - 1.0
			v2 = 2.0 * random.RandomFloat() - 1.0
			rsq = v1 * v1 + v2 * v2
		until ( ( rsq <= 1.0 ) and ( rsq ~= 0.0 ) )

		// The box-muller transformation to get the two gaussian numbers
		fac = math.sqrt( -2.0 * math.log(rsq) / rsq )

		// Store off one value for later use
		flRandomValue = v1 * fac
		bHaveValue = true

		return flStdDev * (v2 * fac) + flMean
	else
		bHaveValue = false
		return flStdDev * m_flRandomValue + flMean
	end
end
--[[
function random.SeedFileLineHash( seedvalue, sharedname, additionalSeed )
	return tonumber( util.CRC( ("%i%i%s"):format( seedvalue, additionalSeed, sharedname ) ) )
end

function _R.Entity:GetPredictionRandomSeed()
	local seed = self:EntIndex()
	
	if self:IsPlayer() then
		seed = bit.band( self:GetCurrentCommand():CommandNumber(), 0x7fffffff )
	end
	
	return seed
end

function _R.Entity:SharedRandomInt( sharedname, flMinVal, flMaxVal, additionalSeed )
	additionalSeed = additionalSeed or 0
	local seed = random.SeedFileLineHash( self:GetPredictionRandomSeed(), sharedname, additionalSeed )
	random.SetSeed( seed )
	return random.RandomInt( flMinVal, flMaxVal )
end

function _R.Entity:SharedRandomFloat( sharedname, flMinVal, flMaxVal, additionalSeed )
	additionalSeed = additionalSeed or 0
	local seed = random.SeedFileLineHash( self:GetPredictionRandomSeed(), sharedname, additionalSeed )
	random.SetSeed( seed )
	return random.RandomFloat( flMinVal, flMaxVal )
end
]]
random.SetSeed( os.time() ) -- Fix?

--[[for i=1,10 do
    local heads = 0
    local tails = 0
    for j=1,100 do
    	local r = random.RandomInt(1,2)
    	if r == 1 then
    		heads = heads + 1
    	else
    		tails = tails + 1
    	end
    end
    print( "Trial " .. i )
    print( "\tHeads = " .. heads )
    print( "\tTails = " .. tails )
end]]