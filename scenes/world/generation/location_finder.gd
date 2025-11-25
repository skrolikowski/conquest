## Location finder for optimal building placement
##
## Provides algorithms for finding optimal locations for:
## - Colony centers (ocean access, balanced resources)
## - Farms (high farm modifiers)
## - Mines (high mine modifiers)
## - Mills (high mill modifiers)
## - Docks (shore/river access)
##
## Uses scoring system with randomization to avoid always picking the same location.
extends RefCounted
class_name LocationFinder


## Reference to WorldGen for tile data
var world_gen: WorldGen


func _init(_world_gen: WorldGen) -> void:
	world_gen = _world_gen


#region COLONY LOCATION

func _has_valid_colony_footprint(_tile: Vector2i) -> bool:
	# var tile_pos : Vector2 = world_gen.get_map_to_local_position(_tile)
	# world_gen.get_land_layer().local_to_map(tile_pos - get_size() * 0.5)

	# Colony center requires 2x2 footprint on land and unoccupied
	var footprint_tiles : Array[Vector2i] = [
		_tile + Vector2i(0, 0),  # Top-left
		_tile + Vector2i(1, 0),  # Right
		_tile + Vector2i(0, 1),  # Down
		_tile + Vector2i(1, 1),  # Diagonal
	]
	
	for footprint_tile: Vector2i in footprint_tiles:
		
		# Check if tile data exists
		if not world_gen.tile_custom_data.has(footprint_tile):
			return false
		
		var tile_data: TileCustomData = world_gen.tile_custom_data[footprint_tile]

		if not world_gen.is_land_tile(footprint_tile):
			return false
	
		# Check if occupied
		elif tile_data.is_occupied():
			return false

	return true


func _find_colony_location_candidates(_colony_level: int = 1) -> Array[Dictionary]:
	var build_radius        : int = GameData.get_building_stat(Term.BuildingType.CENTER, _colony_level).build_radius
	var build_radius_pixels : float = build_radius * Preload.C.TILE_SIZE.x
	var candidates          : Array[Dictionary] = []

	# CenterBuilding requires 2x3 footprint that fits on land..
	for tile: Vector2i in world_gen.get_land_tiles():
		var build_pos           : Vector2 = world_gen.get_map_to_local_position(tile)
		var build_tiles         : Array[Vector2i] = world_gen.get_tiles_in_radius(build_pos, build_radius_pixels)
		var has_valid_footprint : bool = _has_valid_colony_footprint(tile)
		
		if has_valid_footprint && _validate_colony_has_sufficient_build_radius(tile, build_tiles):
			candidates.append({
				"tile": tile,
				"build_tiles": build_tiles,
				"build_radius": build_radius,
				"build_radius_pixels": build_radius_pixels
			})

	return candidates

## Find optimal colony location with ocean/river access
##
## Requirements:
## 1. Colony center on land tile
## 2. 2x2 footprint fits on land
## 3. Sufficient buildable land within build_radius
## 4. At least one shore/river tile in build_radius for dock
## 5. Balanced terrain modifiers preferred
##
## Returns a random selection from top-scored candidates to add variety.
func find_optimal_colony_location(_colony_level:int = 1) -> Vector2i:
	var candidates        : Array[Dictionary] = []
	var scored_candidates : Array[Dictionary] = []

	"""
	Pass:
		Gather any candidates that are land tiles with valid footprint
		and sufficient buildable land.
	"""
	candidates = _find_colony_location_candidates(_colony_level)

	"""
	Fallback:
		If still no candidates, return random starting tile
	"""
	if candidates.is_empty():
		push_error("Could not find any valid colony location with 2x2 footprint")
		return world_gen.get_random_starting_tile()

	"""
	Scoring:
		Score each candidate based on:
		- Ocean/river access within build_radius
		- Terrain modifiers (farm/mine/mill)
		- Biome bonuses
	"""
	# Score each candidate using cached build_tiles
	for candidate: Dictionary in candidates:
		var score: float = _score_colony_location(candidate)
		if score > 0:
			scored_candidates.append({"tile": candidate.tile, "score": score})

	"""
	Fallback #2:
		If no scored candidates, return random starting tile
	"""
	if scored_candidates.is_empty():
		push_error("Could not find optimal colony location, using fallback")
		return world_gen.get_random_starting_tile()

	# Sort by score (highest first)
	scored_candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.score > b.score
	)

	# Select from top candidates with weighted randomness
	var selected_tile: Vector2i = select_random_top_candidate(scored_candidates, 0.2)

	print("Found optimal colony location at %s with score %.1f (from %d candidates)" % [
		selected_tile,
		_get_score_for_tile(scored_candidates, selected_tile),
		scored_candidates.size()
	])

	return selected_tile


