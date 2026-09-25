class_name WorldForestUnderstory2D
extends Node2D
## Visual-only understory that makes Metsa read as forest at the gameplay zoom.
##
## The gameplay tour found the forest empty at the camera the game ships. At
## 0.38 a frame covers about 1,263 by 711 world units, and Metsa's colliding
## stands are three or four trees per 2,048-unit cell - roughly one per screen -
## so `tour_17_forest_interior` held no tree at all and the camp stood on a
## screen of bare mud. More colliding trees are not the answer: every trunk is
## rasterised into the flow field with 215 units of clearance, and at the
## density a forest needs the horde would lose its way to the refuge.
##
## So this layer owns no physics, flow, resource or gameplay state, and is
## configured after the canonical pipeline has finished, exactly as
## `WorldGroundCover2D` is. It sits between that ground cover and the colliding
## trees in scale: saplings, shrubs, ferns, stumps, moss rocks and deadfall at
## 70 to 330 units, which is 27 to 125 screen pixels - the band the tour showed
## empty. It draws at `AMBIENT_SCENERY_Z`, under every gameplay participant, for
## the reason `WorldAmbientScenery2D` records: a shrub must never hide a zombie.
##
## The contract's Metsa job is a canopy wall with a sparse interior around one
## true clearing (docs/WORLD_MAP_REDESIGN_CONTRACT.md, D-03 to D-05), so the
## density is not uniform. Inside `CLEARING_RADIUS` of the camp nothing grows;
## the ring out to `RIM_OUTER_RADIUS` is the wall, filled to `RIM_FILL` with the
## tallest saplings; beyond it the forest interior fills to `FOREST_FILL` scaled
## by the biome mask's forest share, and the wilderness belt thins by the same
## share.
##
## Placement is one hashed candidate per `CELL_SIZE` cell on its own seed, with
## no sequential RNG, so its density can move without shifting a single
## obstacle, scenery item, decoration, cover cluster or resource.

const UNDERSTORY_Z: int = -4
const RENDER_CHUNK_SIZE: float = 2048.0
const CELL_SIZE: float = 230.0
const FOREST_FILL: float = 0.72
## The contract's far wilderness is "the quieter empty" beyond the Metsa circuit
## (D-06, D-07), so it keeps a thin scatter rather than a forest's. At this fill
## the wilderness pockets still host the wild-atlas trial card that
## `existing_wild_atlas_context_validation` places there; at the forest's fill
## two more of them could not.
const WILDERNESS_FILL: float = 0.24
const RIM_FILL: float = 0.92
## The empty bowl. Wider than the 520-unit colliding clear and the 1,360-unit
## decor clear, narrower than the 1,760-unit ambient bowl, so the wall this layer
## draws sits just inside the ambient canopy rather than behind it.
const CLEARING_RADIUS: float = 1180.0
const RIM_OUTER_RADIUS: float = 2150.0
const MINIMUM_FOREST_SHARE: float = 0.30
const ROAD_EDGE_CLEARANCE: float = 90.0
const WORLD_MARGIN: float = 200.0
const MINIMUM_ELEMENT_COUNT: int = 900
const MAXIMUM_ELEMENT_COUNT: int = 6000
const BIOME_MASK: Texture2D = preload(
	"res://assets/2d/environment/terrain/bespren_biome_blend_mask.png"
)
const CHUNK_SCRIPT: Script = preload("res://src/world/world_forest_understory_chunk_2d.gd")

enum UnderstoryKind {
	SAPLING,
	SHRUB,
	FERN,
	STUMP,
	MOSS_ROCK,
	DEADFALL,
}

## Authored span range per kind, in world units.
const KIND_SPANS: Array[Vector2] = [
	Vector2(170.0, 250.0),
	Vector2(95.0, 165.0),
	Vector2(70.0, 120.0),
	Vector2(85.0, 135.0),
	Vector2(80.0, 130.0),
	Vector2(170.0, 250.0),
]
## Rim saplings are the wall, so they stand taller than interior ones.
const RIM_SAPLING_SPAN: Vector2 = Vector2(240.0, 330.0)

var _half_extent: float = 14336.0
var _camp_position: Vector2 = Vector2.ZERO
var _is_position_walkable: Callable = Callable()
var _road_edge_distance: Callable = Callable()
var _biome_at_world: Callable = Callable()
var _biome_image: Image = null
var _positions: PackedVector2Array = PackedVector2Array()
var _spans: PackedFloat32Array = PackedFloat32Array()
var _kinds: PackedInt32Array = PackedInt32Array()
var _seeds: PackedInt32Array = PackedInt32Array()
var _rim_count: int = 0


func _ready() -> void:
	z_index = UNDERSTORY_Z
	z_as_relative = false


