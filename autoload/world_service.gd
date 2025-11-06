extends Node
class_name WorldServiceRef

## Cached references to frequently-accessed world nodes.
## Improves performance by caching scene tree lookups.
##
## DEPRECATION NOTE: This is a transitional pattern. Future code should use:
## - Dependency injection (pass references via constructor/setter)
## - Signals for communication
## - Direct references where appropriate
##
## Example migration:
##   OLD: var canvas = WorldService.get_world_canvas()
##   NEW: @export var world_canvas: WorldCanvas  (set in editor or code)

# Cached node references (lazy-loaded)
var _world_canvas: WorldCanvas = null
var _world_manager: WorldManager = null
var _world_gen: WorldGen = null
var _world_selector: WorldSelector = null


func get_world_canvas() -> WorldCanvas:
	"""Get WorldCanvas singleton. Cached after first access."""
	if not _world_canvas or not is_instance_valid(_world_canvas):
		_world_canvas = get_tree().get_first_node_in_group("world_canvas") as WorldCanvas
		if not _world_canvas:
			push_warning("WorldCanvas not found in scene tree")
	return _world_canvas


func get_world() -> WorldManager:
	"""Get WorldManager singleton. Cached after first access."""
	if not _world_manager or not is_instance_valid(_world_manager):
		_world_manager = get_tree().get_first_node_in_group("world") as WorldManager
		if not _world_manager:
			push_warning("WorldManager not found in scene tree")
	return _world_manager


func get_world_selector() -> WorldSelector:
	"""Get WorldSelector from WorldManager. Cached after first access."""
	if not _world_selector or not is_instance_valid(_world_selector):
		var world : WorldManager = get_world()
		if world:
			_world_selector = world.world_selector
	return _world_selector


func get_world_map() -> WorldGen:
	"""Get WorldGen from WorldManager. Cached after first access."""
	if not _world_gen or not is_instance_valid(_world_gen):
		var world : WorldManager = get_world()
		if world:
			_world_gen = world.world_gen
	return _world_gen


func get_world_tile_map() -> TileMapLayer:
	"""Get land layer TileMapLayer from WorldGen. Not cached (derived property)."""
	var world_map : WorldGen = get_world_map()
	if world_map:
		return world_map.get_land_layer()
	return null


func clear_cache() -> void:
	"""Clear all cached references. Call when scene changes."""
	_world_canvas = null
	_world_manager = null
	_world_gen = null
	_world_selector = null