func _score_colony_ocean_access(_candidate: Dictionary) -> float:
	var score       : float = 0.0
	var colony_tile : Vector2i = _candidate.tile
	var colony_pos  : Vector2 = world_gen.get_map_to_local_position(colony_tile)

	# Find ocean access tiles and calculate distance from colony center
	for build_tile: Vector2i in _candidate.build_tiles:
		var tile_data: TileCustomData = world_gen.tile_custom_data.get(build_tile)
		if tile_data == null:
			continue

		# --
		# Check for ocean access (Dock Access)
		if tile_data.is_river and world_gen.has_ocean_access_tile(build_tile) or tile_data:
			var build_tile_pos : Vector2 = world_gen.get_map_to_local_position(build_tile)
			var distance_from_colony : float = colony_pos.distance_to(build_tile_pos)
			var distance_tiles : float = distance_from_colony / Preload.C.TILE_SIZE.x

			var max_score : float = 50.0
			score += max_score * (distance_tiles / float(_candidate.build_radius))

	return score

## Score a potential colony location
func _score_colony_location(_candidate: Dictionary) -> float:
	var tile      : Vector2i = _candidate.tile
	var tile_data : TileCustomData = world_gen.tile_custom_data[tile]
	var score     : float = 0.0

	# Highest priority: ocean access for trading
	score += _score_colony_ocean_access(_candidate)

	# Terrain production modifiers (important for resources)
	var farm_modifier: int = tile_data.terrain_modifiers[Term.IndustryType.FARM]
	var mine_modifier: int = tile_data.terrain_modifiers[Term.IndustryType.MINE]
	var mill_modifier: int = tile_data.terrain_modifiers[Term.IndustryType.MILL]

	# Weight farm higher (food is critical)
	score += farm_modifier * 1.5
	score += mine_modifier * 1.0
	score += mill_modifier * 1.0

	# Bonus for balanced resources (avoid over-specialization)
	var min_modifier: int = mini(farm_modifier, mini(mine_modifier, mill_modifier))
	var max_modifier: int = maxi(farm_modifier, maxi(mine_modifier, mill_modifier))
	if max_modifier - min_modifier < 50:  # Fairly balanced
		score += 60.0

	# 4. Biome bonuses (lower priority)
	match tile_data.biome:
		WorldGen.TileCategory.GRASS:
			score += 30.0  # Good for farms
		WorldGen.TileCategory.SWAMP:
			score += 10.0  # Mixed
		WorldGen.TileCategory.FOREST:
			score += 20.0  # Good for mills
		WorldGen.TileCategory.MOUNTAIN:
			score += 0.0   # Skip (handled above)

	return score


