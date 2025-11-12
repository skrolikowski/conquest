extends Node2D
class_name ColonyManager

@onready var colony_list: Node = $ColonyList

@export var player: Player

# Colony placement and founding workflow
var workflow : ColonyFoundingWorkflow = ColonyFoundingWorkflow.new()
var colonies : Array[CenterBuilding] = []
var placement_preview : Node2D = preload("res://scenes/player/colony_placement_preview.gd").new()

## Read-only access to placing colony (for testing/UI)
var placing_colony: CenterBuilding:
	get: return placement_preview.colony

## Service dependencies (can be injected for testing)
var _ui_service: ColonyFoundingServices.IUIService
var _focus_service: ColonyFoundingServices.IFocusService
var _scene_loader: ColonyFoundingServices.ISceneLoader


func _ready() -> void:
	# Add placement preview as child for drawing
	add_child(placement_preview)

	# Initialize with production services by default
	_initialize_production_services()


#region SERVICE INITIALIZATION

## Initialize with production services (called in _ready or can be overridden for testing)
func _initialize_production_services() -> void:
	var services: ColonyFoundingServices.ProductionServices = ColonyFoundingServices.ProductionServices.new()
	_ui_service = services.ui_service
	_focus_service = services.focus_service
	_scene_loader = services.scene_loader


## Inject custom services (for testing)
func inject_services(
	ui: ColonyFoundingServices.IUIService,
	focus: ColonyFoundingServices.IFocusService,
	loader: ColonyFoundingServices.ISceneLoader
) -> void:
	_ui_service = ui
	_focus_service = focus
	_scene_loader = loader

#endregion


#region COLONY MANAGEMENT

func get_colonies() -> Array[CenterBuilding]:
	return colonies


func add_colony(_building: CenterBuilding) -> void:
	colonies.append(_building)
	colony_list.add_child(_building)


func remove_colony(_colony: CenterBuilding) -> ColonyFoundingWorkflow.Result:
	if _colony == null:
		return ColonyFoundingWorkflow.Result.error("Cannot remove null colony")

	var colony_index: int = colonies.find(_colony)
	if colony_index == -1:
		return ColonyFoundingWorkflow.Result.error("Colony not found in colonies array")

	# -- Removes any buildings owned by this colony..
	for building: Building in _colony.bm.get_buildings().duplicate():
		_colony.bm.remove_building(building)

	# -- Clear references to prevent dangling pointers..
	if placement_preview.colony == _colony:
		placement_preview.clear_preview()
		# Note: Do NOT reset workflow here - let the caller manage workflow state
		# (cancel_found_colony and undo_create_colony handle their own resets)

	colonies.remove_at(colony_index)
	colony_list.remove_child(_colony)
	_colony.queue_free()

	return ColonyFoundingWorkflow.Result.ok()


func create_colony() -> ColonyFoundingWorkflow.Result:
	# Validate preconditions using workflow
	if not workflow.is_founding():
		return ColonyFoundingWorkflow.Result.error("Cannot create colony: not in founding state")

	if placement_preview.colony == null:
		return ColonyFoundingWorkflow.Result.error("Cannot create colony: placing_colony is null")

	if workflow.context == null or workflow.context.settler_stats == null:
		return ColonyFoundingWorkflow.Result.error("Cannot create colony: settler_stats is null")

	var colony: CenterBuilding = placement_preview.colony
	colony.player = player
	colony.modulate = Color(1, 1, 1, 1.0)

	# -- Store undo data in the colony itself (for multi-colony founding in same turn)
	colony._undo_settler_stats = workflow.context.settler_stats
	colony._undo_settler_position = workflow.context.settler_position

	# -- Set initial resources..
	var unit_stat: Dictionary = GameData.get_unit_stat(Term.UnitType.SETTLER, workflow.context.settler_stats.level)
	colony.set_init_resources(unit_stat.resources)
	colony.refresh_bank()

	# Clear placement preview
	placement_preview.clear_preview()

	# Complete workflow
	var result: ColonyFoundingWorkflow.Result = workflow.complete_founding(colony)
	if result.is_error():
		return result

	_ui_service.close_all_ui()

	# Reset workflow immediately - undo data now stored in colony itself
	# This allows founding multiple colonies in the same turn
	workflow.reset()

	return ColonyFoundingWorkflow.Result.ok(colony)