func configure(
	playable_half_extent: float,
	seed_value: int,
	camp_position: Vector2,
	position_walkable: Callable,
	road_edge_distance: Callable,
	biome_at_world: Callable
) -> void:
	_clear_render_chunks()
	_half_extent = playable_half_extent
	_camp_position = camp_position
	_is_position_walkable = position_walkable
	_road_edge_distance = road_edge_distance
	_biome_at_world = biome_at_world
	_positions.clear()
	_spans.clear()
	_kinds.clear()
	_seeds.clear()
	_rim_count = 0
	_biome_image = BIOME_MASK.get_image()
	var cell_dimension: int = maxi(1, floori((_half_extent * 2.0) / CELL_SIZE))
	for cell_y: int in range(cell_dimension):
		for cell_x: int in range(cell_dimension):
			_consider_cell(cell_x, cell_y, seed_value)
	if _positions.size() < MINIMUM_ELEMENT_COUNT:
		push_error(
			"Forest understory rejected: expected at least %d elements, found %d"
			% [MINIMUM_ELEMENT_COUNT, _positions.size()]
		)
	z_index = UNDERSTORY_Z
	z_as_relative = false
	_build_render_chunks()


func get_element_count() -> int:
	return _positions.size()


func get_rim_element_count() -> int:
	return _rim_count


func get_element_positions() -> PackedVector2Array:
	return _positions.duplicate()


func get_element_spans() -> PackedFloat32Array:
	return _spans.duplicate()


func get_element_kinds() -> PackedInt32Array:
	return _kinds.duplicate()


## Conservative drawn radius of an element, the figure every rejection used.
static func visual_radius(span: float) -> float:
	return span * 0.5


## Read-only render envelopes for sibling presentation gates, in the shape
## `WorldAmbientScenery2D.get_scenery_visual_radii` publishes: this layer draws
## at the same z and occludes a ground card the same way.
func get_element_visual_radii() -> PackedFloat32Array:
	var radii: PackedFloat32Array = PackedFloat32Array()
	for span: float in _spans:
		radii.append(visual_radius(span))
	return radii


func get_render_chunks() -> Array[Node2D]:
	var chunks: Array[Node2D] = []
	for child: Node in get_children():
		var chunk: Node2D = child as Node2D
		if chunk != null:
			chunks.append(chunk)
	return chunks


func get_chunked_element_count() -> int:
	var total: int = 0
	for chunk: Node2D in get_render_chunks():
		var count_variant: Variant = chunk.call(&"get_element_count")
		if count_variant is int:
			total += count_variant
	return total


func _consider_cell(cell_x: int, cell_y: int, seed_value: int) -> void:
	if _positions.size() >= MAXIMUM_ELEMENT_COUNT:
		return
	var cell_seed: int = seed_value + cell_y * 7919 + cell_x * 37
	var cell_origin: Vector2 = Vector2(-_half_extent, -_half_extent) + Vector2(
		float(cell_x) * CELL_SIZE,
		float(cell_y) * CELL_SIZE
	)
	var candidate: Vector2 = cell_origin + Vector2(
		(0.15 + hash_unit(cell_seed + 3) * 0.70) * CELL_SIZE,
		(0.15 + hash_unit(cell_seed + 5) * 0.70) * CELL_SIZE
	)
	if absf(candidate.x) > _half_extent - WORLD_MARGIN or absf(candidate.y) > _half_extent - WORLD_MARGIN:
		return
	var camp_distance: float = candidate.distance_to(_camp_position)
	if camp_distance < CLEARING_RADIUS:
		return
	var on_rim: bool = camp_distance < RIM_OUTER_RADIUS
	var forest_share: float = _sample_forest_share(candidate)
	if not on_rim and forest_share < MINIMUM_FOREST_SHARE:
		return
	var fill: float = RIM_FILL
	if not on_rim:
		match _biome_at(candidate):
			BesprenWorldMap2D.Biome.FOREST:
				fill = FOREST_FILL * forest_share
			BesprenWorldMap2D.Biome.WILDERNESS:
				fill = WILDERNESS_FILL * forest_share
			_:
				return
	if hash_unit(cell_seed) > fill:
		return
	var kind: int = _select_kind(cell_seed, forest_share, on_rim)
	var span_range: Vector2 = RIM_SAPLING_SPAN if on_rim and kind == UnderstoryKind.SAPLING else KIND_SPANS[kind]
	var span: float = lerpf(span_range.x, span_range.y, hash_unit(cell_seed + 7))
	if not _is_clear_of_authored_geometry(candidate, visual_radius(span)):
		return
	_positions.append(candidate)
	_spans.append(span)
	_kinds.append(kind)
	_seeds.append(cell_seed)
	if on_rim:
		_rim_count += 1


