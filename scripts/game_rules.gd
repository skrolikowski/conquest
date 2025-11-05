class_name GameRules
extends RefCounted

## Business logic and sorting utilities for game entities.
## Centralizes game rules like building priorities, combat sorting, etc.
##
## Example usage:
##   buildings.sort_custom(GameRules.sort_buildings_by_priority)
##   var priority = GameRules.get_building_sort_priority(Term.BuildingType.FARM)

#region BUILDING SORTING

static var _building_sort_priority: Dictionary = {
	Term.BuildingType.DOCK: 0,
	Term.BuildingType.HOUSING: 1,
	Term.BuildingType.FARM: 2,
	Term.BuildingType.MILL: 3,
	Term.BuildingType.METAL_MINE: 4,
	Term.BuildingType.GOLD_MINE: 5,
	Term.BuildingType.COMMERCE: 6,
	Term.BuildingType.CHURCH: 7,
	Term.BuildingType.TAVERN: 8,
	Term.BuildingType.FORT: 9,
	Term.BuildingType.WAR_COLLEGE: 10,
}

static func get_building_sort_priority(type: Term.BuildingType) -> int:
	"""Get numeric priority for building type sorting.
	Lower numbers appear first. Unknown types get priority 100."""
	return _building_sort_priority.get(type, 100)

static func sort_building_types_by_priority(a: Term.BuildingType, b: Term.BuildingType) -> bool:
	"""Sort building types by display priority.
	Use with Array.sort_custom()."""
	return get_building_sort_priority(a) < get_building_sort_priority(b)

static func sort_buildings_by_priority(a: Building, b: Building) -> bool:
	"""Sort building instances by their type's display priority.
	Use with Array.sort_custom()."""
	return get_building_sort_priority(a.building_type) < get_building_sort_priority(b.building_type)

#endregion

#region COMBAT UNIT SORTING

static func sort_combat_units_by_type(a: CombatUnit, b: CombatUnit) -> bool:
	"""Sort combat units by type (descending).
	Use with Array.sort_custom()."""
	return a.stat.unit_type > b.stat.unit_type

static func sort_combat_units_by_health(a: CombatUnit, b: CombatUnit) -> bool:
	"""Sort combat units by health (descending - healthiest first).
	Use with Array.sort_custom()."""
	return a.stat.health > b.stat.health

#endregion

#region PRODUCTION SPECIALIZATION

static func calculate_specialization_bonus(building_level_count: int) -> float:
	"""Calculate production specialization bonus based on building-level-grid-squares.

	Bonuses are based on building-level-grid-squares (ie: farms are worth 4 points
	per building level), in blocks of 20:
	- First 20 blocks: 1% each
	- Next 20 blocks: 0.5% each
	- Next 20 blocks: 0.25% each
	- Asymptotically approaches 40% total possible bonus

	Once this bonus is calculated for the largest commodity sector in your colony,
	the bonus value of the SECOND largest commodity is subtracted from the first.

	Bonuses are calculated for mills, mines (gold and metal lumped together), and farms.
	Commerce does not gain production bonuses.
	"""
	var bonus: float = 0.0
	var remaining: int = building_level_count

	# First 20: 1% each
	var first_block: int = mini(remaining, 20)
	bonus += first_block * 0.01
	remaining -= first_block

	if remaining > 0:
		# Next 20: 0.5% each
		var second_block: int = mini(remaining, 20)
		bonus += second_block * 0.005
		remaining -= second_block

	if remaining > 0:
		# Next 20: 0.25% each
		var third_block: int = mini(remaining, 20)
		bonus += third_block * 0.0025
		remaining -= third_block

	# Additional blocks continue diminishing (approach 40% max)
	if remaining > 0:
		var fourth_block: int = mini(remaining, 20)
		bonus += fourth_block * 0.00125

	return bonus

#endregion
