extends Node

## Centralized fog of war management service.
## Handles fog reveal logic for units, colonies, and arbitrary positions.
## Decouples Player/Unit classes from WorldGen/WorldMap dependencies.

signal fog_revealed(position: Vector2, radius: float)

var enabled: bool = false
var _world_gen: WorldGen = null


func initialize(world_gen: WorldGen, _enabled: bool = false) -> void:
	"""Initialize the service with world map reference and enable flag."""
	_world_gen = world_gen
	enabled = _enabled
	print("[FogOfWarService] Initialized - Enabled: ", enabled)


func reveal_around_unit(unit: Unit) -> void:
	"""Reveal fog of war around a single unit based on its fog_reveal stat."""
	if not enabled:
		return

	if unit == null or not is_instance_valid(unit):
		return

	var radius: float = unit.stat.get_stat().fog_reveal
	reveal_at_position(unit.global_position, radius)


func reveal_around_player_units(player: Player) -> void:
	"""Reveal fog of war around all units belonging to a player."""
	if not enabled:
		return

	if player == null:
		return

	for unit in player.units:
		reveal_around_unit(unit)


func reveal_at_position(pos: Vector2, radius: float) -> void:
	"""Reveal fog of war at a specific position with given radius."""
	if not enabled or _world_gen == null:
		return

	_world_gen.reveal_fog_of_war(pos, radius)
	fog_revealed.emit(pos, radius)


func is_fog_enabled() -> bool:
	"""Check if fog of war is currently enabled."""
	return enabled