## Validate sufficient buildable land within build_radius
func _validate_colony_has_sufficient_build_radius(_tile: Vector2i, _build_tiles: Array[Vector2i], _build_ratio_min : float = 0.6) -> bool:
	var build_count : float = 0
	var total_count : int = _build_tiles.size()

	if total_count == 0:
		return false

	for build_tile: Vector2i in _build_tiles:
		
		# Check if tile data exists
		if not world_gen.tile_custom_data.has(build_tile):
			continue

		# -- Checks..
		var tile_data: TileCustomData = world_gen.tile_custom_data[build_tile]

		if tile_data.is_occupied():
			continue
		if world_gen.is_land_tile(build_tile):
			build_count += 1.0
		elif world_gen.is_shore_tile(build_tile) or world_gen.is_river_tile(build_tile) and world_gen.has_ocean_access_tile(build_tile):
			build_count += 0.6

	# --
	# Calculate buildable ratio
	var build_ratio: float = build_count / float(total_count)
	return build_ratio >= _build_ratio_min


## Select a random tile from top-scoring candidates
##
## Uses weighted randomness to favor higher scores while still allowing variety.
## - top_percent: Consider only candidates in the top X% of scores (e.g., 0.2 = top 20%)
static func select_random_top_candidate(scored_candidates: Array[Dictionary], top_percent: float = 0.2) -> Vector2i:
	if scored_candidates.is_empty():
		push_error("No candidates to select from")
		return Vector2i.ZERO

	# Calculate cutoff for top candidates
	var top_count: int = maxi(1, int(scored_candidates.size() * top_percent))
	var top_candidates: Array[Dictionary] = scored_candidates.slice(0, top_count)

	print("[LocationFinder] Selecting from %d top candidates (%.0f%% of %d total)" % [
		top_count,
		top_percent * 100.0,
		scored_candidates.size()
	])

	# Weight by score (higher score = higher probability)
	var total_weight: float = 0.0
	for candidate: Dictionary in top_candidates:
		total_weight += candidate.score

	if total_weight <= 0:
		# All scores are 0 or negative, just pick randomly
		print("[LocationFinder] All scores are 0, selecting purely random")
		return top_candidates.pick_random().tile

	# Random selection weighted by score
	randomize()  # Ensure random seed is different each time
	var random_value: float = randf() * total_weight
	var cumulative_weight: float = 0.0

	print("[LocationFinder] Random value: %.2f / %.2f" % [random_value, total_weight])

	for candidate: Dictionary in top_candidates:
		cumulative_weight += candidate.score
		if random_value <= cumulative_weight:
			print("[LocationFinder] Selected tile %s with score %.2f" % [candidate.tile, candidate.score])
			return candidate.tile

	# Fallback to first candidate
	print("[LocationFinder] Fallback to first candidate")
	return top_candidates[0].tile


## Get score for a specific tile from scored candidates
func _get_score_for_tile(scored_candidates: Array[Dictionary], tile: Vector2i) -> float:
	for candidate: Dictionary in scored_candidates:
		if candidate.tile == tile:
			return candidate.score
	return 0.0

#endregion


#region BUILDING LOCATIONS

## Find optimal farm location within build_radius of colony
##
## Prioritizes:
## - High farm terrain modifier
## - Land tiles (not water/mountain)
## - Within colony build_radius
# func find_optimal_farm_location(colony_position: Vector2, build_radius_pixels: float) -> Vector2i:
# 	var tiles_in_radius: Array[Vector2i] = world_gen.get_tiles_in_radius(colony_position, build_radius_pixels)
# 	var scored_candidates: Array[Dictionary] = []

# 	for tile: Vector2i in tiles_in_radius:
# 		if not world_gen.tile_custom_data.has(tile):
# 			continue

# 		var tile_data: TileCustomData = world_gen.tile_custom_data[tile]

# 		# Must be land, not mountain
# 		if not world_gen.is_land_tile(tile):
# 			continue
# 		if tile_data.biome == WorldGen.TileCategory.MOUNTAIN:
# 			continue

# 		var score: float = 0.0

# 		# Primary factor: farm modifier
# 		score += tile_data.terrain_modifiers[Term.IndustryType.FARM] * 2.0

# 		# Bonus for grass biome
# 		if tile_data.biome == WorldGen.TileCategory.GRASS:
# 			score += 50.0

