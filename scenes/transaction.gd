extends Node
class_name Transaction

var resources: Dictionary = {}


func _init() -> void:
	for i:String in Term.ResourceType:
		var resource_type : Term.ResourceType = Term.ResourceType[i]
		resources[resource_type] = 0


func clone() -> Transaction:
	var transaction : Transaction = Transaction.new()
	for i:Term.ResourceType in transaction.resources:
		resources[i] = transaction.resources[i]
	return transaction


func add_resource_amount_by_type(_resource_type: Term.ResourceType, _amount: int) -> void:
	"""
	Add the given resource and amount to the transaction.

	Example:
	```
	var transaction = Transaction.new()
	transaction.add_resource(Term.ResourceType.GOLD, 100)
	```
	"""
	if resources.has(_resource_type):
		resources[_resource_type] += _amount
	else:
		resources[_resource_type] = _amount


func get_resource_amount(_resource_type: Term.ResourceType) -> int:
	return resources[_resource_type]


func add_resources(_resources: Dictionary) -> void:
	"""
	Initialize the transaction with the given resources and amounts.

	Example:
	```
	var transaction = Transaction.new({ "gold" : 100, "wood" : 50 })
	```
	"""
	for i:String in _resources:
		var resource_type : Term.ResourceType = Def._convert_to_resource_type(i)
		var resource_amount : int = _resources[i]
		resources[resource_type] = resource_amount


#func merge_with(_transaction: Transaction) -> void:
	#"""
	#Merge the given resources and amounts with the current transaction.
#
	#Example:
	#```
	#var transaction = Transaction.new({ "gold" : 100, "wood" : 50 })
	#transaction.merge_resources({ "gold" : 50 })
	#```
	#"""
	#for i:String in _transaction.resources:
		#var resource_type : Term.ResourceType = Def._convert_to_resource_type(i)
		#var resource_amount : int = _transaction.resources[i]
#
		#if resources.has(resource_type):
			#resources[resource_type] += resource_amount
		#else:
			#resources[resource_type] = resource_amount
