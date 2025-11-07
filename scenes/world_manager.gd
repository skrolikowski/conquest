extends Node2D
class_name WorldManager

@onready var world_selector := $WorldSelector as WorldSelector
@onready var world_camera   := %WorldCamera as WorldCamera
@onready var world_gen      := %WorldGen as WorldGen
@onready var world_canvas   := %WorldCanvas as CanvasLayer

# Service instances (created programmatically)
var turn_orchestrator: TurnOrchestrator = null
var focus_service: FocusService = null


func _ready() -> void:
	world_camera.reset()

	world_gen.connect("map_loaded", _on_map_loaded)
	world_canvas.connect("end_turn", _on_end_turn)
	world_canvas.connect("camera_zoom", world_camera.change_zoom)

	# Initialize FogOfWarService
	FogOfWarService.initialize(world_gen, Preload.C.FOG_OF_WAR_ENABLED)

	# Initialize FocusService
	focus_service = FocusService.new()
	focus_service.world_gen = world_gen
	add_child(focus_service)

	# Connect FocusService signals
	focus_service.connect("focus_tile_changed", _on_focus_tile_changed)
	focus_service.connect("focus_node_changed", _on_focus_node_changed)

	# Connect WorldSelector signals to FocusService
	world_selector.connect("cursor_updated", _on_cursor_updated)
	world_selector.connect("node_selected", focus_service.set_focus_node)

	# Initialize TurnOrchestrator
	turn_orchestrator = TurnOrchestrator.new()
	add_child(turn_orchestrator)

	# --
	# print("[WorldManager] New Game")
	#Persistence.new_game()
	# print("[WorldManager] Load Game")
	Persistence.load_game()


func _on_map_loaded() -> void:
	print("[WorldManager] Map Loaded")

	if Persistence.is_new_game:
		turn_orchestrator.new_game()
	else:
		var game_data : Dictionary = Persistence.load_section(Persistence.SECTION.GAME)
		on_load_data(game_data)

		var camera_data : Dictionary = Persistence.load_section(Persistence.SECTION.CAMERA)
		world_camera.on_load_data(camera_data)

		var player_data : Dictionary = Persistence.load_section(Persistence.SECTION.PLAYER)
		turn_orchestrator.on_load_data(player_data)


#region FOCUS MANAGEMENT
func _on_cursor_updated(_cursor_position: Vector2) -> void:
	"""Handle cursor movement - update focused tile"""
	var tile_coords: Vector2i = world_gen.get_local_to_map_position(_cursor_position)
	focus_service.set_focus_tile(tile_coords)


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


#region TURN MANAGEMENT
func begin_turn() -> void:
	print("[WorldManager] Begin Turn")

	# Update canvas with current turn from orchestrator
	world_canvas.turn_number = turn_orchestrator.current_turn
	world_canvas.refresh_current_ui()

	# Delegate to TurnOrchestrator
	turn_orchestrator.begin_turn()


func end_turn() -> void:
	print("[WorldManager] End Turn")

	# Delegate to TurnOrchestrator (which will call begin_turn automatically)
	turn_orchestrator.end_turn()


func _on_end_turn() -> void:
	print("[NOTE] End Turn")

	world_canvas.close_all_ui()

	# Delegate to turn system
	end_turn()

#endregion


#region GAME PERSISTENCE
func on_save_data() -> Dictionary:
	return {
		"turn_number": turn_orchestrator.current_turn,
	}


func on_load_data(_data: Dictionary) -> void:
	# Turn number is loaded by TurnOrchestrator
	pass

#endregion
