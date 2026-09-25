class_name WorldVillageYards2D
extends Node2D
## The lived-in yards of both Kylat (DIST-01's "village quiet: yards, timber,
## rest rhythm").
##
## At the gameplay zoom both villages were a house on bare dirt with poles and a
## barricade: a village only by its houses. What says someone lived here is the
## ground around a house - a trodden apron at its door, a trail worn out of it,
## a woodpile against the wall with a chopping block beside it, a fenced plot
## of furrows, washing on a line. Each homestead gets its own set, placed toward
## the village it belongs to, so the west yard's open middle stays the
## negative space the contract names it by.
##
## Every item is placed only where the map says the ground is open - clear of
## every colliding footprint and off every road - and a trail stops where the
## ground stops being open, so nothing here is drawn under a fence or a wall.
## Visual only: no collision, flow, resource or gameplay state, configured after
## the canonical pipeline like every dress layer, at the decor z.

const YARDS_Z: int = -5
const CHUNK_SCRIPT: Script = preload("res://src/world/world_village_yard_chunk_2d.gd")
## How far in front of a house's facing edge its apron is centred.
const APRON_STANDOFF: float = 230.0
const TRAIL_LENGTH: float = 720.0
const TRAIL_STEP: float = 60.0
const TRAIL_CLEARANCE: float = 40.0
const WOODPILE_RADIUS: float = 110.0
const PLOT_SIZE: Vector2 = Vector2(480.0, 340.0)
const LINE_SPAN: float = 260.0
const ROAD_MARGIN: float = 40.0

var _is_position_walkable: Callable = Callable()
var _road_edge_distance: Callable = Callable()
var _yard_count: int = 0
var _item_counts: Dictionary[StringName, int] = {}
var _apron_centers: PackedVector2Array = PackedVector2Array()


func _ready() -> void:
	z_index = YARDS_Z
	z_as_relative = false


## [param homesteads] holds one (house position, facing target) pair per house,
## as a Vector4: the house at xy and the point its yard faces toward at zw.
## [param house_half_sizes] gives each house's half footprint in the same order.
func configure(
	homesteads: Array[Vector4],
	house_half_sizes: PackedVector2Array,
	position_walkable: Callable,
	road_edge_distance: Callable
) -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	z_index = YARDS_Z
	z_as_relative = false
	_is_position_walkable = position_walkable
	_road_edge_distance = road_edge_distance
	_yard_count = 0
	_apron_centers.clear()
	_item_counts = {&"apron": 0, &"trail": 0, &"woodpile": 0, &"plot": 0, &"line": 0}
	for index: int in range(homesteads.size()):
		var homestead: Vector4 = homesteads[index]
		var house: Vector2 = Vector2(homestead.x, homestead.y)
		var facing: Vector2 = (Vector2(homestead.z, homestead.w) - house).normalized()
		if not facing.is_finite() or facing.is_zero_approx():
			continue
		_add_yard(index, house, house_half_sizes[index], facing)


func get_yard_count() -> int:
	return _yard_count


## Where each placed yard's apron is centred, in placement order, for review
## cameras that should look at a yard rather than at the house beside it.
func get_apron_centers() -> PackedVector2Array:
	return _apron_centers.duplicate()


func get_item_count(item: StringName) -> int:
	return _item_counts.get(item, 0)


func get_chunks() -> Array[Node2D]:
	var chunks: Array[Node2D] = []
	for child: Node in get_children():
		if child is Node2D:
			chunks.append(child as Node2D)
	return chunks


