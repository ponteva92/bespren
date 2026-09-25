class_name WorldCompositionContract
extends Resource
## The authored skeleton of the 14x14 world, as data `BesprenWorldMap2D` consumes.
##
## Roadmap Phase 2 asks that the world's paths, edges, districts, nodes and
## landmarks come from composition data rather than from biome predicates and
## literals scattered through the builders, and that a reviewer can open that
## data. This is it, shipped as `res://data/world/world_composition.tres`:
##
## - the camp seat and its three satellites;
## - every road route with its grade, and which one is the camp's dirt spur;
## - the biome paint that assigns forest and the four districts to macro cells;
## - the five named landmarks the redesign contract calls shout nouns;
## - one pocket table per dress layer and zone, replacing the three independent
##   copies the decor, ambient and accent layers used to author.
##
## It owns no behaviour beyond lookups. Everything that decides - collision,
## flow, the seeded dress streams, gather rules and the peer-one authority path
## - stays where it was; this only says where things are. Biome ids are the
## `BesprenWorldMap2D.Biome` integers and road grades are `RoadGrade` below.

enum RoadGrade {
	## The paved cross and district branches: the way home (contract D-23).
	ASPHALT_SPINE,
	## Village paths and the camp's spur.
	DIRT,
	## The wilderness perimeter loop, the far belt's track.
	PERIMETER,
}

## Bump when a field's meaning changes, so a stale file is refused loudly.
const SCHEMA_VERSION: int = 1

@export var schema_version: int = SCHEMA_VERSION
@export var camp_position: Vector2 = Vector2.ZERO
@export var camp_satellites: Array[WorldCompositionPlacement] = []

@export var road_names: PackedStringArray = PackedStringArray()
@export var road_routes: Array[PackedVector2Array] = []
@export var road_grades: PackedInt32Array = PackedInt32Array()
## Index into `road_routes` of the camp's dirt spur, or -1. The spur is the one
## authored road allowed inside the camp's road-edge clearance (contract D-02).
@export var camp_spur_route: int = -1

## Paint order: every cell starts as `base_biome`, the outer ring becomes
## `perimeter_biome`, each `forest_cell_rects` rect becomes `forest_biome`, and
## the districts are painted last so they win.
@export var base_biome: int = 5
@export var perimeter_biome: int = 0
@export var forest_biome: int = 0
@export var forest_cell_rects: Array[Rect2i] = []
@export var district_names: PackedStringArray = PackedStringArray()
@export var district_biomes: PackedInt32Array = PackedInt32Array()
@export var district_cell_rects: Array[Rect2i] = []

@export var landmark_names: PackedStringArray = PackedStringArray()
@export var landmark_positions: PackedVector2Array = PackedVector2Array()
@export var landmark_radii: PackedFloat32Array = PackedFloat32Array()
@export var landmark_roles: PackedStringArray = PackedStringArray()

@export var pocket_tables: Array[WorldPocketTable] = []


## The pockets one layer samples for one zone. An empty array means the table is
## missing, which every consumer treats as a broken composition.
func get_pockets(layer: StringName, zone: StringName) -> Array[Vector4]:
	var pockets: Array[Vector4] = []
	for table: WorldPocketTable in pocket_tables:
		if table != null and table.layer == layer and table.zone == zone:
			for pocket: Vector4 in table.pockets:
				pockets.append(pocket)
			return pockets
	push_error("World composition has no %s/%s pocket table" % [layer, zone])
	return pockets


func get_landmark_position(landmark: StringName) -> Vector2:
	var index: int = landmark_names.find(String(landmark))
	return landmark_positions[index] if index >= 0 and index < landmark_positions.size() else Vector2.INF


func get_district_rect_cells(district: StringName) -> Rect2i:
	var index: int = district_names.find(String(district))
	return district_cell_rects[index] if index >= 0 and index < district_cell_rects.size() else Rect2i()


## Routes as the road network expects them: all but the grade. Dirt and
## perimeter both draw as dirt until the road hierarchy gives the perimeter its
## own look (roadmap Phase 3).
func get_dirt_flags() -> PackedByteArray:
	var flags: PackedByteArray = PackedByteArray()
	for grade: int in road_grades:
		flags.append(0 if grade == RoadGrade.ASPHALT_SPINE else 1)
	return flags


## Every route except the camp spur, for the rules that keep the refuge
## secluded from roads.
func get_routes_without_spur() -> Array[PackedVector2Array]:
	var routes: Array[PackedVector2Array] = []
	for route_index: int in range(road_routes.size()):
		if route_index != camp_spur_route:
			routes.append(road_routes[route_index])
	return routes


## Structural consistency, so a malformed file fails at load rather than as a
## half-built world. Returns the first problem found, or an empty string.
func validate() -> String:
	if schema_version != SCHEMA_VERSION:
		return "schema_version %d is not %d" % [schema_version, SCHEMA_VERSION]
	if not camp_position.is_finite():
		return "camp_position is not finite"
	if road_routes.is_empty() or road_routes.size() != road_grades.size() or road_routes.size() != road_names.size():
		return "road names, routes and grades disagree in length"
	for route: PackedVector2Array in road_routes:
		if route.size() < 2:
			return "a road route has fewer than two points"
	if camp_spur_route >= road_routes.size():
		return "camp_spur_route is out of range"
	if district_names.size() != district_biomes.size() or district_names.size() != district_cell_rects.size():
		return "district names, biomes and rects disagree in length"
	if (
		landmark_names.size() != landmark_positions.size()
		or landmark_names.size() != landmark_radii.size()
		or landmark_names.size() != landmark_roles.size()
	):
		return "landmark arrays disagree in length"
	for table: WorldPocketTable in pocket_tables:
		if table == null or table.pockets.is_empty():
			return "an empty pocket table"
	return ""