func undo_create_colony(_building: CenterBuilding) -> ColonyFoundingWorkflow.Result:
	if _building == null:
		return ColonyFoundingWorkflow.Result.error("Cannot undo: building is null")

	if _building.building_state != Term.BuildingState.NEW:
		return ColonyFoundingWorkflow.Result.error("Cannot undo: building is not in NEW state")

	# Use per-colony undo data instead of workflow context
	if _building._undo_settler_stats == null:
		return ColonyFoundingWorkflow.Result.error("Cannot undo: settler_stats is null (no saved settler data)")

	# -- Create settler using colony's undo data..
	var settler: UnitStats = UnitStats.New_Unit(Term.UnitType.SETTLER, _building._undo_settler_stats.level)
	settler.on_load_data(_building._undo_settler_stats.on_save_data())
	var settler_pos: Vector2 = _building._undo_settler_position
	var settler_unit: Unit = player.create_unit(settler, settler_pos)
	if settler_unit == null:
		# CRITICAL: If settler creation fails, don't remove colony (data loss prevention)
		return ColonyFoundingWorkflow.Result.error("Failed to create settler unit - colony not removed to prevent data loss")

	# -- Remove occupied tiles..
	_building.bm.remove_occupied_tiles(_building.get_tiles())

	# -- Remove colony..
	var remove_result: ColonyFoundingWorkflow.Result = remove_colony(_building)
	if remove_result.is_error():
		# Settler was created but colony removal failed - inconsistent state
		# This is better than losing both, but should log warning
		push_warning("Colony removal failed after settler creation: %s" % remove_result.error_message)
		return remove_result

	_ui_service.close_all_ui()

	# Note: No need to reset workflow here - it's already reset in create_colony()

	return ColonyFoundingWorkflow.Result.ok(settler_unit)

#endregion


#region COLONY PLACEMENT
func can_settle(_tile: Vector2i) -> bool:
	# Check if all tiles in the colony footprint are valid
	# TODO: assumes colony size is 2x2
	var tile_end: Vector2i = _tile + Vector2i(1, 1)

	for x: int in range(_tile.x, tile_end.x + 1):
		for y: int in range(_tile.y, tile_end.y + 1):
			var tile: Vector2i = Vector2i(x, y)

			# Check if tile is land (not water)
			var is_land_tile: bool = Def.get_world_map().is_land_tile(tile)
			if not is_land_tile:
				return false

			# Check if tile is occupied by any existing colony's buildings
			for colony: CenterBuilding in colonies:
				if colony.bm.is_tile_occupied(tile):
					return false

	return true


func found_colony(_tile: Vector2i, _position: Vector2, _stats: UnitStats) -> ColonyFoundingWorkflow.Result:
	# Validate can start new founding
	if not workflow.can_start_founding():
		return ColonyFoundingWorkflow.Result.error("Cannot found colony: already founding (state: %s)" % workflow.get_state_name())

	if _stats == null:
		return ColonyFoundingWorkflow.Result.error("Cannot found colony: settler stats are null")

	# Validate tile is valid for colony
	if not can_settle(_tile):
		return ColonyFoundingWorkflow.Result.error("Cannot found colony: invalid tile (not land or occupied)")

	# Start workflow
	var start_result: ColonyFoundingWorkflow.Result = workflow.start_founding(_tile, _stats, _position)
	if start_result.is_error():
		return start_result

	# Create colony building
	var building: CenterBuilding = _scene_loader.load_building(Term.BuildingType.CENTER)
	if building == null:
		workflow.reset()
		return ColonyFoundingWorkflow.Result.error("Failed to load colony building scene")

	var world_pos: Vector2 = Def.get_world_tile_map().map_to_local(_tile)
	building.global_position = world_pos
	building.player = player
	building.modulate = Color(1, 1, 1, 0.75)

	add_colony(building)

	# -- update occupied tiles..
	building.bm.add_occupied_tiles(building.get_tiles())

	# Set up placement preview
	placement_preview.set_preview(building, _tile)

	# Transition to confirming state
	var confirm_result: ColonyFoundingWorkflow.Result = workflow.begin_confirming()
	if confirm_result.is_error():
		# Rollback colony creation
		remove_colony(building)
		workflow.reset()
		return confirm_result

	_ui_service.open_found_colony_menu(self)
	_focus_service.set_focus_node(building)

	return ColonyFoundingWorkflow.Result.ok(building)