func _add_yard(index: int, house: Vector2, half_size: Vector2, target_facing: Vector2) -> void:
	# The yard faces its village if it can; a fence or a pole in the way turns
	# it a little, never to face away from the village.
	var facing: Vector2 = Vector2.ZERO
	var apron: Vector2 = Vector2.ZERO
	var reach: float = 0.0
	for turn: float in [0.0, 0.45, -0.45, 0.9, -0.9]:
		var candidate_facing: Vector2 = target_facing.rotated(turn)
		var candidate_reach: float = absf(candidate_facing.x) * half_size.x + absf(candidate_facing.y) * half_size.y
		for standoff: float in [APRON_STANDOFF, APRON_STANDOFF + 140.0]:
			var candidate: Vector2 = house + candidate_facing * (candidate_reach + standoff)
			if _is_open(candidate, 120.0):
				facing = candidate_facing
				apron = candidate
				reach = candidate_reach
				break
		if not facing.is_zero_approx():
			break
	if facing.is_zero_approx():
		return
	var across: Vector2 = facing.orthogonal()
	var chunk: Node2D = Node2D.new()
	chunk.set_script(CHUNK_SCRIPT)
	chunk.name = "Yard_%02d" % index
	add_child(chunk)
	_yard_count += 1
	var salt: int = 4099 + index * 173
	var apron_radii: Vector2 = Vector2(maxf(half_size.x, half_size.y) * 0.62, 250.0)
	chunk.call(&"add_apron", apron, apron_radii, facing.angle() + PI * 0.5, salt)
	_apron_centers.append(apron)
	_item_counts[&"apron"] += 1

	var trail: PackedVector2Array = PackedVector2Array([apron])
	var heading: Vector2 = facing.rotated((WorldForestUnderstory2D.hash_unit(salt + 1) - 0.5) * 0.9)
	var travelled: float = 0.0
	while travelled < TRAIL_LENGTH:
		var next: Vector2 = trail[trail.size() - 1] + heading * TRAIL_STEP
		if not _is_open(next, TRAIL_CLEARANCE):
			break
		trail.append(next)
		travelled += TRAIL_STEP
		heading = heading.rotated((WorldForestUnderstory2D.hash_unit(salt + 7 + trail.size()) - 0.5) * 0.25)
	if trail.size() >= 4:
		chunk.call(&"add_trail", trail, salt + 2)
		_item_counts[&"trail"] += 1

	var side: float = -1.0 if index % 2 == 0 else 1.0
	var woodpile_spots: Array[Vector2] = []
	for woodpile_side: float in [side, -side]:
		woodpile_spots.append(house + facing * (reach + 70.0) + across * woodpile_side * (half_size.x * 0.55))
		woodpile_spots.append(apron + across * woodpile_side * (apron_radii.x + 60.0))
	var woodpile: Vector2 = _first_open(woodpile_spots, WOODPILE_RADIUS)
	if woodpile.is_finite():
		chunk.call(&"add_woodpile", woodpile, salt + 3)
		_item_counts[&"woodpile"] += 1

	var plot_radius: float = PLOT_SIZE.length() * 0.5
	var plot_spots: Array[Vector2] = []
	for plot_side: float in [-side, side]:
		plot_spots.append(apron + facing * 120.0 + across * plot_side * (apron_radii.x + PLOT_SIZE.x * 0.35))
		plot_spots.append(apron + facing * (apron_radii.y + PLOT_SIZE.y * 0.6) + across * plot_side * PLOT_SIZE.x * 0.4)
	var plot_center: Vector2 = _first_open(plot_spots, plot_radius)
	if plot_center.is_finite() and (not woodpile.is_finite() or plot_center.distance_to(woodpile) > plot_radius + WOODPILE_RADIUS):
		chunk.call(&"add_plot", plot_center, PLOT_SIZE, salt + 4)
		_item_counts[&"plot"] += 1

	if index % 2 == 1 or not woodpile.is_finite():
		for line_offset: float in [-40.0, 60.0]:
			var line_center: Vector2 = apron + facing * line_offset + across * side * (apron_radii.x * 0.4)
			var line_from: Vector2 = line_center - across * LINE_SPAN * 0.5
			var line_to: Vector2 = line_center + across * LINE_SPAN * 0.5
			if _is_open(line_from, 30.0) and _is_open(line_to, 30.0):
				chunk.call(&"add_line", line_from, line_to, salt + 5)
				_item_counts[&"line"] += 1
				break


func _first_open(spots: Array[Vector2], radius: float) -> Vector2:
	for spot: Vector2 in spots:
		if _is_open(spot, radius):
			return spot
	return Vector2.INF


func _is_open(point: Vector2, radius: float) -> bool:
	if not _is_position_walkable.is_valid() or not _road_edge_distance.is_valid():
		return false
	var walkable: Variant = _is_position_walkable.call(point, radius)
	if not (walkable is bool and walkable):
		return false
	var road_distance: Variant = _road_edge_distance.call(point)
	return road_distance is float and float(road_distance) > radius + ROAD_MARGIN
