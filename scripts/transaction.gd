extends RefCounted
class_name Transaction
## Resource transaction container with automatic memory management
##
## Transaction is a RefCounted object (not a Node) for efficient memory handling.
## Instances are automatically freed when no longer referenced.


var resources: Dictionary = {}


func _init() -> void:
	for i:String in Term.ResourceType:
		var resource_type : Term.ResourceType = Term.ResourceType[i]
		resources[resource_type] = 0


func clone() -> Transaction:
	var transaction : Transaction = Transaction.new()
	for i:Term.ResourceType in transaction.resources:
		transaction.resources[i] = resources[i]
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


func add_transaction(_transaction: Transaction) -> void:
	"""
	Add the resources and amounts from another transaction to this one.

	Example:
	```
	var transaction1 = Transaction.new()
	transaction1.add_resource(Term.ResourceType.GOLD, 100)

	var transaction2 = Transaction.new()
	transaction2.add_resource(Term.ResourceType.GOLD, 50)

	transaction1.add_transaction(transaction2)
	```
	"""
	for i:Term.ResourceType in _transaction.resources:
		var resource_amount : int = _transaction.resources[i]

		if resources.has(i):
			resources[i] += resource_amount
		else:
			resources[i] = resource_amount


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
		var resource_type : Term.ResourceType = PreloadsRef.TR.resource_type_from_code(i)
		var resource_amount : int = _resources[i]
		resources[resource_type] = resource_amount

func cleanup() -> void:
	resources.clear()


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


#region GAME PERSISTENCE
func on_save_data() -> Dictionary:
	return resources

func on_load_data(_data: Dictionary) -> void:
	resources = _data

#endregion
