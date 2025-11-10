extends Node2D
class_name WorldManager

## WorldManager - Scene container for the game world
##
## After Phase 3, this is a pure scene container managing visual/UI components.
##
## Responsibilities:
## - Scene tree management (camera, canvas, world gen, selector)
## - Signal connections for UI events (camera zoom, etc.)
## - Focus UI updates (cursor visualization, status display)
##
## NOT Responsible For (handled by GameSession):
## - Turn management (begin_turn, end_turn)
## - Service creation (TurnOrchestrator, FocusService)
## - Game lifecycle (start_new_game, load_game, save_game)
## - Focus state management (handled by FocusService)

@onready var world_selector := $WorldSelector as WorldSelector
@onready var world_camera   := %WorldCamera as WorldCamera
@onready var world_gen      := %WorldGen as WorldGen
@onready var world_canvas   := %WorldCanvas as CanvasLayer

var focus_service: FocusService = null  # Injected by GameSession


func _ready() -> void:
	_initialize_scene_components()
	_connect_signals()

	# Initialize global FogOfWarService (autoload singleton)
	# Note: This is a one-time setup per WorldManager, not per session
	FogOfWarService.initialize(world_gen, Preload.C.FOG_OF_WAR_ENABLED)


#region WORLD INITIALIZATION
func _initialize_scene_components() -> void:
	"""
	Initialize scene tree components (camera, canvas, etc.)
	"""
	# WorldCamera
	assert(world_camera != null, "WorldCamera node is missing!")
	world_camera.reset()


func _connect_signals() -> void:
	"""
	Connect WorldCanvas signals (these don't depend on services)
	"""
	# WorldCanvas signals
	# Note: "end_turn" is now connected by GameSession
	world_canvas.connect("camera_zoom", world_camera.change_zoom)


func connect_focus_signals(_focus_service: FocusService) -> void:
	"""
	Connect FocusService signals to update UI.

	Called by GameSession after creating FocusService.
	Delegates UI updates to WorldManager (presentation layer).
	"""
	focus_service = _focus_service
	focus_service.connect("focus_tile_changed", _on_focus_tile_changed)
	focus_service.connect("focus_node_changed", _on_focus_node_changed)

#endregion


#region FOCUS UI UPDATES

func _on_focus_tile_changed(tile: Vector2i, _previous_tile: Vector2i) -> void:
	"""Handle tile focus changes - update cursor and UI"""
	# Update cursor visualization
	world_gen.clear_cursor_tiles()
	if focus_service.current_node == null:
		world_gen.set_cursor_tile(tile)

	# Update tile status in UI
	var tile_info: Dictionary = focus_service.get_tile_info(tile)
	world_canvas.update_tile_focus(tile_info)


func _on_focus_node_changed(node: Node, _previous_node: Node) -> void:
	"""Handle node focus changes - update status display"""
	if node != null:
		if node is Building:
			var building: Building = node as Building
			var info: String = building.get_status_information(focus_service.current_tile)
			world_canvas.update_status(info)
	else:
		# No node focused - show basic tile info
		var status_text: PackedStringArray = PackedStringArray()
		status_text.append("Tile: " + str(focus_service.current_tile))
		world_canvas.update_status(Preload.C.STATUS_SEP.join(status_text))

#endregion
