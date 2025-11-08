extends Node2D
class_name WorldManager

## WorldManager - Scene container for the game world
##
## After Phase 3, this is a pure scene container managing visual/UI components.
##
## Responsibilities:
## - Scene tree management (camera, canvas, world gen, selector)
## - Signal connections for UI events (camera zoom, etc.)
##
## NOT Responsible For (handled by GameSession):
## - Turn management (begin_turn, end_turn)
## - Service creation (TurnOrchestrator, FocusService)
## - Game lifecycle (start_new_game, load_game, save_game)
## - Focus management (cursor updates, tile selection)
##
## Note: In DEBUG_MODE, can be used standalone for quick scene testing.

@onready var world_selector := $WorldSelector as WorldSelector
@onready var world_camera   := %WorldCamera as WorldCamera
@onready var world_gen      := %WorldGen as WorldGen
@onready var world_canvas   := %WorldCanvas as CanvasLayer


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

#endregion
