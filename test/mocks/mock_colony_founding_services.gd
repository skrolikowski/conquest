## Mock implementations of colony founding services for testing
class_name MockColonyFoundingServices
extends RefCounted


## Mock UI service that tracks calls instead of actually opening UI
class MockUIService extends ColonyFoundingServices.IUIService:
	var found_colony_menu_opened: bool = false
	var ui_closed: bool = false
	var last_colony: CenterBuilding = null

	func open_found_colony_menu(colony: CenterBuilding) -> void:
		found_colony_menu_opened = true
		last_colony = colony

	func close_all_ui() -> void:
		ui_closed = true

	func reset() -> void:
		found_colony_menu_opened = false
		ui_closed = false
		last_colony = null

	func was_called(method_name: String) -> bool:
		match method_name:
			"open_found_colony_menu":
				return found_colony_menu_opened
			"close_all_ui":
				return ui_closed
			_:
				return false


## Mock focus service that tracks focus changes
class MockFocusService extends ColonyFoundingServices.IFocusService:
	var focused_node: Node2D = null
	var selection_cleared: bool = false

	func set_focus_node(node: Node2D) -> void:
		focused_node = node

	func clear_selection() -> void:
		selection_cleared = true

	func reset() -> void:
		focused_node = null
		selection_cleared = false


## Mock scene loader that creates test buildings
class MockSceneLoader extends ColonyFoundingServices.ISceneLoader:
	var buildings_loaded: int = 0
	var should_fail: bool = false

	func load_building(type: Term.BuildingType) -> CenterBuilding:
		buildings_loaded += 1

		if should_fail:
			return null

		# Create a minimal CenterBuilding for testing
		var building: CenterBuilding = CenterBuilding.new()
		building.building_type = type
		return building

	func reset() -> void:
		buildings_loaded = 0
		should_fail = false


## Container for all mock services
class MockServices:
	var ui_service: MockUIService
	var focus_service: MockFocusService
	var scene_loader: MockSceneLoader

	func _init() -> void:
		ui_service = MockUIService.new()
		focus_service = MockFocusService.new()
		scene_loader = MockSceneLoader.new()

	func reset_all() -> void:
		ui_service.reset()
		focus_service.reset()
		scene_loader.reset()