# 		# Bonus for river access (irrigation)
# 		if tile_data.is_river:
# 			score += 30.0

# 		if score > 0:
# 			scored_candidates.append({"tile": tile, "score": score})

# 	if scored_candidates.is_empty():
# 		return Vector2i.ZERO

# 	# Sort and select with randomness
# 	scored_candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
# 		return a.score > b.score
# 	)

# 	return _select_random_top_candidate(scored_candidates, 0.3)


## Find optimal mine location (metal/gold)
# func find_optimal_mine_location(colony_position: Vector2, build_radius_pixels: float, mine_type: Term.BuildingType = Term.BuildingType.METAL_MINE) -> Vector2i:
# 	var tiles_in_radius: Array[Vector2i] = world_gen.get_tiles_in_radius(colony_position, build_radius_pixels)
# 	var scored_candidates: Array[Dictionary] = []

# 	for tile: Vector2i in tiles_in_radius:
# 		if not world_gen.tile_custom_data.has(tile):
# 			continue

# 		var tile_data: TileCustomData = world_gen.tile_custom_data[tile]

# 		# Must be land, mountains OK for mines
# 		if not world_gen.is_land_tile(tile):
# 			continue

# 		var score: float = 0.0

# 		# Primary factor: mine modifier
# 		score += tile_data.terrain_modifiers[Term.IndustryType.MINE] * 2.0

# 		# Bonus for mountain biome
# 		if tile_data.biome == WorldGen.TileCategory.MOUNTAIN:
# 			score += 80.0

# 		if score > 0:
# 			scored_candidates.append({"tile": tile, "score": score})

# 	if scored_candidates.is_empty():
# 		return Vector2i.ZERO

# 	scored_candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
# 		return a.score > b.score
# 	)

# 	return _select_random_top_candidate(scored_candidates, 0.3)


## Find optimal mill location
# func find_optimal_mill_location(colony_position: Vector2, build_radius_pixels: float) -> Vector2i:
# 	var tiles_in_radius: Array[Vector2i] = world_gen.get_tiles_in_radius(colony_position, build_radius_pixels)
# 	var scored_candidates: Array[Dictionary] = []

# 	for tile: Vector2i in tiles_in_radius:
# 		if not world_gen.tile_custom_data.has(tile):
# 			continue

# 		var tile_data: TileCustomData = world_gen.tile_custom_data[tile]

# 		# Must be land, not mountain
# 		if not world_gen.is_land_tile(tile):
# 			continue
# 		if tile_data.biome == WorldGen.TileCategory.MOUNTAIN:
# 			continue

# 		var score: float = 0.0

# 		# Primary factor: mill modifier
# 		score += tile_data.terrain_modifiers[Term.IndustryType.MILL] * 2.0

# 		# Bonus for forest biome
# 		if tile_data.biome == WorldGen.TileCategory.FOREST:
# 			score += 50.0

# 		# Bonus for river access (water power)
# 		if tile_data.is_river:
# 			score += 40.0

# 		if score > 0:
# 			scored_candidates.append({"tile": tile, "score": score})

# 	if scored_candidates.is_empty():
# 		return Vector2i.ZERO

# 	scored_candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
# 		return a.score > b.score
# 	)

# 	return _select_random_top_candidate(scored_candidates, 0.3)


## Find optimal dock location (must be on shore/river)
static func find_optimal_dock_location(_world_gen: WorldGen, build_tiles: Dictionary) -> Vector2i:
	var candidates: Array[Vector2i] = []

	for tile: Vector2i in build_tiles:
		if not _world_gen.tile_custom_data.has(tile):
			continue

		var tile_data: TileCustomData = _world_gen.tile_custom_data[tile]

		# Must be shore or river WITH ocean access
		if (tile_data.is_river or tile_data.is_shore) and _world_gen.has_ocean_access_tile(tile):
			candidates.append(tile)

	if candidates.is_empty():
		return Vector2i.ZERO

	return candidates.pick_random()

#endregion
