// Following values should be +16384, -16384, +15/16, -15/16
// NOTE THAT IF THIS GOES ANY BIGGER THEN DISK NODES/LEAVES CANNOT USE SHORTS TO STORE THE BOUNDS
MAX_COORD = 16384
MIN_COORD = -MAX_COORD
MAX_COORD_FRACTION = (1.0-(1.0/16.0))
MIN_COORD_FRACTION = (-1.0+(1.0/16.0))

// Width of the coord system, which is TOO BIG to send as a client/server coordinate value
COORD_EXTENT = (2*MAX_COORD)

// Maximum traceable distance ( assumes cubic world and trace from one corner to opposite )
MAX_TRACE_LENGTH = math.sqrt(3) * COORD_EXTENT