func cancel_found_colony() -> ColonyFoundingWorkflow.Result:
	# Validate state
	if not workflow.is_founding():
		return ColonyFoundingWorkflow.Result.error("Cannot cancel: not in founding state (current: %s)" % workflow.get_state_name())

	if placement_preview.colony == null:
		return ColonyFoundingWorkflow.Result.error("Cannot cancel: placing_colony is null")

	if workflow.context == null or workflow.context.settler_stats == null:
		return ColonyFoundingWorkflow.Result.error("Cannot cancel: settler_stats is null")

	var colony: CenterBuilding = placement_preview.colony

	# Remove occupied tiles first
	colony.bm.remove_occupied_tiles(colony.get_tiles())

	# Create settler BEFORE removing colony (to prevent data loss if creation fails)
	var settler: UnitStats = workflow.context.restore_settler()
	var settler_unit: Unit = player.create_unit(settler, workflow.context.settler_position)

	if settler_unit == null:
		# CRITICAL: Settler creation failed
		# Re-add occupied tiles and keep colony to prevent data loss
		colony.bm.add_occupied_tiles(colony.get_tiles())
		return ColonyFoundingWorkflow.Result.error("Failed to create settler unit - colony preserved to prevent data loss")

	# Now safe to remove colony
	var remove_result: ColonyFoundingWorkflow.Result = remove_colony(colony)
	if remove_result.is_error():
		# Settler exists but colony removal failed - log but continue
		push_warning("Colony removal failed during cancel: %s" % remove_result.error_message)

	# Clear placement preview
	placement_preview.clear_preview()

	# Cancel workflow
	var cancel_result: ColonyFoundingWorkflow.Result = workflow.cancel_founding()
	if cancel_result.is_error():
		return cancel_result

	_ui_service.close_all_ui()

	# Reset workflow
	workflow.reset()

	return ColonyFoundingWorkflow.Result.ok(settler_unit)



#endregion


#region GAME PERSISTENCE
func on_save_data() -> Dictionary:

	# -- Package colonies..
	var colony_data: Array[Dictionary] = []
	for colony: CenterBuilding in get_colonies():
		colony_data.append(colony.on_save_data())

	# -- Package settler data (only if active colony placement)..
	var settler_data: Dictionary = {}
	var settler_position: Vector2 = Vector2.ZERO
	if workflow.context != null and workflow.context.settler_stats != null:
		settler_data = workflow.context.settler_stats.on_save_data()
		settler_position = workflow.context.settler_position

	return {
		"colonies"         : colony_data,
		"settler_position" : settler_position,
		"settler_stats"    : settler_data,
	}


func on_load_data(_data: Dictionary) -> void:

	# -- Load settler data (if applicable) into workflow context..
	var settler_position: Vector2 = _data["settler_position"]
	if not _data["settler_stats"].is_empty():
		var settler_stats: UnitStats = UnitStats.New_Unit(_data["settler_stats"].unit_type, _data["settler_stats"].level)
		settler_stats.on_load_data(_data["settler_stats"])

		# Restore workflow context if there was active founding
		# Note: We need to extract target_tile from somewhere or reconstruct it
		# For now, we'll use a placeholder - this may need improvement
		var target_tile: Vector2i = Vector2i.ZERO  # TODO: May need to save/restore target_tile
		workflow.context = ColonyFoundingWorkflow.ColonyFoundingContext.new(target_tile, settler_stats, settler_position)

	# -- Load colonies..
	for colony_data: Dictionary in _data["colonies"]:
		var building_scene: PackedScene = PreloadsRef.get_building_scene(Term.BuildingType.CENTER)
		var colony: CenterBuilding = building_scene.instantiate() as CenterBuilding
		add_colony(colony)

		colony.on_load_data(colony_data)
		colony.player = player

		#TODO: update biome tilemap layer (remove trees)
		#var start_tile : Vector2i = colony.get_tile()
		#var end_tile   : Vector2i = colony.get_tile_end()
		#Def.get_world_map().clear_biome_tilemap_layer_area(start_tile, end_tile)

	# --
	for colony: CenterBuilding in get_colonies():
		colony.bm.refresh_occupied_tiles()

#endregion
