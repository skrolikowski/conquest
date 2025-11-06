extends Node2D
class_name DefinitionsRef


#region SERVICE LOCATOR (REFACTOR PHASE 5)
## DEPRECATED: These methods use the Service Locator anti-pattern.
## They are maintained for backward compatibility but should be migrated away from.
##
## Recommended migration path:
##   1. Use dependency injection (pass references via @export or constructor)
##   2. Use signals for communication between loosely coupled systems
##   3. Access WorldService directly if service locator is truly needed
##
## These methods now delegate to WorldService which caches the lookups for performance.

func get_world_canvas() -> WorldCanvas:
	return WorldService.get_world_canvas()


func get_world() -> WorldManager:
	return WorldService.get_world()


func get_world_selector() -> WorldSelector:
	return WorldService.get_world_selector()


func get_world_map() -> WorldGen:
	return WorldService.get_world_map()


func get_player_manager() -> PlayerManager:
	return WorldService.get_player_manager()


func get_world_tile_map() -> TileMapLayer:
	return WorldService.get_world_tile_map()

#endregion

func _convert_to_transaction(_resources: Dictionary) -> Transaction:
	var transaction:Transaction = Transaction.new()
	transaction.add_resources(_resources)
	return transaction


#region PRODUCTION
"""
Specialisation bonuses are based on building-level-grid-squares 
(ie: farms are worth 4 points per building level), in blocks of 20: the 
first block is worth 1% each, the next block is worth a 0.5% each, the 
next block of 20 is worth 0.25% each, such that you asymptotically 
approach 40% total possible bonus.  Once this bonus is calculated for 
the largest commodity sector in your colony, the bonus value of the 
SECOND largest commodity is subtracted from the first. As you can see by 
how the numbers start high and then shrink, even having 10 building 
levels of another commodity reduces your possible maximum to 30%.
	Bonuses are calculated for mills, mines (gold and metal lumped 
together), and farms.  Commerce does not gain production bonuses.
"""
#endregion
