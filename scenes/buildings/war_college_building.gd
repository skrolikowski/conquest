extends Building
class_name WarCollegeBuilding


var gold_values : Dictionary = {}


func _ready() -> void:
	super._ready()
	
	title = "War College"
	
	building_type = Term.BuildingType.WAR_COLLEGE
	building_size = Term.BuildingSize.LARGE
	
	gold_values = {
		Term.MilitaryResearch.OFFENSIVE: {
			Term.UnitType.INFANTRY: { "gold": 0, "status": Term.ResearchStatus.NONE },
			Term.UnitType.CALVARY: { "gold": 0, "status": Term.ResearchStatus.NONE },
			Term.UnitType.ARTILLARY: { "gold": 0, "status": Term.ResearchStatus.NONE },
		},
		Term.MilitaryResearch.DEFENSIVE: {
			Term.UnitType.INFANTRY: { "gold": 0, "status": Term.ResearchStatus.NONE },
			Term.UnitType.CALVARY: { "gold": 0, "status": Term.ResearchStatus.NONE },
			Term.UnitType.ARTILLARY: { "gold": 0, "status": Term.ResearchStatus.NONE },
		},
		Term.MilitaryResearch.LEADERSHIP: {
			Term.UnitType.LEADER: { "gold": 0, "status": Term.ResearchStatus.NONE },
		}
	}


func commit_military_research() -> void:
	for research_type:Term.MilitaryResearch in gold_values:
		for unit_type:Term.UnitType in gold_values[research_type]:
			var gold   : float = gold_values[research_type][unit_type]["gold"]
			var status : Term.ResearchStatus = gold_values[research_type][unit_type]["status"]
			
			# -- Check for research requests..
			if status == Term.ResearchStatus.ONE_TIME || status == Term.ResearchStatus.PER_TURN:

				# -- Check if we can afford the research..
				if colony.can_afford_resource_this_turn(Term.ResourceType.GOLD, gold):
					#TODO: have colony commit gold and update military research updates
					colony.train_military_research(research_type, unit_type, gold)
					
					# -- One 'n done, set back to suspended..
					if status == Term.ResearchStatus.ONE_TIME:
						gold_values[research_type][unit_type]["status"] = Term.ResearchStatus.SUSPENDED
				else:
					# -- Not enough gold, set back to suspended..
					gold_values[research_type][unit_type]["status"] = Term.ResearchStatus.SUSPENDED


