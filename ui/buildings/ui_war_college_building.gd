extends PanelContainer
class_name UIWarCollegeBuilding

var building       : WarCollegeBuilding : set = _set_building
var building_state : Term.BuildingState


func _ready() -> void:
	%BuildingDemolish.connect("toggled", _on_building_demolish_toggled)
	
	%OffensiveInfantryGoldValue.connect("value_changed", _on_gold_value_changed.bind(Term.MilitaryResearch.OFFENSIVE, Term.UnitType.INFANTRY))
	%OffensiveInfantryGoldStatus.connect("item_selected", _on_gold_status_selected.bind(Term.MilitaryResearch.OFFENSIVE, Term.UnitType.INFANTRY))
	#TODO: copilot autocomplete
	

func _set_building(_building: WarCollegeBuilding) -> void:
	building = _building
	building_state = building.building_state
	
	%BuildingTitle.text = building.title
	%ColonyTitle.text   = "Colony:" + building.colony.title

	%BuildingDemolish.disabled = not building.can_demolish()

	# -- Military Research
	var research : Dictionary = building.colony.military_research
	
	# -- Offensive Research..
	var off_infantry_level      : int = research[Term.MilitaryResearch.OFFENSIVE][Term.UnitType.INFANTRY]["level"]
	var off_infantry_max_level  : int = Def.get_research_max_exp_by_level(off_infantry_level)
	var off_infantry_exp        : int = research[Term.MilitaryResearch.OFFENSIVE][Term.UnitType.INFANTRY]["exp"]
	var off_calvary_level       : int = research[Term.MilitaryResearch.OFFENSIVE][Term.UnitType.CALVARY]["level"]
	var off_calvary_max_level   : int = Def.get_research_max_exp_by_level(off_calvary_level)
	var off_calvary_exp         : int = research[Term.MilitaryResearch.OFFENSIVE][Term.UnitType.CALVARY]["exp"]
	var off_artillary_level     : int = research[Term.MilitaryResearch.OFFENSIVE][Term.UnitType.ARTILLARY]["level"]
	var off_artillary_max_level : int = Def.get_research_max_exp_by_level(off_artillary_level)
	var off_artillary_exp       : int = research[Term.MilitaryResearch.OFFENSIVE][Term.UnitType.ARTILLARY]["exp"]
	
	# -- Defensive Research..
	var def_infantry_level      : int = research[Term.MilitaryResearch.DEFENSIVE][Term.UnitType.INFANTRY]["level"]
	var def_infantry_max_level  : int = Def.get_research_max_exp_by_level(def_infantry_level)
	var def_infantry_exp        : int = research[Term.MilitaryResearch.DEFENSIVE][Term.UnitType.INFANTRY]["exp"]
	var def_calvary_level       : int = research[Term.MilitaryResearch.DEFENSIVE][Term.UnitType.CALVARY]["level"]
	var def_calvary_max_level   : int = Def.get_research_max_exp_by_level(def_calvary_level)
	var def_calvary_exp         : int = research[Term.MilitaryResearch.DEFENSIVE][Term.UnitType.CALVARY]["exp"]
	var def_artillary_level     : int = research[Term.MilitaryResearch.DEFENSIVE][Term.UnitType.ARTILLARY]["level"]
	var def_artillary_max_level : int = Def.get_research_max_exp_by_level(def_artillary_level)
	var def_artillary_exp       : int = research[Term.MilitaryResearch.DEFENSIVE][Term.UnitType.ARTILLARY]["exp"]
	
	# -- Leader Research..
	var leader_level     : int = research[Term.MilitaryResearch.LEADERSHIP][Term.UnitType.LEADER]["level"]
	var leader_max_level : int = Def.get_research_max_exp_by_level(leader_level)
	var leader_exp       : int = research[Term.MilitaryResearch.LEADERSHIP][Term.UnitType.LEADER]["exp"]

	%OffensiveInfantryGoldStatus.disabled = off_infantry_level >= Def.get_research_max_level()
	#TODO: copilot autocomplete
	
	%OffensiveInfantryLevel.text = str(off_infantry_level)
	%OffensiveInfantryExp.text = str(off_infantry_exp) + "/" + str(off_infantry_max_level)
	#TODO: copilot autocomplete


func _on_building_demolish_toggled(toggled_on:bool) -> void:
	if toggled_on:
		building.building_state = Term.BuildingState.SELL
		#TODO: suspend all research
	else:
		building.building_state = building_state


func _on_gold_value_changed(_value: float, _research_type: Term.MilitaryResearch, _unit_type: Term.UnitType) -> void:
	building.gold_values[_research_type][_unit_type]["gold"] = _value

	
func _on_gold_status_selected(_index: int, _research_type: Term.MilitaryResearch, _unit_type: Term.UnitType) -> void:
	if _index >= 0:
		building.gold_values[_research_type][_unit_type]["status"] = _index + 1
	else:
		building.gold_values[_research_type][_unit_type]["status"] = Term.ResearchStatus.NONE
