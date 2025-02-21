extends Node2D
class_name Bank

var resources      : Dictionary = {}
var consuming      : Dictionary = {}
var trading 	   : Dictionary = {}
var next_resources : Dictionary = {}


func _init() -> void:
	for i:String in Term.ResourceType:
		var type : Term.ResourceType = Term.ResourceType[i]
		resources[type]      = 0
		consuming[type]      = 0
		trading[type]        = 0
		next_resources[type] = 0


#region AFFORDANCE MANAGEMENT
func can_afford_this_turn(transaction: Transaction) -> bool:
	if Def.WEALTH_MODE_ENABLED:
		return true

	# --
	for type:Term.ResourceType in transaction.resources:
		var amount : int = transaction.resources[type]
		if not can_afford_resource_this_turn(type, amount):
			return false
	return true


func can_afford_next_turn(transaction: Transaction) -> bool:
	if Def.WEALTH_MODE_ENABLED:
		return true

	# --
	for type:Term.ResourceType in transaction.resources:
		var amount : int = transaction.resources[type]
		if not can_afford_resource_next_turn(type, amount):
			return false
	return true

#func can_afford(transaction: Transaction) -> bool:
	#for type:Term.ResourceType in transaction.resources:
		#var amount : int = transaction.resources[type]
		#if not can_afford_resource(type, amount):
			#return false
	#return true


func can_afford_resource_next_turn(_resource_type: Term.ResourceType, _amount: int) -> bool:
	if Def.WEALTH_MODE_ENABLED:
		return true
	return get_next_resource_value(_resource_type) >= _amount


func can_afford_resource_this_turn(_resource_type: Term.ResourceType, _amount: int) -> bool:
	if Def.WEALTH_MODE_ENABLED:
		return true
	return get_resource_value(_resource_type) >= _amount

#endregion


#region RESOURCE MANAGEMENT
func get_resource_value(resource_type: Term.ResourceType) -> int:
	return resources[resource_type]


func get_next_resource_value(resource_type: Term.ResourceType) -> int:
	return next_resources[resource_type]


func set_resource_value(resource_type: Term.ResourceType, amount: int) -> void:
	resources[resource_type] = amount


func set_resources(transaction: Transaction) -> void:
	for type:Term.ResourceType in transaction.resources:
		set_resource_value(type, transaction.resources[type])


func set_next_resource_value(resource_type: Term.ResourceType, amount: int) -> void:
	next_resources[resource_type] = amount


func set_next_resources(transaction: Transaction) -> void:
	for type:Term.ResourceType in transaction.resources:
		set_next_resource_value(type, transaction.resources[type])

#endregion


#region CONSUMING
func get_consuming_value(resource_type: Term.ResourceType) -> int:
	return consuming[resource_type]


func set_consuming_value(resource_type: Term.ResourceType, value: int) -> void:
	consuming[resource_type] = value

func consume_purchase(transaction: Transaction) -> void:
	for type:Term.ResourceType in transaction.resources:
		var amount : int = transaction.resources[type]
		consuming[type] -= amount
		
func consume_credit(transaction: Transaction) -> void:
	for type:Term.ResourceType in transaction.resources:
		var amount : int = transaction.resources[type]
		consuming[type] += amount
#endregion


#region TRADING
func get_trading_value(resource_type: Term.ResourceType) -> int:
	return trading[resource_type]

func set_trading_value(resource_type: Term.ResourceType, value: int) -> void:
	trading[resource_type] = value
#endregion


func resource_purchase(transaction: Transaction) -> void:
	if Def.WEALTH_MODE_ENABLED:
		return

	# --
	for type:Term.ResourceType in transaction.resources:
		var amount : int = transaction.resources[type]
		resources[type] -= amount


func resource_credit(transaction: Transaction) -> void:
	if Def.WEALTH_MODE_ENABLED:
		return

	# --
	for type:Term.ResourceType in transaction.resources:
		var amount : int = transaction.resources[type]
		resources[type] += amount


func commit() -> void:
	for i:String in Term.ResourceType:
		var type : Term.ResourceType = Term.ResourceType[i]
		resources[type] += next_resources[type]
		consuming[type] = 0
		trading[type]   = 0
