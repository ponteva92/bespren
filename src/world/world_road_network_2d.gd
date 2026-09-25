class_name WorldRoadNetwork2D
extends Node2D
## Authored road topology rendered through bounded mobile-friendly child chunks.

const ASPHALT_OUTER_WIDTH: float = 540.0
const ASPHALT_INNER_WIDTH: float = 420.0
const DIRT_OUTER_WIDTH: float = 480.0
const DIRT_INNER_WIDTH: float = 360.0
## The wilderness perimeter is the far belt's track, not a road the loop uses
## (contract D-20), so it draws as the narrowest grade: two wheel ruts and a
## grass crown down a 230-unit bed, 88 screen pixels at the gameplay zoom
## against the dirt branch's 137 and the spine's 160. It keeps the dirt grade's
## 480-unit corridor for every clearance rule, so the dress layers still leave
## the ride open either side of it and nothing seeded moves; what changes is how
## much of that corridor the track itself occupies.
const PERIMETER_OUTER_WIDTH: float = 330.0
const PERIMETER_INNER_WIDTH: float = 230.0
const DASH_LENGTH: float = 220.0
const DASH_GAP: float = 250.0
const MAX_RENDER_CHUNK_LENGTH: float = 4096.0
## A route end within this of another route's centreline is a junction; any
## other end is free and gets a ragged cap instead of a square cut.
const JUNCTION_TOLERANCE: float = 1.0

var _routes: Array[PackedVector2Array] = []
var _grades: PackedInt32Array = PackedInt32Array()


func _ready() -> void:
	z_index = -20
	z_as_relative = false


## [param grades] are `WorldCompositionContract.RoadGrade` values, one per route.
func configure(routes: Array[PackedVector2Array], grades: PackedInt32Array) -> void:
	_clear_render_chunks()
	_routes.clear()
	for route: PackedVector2Array in routes:
		_routes.append(route.duplicate())
	_grades = grades.duplicate()
	z_index = -20
	z_as_relative = false
	_build_render_chunks()


func get_route_count() -> int:
	return _routes.size()


func get_route_grade(route_index: int) -> int:
	if route_index < 0 or route_index >= _grades.size():
		return WorldCompositionContract.RoadGrade.ASPHALT_SPINE
	return _grades[route_index]


## Drawn widths per grade, as Vector2(outer, inner).
static func get_grade_widths(grade: int) -> Vector2:
	match grade:
		WorldCompositionContract.RoadGrade.DIRT:
			return Vector2(DIRT_OUTER_WIDTH, DIRT_INNER_WIDTH)
		WorldCompositionContract.RoadGrade.PERIMETER:
			return Vector2(PERIMETER_OUTER_WIDTH, PERIMETER_INNER_WIDTH)
	return Vector2(ASPHALT_OUTER_WIDTH, ASPHALT_INNER_WIDTH)


## The corridor half width every clearance rule measures from. The perimeter
## keeps the dirt corridor; see `PERIMETER_OUTER_WIDTH`.
static func get_clearance_half_width(grade: int) -> float:
	if grade == WorldCompositionContract.RoadGrade.ASPHALT_SPINE:
		return ASPHALT_OUTER_WIDTH * 0.5
	return DIRT_OUTER_WIDTH * 0.5


## Whether a route's first (or last) point is a free end rather than a junction.
func is_route_end_free(route_index: int, at_finish: bool) -> bool:
	if route_index < 0 or route_index >= _routes.size():
		return false
	var route: PackedVector2Array = _routes[route_index]
	if route.size() < 2:
		return false
	var point: Vector2 = route[route.size() - 1] if at_finish else route[0]
	if route[0].is_equal_approx(route[route.size() - 1]):
		return false
	for other_index: int in range(_routes.size()):
		var other: PackedVector2Array = _routes[other_index]
		for segment: int in range(other.size() - 1):
			if other_index == route_index:
				# The route's own segments count only when the end lands on a
				# segment it does not belong to.
				var own_last: int = route.size() - 2 if at_finish else 0
				if segment == own_last:
					continue
			var closest: Vector2 = Geometry2D.get_closest_point_to_segment(point, other[segment], other[segment + 1])
			if point.distance_to(closest) <= JUNCTION_TOLERANCE:
				return false
	return true


func get_routes() -> Array[PackedVector2Array]:
	var copy: Array[PackedVector2Array] = []
	for route: PackedVector2Array in _routes:
		copy.append(route.duplicate())
	return copy


func get_minimum_road_edge_distance(world_position: Vector2, excluded_route: int = -1) -> float:
	## Returns physical clearance from a point to the nearest rendered outer
	## road edge, rather than merely measuring to its centerline.
	## [param excluded_route] skips one route, which is how the camp's seclusion
	## rules measure every road except the camp's own spur.
	if not world_position.is_finite():
		return 0.0
	var shortest: float = INF
	for route_index: int in range(_routes.size()):
		if route_index == excluded_route:
			continue
		var route: PackedVector2Array = _routes[route_index]
		var outer_half_width: float = get_clearance_half_width(get_route_grade(route_index))
		for point_index: int in range(route.size() - 1):
			var closest: Vector2 = Geometry2D.get_closest_point_to_segment(
				world_position,
				route[point_index],
				route[point_index + 1]
			)
			shortest = minf(
				shortest,
				maxf(0.0, world_position.distance_to(closest) - outer_half_width)
			)
	return shortest