func _select_kind(cell_seed: int, forest_share: float, on_rim: bool) -> int:
	var roll: float = hash_unit(cell_seed + 11)
	if on_rim:
		# The wall is saplings and shrubs; ground-level kinds would not close it.
		if roll < 0.62:
			return UnderstoryKind.SAPLING
		if roll < 0.88:
			return UnderstoryKind.SHRUB
		return UnderstoryKind.FERN
	# Deeper forest grows; the thin wilderness belt carries stone and deadfall.
	var sapling_share: float = lerpf(0.10, 0.30, forest_share)
	if roll < sapling_share:
		return UnderstoryKind.SAPLING
	var shrub_edge: float = sapling_share + 0.26
	if roll < shrub_edge:
		return UnderstoryKind.SHRUB
	var fern_edge: float = shrub_edge + lerpf(0.10, 0.22, forest_share)
	if roll < fern_edge:
		return UnderstoryKind.FERN
	if roll < fern_edge + 0.12:
		return UnderstoryKind.STUMP
	if roll < fern_edge + 0.24:
		return UnderstoryKind.MOSS_ROCK
	return UnderstoryKind.DEADFALL


func _is_clear_of_authored_geometry(candidate: Vector2, radius: float) -> bool:
	if not _road_edge_distance.is_valid() or not _is_position_walkable.is_valid():
		return false
	var road_distance_variant: Variant = _road_edge_distance.call(candidate)
	if not road_distance_variant is float and not road_distance_variant is int:
		return false
	if float(road_distance_variant) < ROAD_EDGE_CLEARANCE + radius:
		return false
	## An overlap query only: the whole drawn radius stays off every colliding
	## footprint, so a walk-through shrub never impersonates an obstacle and
	## never hides one.
	var walkable_variant: Variant = _is_position_walkable.call(candidate, radius)
	return walkable_variant is bool and walkable_variant


## The same mask `terrain_material_blend.gdshader` samples, read the way
## `WorldGroundCover2D` reads it, so the understory never lands on ground the
## shader paints as pavement.
func _sample_forest_share(world_position: Vector2) -> float:
	if _biome_image == null:
		return 0.0
	var mask_size: Vector2i = _biome_image.get_size()
	if mask_size.x <= 0 or mask_size.y <= 0:
		return 0.0
	var span: float = maxf(_half_extent * 2.0, 1.0)
	var pixel: Color = _biome_image.get_pixel(
		clampi(floori((world_position.x + _half_extent) / span * float(mask_size.x)), 0, mask_size.x - 1),
		clampi(floori((world_position.y + _half_extent) / span * float(mask_size.y)), 0, mask_size.y - 1)
	)
	var mud: float = maxf(1.0 - pixel.r - pixel.g - pixel.b, 0.0)
	var total: float = pixel.r + pixel.g + pixel.b + mud
	if total <= 0.0:
		return 0.0
	return pixel.r / total


func _biome_at(world_position: Vector2) -> int:
	if not _biome_at_world.is_valid():
		return -1
	var biome_variant: Variant = _biome_at_world.call(world_position)
	return biome_variant if biome_variant is int else -1


static func hash_unit(value: int) -> float:
	return fposmod(sin(float(value) * 12.9898 + 4.1414) * 43758.5453, 1.0)


func _build_render_chunks() -> void:
	var chunks_by_coordinate: Dictionary = {}
	for element_index: int in range(_positions.size()):
		var element_position: Vector2 = _positions[element_index]
		var chunk: Node2D = _get_or_create_chunk(element_position, chunks_by_coordinate)
		chunk.call(
			&"add_element",
			element_position,
			_spans[element_index],
			_kinds[element_index],
			_seeds[element_index]
		)
	for chunk: Node2D in get_render_chunks():
		chunk.call(&"seal")


func _get_or_create_chunk(world_position: Vector2, chunks_by_coordinate: Dictionary) -> Node2D:
	var chunk_dimension: int = maxi(1, ceili((_half_extent * 2.0) / RENDER_CHUNK_SIZE))
	var coordinate: Vector2i = Vector2i(
		clampi(floori((world_position.x + _half_extent) / RENDER_CHUNK_SIZE), 0, chunk_dimension - 1),
		clampi(floori((world_position.y + _half_extent) / RENDER_CHUNK_SIZE), 0, chunk_dimension - 1)
	)
	if chunks_by_coordinate.has(coordinate):
		return chunks_by_coordinate[coordinate] as Node2D
	var chunk: Node2D = CHUNK_SCRIPT.new() as Node2D
	chunk.name = "ForestUnderstoryChunk_%02d_%02d" % [coordinate.x, coordinate.y]
	add_child(chunk)
	chunk.call(
		&"configure_origin",
		Vector2(-_half_extent, -_half_extent) + Vector2(coordinate) * RENDER_CHUNK_SIZE
	)
	chunks_by_coordinate[coordinate] = chunk
	return chunk


func _clear_render_chunks() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.free()
