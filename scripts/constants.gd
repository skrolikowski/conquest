## Game-wide constants
## This is a pure constants file (no class_name, no extends) for maximum compatibility
## All files can reference these constants at compile-time

const DEBUG_MODE: bool = true

# Rendering
const TILE_SIZE: Vector2i = Vector2i(48, 48)
const STATUS_SEP: String = "; "

# Feature flags
const FOG_OF_WAR_ENABLED: bool = false
const CONFIRM_END_TURN_ENABLED: bool = false
const WEALTH_MODE_ENABLED: bool = true

# Combat grid layout
const DEFENDER_RESERVE_ROW: Vector2i = Vector2i(5, 0)
const DEFENDER_FLAG_SQUARE: Vector2i = Vector2i(4, 1)
const ATTACKER_RESERVE_ROW: Vector2i = Vector2i(0, 0)
const ATTACKER_FLAG_SQUARE: Vector2i = Vector2i(1, 1)