func get_render_chunk_count() -> int:
	return get_child_count()


func get_render_chunk_bounds() -> Array[Rect2]:
	var bounds: Array[Rect2] = []
	for child: Node in get_children():
		var chunk: WorldRoadSegmentChunk2D = child as WorldRoadSegmentChunk2D
		if chunk != null:
			bounds.append(chunk.get_world_render_bounds())
	return bounds


func get_render_chunks() -> Array[WorldRoadSegmentChunk2D]:
	var chunks: Array[WorldRoadSegmentChunk2D] = []
	for child: Node in get_children():
		var chunk: WorldRoadSegmentChunk2D = child as WorldRoadSegmentChunk2D
		if chunk != null:
			chunks.append(chunk)
	return chunks


## Two passes over the whole network. Every route's shoulder is drawn before
## any route's bed, because a road drawn as one item per segment lays its dark
## outer band across whatever bed was drawn before it: at the central cross the
## north-south shoulder cut straight through the east-west carriageway, and the
## junction read as two strips stacked on each other. Drawn this way, beds meet
## beds and a junction reads as one surface.
func _build_render_chunks() -> void:
	var chunk_index: int = 0
	for pass_kind: int in [WorldRoadSegmentChunk2D.Pass.SHOULDER, WorldRoadSegmentChunk2D.Pass.BED]:
		for route_index: int in range(_routes.size()):
			var route: PackedVector2Array = _routes[route_index]
			if route.size() < 2:
				continue
			var grade: int = get_route_grade(route_index)
			var widths: Vector2 = get_grade_widths(grade)
			var start_is_free: bool = is_route_end_free(route_index, false)
			var finish_is_free: bool = is_route_end_free(route_index, true)
			for point_index: int in range(route.size() - 1):
				var start: Vector2 = route[point_index]
				var finish: Vector2 = route[point_index + 1]
				var displacement: Vector2 = finish - start
				var length: float = displacement.length()
				if length <= 0.0:
					continue
				var direction: Vector2 = displacement / length
				var subdivision_count: int = maxi(1, ceili(length / MAX_RENDER_CHUNK_LENGTH))
				for subdivision: int in range(subdivision_count):
					var start_distance: float = minf(
						float(subdivision) * MAX_RENDER_CHUNK_LENGTH,
						length
					)
					var finish_distance: float = minf(
						float(subdivision + 1) * MAX_RENDER_CHUNK_LENGTH,
						length
					)
					var chunk: WorldRoadSegmentChunk2D = WorldRoadSegmentChunk2D.new()
					chunk.name = (
						"RoadShoulder_%03d" if pass_kind == WorldRoadSegmentChunk2D.Pass.SHOULDER
						else "RoadChunk_%03d"
					) % chunk_index
					add_child(chunk)
					chunk.configure(
						start + direction * start_distance,
						start + direction * finish_distance,
						grade != WorldCompositionContract.RoadGrade.ASPHALT_SPINE,
						widths.x,
						widths.y,
						DASH_LENGTH,
						DASH_GAP,
						start_distance
					)
					chunk.configure_pass(
						pass_kind,
						grade,
						start_is_free and point_index == 0 and subdivision == 0,
						finish_is_free and point_index == route.size() - 2 and subdivision == subdivision_count - 1,
						_junctions_on_segment(route_index, start, finish)
					)
					chunk_index += 1


## Points on segment a-b where another route crosses it or ends on it, each
## with that route's drawn half width: the extent of the shared surface.
func _junctions_on_segment(route_index: int, a: Vector2, b: Vector2) -> PackedVector3Array:
	var junctions: PackedVector3Array = PackedVector3Array()
	for other_index: int in range(_routes.size()):
		if other_index == route_index:
			continue
		var other: PackedVector2Array = _routes[other_index]
		var reach: float = get_grade_widths(get_route_grade(other_index)).x * 0.5
		for segment: int in range(other.size() - 1):
			var crossing: Variant = Geometry2D.segment_intersects_segment(a, b, other[segment], other[segment + 1])
			if crossing is Vector2:
				junctions.append(Vector3((crossing as Vector2).x, (crossing as Vector2).y, reach))
		for end_point: Vector2 in [other[0], other[other.size() - 1]]:
			var closest: Vector2 = Geometry2D.get_closest_point_to_segment(end_point, a, b)
			if end_point.distance_to(closest) <= JUNCTION_TOLERANCE:
				junctions.append(Vector3(closest.x, closest.y, reach))
	return junctions


func _clear_render_chunks() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.free()
