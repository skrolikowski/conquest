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


## Production implementation using actual game services
class ProductionServices:
	var ui_service: IUIService
	var focus_service: IFocusService
	var scene_loader: ISceneLoader

	func _init() -> void:
		ui_service = ProductionUIService.new()
		focus_service = ProductionFocusService.new()
		scene_loader = ProductionSceneLoader.new()


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
