## Controller for building placement workflow
##
## Orchestrates the building placement process:
## - Manages placement state via BuildingPlacementWorkflow
## - Handles visual preview via BuildingPlacementPreview
## - Validates placement rules
## - Coordinates with BuildingManager for final placement
## - Handles input and UI interactions
##
## This separates placement concerns from building collection management.
extends Area2D
class_name BuildingPlacementController

# const BuildingPlacementWorkflow: GDScript = preload("res://scenes/player/colony/building_placement_workflow.gd")
# const BuildingPlacementPreview: GDScript = preload("res://scenes/player/colony/building_placement_preview.gd")


@onready var ghost_timer: Timer = $GhostTimer as Timer

## Reference to the colony center building
@export var colony: CenterBuilding

## Placement workflow state machine
var workflow: BuildingPlacementWorkflow = BuildingPlacementWorkflow.new()

## Visual preview handler
var placement_preview: BuildingPlacementPreview = BuildingPlacementPreview.new()

## Dictionary of valid build tiles: Vector2i -> TileData
var build_tiles: Dictionary = {}

## World manager reference
var world_manager: WorldManager


func _ready() -> void:
	# Add placement preview as child for drawing
	add_child(placement_preview)

	# Connect to world selector for cursor updates
	world_manager = Def.get_world() as WorldManager
	world_manager.world_selector.connect("cursor_updated", _on_cursor_updated)


#region EVENT HANDLERS

func _on_cursor_updated() -> void:
	_refresh_placing_position()

#endregion


#region BUILDING PLACEMENT

## Start placing a building
func start_building_placement(building: Building) -> void:
	# Start workflow
	var result: BuildingPlacementWorkflow.Result = workflow.start_placement(building, colony)
	if result.is_error():
		push_error("Failed to start placement: %s" % result.error_message)
		return

	# Add building to manager (temporary, will be finalized or removed)
	colony.bm.add_building(building)

	# Calculate valid build tiles
	_refresh_build_tiles()

	# Get initial tile position
	var tile_map_layer: TileMapLayer = Def.get_world_tile_map()
	var initial_tile: Vector2i = tile_map_layer.local_to_map(get_global_mouse_position())

	# Set up preview
	placement_preview.set_preview(building, initial_tile, build_tiles)

	# Set focus
	world_manager.focus_service.set_focus_node(building)


## Update building position based on cursor
func _refresh_placing_position() -> void:
	if not workflow.is_placing():
		return

	if workflow.context == null or workflow.context.building == null:
		return

	var tile_map_layer: TileMapLayer = Def.get_world_tile_map()
	var map_tile: Vector2i = tile_map_layer.local_to_map(get_global_mouse_position())

	if workflow.context.target_tile != map_tile:
		_update_building_position(map_tile)


## Update building position and visual feedback
func _update_building_position(tile: Vector2i) -> void:
	if workflow.context == null:
		return

	# Update context
	workflow.context.set_target_tile(tile)

	# Update preview
	placement_preview.update_position(tile)

	# Update visual feedback (red if invalid, white if valid)
	var building: Building = workflow.context.building
	if not _can_place_building():
		building.modulate = Color(1, 0, 0, 0.75)
	else:
		building.modulate = Color(1, 1, 1, 1)

	# Update focus
	world_manager.focus_service.set_focus_node(building)


## Check if building can be placed at current position
func _can_place_building() -> bool:
	if workflow.context == null or workflow.context.building == null:
		return false

	var building: Building = workflow.context.building
	var placing_tile: Vector2i = workflow.context.target_tile
	var placing_end: Vector2i = building.get_tile_end()

	# Check each tile in building footprint
	for x: int in range(placing_tile.x, placing_end.x + 1):
		for y: int in range(placing_tile.y, placing_end.y + 1):
			var tile: Vector2i = Vector2i(x, y)

			# Check if tile is in valid build range
			if not build_tiles.has(tile):
				return false

			# Check if tile is already occupied
			if colony.bm.is_tile_occupied(tile):
				return false

			# Water building checks (docks)
			if building.is_water_building():
				var is_shore_tile: bool = Def.get_world_map().is_shore_tile(tile)
				if is_shore_tile:
					return true

				var is_river_tile: bool = Def.get_world_map().is_river_tile(tile)
				if is_river_tile:
					return true

				return false
			else:
				# Land building checks
				var is_land_tile: bool = Def.get_world_map().is_land_tile(tile)
				if not is_land_tile:
					return false

	return true


## Confirm placement (called when player clicks)
func confirm_placement() -> void:
	if not workflow.is_placing():
		return

	if workflow.context == null or workflow.context.building == null:
		return

	var building: Building = workflow.context.building

	if not _can_place_building():
		# Invalid placement - remove building
		colony.bm.remove_building(building)
	else:
		# Valid placement - finalize
		colony.bm.add_occupied_tiles(building.get_tiles(), building)
		colony.purchase_building(building)

		# Set timer to disallow selection temporarily
		building.is_selectable = false
		var cb: Callable = func(_b: Building) -> void:
			_b.is_selectable = true

		ghost_timer.wait_time = 0.1
		ghost_timer.connect("timeout", cb.bind(building), CONNECT_ONE_SHOT)
		ghost_timer.start()

		# Refresh UI
		WorldService.get_world_canvas().refresh_current_ui()

	# Clear preview
	placement_preview.clear_preview()

	# Complete workflow
	workflow.complete_placement()

	# Clear focus
	world_manager.focus_service.set_focus_node(null)

	# Reset workflow
	workflow.reset()


## Calculate valid build tiles based on colony's build radius
func _refresh_build_tiles() -> void:
	var world_map: WorldGen = Def.get_world_map()
	var build_radius: float = GameData.get_building_stat(Term.BuildingType.CENTER, colony.level).build_radius * Preload.C.TILE_SIZE.x
	var tiles_in_range: Array[Vector2i] = Def.get_world_map().get_tiles_in_radius(global_position, build_radius)
	var tile_map_layer: TileMapLayer = Def.get_world_tile_map()

	build_tiles = {}

	for tile: Vector2i in tiles_in_range:
		if world_map.tile_custom_data[tile].is_fog_of_war:
			continue

		build_tiles[tile] = tile_map_layer.get_cell_tile_data(tile)

#endregion


#region INPUT HANDLING

func _unhandled_input(_event: InputEvent) -> void:
	if _event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = _event as InputEventMouseButton
		if mouse_event.button_index == 1 and mouse_event.pressed and workflow.is_placing():
			confirm_placement()

#endregion
