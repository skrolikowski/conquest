extends Node
class_name GameConfigRef

## Game balance tuning parameters and runtime configuration.
## Centralizes all balance values for easy tweaking and testing.
##
## NOTE: Game constants (TILE_SIZE, feature flags, etc.) are now in scripts/constants.gd
##
## Example usage:
##   var growth_rate = GameConfig.get_base_population_growth_rate()

const C = preload("res://scripts/constants.gd")  # Shared constants

# Re-export constants for convenience (can still use GameConfig.TILE_SIZE)
const TILE_SIZE: Vector2i = C.TILE_SIZE
const STATUS_SEP: String = C.STATUS_SEP
const FOG_OF_WAR_ENABLED: bool = C.FOG_OF_WAR_ENABLED
const CONFIRM_END_TURN_ENABLED: bool = C.CONFIRM_END_TURN_ENABLED
const WEALTH_MODE_ENABLED: bool = C.WEALTH_MODE_ENABLED
const DEFENDER_RESERVE_ROW: Vector2i = C.DEFENDER_RESERVE_ROW
const DEFENDER_FLAG_SQUARE: Vector2i = C.DEFENDER_FLAG_SQUARE
const ATTACKER_RESERVE_ROW: Vector2i = C.ATTACKER_RESERVE_ROW
const ATTACKER_FLAG_SQUARE: Vector2i = C.ATTACKER_FLAG_SQUARE

#region POPULATION GROWTH

static func get_base_population_growth_rate() -> float:
	"""Base population growth rate: 8% of current population + 10 per Church level.

	Source: https://gamefaqs.gamespot.com/pc/196975-conquest-of-the-new-world/faqs/2038
	"""
	return 0.08

static func get_crops_consumption_rate() -> float:
	"""Crops consumption rate: 1 crop feeds 100 population."""
	return 0.01

#endregion

#region MILITARY RESEARCH

static func get_research_max_level() -> int:
	"""Maximum research level for military technologies."""
	return 5

static func get_research_max_exp_by_level(level: int) -> int:
	"""Experience required to reach each research level."""
	const LEVEL_EXP: Dictionary = {
		1: 1000,
		2: 5000,
		3: 10000,
		4: 25000,
		5: 50000,
	}
	return LEVEL_EXP.get(level, 0)

#endregion

#region PRODUCTION SPECIALIZATION

## Production specialization bonus documentation
##
## Specialization bonuses are based on building-level-grid-squares
## (ie: farms are worth 4 points per building level), in blocks of 20:
## - First 20 blocks: 1% each
## - Next 20 blocks: 0.5% each
## - Next 20 blocks: 0.25% each
## - Asymptotically approaches 40% total possible bonus
##
## Once this bonus is calculated for the largest commodity sector in your colony,
## the bonus value of the SECOND largest commodity is subtracted from the first.
## As you can see by how the numbers start high and then shrink, even having 10
## building levels of another commodity reduces your possible maximum to 30%.
##
## Bonuses are calculated for mills, mines (gold and metal lumped together), and farms.
## Commerce does not gain production bonuses.
##
## NOTE: Actual calculation is implemented in GameRules.calculate_specialization_bonus()

#endregion
