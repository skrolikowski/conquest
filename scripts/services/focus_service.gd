extends Node
class_name FocusService

## Service for managing cursor, tile, and node focus state
## Centralizes focus logic to keep it out of WorldManager

signal focus_tile_changed(tile: Vector2i, previous_tile: Vector2i)
signal focus_node_changed(node: Node, previous_node: Node)

var current_tile: Vector2i
var current_node: Node

# Injected dependencies
var world_gen: WorldGen


func set_focus_tile(_tile: Vector2i) -> void:
	if current_tile != _tile:
		var prev : Vector2i = current_tile
		current_tile = _tile
		focus_tile_changed.emit(_tile, prev)


func set_focus_node(_node: Node) -> void:
	if current_node != _node:
		var prev: Node = current_node
		current_node = _node
		focus_node_changed.emit(_node, prev)


func get_tile_info(tile: Vector2i) -> Dictionary:
	"""
	Centralize tile introspection - returns all relevant data about a tile
	"""
	var info := {
		"position": tile,
		"height": 0.0,
		"modifiers": {}
	}

	if world_gen:
		info["height"] = world_gen.get_tile_height(tile)
		info["modifiers"] = world_gen.get_terrain_modifier_by_industry_type(tile)

	return info
