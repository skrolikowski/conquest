extends Node
class_name WeightedTable

var items      : Array[Dictionary] = []
var weight_sum : int = 0


func add_item(_item: Object, _weight: int) -> void:
	items.append({ "item" : _item, "weight": _weight })
	weight_sum += _weight


func pick_item() -> Object:
	var chosen_weight : int = randi_range(1, weight_sum)
	var iteration_sum : int = 0
	for item in items:
		iteration_sum += item["weight"]
		if chosen_weight <= iteration_sum:
			return item.item
	return null
 
