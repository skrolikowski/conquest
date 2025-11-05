extends PanelContainer
class_name UIBuildBuilding

const TypeRegistry = preload("res://scripts/type_registry.gd")
const GameRules = preload("res://scripts/game_rules.gd")

@onready var btn_close : Button = %BtnClose as Button

var colony : CenterBuilding : set = _set_colony


func _set_colony(_building: CenterBuilding) -> void:
	colony = _building


func _ready() -> void:
	btn_close.connect("pressed", _on_close_pressed)

	# -- Gather building types..
	var building_types : Array[Term.BuildingType] = []
	for i: String in Term.BuildingType:
		building_types.append(Term.BuildingType[i])

	building_types.sort_custom(GameRules.sort_building_types_by_priority)

	# --
	for building_type: Term.BuildingType in building_types:
		if building_type == Term.BuildingType.NONE or building_type == Term.BuildingType.CENTER:
			continue
			
		create_button(building_type)


func create_button(_building_type : Term.BuildingType) -> void:
	var build_button : Button = Button.new()
	build_button.text = TypeRegistry.building_type_to_name(_building_type)
	
	var build_cost : Transaction = GameData.get_building_cost(_building_type)
	if colony.bank.can_afford_this_turn(build_cost):
		build_button.connect("pressed", _on_button_pressed.bind(_building_type))
	else:
		build_button.disabled = true
	
	build_button.connect("mouse_entered", _on_button_entered.bind(_building_type))
	build_button.connect("mouse_exited", _on_button_exited)
	
	%BuildingButtons.add_child(build_button)


func _on_button_pressed(_building_type: Term.BuildingType) -> void:
	colony.create_building(_building_type)

	Def.get_world_canvas().close_sub_ui(self)


func _on_button_entered(_building_type: Term.BuildingType) -> void:
	Def.get_world_canvas().update_status(Print.build_building_type(_building_type))


func _on_button_exited() -> void:
	Def.get_world_canvas().clear_status()


func _on_close_pressed() -> void:
	Def.get_world_canvas().close_sub_ui(self)
