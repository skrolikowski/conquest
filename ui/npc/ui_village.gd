extends PanelContainer
class_name UIVillage

@onready var btn_close  : Button = %BtnClose as Button

var npc     : NPC
var village : Village : set = _set_village


func _ready() -> void:
	btn_close.connect("pressed", _on_close_pressed)


func _set_village(_village: Village) -> void:
	npc     = _village.npc
	village = _village
	
	# --
	%VillageTitle.text    = npc.title + " Village"
	%PopulationValue.text = str(village.population)
	%VillagesValue.text   = str(npc.get_village_count())
	
	# -- Health..
	if village.health >= 0.8:
		%HealthValue.text = "Great"
	elif village.health >= 0.6:
		%HealthValue.text = "Good"
	elif village.health >= 0.4:
		%HealthValue.text = "Mediocre"
	else:
		%HealthValue.text = "Poor"
	
	# -- Relationship..
	var relationship : int = npc.get_diplomacy_with_player()
	if relationship > 7:
		%Relationship.text = "Friendly"
	elif village.population > 4:
		%Relationship.text = "Neutral"
	else:
		%Relationship.text = "Hostile"

	# -- Army size..
	if village.army_size == Village.ArmySize.NONE:
		%ArmySize.text = "None"
	elif village.army_size == Village.ArmySize.SM:
		%ArmySize.text = "Small"
	elif village.army_size == Village.ArmySize.MD:
		%ArmySize.text = "Medium"
	else:
		%ArmySize.text = "Large"


func _on_close_pressed() -> void:
	Def.get_world_canvas().close_all_ui()
