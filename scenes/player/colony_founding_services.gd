## Service interfaces for colony founding system
## Enables dependency injection and testability
class_name ColonyFoundingServices
extends RefCounted

## Interface for UI operations during colony founding
class IUIService extends RefCounted:
	## Open the colony founding menu with the given colony
	func open_found_colony_menu(_colony_manager: ColonyManager) -> void:
		push_error("IUIService.open_found_colony_menu() not implemented")

	## Close all UI panels
	func close_all_ui() -> void:
		push_error("IUIService.close_all_ui() not implemented")


## Interface for focus/selection management
class IFocusService extends RefCounted:
	## Set focus on the given node
	func set_focus_node(_node: Node2D) -> void:
		push_error("IFocusService.set_focus_node() not implemented")

	## Clear current selection
	func clear_selection() -> void:
		push_error("IFocusService.clear_selection() not implemented")


## Interface for scene loading operations
class ISceneLoader extends RefCounted:
	## Load a building scene by type
	func load_building(_type: Term.BuildingType) -> CenterBuilding:
		push_error("ISceneLoader.load_building() not implemented")
		return null


## Interface for world map operations
class IWorldMap extends RefCounted:
	## Convert tile coordinates to world position
	func tile_to_world(_tile: Vector2i) -> Vector2:
		push_error("IWorldMap.tile_to_world() not implemented")
		return Vector2.ZERO

	## Check if a tile is valid for colony placement
	func is_valid_colony_tile(_tile: Vector2i) -> bool:
		push_error("IWorldMap.is_valid_colony_tile() not implemented")
		return false


## Production implementation using actual game services
class ProductionServices:
	var ui_service: IUIService
	var focus_service: IFocusService
	var scene_loader: ISceneLoader
	var world_map: IWorldMap

	func _init() -> void:
		ui_service = ProductionUIService.new()
		focus_service = ProductionFocusService.new()
		scene_loader = ProductionSceneLoader.new()
		world_map = ProductionWorldMap.new()


## Production UI service using WorldCanvas
class ProductionUIService extends IUIService:
	func open_found_colony_menu(_colony_manager: ColonyManager) -> void:
		WorldService.get_world_canvas().open_found_colony_menu(_colony_manager)

	func close_all_ui() -> void:
		WorldService.get_world_canvas().close_all_ui()


## Production focus service using WorldManager
class ProductionFocusService extends IFocusService:
	func set_focus_node(node: Node2D) -> void:
		Def.get_world().focus_service.set_focus_node(node)

	func clear_selection() -> void:
		Def.get_world_selector().clear_selection()


## Production scene loader using Preloads
class ProductionSceneLoader extends ISceneLoader:
	func load_building(type: Term.BuildingType) -> CenterBuilding:
		var scene: PackedScene = PreloadsRef.get_building_scene(type)
		return scene.instantiate() as CenterBuilding


## Production world map using TileMap
class ProductionWorldMap extends IWorldMap:
	func tile_to_world(tile: Vector2i) -> Vector2:
		return Def.get_world_tile_map().map_to_local(tile)

	func is_valid_colony_tile(tile: Vector2i) -> bool:
		# Check if tile is on land (not water)
		var world_gen: WorldGen = Def.get_world_map()
		if not world_gen.tile_heights.has(tile):
			return false

		var height: float = world_gen.tile_heights[tile]
		# Height > -0.01 means land
		return height > -0.01
