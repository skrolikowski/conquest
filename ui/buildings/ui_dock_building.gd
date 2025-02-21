extends UIBuilding
class_name UIDockBuilding

@onready var construct_ship : CheckBox = %ConstructShip as CheckBox


func _ready() -> void:
	construct_ship.connect("toggled", _on_construct_ship_toggled)


func _set_building(_building: Building) -> void:
	super._set_building(_building)
	
	
	# -- Dock Building Data
	_building = _building as DockBuilding

	var unit_count    : int = building.colony.get_ship_unit_count()
	var unit_capacity : int = building.colony.get_max_ship_unit_count()
	%ShipCountValue.text = "Ship Count: " + str(unit_count) + "/" + str(unit_capacity)
	
	# -- Construct Ship
	construct_ship.disabled = not _building.can_construct_ship()


func refresh_ui() -> void:
	super.refresh_ui()

	construct_ship.disabled = not building.can_construct_ship()


func _on_construct_ship_toggled(toggled_on : bool) -> void:
	# building = building as DockBuilding

	if toggled_on:
		building.construct_ship = true
		building.building_state = Term.BuildingState.TRAIN
	else:
		building.construct_ship = false
		building.building_state = Term.BuildingState.ACTIVE
		
	refresh_ui()
