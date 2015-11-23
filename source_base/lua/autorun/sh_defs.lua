-- Global definitions

// entity capabilities
// These are caps bits to indicate what an object's capabilities (currently used for +USE, save/restore and level transitions)
FCAP_MUST_SPAWN	= 0x00000001		// Spawn after restore
FCAP_ACROSS_TRANSITION = 0x00000002		// should transfer between transitions 
// UNDONE: This will ignore transition volumes (trigger_transition), but not the PVS!!!
FCAP_FORCE_TRANSITION = 0x00000004		// ALWAYS goes across transitions
FCAP_NOTIFY_ON_TRANSITION = 0x00000008		// Entity will receive Inside/Outside transition inputs when a transition occurs

FCAP_IMPULSE_USE = 0x00000010		// can be used by the player
FCAP_CONTINUOUS_USE	= 0x00000020		// can be used by the player
FCAP_ONOFF_USE = 0x00000040		// can be used by the player
FCAP_DIRECTIONAL_USE = 0x00000080		// Player sends +/- 1 when using (currently only tracktrains)
// NOTE: Normally +USE only works in direct line of sight.  Add these caps for additional searches
FCAP_USE_ONGROUND = 0x00000100
FCAP_USE_IN_RADIUS = 0x00000200
FCAP_SAVE_NON_NETWORKABLE = 0x00000400

FCAP_MASTER = 0x10000000		// Can be used to "master" other entities (like multisource)
FCAP_WCEDIT_POSITION = 0x40000000		// Can change position and update Hammer in edit mode
FCAP_DONT_SAVE = 0x80000000		// Don't save this

// -----------------------------------------
//	Vector cones
// -----------------------------------------
// VECTOR_CONE_PRECALCULATED - this resolves to vec3_origin, but adds some
// context indicating that the person writing the code is not allowing
// FireBullets() to modify the direction of the shot because the shot direction
// being passed into the function has already been modified by another piece of
// code and should be fired as specified. See GetActualShotTrajectory(). 

// NOTE: The way these are calculated is that each component == sin (degrees/2)
VECTOR_CONE_PRECALCULATED = vector_origin
VECTOR_CONE_1DEGREES = Vector( 0.00873, 0.00873, 0.00873 )
VECTOR_CONE_2DEGREES = Vector( 0.01745, 0.01745, 0.01745 )
VECTOR_CONE_3DEGREES = Vector( 0.02618, 0.02618, 0.02618 )
VECTOR_CONE_4DEGREES = Vector( 0.03490, 0.03490, 0.03490 )
VECTOR_CONE_5DEGREES = Vector( 0.04362, 0.04362, 0.04362 )
VECTOR_CONE_6DEGREES = Vector( 0.05234, 0.05234, 0.05234 )
VECTOR_CONE_7DEGREES = Vector( 0.06105, 0.06105, 0.06105 )
VECTOR_CONE_8DEGREES = Vector( 0.06976, 0.06976, 0.06976 )
VECTOR_CONE_9DEGREES = Vector( 0.07846, 0.07846, 0.07846 )
VECTOR_CONE_10DEGREES = Vector( 0.08716, 0.08716, 0.08716 )
VECTOR_CONE_15DEGREES = Vector( 0.13053, 0.13053, 0.13053 )
VECTOR_CONE_20DEGREES = Vector( 0.17365, 0.17365, 0.17365 )