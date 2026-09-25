extends SceneTree
## Headless contract gate for the deterministic 14x14 tactical world.

const WORLD_MAP_SCENE: PackedScene = preload("res://scenes/world/world_map_2d.tscn")
const GAME_WORLD_SCENE: PackedScene = preload("res://scenes/game/game_world.tscn")
const NETWORK_PLAYER_SCENE: PackedScene = preload("res://scenes/characters/network_player.tscn")
const EXPECTED_GRID_SIZE: int = 14
const EXPECTED_CELL_SIZE: float = 2048.0
const EXPECTED_HALF_EXTENT: float = 14336.0
const EXPECTED_WORLD_SIZE: float = 28672.0
const EXPECTED_GROUND_Z: int = -20
const EXPECTED_DECOR_Z: int = -5
const EXPECTED_AMBIENT_SCENERY_Z: int = -4
const EXPECTED_WILDERNESS_ACCENT_Z: int = -5
const EXPECTED_ENTITY_Z: int = 5
const EXPECTED_BOUNDARY_COUNT: int = 4
const EXPECTED_FLOW_DIMENSION: int = 112
const EXPECTED_NATURE_TILES_PER_MACRO_CELL: int = 4
const EXPECTED_NATURE_VARIANT_MINIMUM: int = 5
const EXPECTED_NATURE_ATLAS_PATH: String = "res://assets/tiles/claw_forest_ground.png"
const EXPECTED_TREE_ATLAS_PATH: String = (
	"res://assets/2d/environment/polyhaven_wild/polyhaven_wild_atlas.png"
)
const EXPECTED_DENSE_DECOR_ZONE_TOTALS: Array[int] = [265, 193, 116, 116, 286, 124]
const EXPECTED_AMBIENT_SCENERY_ZONE_TOTALS: Array[int] = [96, 72, 48, 48, 236, 92, 48]
const EXPECTED_AMBIENT_SCENERY_TOTAL: int = 640
const EXPECTED_WILDERNESS_ACCENT_ANCHOR_TOTAL: int = 24
const WILDERNESS_ACCENT_MINIMUM_SPAN: float = 112.0
const WILDERNESS_ACCENT_MAXIMUM_SPAN: float = 160.0
const WILDERNESS_ACCENT_CAMP_CLEAR_RADIUS: float = 1760.0
const WILDERNESS_ACCENT_ROAD_CLEARANCE: float = 480.0
const EXPECTED_WILDERNESS_ACCENT_ATLAS_PATH: String = (
	"res://assets/2d/environment/polyhaven/polyhaven_environment_atlas.png"
)
## Re-pinned for the East Kylat relayout (hamlet plus walled grave plot), which
## moves colliding houses, walls, poles, a ruin and three dressing props, and
## again for the camp's dirt spur, whose verge keeps the forest stands off it. The
## visual-only layers added beside it - understory, camp clearing and grave
## rows - are configured after the bake and write no flow, which this pin keeps
## proving: any change to them leaves it where it is. Re-pinned a third time for
## Phase 4's district jobs, whose Kaupunki street walls and Ostari parked cars
## are colliding footprints; the urban fabric beside them writes no flow, and
## `_validate_district_jobs` proves the walls leave the spine's two flow columns
## open.
const EXPECTED_FLOW_FIELD_MASK_HASH: String = (
	"5a08ceb28d008d6f80c599f0c1c9408065d5e1cd63e4055b15e38093497b49a2"
)
## Share of the Kaupunki spine, sampled every 50 units, where a building face
## stands inside a 0.38 gameplay frame (632 units either side of the centreline).
## Before the street walls it was 0.000 on both sides: every ruin stood 889 to
## 1,000 units off the centreline, just outside the frame. With them it is 0.793
## on at least one side and 0.533 west, 0.592 east.
const MINIMUM_CITY_FRONTAGE_EITHER_SIDE: float = 0.75
const MINIMUM_CITY_FRONTAGE_EACH_SIDE: float = 0.45
const GAMEPLAY_HALF_FRAME_WIDTH: float = 632.0
const EXPECTED_OSTARI_PARKING_BAYS: int = 34
const AMBIENT_SCENERY_CAMP_CLEAR_RADIUS: float = 1760.0
const AMBIENT_SCENERY_ROAD_CLEARANCE: float = 480.0
const AMBIENT_SCENERY_CONNECTOR_ROAD_CLEARANCE: float = 360.0
## Forest and wilderness dress their own tracks closer than the districts do;
## see `WorldAmbientScenery2D.FOREST_ROAD_EDGE_CLEARANCE` for why a layer that
## cannot occlude a gameplay participant does not owe a road the urban verge.
const AMBIENT_SCENERY_FOREST_ROAD_CLEARANCE: float = 300.0
const AMBIENT_SCENERY_STRUCTURAL_SEPARATION: float = 340.0
const AMBIENT_SCENERY_SCRIPT: Script = preload("res://src/world/world_ambient_scenery_2d.gd")
const WILDERNESS_ACCENT_SCRIPT: Script = preload("res://src/world/world_wilderness_accent_2d.gd")
const PLAYER_RADIUS: float = 34.0
const MAX_ROAD_CHUNK_SPAN: float = 4640.0
const MAX_DECOR_CHUNK_SPAN: float = 4896.0
const MAX_AMBIENT_SCENERY_CHUNK_SPAN: float = 5500.0
const MAX_WILDERNESS_ACCENT_CHUNK_SPAN: float = 4800.0
const CAMP_ROUTE_MARGIN: float = 96.0
const EXPECTED_STARTING_CAMP_POSITION: Vector2 = Vector2(9950.0, 2400.0)
const EXPECTED_STARTING_CAMP_ROAD_EDGE_DISTANCE: float = 2098.0
const COOP_SPAWN_OFFSETS: Array[Vector2] = [
	Vector2(-220.0, 285.0),
	Vector2(-75.0, 380.0),
	Vector2(70.0, 285.0),
	Vector2(215.0, 380.0),
]
const STARTER_RESOURCE_OFFSETS: Array[Vector2] = [
	Vector2(390.0, 120.0),
	Vector2(-410.0, 150.0),
	Vector2(130.0, -430.0),
]
const EXPECTED_CAMP_SATELLITE_OFFSETS: Dictionary = {
	&"StartingCampBedding": Vector2(-780.0, -240.0),
	&"StartingCampSupplyCache": Vector2(350.0, 650.0),
	&"StartingCampMedicalCache": Vector2(0.0, 720.0),
}
const VILLAGE_DRESSING_MINIMUM_ROAD_EDGE_CLEARANCE: float = 520.0
const EXPECTED_VILLAGE_DRESSING: Dictionary = {
	&"WestVillageScrapCache": {
		&"position": Vector2(-9300.0, 8200.0),
		&"kind": WorldObstacle2D.VisualKind.SCRAP_PILE,
		&"biome": BesprenWorldMap2D.Biome.VILLAGE_WEST,
	},
	&"WestVillageMossRock": {
		&"position": Vector2(-6750.0, 8450.0),
		&"kind": WorldObstacle2D.VisualKind.MOSSY_ROCK,
		&"biome": BesprenWorldMap2D.Biome.VILLAGE_WEST,
	},
	&"WestVillageFallenLog": {
		&"position": Vector2(-9300.0, 8950.0),
		&"kind": WorldObstacle2D.VisualKind.FALLEN_LOG,
		&"biome": BesprenWorldMap2D.Biome.VILLAGE_WEST,
	},
	&"EastVillageVehicleWreck": {
		&"position": Vector2(6750.0, 10450.0),
		&"kind": WorldObstacle2D.VisualKind.VEHICLE_WRECK,
		&"biome": BesprenWorldMap2D.Biome.VILLAGE_EAST,
	},
	&"EastVillageScrapCache": {
		&"position": Vector2(4900.0, 8300.0),
		&"kind": WorldObstacle2D.VisualKind.SCRAP_PILE,
		&"biome": BesprenWorldMap2D.Biome.VILLAGE_EAST,
	},
	&"EastVillageMossRock": {
		&"position": Vector2(10800.0, 10600.0),
		&"kind": WorldObstacle2D.VisualKind.MOSSY_ROCK,
		&"biome": BesprenWorldMap2D.Biome.VILLAGE_EAST,
	},
}
const EXPECTED_BIOME_COUNTS: Array[int] = [
	78,
	25,
	16,
	16,
	16,
	45,
]

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	call_deferred(&"_run")


func _run() -> void:
	var world_map: BesprenWorldMap2D = WORLD_MAP_SCENE.instantiate() as BesprenWorldMap2D
	_check(world_map != null, "World map scene instantiates as BesprenWorldMap2D")
	if world_map == null:
		_finish()
		return
	root.add_child(world_map)
	await process_frame
	world_map.ensure_built()

	_validate_dimensions(world_map)
	_validate_biomes(world_map)
	_validate_render_layers(world_map)
	_validate_gameplay_entity_layers()
	_validate_collision_contract(world_map)
	_validate_flow_field(world_map)
	_validate_motion_resolver(world_map)
	_validate_forest_understory(world_map)
	_validate_camp_clearing(world_map)
	_validate_east_rest(world_map)
	_validate_composition(world_map)
	_validate_road_hierarchy(world_map)
	_validate_district_jobs(world_map)

	world_map.queue_free()
	await process_frame
	_finish()


func _validate_dimensions(world_map: BesprenWorldMap2D) -> void:
	_check(BesprenWorldMap2D.GRID_SIZE == EXPECTED_GRID_SIZE, "Macro grid is exactly 14x14")
	_check(is_equal_approx(BesprenWorldMap2D.CELL_SIZE, EXPECTED_CELL_SIZE), "Macro cell size is exactly 2048")
	_check(
		is_equal_approx(BesprenWorldMap2D.PLAYABLE_HALF_EXTENT, EXPECTED_HALF_EXTENT),
		"Playable half extent is exactly 14336"
	)
	_check(is_equal_approx(BesprenWorldMap2D.WORLD_SIZE, EXPECTED_WORLD_SIZE), "World canvas size is exactly 28672")
	_check(
		BesprenWorldMap2D.GRID_SIZE * BesprenWorldMap2D.CELL_SIZE == BesprenWorldMap2D.WORLD_SIZE,
		"Fourteen macro cells span the complete world canvas"
	)
	_check(
		world_map.get_world_size().is_equal_approx(Vector2(EXPECTED_WORLD_SIZE, EXPECTED_WORLD_SIZE)),
		"World API reports a 28672x28672 canvas"
	)
	_check(
		BesprenWorldMap2D.STARTING_CAMP_POSITION.is_equal_approx(
			EXPECTED_STARTING_CAMP_POSITION
		),
		"Starting camp owns the exact secluded east-forest position (9950, 2400)"
	)
	_check(
		is_equal_approx(
			world_map.get_minimum_road_edge_distance_excluding_camp_spur(
				BesprenWorldMap2D.STARTING_CAMP_POSITION
			),
			EXPECTED_STARTING_CAMP_ROAD_EDGE_DISTANCE
		),
		"Starting camp center is exactly 2098 world units from its nearest road edge other than its own spur"
	)
	_check(
		world_map.get_minimum_road_edge_distance_excluding_camp_spur(
			BesprenWorldMap2D.STARTING_CAMP_POSITION
		) - BesprenWorldMap2D.CORE_COLLISION_RADIUS
		>= BesprenWorldMap2D.STARTING_CAMP_REQUIRED_ROAD_EDGE_CLEARANCE,
		"Complete Base footprint preserves at least 1600 units from every road edge but its spur"
	)
	var expected_rect: Rect2 = Rect2(
		Vector2(-EXPECTED_HALF_EXTENT, -EXPECTED_HALF_EXTENT),
		Vector2(EXPECTED_WORLD_SIZE, EXPECTED_WORLD_SIZE)
	)
	_check(_rect_is_equal_approx(world_map.get_playable_rect(), expected_rect), "Playable rectangle is centered on the 2D origin")


func _validate_biomes(world_map: BesprenWorldMap2D) -> void:
	var regions: Dictionary[StringName, Rect2] = world_map.get_biome_regions()
	var expected_regions: Dictionary[StringName, Rect2] = {
		&"kaupunki": Rect2(Vector2(-12288.0, -12288.0), Vector2(10240.0, 10240.0)),
		&"ostari": Rect2(Vector2(0.0, -10240.0), Vector2(8192.0, 8192.0)),
		&"kyla_west": Rect2(Vector2(-12288.0, 4096.0), Vector2(8192.0, 8192.0)),
		&"kyla_east": Rect2(Vector2(4096.0, 4096.0), Vector2(8192.0, 8192.0)),
		&"metsa_perimeter": world_map.get_playable_rect(),
	}
	_check(regions.size() == expected_regions.size(), "Biome API exposes the five tactical blueprint regions")
	var all_regions_match: bool = true
	for region_name: StringName in expected_regions:
		if not regions.has(region_name):
			all_regions_match = false
			continue
		if not _rect_is_equal_approx(regions[region_name], expected_regions[region_name]):
			all_regions_match = false
	_check(all_regions_match, "Kaupunki, Ostari, both Kylat, and Metsa regions match the blueprint")

	var counted_cells: int = 0
	var every_cell_has_valid_biome: bool = true
	for biome: int in range(BesprenWorldMap2D.Biome.size()):
		var biome_count: int = world_map.get_biome_cell_count(biome)
		counted_cells += biome_count
		_check(
			biome_count == EXPECTED_BIOME_COUNTS[biome],
			"Biome %s owns exactly %d cells" % [
				String(BesprenWorldMap2D.Biome.keys()[biome]),
				EXPECTED_BIOME_COUNTS[biome],
			]
		)
	for row: int in range(EXPECTED_GRID_SIZE):
		for column: int in range(EXPECTED_GRID_SIZE):
			var biome_at_cell: int = world_map.get_biome_at_cell(Vector2i(column, row))
			if biome_at_cell < 0 or biome_at_cell >= BesprenWorldMap2D.Biome.size():
				every_cell_has_valid_biome = false
	_check(counted_cells == EXPECTED_GRID_SIZE * EXPECTED_GRID_SIZE, "Biome counts cover all 196 macro cells")
	_check(every_cell_has_valid_biome, "Every in-bounds macro cell resolves to one valid biome")
	_check(world_map.get_biome_at_cell(Vector2i(-1, 0)) == -1, "Out-of-bounds macro cells are rejected")
	_check(world_map.get_biome_at_cell(Vector2i(1, 1)) == BesprenWorldMap2D.Biome.CITY, "Kaupunki cell resolves to City")
	_check(world_map.get_biome_at_cell(Vector2i(7, 2)) == BesprenWorldMap2D.Biome.MALL, "Ostari cell resolves to Mall")
	_check(world_map.get_biome_at_cell(Vector2i(1, 9)) == BesprenWorldMap2D.Biome.VILLAGE_WEST, "Western Kyla cell resolves correctly")
	_check(world_map.get_biome_at_cell(Vector2i(9, 9)) == BesprenWorldMap2D.Biome.VILLAGE_EAST, "Eastern Kyla cell resolves correctly")
	_check(world_map.get_biome_at_cell(Vector2i(0, 0)) == BesprenWorldMap2D.Biome.FOREST, "Perimeter cell resolves to Metsa")
	_check(world_map.get_biome_at_cell(Vector2i(6, 6)) == BesprenWorldMap2D.Biome.WILDERNESS, "Open connector cell resolves to Wilderness")


func _validate_render_layers(world_map: BesprenWorldMap2D) -> void:
	var ground_tiles: TileMapLayer = world_map.get_node_or_null("GroundTiles") as TileMapLayer
	var terrain_details: Node2D = world_map.get_node_or_null("TerrainDetails") as Node2D
	var terrain_tiles: TileMapLayer = world_map.get_node_or_null("TerrainDetails/TerrainTiles") as TileMapLayer
	var road_network: WorldRoadNetwork2D = world_map.get_node_or_null("TerrainDetails/RoadNetwork") as WorldRoadNetwork2D
	var background_decor: WorldBackgroundDecor2D = world_map.get_node_or_null("BackgroundDecor") as WorldBackgroundDecor2D
	var wilderness_accent: Node2D = world_map.get_node_or_null("WildernessAccent") as Node2D
	var ambient_scenery: Node2D = world_map.get_node_or_null("AmbientScenery") as Node2D
	var structures: Node2D = world_map.get_node_or_null("Structures") as Node2D
	_check(ground_tiles != null, "GroundTiles layer exists")
	_check(terrain_details != null, "TerrainDetails layer exists")
	_check(terrain_tiles != null, "TerrainTiles layer exists")
	_check(road_network != null, "RoadNetwork layer exists")
	_check(background_decor != null, "BackgroundDecor layer exists")
	_check(wilderness_accent != null, "WildernessAccent visual-only layer exists")
	_check(ambient_scenery != null, "AmbientScenery visual-only layer exists")
	_check(structures != null, "Structures entity container exists")
	if ground_tiles != null:
		_check_absolute_z(ground_tiles, EXPECTED_GROUND_Z, "GroundTiles")
		_check(ground_tiles.get_used_cells().size() == EXPECTED_GRID_SIZE * EXPECTED_GRID_SIZE, "GroundTiles covers all 196 macro cells")
	if terrain_details != null:
		_check_absolute_z(terrain_details, EXPECTED_GROUND_Z, "TerrainDetails")
	if terrain_tiles != null:
		_check_absolute_z(terrain_tiles, EXPECTED_GROUND_Z, "TerrainTiles")
		_validate_nature_tiles(world_map, terrain_tiles)
	if road_network != null:
		_check_absolute_z(road_network, EXPECTED_GROUND_Z, "RoadNetwork")
		_check(road_network.get_route_count() == 9, "Road network exposes all nine authored routes, the camp spur included")
		var routes_are_valid: bool = true
		for route: PackedVector2Array in road_network.get_routes():
			if route.size() < 2:
				routes_are_valid = false
		_check(routes_are_valid, "Every road route contains at least one traversable segment")
		_validate_road_render_chunks(road_network)
	if background_decor != null:
		_check_absolute_z(background_decor, EXPECTED_DECOR_Z, "BackgroundDecor")
		_check(
			background_decor.get_decoration_count() == WorldBackgroundDecor2D.TOTAL_DECORATION_COUNT,
			"Background decor batches rubble, cracks, moss, and nine prop families"
		)
		_validate_decor_render_chunks(background_decor)
	if wilderness_accent != null:
		_check_absolute_z(wilderness_accent, EXPECTED_WILDERNESS_ACCENT_Z, "WildernessAccent")
		_validate_wilderness_accent(world_map, wilderness_accent)
	if ambient_scenery != null:
		_check_absolute_z(ambient_scenery, EXPECTED_AMBIENT_SCENERY_Z, "AmbientScenery")
		_validate_ambient_scenery(world_map, ambient_scenery)
	_check(world_map.y_sort_enabled, "World map root explicitly enables Y-sort")
	if structures != null:
		_check_absolute_z(structures, EXPECTED_ENTITY_Z, "Structures")
		_check(structures.y_sort_enabled, "Structures container explicitly enables Y-sort")


func _validate_road_render_chunks(road_network: WorldRoadNetwork2D) -> void:
	var chunks: Array[WorldRoadSegmentChunk2D] = road_network.get_render_chunks()
	var bounds: Array[Rect2] = road_network.get_render_chunk_bounds()
	_check(chunks.size() > road_network.get_route_count(), "Road rendering is split across multiple bounded CanvasItems")
	_check(bounds.size() == chunks.size(), "Every road render chunk exposes one culling bound")
	var every_chunk_is_bounded: bool = not chunks.is_empty()
	var every_chunk_uses_ground_z: bool = not chunks.is_empty()
	for chunk_index: int in range(chunks.size()):
		var chunk_bounds: Rect2 = bounds[chunk_index]
		if (
			chunk_bounds.size.x > MAX_ROAD_CHUNK_SPAN
			or chunk_bounds.size.y > MAX_ROAD_CHUNK_SPAN
			or chunk_bounds.size.x >= EXPECTED_WORLD_SIZE
			or chunk_bounds.size.y >= EXPECTED_WORLD_SIZE
		):
			every_chunk_is_bounded = false
		if chunks[chunk_index].z_index != EXPECTED_GROUND_Z or chunks[chunk_index].z_as_relative:
			every_chunk_uses_ground_z = false
	_check(every_chunk_is_bounded, "No road CanvasItem spans the 28672-unit world")
	_check(every_chunk_uses_ground_z, "Every road chunk stays on absolute terrain z=-20")


func _validate_decor_render_chunks(background_decor: WorldBackgroundDecor2D) -> void:
	var chunks: Array[WorldBackgroundDecorChunk2D] = background_decor.get_render_chunks()
	var bounds: Array[Rect2] = background_decor.get_render_chunk_bounds()
	var zone_counts: PackedInt32Array = background_decor.get_zone_decoration_counts()
	_check(
		background_decor.get_decoration_count() == WorldBackgroundDecor2D.TOTAL_DECORATION_COUNT
		and WorldBackgroundDecor2D.TOTAL_DECORATION_COUNT == 1100
		and Array(zone_counts) == EXPECTED_DENSE_DECOR_ZONE_TOTALS,
		"Every world zone receives its dense 1100-mark rubble, foliage, and prop allocation"
	)
	_check(chunks.size() > 1, "Background decorations are split across multiple regional CanvasItems")
	_check(bounds.size() == chunks.size(), "Every background render chunk exposes one culling bound")
	_check(
		background_decor.get_chunked_decoration_count() == background_decor.get_decoration_count(),
		"Regional decor chunks retain all 1100 deterministic decorations"
	)
	var every_chunk_is_bounded: bool = not chunks.is_empty()
	var every_chunk_uses_decor_z: bool = not chunks.is_empty()
	var every_chunk_uses_sleek_grade: bool = not chunks.is_empty()
	for chunk_index: int in range(chunks.size()):
		var chunk_bounds: Rect2 = bounds[chunk_index]
		if (
			chunk_bounds.size.x > MAX_DECOR_CHUNK_SPAN
			or chunk_bounds.size.y > MAX_DECOR_CHUNK_SPAN
			or chunk_bounds.size.x >= EXPECTED_WORLD_SIZE
			or chunk_bounds.size.y >= EXPECTED_WORLD_SIZE
		):
			every_chunk_is_bounded = false
		if chunks[chunk_index].z_index != EXPECTED_DECOR_Z or chunks[chunk_index].z_as_relative:
			every_chunk_uses_decor_z = false
		var grade_material: ShaderMaterial = chunks[chunk_index].material as ShaderMaterial
		if (
			grade_material == null
			or grade_material.shader == null
			or grade_material.shader.resource_path != "res://shaders/sleek_canvas_grade.gdshader"
		):
			every_chunk_uses_sleek_grade = false
	_check(every_chunk_is_bounded, "No background-decor CanvasItem spans the 28672-unit world")
	_check(every_chunk_uses_decor_z, "Every background chunk stays on absolute decor z=-5")
	_check(every_chunk_uses_sleek_grade, "Every prop batch uses the sleek mobile color-grade shader")
	var rubble_sizes: PackedFloat32Array = background_decor.get_rubble_sizes()
	var moss_sizes: PackedFloat32Array = background_decor.get_moss_sizes()
	var prop_sizes: PackedFloat32Array = background_decor.get_prop_sizes()
	var decor_size_metadata_is_sound: bool = (
		rubble_sizes.size() == background_decor.get_rubble_positions().size()
		and moss_sizes.size() == background_decor.get_moss_positions().size()
		and prop_sizes.size() == background_decor.get_prop_positions().size()
	)
	for size: float in rubble_sizes:
		if not is_finite(size) or size <= 0.0:
			decor_size_metadata_is_sound = false
	for size: float in moss_sizes:
		if not is_finite(size) or size <= 0.0:
			decor_size_metadata_is_sound = false
	for size: float in prop_sizes:
		if not is_finite(size) or size <= 0.0:
			decor_size_metadata_is_sound = false
	_check(
		decor_size_metadata_is_sound,
		"Background decor exposes finite read-only size metadata for visual-envelope review"
	)
	_check(
		WorldBackgroundDecor2D.CAMP_POSITION.is_equal_approx(
			BesprenWorldMap2D.STARTING_CAMP_POSITION
		),
		"Background-decor clearing follows the exact relocated camp position"
	)
	var camp_clear_radius_squared: float = WorldBackgroundDecor2D.CAMP_CLEAR_RADIUS * WorldBackgroundDecor2D.CAMP_CLEAR_RADIUS
	var all_forest_details_clear_camp: bool = true
	for moss_position: Vector2 in background_decor.get_moss_positions():
		if moss_position.distance_squared_to(BesprenWorldMap2D.STARTING_CAMP_POSITION) < camp_clear_radius_squared:
			all_forest_details_clear_camp = false
	for prop_position: Vector2 in background_decor.get_prop_positions():
		if prop_position.distance_squared_to(BesprenWorldMap2D.STARTING_CAMP_POSITION) < camp_clear_radius_squared:
			all_forest_details_clear_camp = false
	_check(
		all_forest_details_clear_camp,
		"Moss and prop scatter preserve the relocated camp's 1360-unit visual clearing"
	)

	var deterministic_copy: WorldBackgroundDecor2D = WorldBackgroundDecor2D.new()
	deterministic_copy.configure(
		BesprenWorldMap2D.PLAYABLE_HALF_EXTENT,
		BesprenWorldMap2D.WORLD_BUILD_SEED + 91
	)
	_check(
		deterministic_copy.get_rubble_positions() == background_decor.get_rubble_positions()
		and deterministic_copy.get_crack_starts() == background_decor.get_crack_starts()
		and deterministic_copy.get_crack_ends() == background_decor.get_crack_ends()
		and deterministic_copy.get_moss_positions() == background_decor.get_moss_positions()
		and deterministic_copy.get_rubble_sizes() == rubble_sizes
		and deterministic_copy.get_moss_sizes() == moss_sizes
		and deterministic_copy.get_prop_positions() == background_decor.get_prop_positions()
		and deterministic_copy.get_prop_sizes() == prop_sizes
		and deterministic_copy.get_prop_kinds() == background_decor.get_prop_kinds(),
		"Background chunking preserves the exact seeded layout and prop-family stream"
	)
	deterministic_copy.free()


func _validate_wilderness_accent(world_map: BesprenWorldMap2D, wilderness_accent: Node2D) -> void:
	var anchor_count_variant: Variant = wilderness_accent.call(&"get_anchor_count")
	var positions_variant: Variant = wilderness_accent.call(&"get_anchor_positions")
	var spans_variant: Variant = wilderness_accent.call(&"get_anchor_spans")
	var rotations_variant: Variant = wilderness_accent.call(&"get_anchor_rotations")
	var recipes_variant: Variant = wilderness_accent.call(&"get_anchor_recipes")
	var variants_variant: Variant = wilderness_accent.call(&"get_anchor_variants")
	var radii_variant: Variant = wilderness_accent.call(&"get_anchor_visual_radii")
	var frame_counts_variant: Variant = wilderness_accent.call(&"get_anchor_frame_counts")
	var chunks_variant: Variant = wilderness_accent.call(&"get_render_chunks")
	var bounds_variant: Variant = wilderness_accent.call(&"get_render_chunk_bounds")
	var chunked_anchor_count_variant: Variant = wilderness_accent.call(&"get_chunked_anchor_count")
	var frame_count_variant: Variant = wilderness_accent.call(&"get_frame_count")
	var positions: PackedVector2Array = PackedVector2Array()
	var spans: PackedFloat32Array = PackedFloat32Array()
	var rotations: PackedFloat32Array = PackedFloat32Array()
	var recipes: PackedInt32Array = PackedInt32Array()
	var variants: PackedInt32Array = PackedInt32Array()
	var radii: PackedFloat32Array = PackedFloat32Array()
	var frame_counts: PackedInt32Array = PackedInt32Array()
	var chunks: Array = []
	var bounds: Array = []
	if positions_variant is PackedVector2Array:
		positions = positions_variant
	if spans_variant is PackedFloat32Array:
		spans = spans_variant
	if rotations_variant is PackedFloat32Array:
		rotations = rotations_variant
	if recipes_variant is PackedInt32Array:
		recipes = recipes_variant
	if variants_variant is PackedInt32Array:
		variants = variants_variant
	if radii_variant is PackedFloat32Array:
		radii = radii_variant
	if frame_counts_variant is PackedInt32Array:
		frame_counts = frame_counts_variant
	if chunks_variant is Array:
		chunks = chunks_variant
	if bounds_variant is Array:
		bounds = bounds_variant
	_check(
		anchor_count_variant is int
		and anchor_count_variant == EXPECTED_WILDERNESS_ACCENT_ANCHOR_TOTAL
		and positions.size() == EXPECTED_WILDERNESS_ACCENT_ANCHOR_TOTAL
		and spans.size() == EXPECTED_WILDERNESS_ACCENT_ANCHOR_TOTAL
		and rotations.size() == EXPECTED_WILDERNESS_ACCENT_ANCHOR_TOTAL
		and recipes.size() == EXPECTED_WILDERNESS_ACCENT_ANCHOR_TOTAL
		and variants.size() == EXPECTED_WILDERNESS_ACCENT_ANCHOR_TOTAL
		and radii.size() == EXPECTED_WILDERNESS_ACCENT_ANCHOR_TOTAL
		and frame_counts.size() == EXPECTED_WILDERNESS_ACCENT_ANCHOR_TOTAL,
		"WildernessAccent owns exactly 24 independent low-profile ecology anchors"
	)
	_check(
		chunks.size() > 1
		and bounds.size() == chunks.size()
		and chunked_anchor_count_variant is int
		and chunked_anchor_count_variant == EXPECTED_WILDERNESS_ACCENT_ANCHOR_TOTAL,
		"WildernessAccent batches every anchor into bounded regional CanvasItems"
	)
	_check(
		frame_count_variant is int
		and frame_count_variant >= EXPECTED_WILDERNESS_ACCENT_ANCHOR_TOTAL * 2
		and frame_count_variant <= EXPECTED_WILDERNESS_ACCENT_ANCHOR_TOTAL * 4,
		"WildernessAccent keeps its Poly Haven moss-rock recipes inside the 2-4 frame mobile budget"
	)
	var every_anchor_is_safe: bool = positions.size() == EXPECTED_WILDERNESS_ACCENT_ANCHOR_TOTAL
	var recipes_are_supported: bool = recipes.size() == EXPECTED_WILDERNESS_ACCENT_ANCHOR_TOTAL
	var every_anchor_stays_inside_mobile_frame_budget: bool = (
		frame_counts.size() == EXPECTED_WILDERNESS_ACCENT_ANCHOR_TOTAL
	)
	for anchor_index: int in range(positions.size()):
		var position: Vector2 = positions[anchor_index]
		var in_pocket_variant: Variant = wilderness_accent.call(
			&"is_position_in_wilderness_pocket",
			position
		)
		if (
			not position.is_finite()
			or not in_pocket_variant is bool
			or not in_pocket_variant
			or position.distance_to(BesprenWorldMap2D.STARTING_CAMP_POSITION)
				< WILDERNESS_ACCENT_CAMP_CLEAR_RADIUS
			or world_map.get_minimum_road_edge_distance(position) < WILDERNESS_ACCENT_ROAD_CLEARANCE
			or not world_map.is_position_walkable(position, radii[anchor_index])
		):
			every_anchor_is_safe = false
		if (
			spans[anchor_index] < WILDERNESS_ACCENT_MINIMUM_SPAN
			or spans[anchor_index] > WILDERNESS_ACCENT_MAXIMUM_SPAN
			or not is_equal_approx(radii[anchor_index], spans[anchor_index] * 0.90 + 38.0)
			or recipes[anchor_index] < 0
			or recipes[anchor_index] >= 4
		):
			recipes_are_supported = false
		if frame_counts[anchor_index] < 2 or frame_counts[anchor_index] > 4:
			every_anchor_stays_inside_mobile_frame_budget = false
		for previous_index: int in range(anchor_index):
			if position.distance_to(positions[previous_index]) < 300.0:
				every_anchor_is_safe = false
	_check(
		every_anchor_is_safe,
		"Every wilderness anchor stays finite, pocket-bounded, obstacle-clear, camp-clear, and road-clear"
	)
	_check(
		recipes_are_supported,
		"WildernessAccent uses only bounded low-profile moss-rock recipe IDs and spans"
	)
	_check(
		every_anchor_stays_inside_mobile_frame_budget,
		"Every WildernessAccent anchor individually stays inside the 2-4 frame mobile budget"
	)
	var every_chunk_is_bounded: bool = not chunks.is_empty()
	var every_chunk_is_decor_z: bool = not chunks.is_empty()
	var every_chunk_uses_sleek_grade: bool = not chunks.is_empty()
	var every_chunk_uses_mipped_polyhaven_atlas: bool = not chunks.is_empty()
	for chunk_index: int in range(chunks.size()):
		var chunk: Node2D = chunks[chunk_index] as Node2D
		if chunk == null or not bounds[chunk_index] is Rect2:
			every_chunk_is_bounded = false
			every_chunk_is_decor_z = false
			every_chunk_uses_sleek_grade = false
			every_chunk_uses_mipped_polyhaven_atlas = false
			continue
		var chunk_bounds: Rect2 = bounds[chunk_index]
		if (
			chunk_bounds.size.x > MAX_WILDERNESS_ACCENT_CHUNK_SPAN
			or chunk_bounds.size.y > MAX_WILDERNESS_ACCENT_CHUNK_SPAN
			or chunk_bounds.size.x >= EXPECTED_WORLD_SIZE
			or chunk_bounds.size.y >= EXPECTED_WORLD_SIZE
		):
			every_chunk_is_bounded = false
		if chunk.z_index != EXPECTED_WILDERNESS_ACCENT_Z or chunk.z_as_relative:
			every_chunk_is_decor_z = false
		var grade_material: ShaderMaterial = chunk.material as ShaderMaterial
		if (
			grade_material == null
			or grade_material.shader == null
			or grade_material.shader.resource_path != "res://shaders/sleek_canvas_grade.gdshader"
		):
			every_chunk_uses_sleek_grade = false
		var source_texture_variant: Variant = chunk.call(&"get_source_texture")
		if (
			not source_texture_variant is Texture2D
			or (source_texture_variant as Texture2D).resource_path != EXPECTED_WILDERNESS_ACCENT_ATLAS_PATH
			or chunk.texture_filter != CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		):
			every_chunk_uses_mipped_polyhaven_atlas = false
	_check(every_chunk_is_bounded, "No WildernessAccent CanvasItem spans the 28672-unit world")
	_check(every_chunk_is_decor_z, "Every WildernessAccent chunk stays behind ambient silhouettes at absolute z=-5")
	_check(every_chunk_uses_sleek_grade, "Every WildernessAccent batch reuses the shared mobile color grade")
	_check(
		every_chunk_uses_mipped_polyhaven_atlas,
		"Every WildernessAccent chunk reuses the shipped mipped CC0 Poly Haven atlas"
	)
	_check(
		not _subtree_has_physics(wilderness_accent),
		"WildernessAccent recursively owns no physics body, shape, obstacle, or navigation footprint"
	)
	_check(
		world_map.get_node_or_null("BackgroundDecor").get_index() < wilderness_accent.get_index()
		and wilderness_accent.get_index() < world_map.get_node_or_null("AmbientScenery").get_index(),
		"WildernessAccent draws after ground decor and before ambient tree/ruin silhouettes"
	)
	var deterministic_copy: Node2D = WILDERNESS_ACCENT_SCRIPT.new() as Node2D
	var deterministic_layout_matches: bool = deterministic_copy != null
	if deterministic_copy != null:
		deterministic_copy.call(
			&"configure",
			BesprenWorldMap2D.PLAYABLE_HALF_EXTENT,
			BesprenWorldMap2D.WORLD_BUILD_SEED + 173,
			BesprenWorldMap2D.STARTING_CAMP_POSITION,
			Callable(world_map, &"is_position_walkable"),
			Callable(world_map, &"get_minimum_road_edge_distance")
		)
		var copy_positions: Variant = deterministic_copy.call(&"get_anchor_positions")
		var copy_spans: Variant = deterministic_copy.call(&"get_anchor_spans")
		var copy_rotations: Variant = deterministic_copy.call(&"get_anchor_rotations")
		var copy_recipes: Variant = deterministic_copy.call(&"get_anchor_recipes")
		var copy_variants: Variant = deterministic_copy.call(&"get_anchor_variants")
		deterministic_layout_matches = (
			copy_positions is PackedVector2Array
			and copy_spans is PackedFloat32Array
			and copy_rotations is PackedFloat32Array
			and copy_recipes is PackedInt32Array
			and copy_variants is PackedInt32Array
			and copy_positions == positions
			and copy_spans == spans
			and copy_rotations == rotations
			and copy_recipes == recipes
			and copy_variants == variants
		)
		deterministic_copy.free()
	_check(
		deterministic_layout_matches,
		"WildernessAccent preserves its own exact seed stream without shifting legacy decor streams"
	)


func _validate_ambient_scenery(world_map: BesprenWorldMap2D, ambient_scenery: Node2D) -> void:
	var count_variant: Variant = ambient_scenery.call(&"get_scenery_count")
	var zone_counts_variant: Variant = ambient_scenery.call(&"get_zone_scenery_counts")
	var positions_variant: Variant = ambient_scenery.call(&"get_scenery_positions")
	var kinds_variant: Variant = ambient_scenery.call(&"get_scenery_kinds")
	var sizes_variant: Variant = ambient_scenery.call(&"get_scenery_sizes")
	var visual_radii_variant: Variant = ambient_scenery.call(&"get_scenery_visual_radii")
	var zones_variant: Variant = ambient_scenery.call(&"get_scenery_zones")
	var chunks_variant: Variant = ambient_scenery.call(&"get_render_chunks")
	var bounds_variant: Variant = ambient_scenery.call(&"get_render_chunk_bounds")
	var chunked_count_variant: Variant = ambient_scenery.call(&"get_chunked_scenery_count")
	var zone_counts: PackedInt32Array = PackedInt32Array()
	var positions: PackedVector2Array = PackedVector2Array()
	var kinds: PackedInt32Array = PackedInt32Array()
	var sizes: PackedFloat32Array = PackedFloat32Array()
	var visual_radii: PackedFloat32Array = PackedFloat32Array()
	var zones: PackedInt32Array = PackedInt32Array()
	var chunks: Array = []
	var bounds: Array = []
	if zone_counts_variant is PackedInt32Array:
		zone_counts = zone_counts_variant
	if positions_variant is PackedVector2Array:
		positions = positions_variant
	if kinds_variant is PackedInt32Array:
		kinds = kinds_variant
	if sizes_variant is PackedFloat32Array:
		sizes = sizes_variant
	if visual_radii_variant is PackedFloat32Array:
		visual_radii = visual_radii_variant
	if zones_variant is PackedInt32Array:
		zones = zones_variant
	if chunks_variant is Array:
		chunks = chunks_variant
	if bounds_variant is Array:
		bounds = bounds_variant
	_check(
		count_variant is int
		and count_variant == EXPECTED_AMBIENT_SCENERY_TOTAL
		and positions.size() == EXPECTED_AMBIENT_SCENERY_TOTAL
		and kinds.size() == EXPECTED_AMBIENT_SCENERY_TOTAL
		and sizes.size() == EXPECTED_AMBIENT_SCENERY_TOTAL
		and visual_radii.size() == EXPECTED_AMBIENT_SCENERY_TOTAL
		and zones.size() == EXPECTED_AMBIENT_SCENERY_TOTAL
		and Array(zone_counts) == EXPECTED_AMBIENT_SCENERY_ZONE_TOTALS,
		"Ambient scenery owns its exact 576 region-weighted ruin, tree, and prop groups"
	)
	var visual_radius_metadata_is_sound: bool = visual_radii.size() == positions.size()
	for scenery_index: int in range(visual_radii.size()):
		if (
			not is_finite(visual_radii[scenery_index])
			or visual_radii[scenery_index] <= 0.0
			or visual_radii[scenery_index] > sizes[scenery_index]
		):
			visual_radius_metadata_is_sound = false
	_check(
		visual_radius_metadata_is_sound,
		"Ambient visual-radius metadata is finite, positive, and bounded by its source group size"
	)
	_check(
		chunks.size() > 1
		and bounds.size() == chunks.size()
		and chunked_count_variant is int
		and chunked_count_variant == EXPECTED_AMBIENT_SCENERY_TOTAL,
		"Ambient scenery batches every visual group into bounded regional CanvasItems"
	)
	var every_chunk_is_bounded: bool = not chunks.is_empty()
	var every_chunk_is_ambient: bool = not chunks.is_empty()
	var every_chunk_uses_sleek_grade: bool = not chunks.is_empty()
	var every_child_is_visual_only: bool = true
	for child: Node in ambient_scenery.get_children():
		if child is CollisionObject2D or child is CollisionShape2D:
			every_child_is_visual_only = false
	for chunk_index: int in range(chunks.size()):
		var chunk: Node2D = chunks[chunk_index] as Node2D
		if chunk == null or not bounds[chunk_index] is Rect2:
			every_chunk_is_bounded = false
			every_chunk_is_ambient = false
			every_chunk_uses_sleek_grade = false
			continue
		var chunk_bounds: Rect2 = bounds[chunk_index]
		if (
			chunk_bounds.size.x > MAX_AMBIENT_SCENERY_CHUNK_SPAN
			or chunk_bounds.size.y > MAX_AMBIENT_SCENERY_CHUNK_SPAN
			or chunk_bounds.size.x >= EXPECTED_WORLD_SIZE
			or chunk_bounds.size.y >= EXPECTED_WORLD_SIZE
		):
			every_chunk_is_bounded = false
		if chunk.z_index != EXPECTED_AMBIENT_SCENERY_Z or chunk.z_as_relative:
			every_chunk_is_ambient = false
		var grade_material: ShaderMaterial = chunk.material as ShaderMaterial
		if (
			grade_material == null
			or grade_material.shader == null
			or grade_material.shader.resource_path != "res://shaders/sleek_canvas_grade.gdshader"
		):
			every_chunk_uses_sleek_grade = false
	_check(every_chunk_is_bounded, "No ambient-scenery CanvasItem spans the 28672-unit world")
	_check(every_chunk_is_ambient, "Every ambient-scenery chunk stays on absolute visual z=-4")
	_check(every_chunk_uses_sleek_grade, "Every ambient-scenery batch uses the shared mobile color grade")
	_check(every_child_is_visual_only, "Ambient scenery adds no physics body, collision shape, or flow-field footprint")
	var every_position_preserves_clearings: bool = positions.size() == zones.size()
	for position_index: int in range(positions.size()):
		var zone_id: int = zones[position_index]
		var road_clearance: float = AMBIENT_SCENERY_ROAD_CLEARANCE
		if zone_id == 4 or zone_id == 5:
			road_clearance = AMBIENT_SCENERY_FOREST_ROAD_CLEARANCE
		elif zone_id == 6:
			road_clearance = AMBIENT_SCENERY_CONNECTOR_ROAD_CLEARANCE
		if (
			positions[position_index].distance_to(BesprenWorldMap2D.STARTING_CAMP_POSITION)
			< AMBIENT_SCENERY_CAMP_CLEAR_RADIUS
			or world_map.get_minimum_road_edge_distance(positions[position_index]) < road_clearance
		):
			every_position_preserves_clearings = false
	_check(
		every_position_preserves_clearings,
		"Every ambient group preserves the 1760-unit camp clearing and road centerline margins"
	)
	var has_ruins: bool = kinds.count(0) > 0 and kinds.count(1) > 0
	var has_tree_canopies: bool = kinds.count(2) > 0
	var has_props: bool = (
		kinds.count(4) > 0
		and kinds.count(5) > 0
		and kinds.count(6) > 0
		and kinds.count(7) > 0
		and kinds.count(8) > 0
		and kinds.count(9) > 0
	)
	_check(
		has_ruins and has_tree_canopies and has_props,
		"Ambient allocation visibly covers ruin facades, tree canopies, and mixed-world props"
	)
	var structural_positions: PackedVector2Array = PackedVector2Array()
	var structural_silhouettes_are_readable: bool = true
	for scenery_index: int in range(positions.size()):
		if kinds[scenery_index] != 0 and kinds[scenery_index] != 1:
			continue
		for existing_position: Vector2 in structural_positions:
			if (
				positions[scenery_index].distance_to(existing_position)
				< AMBIENT_SCENERY_STRUCTURAL_SEPARATION
			):
				structural_silhouettes_are_readable = false
		structural_positions.append(positions[scenery_index])
	_check(
		structural_silhouettes_are_readable,
		"Large non-colliding ruins keep a 340-unit composition gap from one another"
	)
	var deterministic_copy: Node2D = AMBIENT_SCENERY_SCRIPT.new() as Node2D
	var deterministic_layout_matches: bool = deterministic_copy != null
	if deterministic_copy != null:
		deterministic_copy.call(
			&"configure",
			BesprenWorldMap2D.PLAYABLE_HALF_EXTENT,
			BesprenWorldMap2D.WORLD_BUILD_SEED + 137,
			BesprenWorldMap2D.STARTING_CAMP_POSITION,
			Callable(world_map, &"is_position_walkable"),
			Callable(world_map, &"get_minimum_road_edge_distance")
		)
		var copy_positions: Variant = deterministic_copy.call(&"get_scenery_positions")
		var copy_kinds: Variant = deterministic_copy.call(&"get_scenery_kinds")
		var copy_sizes: Variant = deterministic_copy.call(&"get_scenery_sizes")
		var copy_visual_radii: Variant = deterministic_copy.call(&"get_scenery_visual_radii")
		var copy_zones: Variant = deterministic_copy.call(&"get_scenery_zones")
		deterministic_layout_matches = (
			copy_positions is PackedVector2Array
			and copy_kinds is PackedInt32Array
			and copy_zones is PackedInt32Array
			and copy_positions == positions
			and copy_kinds == kinds
			and copy_sizes is PackedFloat32Array
			and copy_visual_radii is PackedFloat32Array
			and copy_sizes == sizes
			and copy_visual_radii == visual_radii
			and copy_zones == zones
		)
		deterministic_copy.free()
	_check(
		deterministic_layout_matches,
		"Ambient scenery preserves its exact seeded layout without mutable gameplay state"
	)


func _validate_nature_tiles(
	world_map: BesprenWorldMap2D,
	terrain_tiles: TileMapLayer
) -> void:
	var tile_set_resource: TileSet = terrain_tiles.tile_set
	_check(tile_set_resource != null, "TerrainTiles owns a runtime TileSet")
	if tile_set_resource == null:
		return

	var used_cells: Array[Vector2i] = terrain_tiles.get_used_cells()
	_check(not used_cells.is_empty(), "TerrainTiles contains imported environment cells")
	_check(
		BesprenWorldMap2D.NATURE_TILES_PER_MACRO_CELL == EXPECTED_NATURE_TILES_PER_MACRO_CELL,
		"Nature coverage uses a deterministic 4x4 detail grid per macro cell"
	)
	var expected_tile_count: int = 0
	var every_expected_cell_is_filled: bool = true
	for macro_row: int in range(EXPECTED_GRID_SIZE):
		for macro_column: int in range(EXPECTED_GRID_SIZE):
			var macro_cell: Vector2i = Vector2i(macro_column, macro_row)
			var biome: int = world_map.get_biome_at_cell(macro_cell)
			var expects_nature: bool = (
				biome == BesprenWorldMap2D.Biome.FOREST
				or biome == BesprenWorldMap2D.Biome.WILDERNESS
			)
			for detail_y: int in range(EXPECTED_NATURE_TILES_PER_MACRO_CELL):
				for detail_x: int in range(EXPECTED_NATURE_TILES_PER_MACRO_CELL):
					var detail_cell: Vector2i = Vector2i(
						macro_column * EXPECTED_NATURE_TILES_PER_MACRO_CELL + detail_x,
						macro_row * EXPECTED_NATURE_TILES_PER_MACRO_CELL + detail_y
					)
					var cell_is_filled: bool = terrain_tiles.get_cell_source_id(detail_cell) >= 0
					if expects_nature:
						expected_tile_count += 1
					if cell_is_filled != expects_nature:
						every_expected_cell_is_filled = false
	_check(
		used_cells.size() == expected_tile_count,
		"TerrainTiles covers every Forest/Wilderness macro cell with exactly 4x4 detail cells"
	)
	_check(
		every_expected_cell_is_filled,
		"Nature detail cells have no holes or spillover outside Forest/Wilderness biomes"
	)

	var atlas_variants: Dictionary[Vector2i, bool] = {}
	var every_used_cell_uses_imported_atlas: bool = not used_cells.is_empty()
	for used_cell: Vector2i in used_cells:
		atlas_variants[terrain_tiles.get_cell_atlas_coords(used_cell)] = true
		var source_id: int = terrain_tiles.get_cell_source_id(used_cell)
		var atlas_source: TileSetAtlasSource = (
			tile_set_resource.get_source(source_id) as TileSetAtlasSource
		)
		if (
			atlas_source == null
			or atlas_source.texture == null
			or atlas_source.texture.resource_path != EXPECTED_NATURE_ATLAS_PATH
		):
			every_used_cell_uses_imported_atlas = false
	_check(
		atlas_variants.size() >= EXPECTED_NATURE_VARIANT_MINIMUM,
		"TerrainTiles uses at least five imported atlas-coordinate variants"
	)
	_check(
		every_used_cell_uses_imported_atlas,
		"Every nature detail cell uses res://assets/tiles/claw_forest_ground.png"
	)


func _validate_collision_contract(world_map: BesprenWorldMap2D) -> void:
	var obstacles: Array[WorldObstacle2D] = world_map.get_obstacle_nodes()
	var category_counts: PackedInt32Array = PackedInt32Array()
	category_counts.resize(WorldObstacle2D.VisualKind.size())
	category_counts.fill(0)
	var every_obstacle_has_collision: bool = not obstacles.is_empty()
	var every_shape_matches_kind: bool = not obstacles.is_empty()
	var every_obstacle_uses_static_layer: bool = not obstacles.is_empty()
	var every_obstacle_uses_entity_z: bool = not obstacles.is_empty()
	var every_obstacle_blocks_its_center: bool = not obstacles.is_empty()
	var tree_count: int = 0
	var camp_satellite_count: int = 0
	var camp_names: Dictionary[StringName, bool] = {}
	var every_camp_satellite_is_rectangular: bool = true
	var every_camp_satellite_clears_core: bool = true
	var every_camp_satellite_clears_routes: bool = true
	var every_camp_satellite_is_in_forest: bool = true
	var every_camp_satellite_matches_authored_offset: bool = true
	var every_camp_satellite_preserves_deep_road_clearance: bool = true
	var every_tree_has_active_collision: bool = true
	var every_tree_has_imported_visual: bool = true
	var every_tree_uses_imported_atlas: bool = true
	for obstacle: WorldObstacle2D in obstacles:
		var visual_kind: int = obstacle.get_visual_kind()
		if visual_kind >= 0 and visual_kind < category_counts.size():
			category_counts[visual_kind] += 1
		else:
			every_obstacle_has_collision = false
		var collision: CollisionShape2D = obstacle.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if collision == null or collision.shape == null:
			every_obstacle_has_collision = false
		else:
			var shape_matches: bool = (
				obstacle.get_shape_kind() == WorldObstacle2D.ShapeKind.RECTANGLE
				and collision.shape is RectangleShape2D
			) or (
				obstacle.get_shape_kind() == WorldObstacle2D.ShapeKind.CIRCLE
				and collision.shape is CircleShape2D
			)
			if not shape_matches:
				every_shape_matches_kind = false
		if obstacle.collision_layer != BesprenWorldMap2D.WORLD_STATIC_LAYER or obstacle.collision_mask != 0:
			every_obstacle_uses_static_layer = false
		if obstacle.z_index != EXPECTED_ENTITY_Z or obstacle.z_as_relative:
			every_obstacle_uses_entity_z = false
		if world_map.is_position_walkable(obstacle.position):
			every_obstacle_blocks_its_center = false
		if visual_kind == WorldObstacle2D.VisualKind.TREE:
			tree_count += 1
			var tree_body: StaticBody2D = obstacle as StaticBody2D
			if (
				tree_body == null
				or collision == null
				or collision.shape == null
				or collision.disabled
			):
				every_tree_has_active_collision = false
			var imported_visual: Sprite2D = obstacle.get_node_or_null("ImportedTreeVisual") as Sprite2D
			if imported_visual == null or imported_visual.texture == null:
				every_tree_has_imported_visual = false
				every_tree_uses_imported_atlas = false
			elif _get_texture_source_path(imported_visual.texture) != EXPECTED_TREE_ATLAS_PATH:
				every_tree_uses_imported_atlas = false
		if visual_kind in [
			WorldObstacle2D.VisualKind.CAMP_BEDDING,
			WorldObstacle2D.VisualKind.CAMP_SUPPLY_CACHE,
			WorldObstacle2D.VisualKind.CAMP_MEDICAL_CACHE,
		]:
			camp_satellite_count += 1
			camp_names[obstacle.name] = true
			if (
				not EXPECTED_CAMP_SATELLITE_OFFSETS.has(obstacle.name)
				or not obstacle.position.is_equal_approx(
					BesprenWorldMap2D.STARTING_CAMP_POSITION
					+ EXPECTED_CAMP_SATELLITE_OFFSETS[obstacle.name]
				)
			):
				every_camp_satellite_matches_authored_offset = false
			if obstacle.get_shape_kind() != WorldObstacle2D.ShapeKind.RECTANGLE:
				every_camp_satellite_is_rectangular = false
			var footprint_radius: float = obstacle.half_size.length() + PLAYER_RADIUS
			if (
				obstacle.position.distance_to(BesprenWorldMap2D.STARTING_CAMP_POSITION)
				< BesprenWorldMap2D.STARTING_CAMP_OPEN_RADIUS + footprint_radius
			):
				every_camp_satellite_clears_core = false
			if _distance_to_routes(obstacle.position, world_map.get_road_routes()) < footprint_radius + CAMP_ROUTE_MARGIN:
				every_camp_satellite_clears_routes = false
			if (
				world_map.get_minimum_road_edge_distance_excluding_camp_spur(obstacle.position)
				- obstacle.half_size.length()
				< BesprenWorldMap2D.STARTING_CAMP_REQUIRED_ROAD_EDGE_CLEARANCE
			):
				every_camp_satellite_preserves_deep_road_clearance = false
			var macro_cell: Vector2i = Vector2i(
				floori((obstacle.position.x + EXPECTED_HALF_EXTENT) / EXPECTED_CELL_SIZE),
				floori((obstacle.position.y + EXPECTED_HALF_EXTENT) / EXPECTED_CELL_SIZE)
			)
			if world_map.get_biome_at_cell(macro_cell) != BesprenWorldMap2D.Biome.FOREST:
				every_camp_satellite_is_in_forest = false
	_check(every_obstacle_has_collision, "Every authored structure owns a CollisionShape2D")
	_check(every_shape_matches_kind, "Rectangle and circle obstacle records use matching 2D physics shapes")
	_check(every_obstacle_uses_static_layer, "Every authored obstacle uses only the WorldStatic physics layer")
	_check(every_obstacle_uses_entity_z, "Every authored obstacle resides on absolute entity z=5")
	_check(every_obstacle_blocks_its_center, "Every authored obstacle blocks its physical center")
	_check(tree_count > 0, "Collision coverage includes authored boundary trees")
	_check(every_tree_has_active_collision, "Every tree remains an active colliding StaticBody2D")
	_check(every_tree_has_imported_visual, "Every tree owns an ImportedTreeVisual Sprite2D")
	_check(
		every_tree_uses_imported_atlas,
		"Every ImportedTreeVisual uses the baked polyhaven_wild atlas"
	)
	_check(
		camp_satellite_count == BesprenWorldMap2D.STARTING_CAMP_SATELLITE_COUNT
		and camp_names.has_all([
			&"StartingCampBedding",
			&"StartingCampSupplyCache",
			&"StartingCampMedicalCache",
		]),
		"Forest camp owns exactly the three named satellite obstacles"
	)
	_check(every_camp_satellite_is_rectangular, "Every camp satellite uses an authored rectangle footprint")
	_check(every_camp_satellite_matches_authored_offset, "Camp satellites match the exact asymmetric deep-forest composition")
	_check(every_camp_satellite_clears_core, "Camp satellites preserve the central Base and build-clearance ring")
	_check(every_camp_satellite_clears_routes, "Camp satellites preserve a physical margin from every authored road segment")
	_check(
		every_camp_satellite_preserves_deep_road_clearance,
		"Every complete camp-satellite footprint stays at least 1600 units from every road edge but the spur"
	)
	_check(every_camp_satellite_is_in_forest, "Every camp satellite remains inside the secluded Forest biome")
	var spawn_and_resource_lanes_clear: bool = true
	var spawn_and_resource_lanes_are_deep: bool = true
	var clearance_offsets: Array[Vector2] = COOP_SPAWN_OFFSETS.duplicate()
	clearance_offsets.append_array(STARTER_RESOURCE_OFFSETS)
	for offset: Vector2 in clearance_offsets:
		if not world_map.is_position_walkable(
			BesprenWorldMap2D.STARTING_CAMP_POSITION + offset,
			PLAYER_RADIUS
		):
			spawn_and_resource_lanes_clear = false
		if (
			world_map.get_minimum_road_edge_distance_excluding_camp_spur(
				BesprenWorldMap2D.STARTING_CAMP_POSITION + offset
			) - PLAYER_RADIUS
			< BesprenWorldMap2D.STARTING_CAMP_REQUIRED_ROAD_EDGE_CLEARANCE
		):
			spawn_and_resource_lanes_are_deep = false
	_check(spawn_and_resource_lanes_clear, "Co-op spawn and starter-resource approach lanes remain walkable")
	_check(
		spawn_and_resource_lanes_are_deep,
		"All four co-op spawns and three starter-resource approaches stay at least 1600 units from every road edge"
	)
	_validate_village_dressing(world_map, obstacles)
	_validate_density_landmarks(world_map, obstacles)
	var every_category_present: bool = true
	for category_count: int in category_counts:
		if category_count <= 0:
			every_category_present = false
	_check(every_category_present, "Collision coverage includes every world and camp visual category")

	var world_bounds: Node2D = world_map.get_node_or_null("WorldBounds") as Node2D
	_check(world_map.get_world_boundary_count() == EXPECTED_BOUNDARY_COUNT, "World API reports exactly four collision bounds")
	_check(
		world_map.get_static_collision_count() == obstacles.size() + EXPECTED_BOUNDARY_COUNT,
		"Static collision total includes every obstacle and four bounds"
	)
	_check(world_bounds != null and world_bounds.get_child_count() == EXPECTED_BOUNDARY_COUNT, "WorldBounds owns four physical boundary bodies")
	if world_bounds == null:
		return
	var every_boundary_is_physical: bool = true
	for boundary_node: Node in world_bounds.get_children():
		var boundary: StaticBody2D = boundary_node as StaticBody2D
		if boundary == null:
			every_boundary_is_physical = false
			continue
		var boundary_collision: CollisionShape2D = boundary.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if (
			boundary_collision == null
			or not (boundary_collision.shape is RectangleShape2D)
			or boundary.collision_layer != BesprenWorldMap2D.WORLD_STATIC_LAYER
			or boundary.collision_mask != 0
			or not boundary.is_in_group(&"world_boundary")
		):
			every_boundary_is_physical = false
	_check(every_boundary_is_physical, "All four bounds are rectangular StaticBody2D collision barriers")


func _validate_village_dressing(
	world_map: BesprenWorldMap2D,
	obstacles: Array[WorldObstacle2D]
) -> void:
	var obstacles_by_name: Dictionary[StringName, WorldObstacle2D] = {}
	for obstacle: WorldObstacle2D in obstacles:
		obstacles_by_name[obstacle.name] = obstacle

	var west_count: int = 0
	var east_count: int = 0
	var west_families: Dictionary[int, bool] = {}
	var east_families: Dictionary[int, bool] = {}
	var every_record_matches: bool = true
	var every_record_uses_imported_visuals: bool = true
	var every_record_owns_its_village_biome: bool = true
	var every_record_clears_roads: bool = true
	var every_record_clears_village_shells: bool = true
	for dressing_name: StringName in EXPECTED_VILLAGE_DRESSING:
		if not obstacles_by_name.has(dressing_name):
			every_record_matches = false
			continue
		var dressing: WorldObstacle2D = obstacles_by_name[dressing_name]
		var expected: Dictionary = EXPECTED_VILLAGE_DRESSING[dressing_name]
		var expected_biome: int = expected[&"biome"]
		if (
			not dressing.position.is_equal_approx(expected[&"position"])
			or dressing.get_visual_kind() != expected[&"kind"]
		):
			every_record_matches = false
		if dressing.get_imported_visual_count() <= 0:
			every_record_uses_imported_visuals = false
		var macro_cell: Vector2i = Vector2i(
			floori((dressing.position.x + EXPECTED_HALF_EXTENT) / EXPECTED_CELL_SIZE),
			floori((dressing.position.y + EXPECTED_HALF_EXTENT) / EXPECTED_CELL_SIZE)
		)
		if world_map.get_biome_at_cell(macro_cell) != expected_biome:
			every_record_owns_its_village_biome = false
		var footprint_radius: float = (
			dressing.collision_radius
			if dressing.get_shape_kind() == WorldObstacle2D.ShapeKind.CIRCLE
			else dressing.half_size.length()
		)
		if (
			world_map.get_minimum_road_edge_distance(dressing.position)
			- footprint_radius
			< VILLAGE_DRESSING_MINIMUM_ROAD_EDGE_CLEARANCE
		):
			every_record_clears_roads = false
		for shell: WorldObstacle2D in obstacles:
			if shell == dressing or shell.name in EXPECTED_VILLAGE_DRESSING:
				continue
			if shell.get_visual_kind() not in [
				WorldObstacle2D.VisualKind.VILLAGE_HOUSE,
				WorldObstacle2D.VisualKind.WOODEN_FENCE,
				WorldObstacle2D.VisualKind.UTILITY_POLE,
			]:
				continue
			if dressing.get_world_bounds(PLAYER_RADIUS).intersects(
				shell.get_world_bounds(PLAYER_RADIUS)
			):
				every_record_clears_village_shells = false
		if expected_biome == BesprenWorldMap2D.Biome.VILLAGE_WEST:
			west_count += 1
			west_families[dressing.get_visual_kind()] = true
		else:
			east_count += 1
			east_families[dressing.get_visual_kind()] = true

	_check(
		west_count == BesprenWorldMap2D.VILLAGE_DRESSING_COUNT_PER_SIDE
		and east_count == BesprenWorldMap2D.VILLAGE_DRESSING_COUNT_PER_SIDE,
		"West and east villages each own exactly three authored dressing props"
	)
	_check(every_record_matches, "All six village dressing props match exact names, positions, and visual families")
	_check(
		west_families.size() == 3 and east_families.size() == 3,
		"Each village mixes exactly three non-fence prop families"
	)
	_check(every_record_uses_imported_visuals, "Every village dressing prop resolves an imported atlas visual")
	_check(every_record_owns_its_village_biome, "Village dressing remains inside its authored west/east biome")
	_check(
		every_record_clears_roads,
		"Every complete village dressing footprint stays at least 520 units from road edges"
	)
	_check(
		every_record_clears_village_shells,
		"Village dressing preserves player clearance from houses, fences, and utility poles"
	)


func _validate_density_landmarks(
	world_map: BesprenWorldMap2D,
	obstacles: Array[WorldObstacle2D]
) -> void:
	var city_ruin_count: int = 0
	var mall_ruin_count: int = 0
	var west_village_ruin_count: int = 0
	var east_village_ruin_count: int = 0
	var forest_stand_count: int = 0
	var wilderness_grove_count: int = 0
	var every_density_anchor_is_imported_and_clear: bool = true
	var every_dense_tree_preserves_camp_and_road_clearance: bool = true
	for obstacle: WorldObstacle2D in obstacles:
		var obstacle_name: String = String(obstacle.name)
		var expected_biome: int = -1
		if obstacle_name.begins_with("DenseCityRuin_"):
			city_ruin_count += 1
			expected_biome = BesprenWorldMap2D.Biome.CITY
		elif obstacle_name.begins_with("DenseMallRuin_"):
			mall_ruin_count += 1
			expected_biome = BesprenWorldMap2D.Biome.MALL
		elif obstacle_name.begins_with("DenseWestVillageRuin_"):
			west_village_ruin_count += 1
			expected_biome = BesprenWorldMap2D.Biome.VILLAGE_WEST
		elif obstacle_name.begins_with("DenseEastVillageRuin_"):
			east_village_ruin_count += 1
			expected_biome = BesprenWorldMap2D.Biome.VILLAGE_EAST

		if expected_biome >= 0:
			var anchor_radius: float = obstacle.half_size.length()
			var macro_cell: Vector2i = Vector2i(
				floori((obstacle.position.x + EXPECTED_HALF_EXTENT) / EXPECTED_CELL_SIZE),
				floori((obstacle.position.y + EXPECTED_HALF_EXTENT) / EXPECTED_CELL_SIZE)
			)
			if (
				obstacle.get_imported_visual_count() <= 0
				or obstacle.get_shape_kind() != WorldObstacle2D.ShapeKind.RECTANGLE
				or world_map.get_biome_at_cell(macro_cell) != expected_biome
				or world_map.get_minimum_road_edge_distance(obstacle.position) - anchor_radius
				< BesprenWorldMap2D.DENSE_LANDMARK_ROAD_EDGE_CLEARANCE
			):
				every_density_anchor_is_imported_and_clear = false

		if obstacle_name.begins_with("ForestStand_"):
			forest_stand_count += 1
		elif obstacle_name.begins_with("WildernessGrove_"):
			wilderness_grove_count += 1
		else:
			continue
		if (
			obstacle.position.distance_to(BesprenWorldMap2D.STARTING_CAMP_POSITION)
			< BesprenWorldMap2D.DENSE_TREE_CAMP_CLEAR_RADIUS
			or world_map.get_minimum_road_edge_distance(obstacle.position) - obstacle.collision_radius
			< BesprenWorldMap2D.DENSE_TREE_ROAD_EDGE_CLEARANCE
		):
			every_dense_tree_preserves_camp_and_road_clearance = false

	_check(
		city_ruin_count == BesprenWorldMap2D.DENSE_CITY_RUIN_COUNT
		and mall_ruin_count == BesprenWorldMap2D.DENSE_MALL_RUIN_COUNT
		and west_village_ruin_count == BesprenWorldMap2D.DENSE_VILLAGE_RUIN_COUNT_PER_SIDE
		and east_village_ruin_count == BesprenWorldMap2D.DENSE_VILLAGE_RUIN_COUNT_PER_SIDE,
		"Kaupunki, Ostari, and both villages gain their planned dense ruin anchors"
	)
	_check(
		every_density_anchor_is_imported_and_clear,
		"Every new ruin uses an imported silhouette inside its biome and outside road clearance"
	)
	_check(
		forest_stand_count >= BesprenWorldMap2D.MIN_DENSE_FOREST_TREE_COUNT
		and wilderness_grove_count >= BesprenWorldMap2D.MIN_WILDERNESS_GROVE_TREE_COUNT,
		"Forest and wilderness receive materially denser tree coverage (%d forest stands, %d wilderness groves)" % [
			forest_stand_count,
			wilderness_grove_count,
		]
	)
	_check(
		every_dense_tree_preserves_camp_and_road_clearance,
		"Dense trees preserve the camp clearing and every authored road shoulder"
	)


func _validate_gameplay_entity_layers() -> void:
	var game_world: Node2D = GAME_WORLD_SCENE.instantiate() as Node2D
	_check(game_world != null, "Gameplay composition instantiates for entity-layer validation")
	if game_world == null:
		return
	var entity_root: Node2D = game_world.get_node_or_null("YSortWorld") as Node2D
	var players: Node2D = game_world.get_node_or_null("YSortWorld/Players") as Node2D
	var base_core: Node2D = game_world.get_node_or_null("YSortWorld/BaseCore") as Node2D
	_check(entity_root != null, "Gameplay composition owns a YSortWorld entity root")
	_check(players != null, "Gameplay composition owns a Players entity container")
	_check(base_core != null, "Gameplay composition owns the Base Core entity")
	if entity_root != null:
		_check_absolute_z(entity_root, EXPECTED_ENTITY_Z, "YSortWorld")
		_check(entity_root.y_sort_enabled, "Gameplay entity root explicitly enables Y-sort")
	if players != null:
		_check_absolute_z(players, EXPECTED_ENTITY_Z, "Players")
		_check(players.y_sort_enabled, "Players container explicitly enables Y-sort")
	if base_core != null:
		_check_absolute_z(base_core, EXPECTED_ENTITY_Z, "BaseCore")
	game_world.free()

	var network_player: Node2D = NETWORK_PLAYER_SCENE.instantiate() as Node2D
	_check(network_player != null, "Network player entity instantiates for layer validation")
	if network_player != null:
		_check_absolute_z(network_player, EXPECTED_ENTITY_Z, "NetworkPlayer")
		network_player.free()


func _validate_flow_field(world_map: BesprenWorldMap2D) -> void:
	var expected_dimensions: Vector2i = Vector2i(EXPECTED_FLOW_DIMENSION, EXPECTED_FLOW_DIMENSION)
	_check(world_map.get_flow_field_dimensions() == expected_dimensions, "Flow-field mask is exactly 112x112")
	_check(
		world_map.get_flow_field_mask_hash() == EXPECTED_FLOW_FIELD_MASK_HASH,
		"Visual-only layers leave the complete 112x112 flow-field mask at its pinned hash"
	)
	var blocked_count: int = world_map.get_blocked_flow_cell_count()
	_check(blocked_count > 0, "Flow-field mask contains blocked cells")
	_check(blocked_count < EXPECTED_FLOW_DIMENSION * EXPECTED_FLOW_DIMENSION, "Flow-field mask preserves traversable cells")
	var core_cell: Vector2i = world_map.world_to_flow_cell(BesprenWorldMap2D.STARTING_CAMP_POSITION)
	_check(world_map.is_flow_cell_blocked(core_cell), "Base Core footprint is baked into the flow-field mask")
	_check(world_map.is_flow_cell_blocked(Vector2i(-1, 0)), "Flow-field cells west of the world are blocked")
	_check(world_map.is_flow_cell_blocked(Vector2i(EXPECTED_FLOW_DIMENSION, 0)), "Flow-field cells east of the world are blocked")
	var obstacles: Array[WorldObstacle2D] = world_map.get_obstacle_nodes()
	var every_obstacle_is_flow_blocked: bool = not obstacles.is_empty()
	for obstacle: WorldObstacle2D in obstacles:
		if not world_map.is_flow_cell_blocked(world_map.world_to_flow_cell(obstacle.position)):
			every_obstacle_is_flow_blocked = false
	_check(every_obstacle_is_flow_blocked, "Every static obstacle footprint is represented in the flow-field mask")
	var building: WorldObstacle2D = null
	for obstacle: WorldObstacle2D in obstacles:
		if obstacle.get_visual_kind() == WorldObstacle2D.VisualKind.CITY_BUILDING:
			building = obstacle
			break
	_check(building != null, "Flow-field validation resolves an authored city building")
	if building != null:
		_check(
			world_map.is_flow_cell_blocked(world_map.world_to_flow_cell(building.position)),
			"A city building footprint is baked into the flow-field mask"
		)
	var sample_cell: Vector2i = Vector2i(23, 71)
	_check(
		world_map.world_to_flow_cell(world_map.flow_cell_to_world(sample_cell)) == sample_cell,
		"Flow-field world/cell conversion round-trips"
	)


func _validate_motion_resolver(world_map: BesprenWorldMap2D) -> void:
	var obstacles: Array[WorldObstacle2D] = world_map.get_obstacle_nodes()
	_check(not obstacles.is_empty(), "Motion resolver has authored obstacle input")
	if obstacles.is_empty():
		return
	var current_position: Vector2 = _find_walkable_position(world_map, PLAYER_RADIUS)
	_check(current_position.is_finite(), "Validation locates a walkable player start")
	if not current_position.is_finite():
		return
	var blocked_destination: Vector2 = obstacles[0].position
	_check(not world_map.is_position_walkable(blocked_destination, PLAYER_RADIUS), "Obstacle destination is non-walkable at player clearance")
	var resolved_position: Vector2 = world_map.resolve_player_motion(
		current_position,
		blocked_destination,
		PLAYER_RADIUS
	)
	_check(not resolved_position.is_equal_approx(blocked_destination), "Motion resolver refuses movement into a static structure")
	_check(world_map.is_position_walkable(resolved_position, PLAYER_RADIUS), "Motion resolver returns a walkable slide or prior position")


func _find_walkable_position(world_map: BesprenWorldMap2D, clearance: float) -> Vector2:
	for row: int in range(EXPECTED_GRID_SIZE):
		for column: int in range(EXPECTED_GRID_SIZE):
			var candidate: Vector2 = world_map.get_cell_center(Vector2i(column, row))
			if world_map.is_position_walkable(candidate, clearance):
				return candidate
	return Vector2.INF


func _distance_to_routes(point: Vector2, routes: Array[PackedVector2Array]) -> float:
	var shortest: float = INF
	for route: PackedVector2Array in routes:
		for point_index: int in range(route.size() - 1):
			var closest: Vector2 = Geometry2D.get_closest_point_to_segment(
				point,
				route[point_index],
				route[point_index + 1]
			)
			shortest = minf(shortest, point.distance_to(closest))
	return shortest


## The understory exists because the gameplay tour found Metsa empty at the
## zoom the game ships, so the check that matters most is that one: a gameplay
## frame over forest ground, clear of roads and the camp bowl, now holds a
## forest's worth of subjects. The rest pins that it stays a dress layer.
func _validate_forest_understory(world_map: BesprenWorldMap2D) -> void:
	var understory: WorldForestUnderstory2D = world_map.forest_understory
	_check(understory != null, "World map owns the forest understory layer")
	if understory == null:
		return
	_check_absolute_z(understory, EXPECTED_AMBIENT_SCENERY_Z, "Forest understory")
	var count: int = understory.get_element_count()
	_check(
		count >= WorldForestUnderstory2D.MINIMUM_ELEMENT_COUNT
		and count <= WorldForestUnderstory2D.MAXIMUM_ELEMENT_COUNT,
		"Forest understory places %d elements inside its authored bounds" % count
	)
	_check(
		understory.get_chunked_element_count() == count,
		"Every understory element is drawn by exactly one render chunk"
	)
	_check(not _subtree_has_physics(understory), "Forest understory owns no physics")
	var every_chunk_is_lit: bool = not understory.get_render_chunks().is_empty()
	for chunk: Node2D in understory.get_render_chunks():
		var grade: ShaderMaterial = chunk.material as ShaderMaterial
		if (
			grade == null
			or grade.shader == null
			or grade.shader.code.contains("render_mode unshaded")
			or chunk.z_index != EXPECTED_AMBIENT_SCENERY_Z
		):
			every_chunk_is_lit = false
	_check(every_chunk_is_lit, "Understory chunks draw at the ambient z through the lit canvas grade")
	var positions: PackedVector2Array = understory.get_element_positions()
	var radii: PackedFloat32Array = understory.get_element_visual_radii()
	var camp: Vector2 = BesprenWorldMap2D.STARTING_CAMP_POSITION
	var every_element_is_clear: bool = positions.size() == radii.size()
	var bowl_is_empty: bool = true
	for index: int in range(mini(positions.size(), radii.size())):
		var element: Vector2 = positions[index]
		if not world_map.is_position_walkable(element, radii[index]):
			every_element_is_clear = false
		if world_map.get_minimum_road_edge_distance(element) < (
			WorldForestUnderstory2D.ROAD_EDGE_CLEARANCE + radii[index] - 0.01
		):
			every_element_is_clear = false
		if element.distance_to(camp) < WorldForestUnderstory2D.CLEARING_RADIUS:
			bowl_is_empty = false
	_check(every_element_is_clear, "No understory element overlaps a colliding footprint or a road verge")
	_check(bowl_is_empty, "The camp bowl holds no understory inside %.0f units" % WorldForestUnderstory2D.CLEARING_RADIUS)
	_check(
		understory.get_rim_element_count() >= 100,
		"The bowl's rim carries a wall of %d understory elements" % understory.get_rim_element_count()
	)
	# Forest frames at the gameplay zoom: 1,263 x 711 world units centred on a
	# grid over forest cells, away from roads and the camp. Before this layer the
	# tour's forest interior frame held no subject at all.
	var frame_half: Vector2 = Vector2(632.0, 356.0)
	var frames: int = 0
	var subjects: int = 0
	var sparse_frames: int = 0
	var y: float = -13000.0
	while y < 13000.0:
		var x: float = -13000.0
		while x < 13000.0:
			var center: Vector2 = Vector2(x, y)
			if (
				world_map.get_biome_at_world(center) == BesprenWorldMap2D.Biome.FOREST
				and world_map.get_minimum_road_edge_distance(center) > 700.0
				and center.distance_to(camp) > WorldForestUnderstory2D.RIM_OUTER_RADIUS
			):
				var in_frame: int = 0
				for element: Vector2 in positions:
					if absf(element.x - center.x) < frame_half.x and absf(element.y - center.y) < frame_half.y:
						in_frame += 1
				frames += 1
				subjects += in_frame
				if in_frame < 3:
					sparse_frames += 1
			x += 1300.0
		y += 730.0
	var mean_subjects: float = float(subjects) / maxf(float(frames), 1.0)
	_check(
		frames >= 20 and mean_subjects >= 6.0,
		"Forest gameplay frames average %.1f understory subjects over %d frames" % [mean_subjects, frames]
	)
	_check(
		sparse_frames * 10 <= frames,
		"At most a tenth of forest gameplay frames fall under three subjects (%d of %d)" % [sparse_frames, frames]
	)
	# Rebuilding on the same seed reproduces the layer exactly.
	var first_hash: int = hash(positions)
	understory.configure(
		BesprenWorldMap2D.PLAYABLE_HALF_EXTENT,
		BesprenWorldMap2D.WORLD_BUILD_SEED + 251,
		camp,
		Callable(world_map, &"is_position_walkable"),
		Callable(world_map, &"get_minimum_road_edge_distance"),
		Callable(world_map, &"get_biome_at_world")
	)
	_check(
		hash(understory.get_element_positions()) == first_hash,
		"Forest understory rebuilds identically on the same seed"
	)


func _validate_camp_clearing(world_map: BesprenWorldMap2D) -> void:
	var clearing: WorldCampClearing2D = world_map.camp_clearing
	_check(clearing != null, "World map owns the camp clearing layer")
	if clearing == null:
		return
	_check_absolute_z(clearing, WorldCampClearing2D.CLEARING_Z, "Camp clearing")
	var terrain_details: Node = world_map.get_node_or_null(^"TerrainDetails")
	var terrain_overlay: Node = world_map.get_node_or_null(^"TerrainMaterialOverlay")
	_check(
		terrain_details != null
		and terrain_overlay != null
		and terrain_overlay.get_index() < clearing.get_index()
		and clearing.get_index() < terrain_details.get_index(),
		"Camp clearing draws over the terrain and under the roads, so the spur leaves it visibly"
	)
	_check(
		clearing.position.is_equal_approx(BesprenWorldMap2D.STARTING_CAMP_POSITION),
		"Camp clearing is centred on the starting camp"
	)
	_check(
		clearing.get_path_target_count() == BesprenWorldMap2D.STARTING_CAMP_SATELLITE_COUNT,
		"A worn path leads to each of the %d camp satellites" % BesprenWorldMap2D.STARTING_CAMP_SATELLITE_COUNT
	)
	var grain: ShaderMaterial = clearing.material as ShaderMaterial
	_check(
		grain != null
		and grain.shader != null
		and grain.shader.resource_path == WorldRoadSegmentChunk2D.DETAIL_SHADER_PATH
		and not grain.shader.code.contains("render_mode unshaded"),
		"Camp clearing wears the lit dirt grain the dirt roads use"
	)
	_check(not _subtree_has_physics(clearing), "Camp clearing owns no physics")


## East Kylat must stop being the west village translated. The strongest
## statement of that is geometric: no east house or wall sits where the west's
## mirror image would put it. The rest pins the plot's job - walls with gaps a
## survivor fits through, grave rows inside, and a gate on the road side.
func _validate_east_rest(world_map: BesprenWorldMap2D) -> void:
	var west: Array[Vector2] = []
	var east: Array[Vector2] = []
	var walls: Array[WorldObstacle2D] = []
	for obstacle: WorldObstacle2D in world_map.get_obstacle_nodes():
		var obstacle_name: String = String(obstacle.name)
		if obstacle_name.begins_with("WestVillageHouse_") or obstacle_name.begins_with("WestVillageFence_"):
			west.append(obstacle.position)
		elif obstacle_name.begins_with("EastVillageHouse_") or obstacle_name.begins_with("EastVillageFence_"):
			east.append(obstacle.position)
			if obstacle_name.begins_with("EastVillageFence_"):
				walls.append(obstacle)
	var translated_matches: int = 0
	var mirrored_matches: int = 0
	for east_position: Vector2 in east:
		for west_position: Vector2 in west:
			if east_position.distance_to(west_position + Vector2(16100.0, 0.0)) < 400.0:
				translated_matches += 1
			if east_position.distance_to(Vector2(-west_position.x, west_position.y)) < 400.0:
				mirrored_matches += 1
	_check(
		translated_matches <= 1 and mirrored_matches <= 1,
		"East Kylat is its own layout: %d translated and %d mirrored matches with the west (at most one each)" % [
			translated_matches, mirrored_matches
		]
	)
	var plot: Rect2 = BesprenWorldMap2D.EAST_REST_PLOT
	var every_wall_on_plot: bool = walls.size() == 6
	for wall: WorldObstacle2D in walls:
		var on_edge: bool = (
			is_equal_approx(wall.position.x, plot.position.x)
			or is_equal_approx(wall.position.x, plot.end.x)
			or is_equal_approx(wall.position.y, plot.position.y)
			or is_equal_approx(wall.position.y, plot.end.y)
		)
		if not on_edge:
			every_wall_on_plot = false
	_check(every_wall_on_plot, "East Kylat's six wall runs stand on the grave plot's edges")
	# Every corner and the middle of each long side must admit a survivor.
	var openings: Array[Vector2] = [
		plot.position,
		Vector2(plot.end.x, plot.position.y),
		plot.end,
		Vector2(plot.position.x, plot.end.y),
		Vector2(plot.get_center().x, plot.position.y),
		Vector2(plot.get_center().x, plot.end.y),
	]
	var every_opening_is_walkable: bool = true
	for opening: Vector2 in openings:
		if not world_map.is_position_walkable(opening, PLAYER_RADIUS):
			every_opening_is_walkable = false
	_check(every_opening_is_walkable, "The grave plot's corners and long-side middles are open to a survivor")
	_check(
		world_map.is_position_walkable(plot.get_center(), PLAYER_RADIUS),
		"The grave plot's interior is walkable"
	)
	var graves: WorldGraveyard2D = world_map.graveyard
	_check(graves != null and not _subtree_has_physics(graves), "Grave rows are a visual-only layer")
	if graves != null:
		_check_absolute_z(graves, EXPECTED_DECOR_Z, "Grave rows")
		_check(
			graves.get_marker_count() >= 30 and plot.encloses(graves.get_plot()),
			"%d grave markers stand inside the walled plot" % graves.get_marker_count()
		)


## Roadmap Phase 2: the skeleton comes from one shipped Resource the map
## consumes, and it replaces the copies rather than adding a fourth. So besides
## the file's own consistency this greps the dress layers for the tables and the
## camp literal the composition was meant to retire - a shared source is only a
## claim until the primitives it replaced are gone (CLAUDE.md 7).
func _validate_composition(world_map: BesprenWorldMap2D) -> void:
	var composition: WorldCompositionContract = BesprenWorldMap2D.COMPOSITION
	_check(composition != null, "The world map preloads a shipped WorldCompositionContract")
	if composition == null:
		return
	_check(
		composition.resource_path == "res://data/world/world_composition.tres",
		"The composition ships as res://data/world/world_composition.tres"
	)
	_check(composition.validate().is_empty(), "The composition is internally consistent: %s" % composition.validate())
	_check(
		BesprenWorldMap2D.STARTING_CAMP_POSITION == composition.camp_position
		and WorldBackgroundDecor2D.CAMP_POSITION == composition.camp_position,
		"Every camp position consumer resolves through the composition"
	)
	_check(
		world_map.get_road_route_count() == composition.road_routes.size(),
		"The road network draws exactly the composition's %d routes" % composition.road_routes.size()
	)
	_check(
		WorldWildernessAccent2D.WILDERNESS_POCKETS == WorldAmbientScenery2D.WILDERNESS_POCKETS
		and WorldAmbientScenery2D.WILDERNESS_POCKETS == composition.get_pockets(&"ambient", &"wilderness"),
		"The wilderness accent reads the ambient table instead of its own copy"
	)
	_check(
		WorldBackgroundDecor2D.FOREST_POCKETS == composition.get_pockets(&"decor", &"forest")
		and WorldAmbientScenery2D.CITY_POCKETS == composition.get_pockets(&"ambient", &"city"),
		"Decor and ambient pocket accessors are the composition's tables"
	)
	var retired_primitives: Array[String] = []
	for script_path: String in [
		"res://src/world/world_map_2d.gd",
		"res://src/world/world_background_decor_2d.gd",
		"res://src/world/world_ambient_scenery_2d.gd",
		"res://src/world/world_wilderness_accent_2d.gd",
	]:
		var source: String = FileAccess.get_file_as_string(script_path)
		if source.contains("_POCKETS: Array[Vector4] = [") or source.contains("Vector2(9950.0, 2400.0)"):
			retired_primitives.append(script_path.get_file())
	_check(
		retired_primitives.is_empty(),
		"No world script still authors a pocket table or the camp literal (%s)" % ", ".join(retired_primitives)
	)
	var expected_landmarks: PackedStringArray = PackedStringArray([
		"camp_amber_gold", "mall_gate", "west_yard", "city_choke", "metsa_threat_weenie",
	])
	_check(
		composition.landmark_names == expected_landmarks,
		"The composition names exactly the contract's five shout nouns"
	)
	var landmarks_are_placed: bool = composition.landmark_positions.size() == expected_landmarks.size()
	for position: Vector2 in composition.landmark_positions:
		if not BesprenWorldMap2D.PLAYABLE_RECT.has_point(position):
			landmarks_are_placed = false
	_check(landmarks_are_placed, "Every landmark sits inside the playable extents")
	_check(
		composition.get_landmark_position(&"camp_amber_gold") == composition.camp_position,
		"The camp landmark is the camp"
	)
	_check(
		world_map.get_biome_at_world(composition.get_landmark_position(&"metsa_threat_weenie"))
		== BesprenWorldMap2D.Biome.FOREST,
		"The Metsa threat weenie's reserved seat is in Metsa"
	)
	# The dirt spur (contract D-02): the camp's readable exit, the one road the
	# seclusion ring admits. It starts inside the trodden clearing, clear of the
	# Base, spawn lanes and teaching nodes, and ends on the asphalt spine, short
	# enough that the 30s loop stays a tight Metsa circuit.
	var spur_index: int = composition.camp_spur_route
	_check(
		spur_index >= 0 and composition.road_grades[spur_index] == WorldCompositionContract.RoadGrade.DIRT,
		"The composition names a dirt camp spur"
	)
	var spur: PackedVector2Array = world_map.get_camp_spur_route()
	if spur.size() >= 2:
		var camp: Vector2 = composition.camp_position
		var start_distance: float = spur[0].distance_to(camp)
		_check(
			start_distance > BesprenWorldMap2D.CORE_COLLISION_RADIUS + WorldRoadNetwork2D.DIRT_OUTER_WIDTH * 0.5
			and start_distance < BesprenWorldMap2D.STARTING_CAMP_OPEN_RADIUS,
			"The spur starts in the camp's open ring, in frame from the refuge and clear of the Base (%.0f units out)" % start_distance
		)
		var ends_on_spine: bool = false
		for route_index: int in range(composition.road_routes.size()):
			if composition.road_grades[route_index] != WorldCompositionContract.RoadGrade.ASPHALT_SPINE:
				continue
			if _distance_to_routes(spur[spur.size() - 1], [composition.road_routes[route_index]]) < 1.0:
				ends_on_spine = true
		_check(ends_on_spine, "The spur ends on the asphalt spine, so asphalt always leads home")
		var spur_length: float = 0.0
		for point_index: int in range(1, spur.size()):
			spur_length += spur[point_index].distance_to(spur[point_index - 1])
		_check(spur_length <= 2600.0, "The spur is a short exit, not a commute (%.0f units)" % spur_length)
		var lanes_clear_of_spur: bool = true
		var lane_offsets: Array[Vector2] = COOP_SPAWN_OFFSETS.duplicate()
		lane_offsets.append_array(STARTER_RESOURCE_OFFSETS)
		for offset: Vector2 in lane_offsets:
			if _distance_to_routes(camp + offset, [spur]) < WorldRoadNetwork2D.DIRT_OUTER_WIDTH * 0.5 + PLAYER_RADIUS:
				lanes_clear_of_spur = false
		_check(lanes_clear_of_spur, "No spawn lane or teaching node stands on the spur")
		_check(
			world_map.get_minimum_road_edge_distance(camp) < world_map.get_minimum_road_edge_distance_excluding_camp_spur(camp),
			"The spur is the camp's nearest road; every other road keeps the seclusion ring"
		)
	var regions: Dictionary[StringName, Rect2] = world_map.get_biome_regions()
	_check(
		regions.has(&"kaupunki") and regions.has(&"ostari") and regions.has(&"kyla_west") and regions.has(&"kyla_east"),
		"District regions are derived from the composition's district paint"
	)


## Roadmap Phase 3: three grades that read apart at 1x through width, edge and
## negative space; junctions drawn as one surface; free ends that wear out
## instead of stopping square. Collision and flow stay canonical, which the
## pinned flow hash above already proves for this change.
func _validate_road_hierarchy(world_map: BesprenWorldMap2D) -> void:
	var network: WorldRoadNetwork2D = world_map.road_network
	var composition: WorldCompositionContract = BesprenWorldMap2D.COMPOSITION
	var grades_present: Dictionary[int, bool] = {}
	for route_index: int in range(network.get_route_count()):
		grades_present[network.get_route_grade(route_index)] = true
	_check(grades_present.size() == 3, "The road network draws all three grades: spine, dirt and perimeter")
	var spine: Vector2 = WorldRoadNetwork2D.get_grade_widths(WorldCompositionContract.RoadGrade.ASPHALT_SPINE)
	var dirt: Vector2 = WorldRoadNetwork2D.get_grade_widths(WorldCompositionContract.RoadGrade.DIRT)
	var track: Vector2 = WorldRoadNetwork2D.get_grade_widths(WorldCompositionContract.RoadGrade.PERIMETER)
	_check(
		spine.y > dirt.y and dirt.y > track.y and spine.x > dirt.x and dirt.x > track.x,
		"Drawn widths step down spine > dirt > perimeter (%.0f / %.0f / %.0f bed)" % [spine.y, dirt.y, track.y]
	)
	_check(
		is_equal_approx(
			WorldRoadNetwork2D.get_clearance_half_width(WorldCompositionContract.RoadGrade.PERIMETER),
			WorldRoadNetwork2D.DIRT_OUTER_WIDTH * 0.5
		),
		"The perimeter keeps the dirt corridor for every clearance rule, so nothing seeded moves"
	)
	var perimeter_index: int = composition.road_names.find("wilderness_perimeter")
	_check(
		perimeter_index >= 0 and network.get_route_grade(perimeter_index) == WorldCompositionContract.RoadGrade.PERIMETER,
		"The wilderness perimeter loop is the perimeter grade"
	)
	var chunks: Array[WorldRoadSegmentChunk2D] = network.get_render_chunks()
	var last_shoulder: int = -1
	var first_bed: int = chunks.size()
	var shoulders: int = 0
	var beds: int = 0
	for chunk: WorldRoadSegmentChunk2D in chunks:
		if chunk.get_pass() == WorldRoadSegmentChunk2D.Pass.SHOULDER:
			shoulders += 1
			last_shoulder = maxi(last_shoulder, chunk.get_index())
		elif chunk.get_pass() == WorldRoadSegmentChunk2D.Pass.BED:
			beds += 1
			first_bed = mini(first_bed, chunk.get_index())
	_check(
		shoulders > 0 and shoulders == beds and last_shoulder < first_bed,
		"Every shoulder is drawn before any bed, so junctions read as one surface (%d + %d items)" % [shoulders, beds]
	)
	var spur: int = composition.camp_spur_route
	_check(
		spur >= 0 and network.is_route_end_free(spur, false) and not network.is_route_end_free(spur, true),
		"The spur's camp end is free and its spine end is a junction"
	)
	_check(
		not network.is_route_end_free(perimeter_index, false) and not network.is_route_end_free(perimeter_index, true),
		"The closed perimeter loop has no free ends"
	)
	var capped_chunks: int = 0
	var spur_is_capped: bool = false
	for chunk: WorldRoadSegmentChunk2D in chunks:
		if chunk.has_cap():
			capped_chunks += 1
			var bounds: Rect2 = chunk.get_world_render_bounds()
			if bounds.grow(1.0).has_point(composition.road_routes[spur][0]):
				spur_is_capped = true
	_check(spur_is_capped, "The spur wears out into the camp clearing instead of stopping square")
	var free_ends: int = 0
	for route_index: int in range(network.get_route_count()):
		free_ends += int(network.is_route_end_free(route_index, false)) + int(network.is_route_end_free(route_index, true))
	_check(
		capped_chunks == free_ends * 2,
		"Every free route end is capped in both passes and no junction end is (%d ends)" % free_ends
	)


func _subtree_has_physics(node: Node) -> bool:
	if node is CollisionObject2D or node is CollisionShape2D or node is WorldObstacle2D:
		return true
	for child: Node in node.get_children():
		if _subtree_has_physics(child):
			return true
	return false


## Phase 4 (DIST-01): Kaupunki reads as a dense street with a choke, and Ostari
## as a mall car park. What is pinned is the job each district's geometry does
## at the 0.38 zoom - frontage inside the frame, an unbroken pinch at the
## landmark, bays either side of the mall road - and that none of it costs the
## spine its flow or puts dress on a carriageway.
func _validate_district_jobs(world_map: BesprenWorldMap2D) -> void:
	var spine_x: float = BesprenWorldMap2D.CITY_SPINE_X
	var walls: Array[WorldObstacle2D] = world_map.get_street_wall_obstacles()
	_check(walls.size() >= 12, "Kaupunki's spine is lined by %d street-wall shells" % walls.size())
	var faces_on_kerb_line: bool = not walls.is_empty()
	var walls_are_buildings: bool = not walls.is_empty()
	var walls_clear_of_holders: bool = true
	var walls_clear_of_roads: bool = true
	var spine_columns_open: bool = true
	var column_xs: Array[float] = [spine_x - 128.0, spine_x + 128.0]
	for wall: WorldObstacle2D in walls:
		walls_are_buildings = walls_are_buildings and wall.get_visual_kind() == WorldObstacle2D.VisualKind.CITY_BUILDING
		var bounds: Rect2 = wall.get_world_bounds(0.0)
		var near_face: float = spine_x - bounds.end.x if wall.position.x < spine_x else bounds.position.x - spine_x
		if near_face < BesprenWorldMap2D.STREET_WALL_CHOKE_FACE_OFFSET - 1.0 or near_face > BesprenWorldMap2D.STREET_WALL_FACE_OFFSET + 1.0:
			faces_on_kerb_line = false
		for other: WorldObstacle2D in world_map.get_obstacle_nodes():
			if other != wall and other.get_world_bounds(0.0).intersects(bounds):
				walls_clear_of_holders = false
		for corner: Vector2 in [bounds.position, bounds.end, Vector2(bounds.position.x, bounds.end.y), Vector2(bounds.end.x, bounds.position.y)]:
			if world_map.get_minimum_road_edge_distance(corner) < 45.0:
				walls_clear_of_roads = false
		var row_y: float = world_map.flow_cell_to_world(world_map.world_to_flow_cell(Vector2(spine_x, bounds.position.y))).y
		while row_y <= bounds.end.y + BesprenWorldMap2D.FLOW_FIELD_CELL_SIZE:
			for column_x: float in column_xs:
				if wall.contains_world_point(Vector2(column_x, row_y), BesprenWorldMap2D.FLOW_FIELD_RASTER_CLEARANCE):
					spine_columns_open = false
			row_y += BesprenWorldMap2D.FLOW_FIELD_CELL_SIZE
	_check(walls_are_buildings, "Every street wall is a city building shell")
	_check(faces_on_kerb_line, "Every street wall fronts the kerb line, 360 to 420 units off the spine")
	_check(walls_clear_of_holders, "No street wall overlaps any other footprint")
	_check(walls_clear_of_roads, "No street wall reaches a road")
	_check(spine_columns_open, "No street wall blocks either flow column beside the spine")

	var choke_center: Vector2 = BesprenWorldMap2D.COMPOSITION.get_landmark_position(&"city_choke")
	var choke_half: float = BesprenWorldMap2D.COMPOSITION.get_landmark_radius(&"city_choke")
	_check(
		is_equal_approx(choke_center.x, spine_x)
		and world_map.get_biome_at_world(choke_center) == BesprenWorldMap2D.Biome.CITY,
		"The city_choke landmark sits on Kaupunki's spine"
	)
	var choke_is_unbroken: bool = true
	for side: int in [-1, 1]:
		var covered: float = 0.0
		for wall: WorldObstacle2D in walls:
			if signf(wall.position.x - spine_x) != float(side):
				continue
			var bounds: Rect2 = wall.get_world_bounds(0.0)
			var overlap: float = minf(bounds.end.y, choke_center.y + choke_half) - maxf(bounds.position.y, choke_center.y - choke_half)
			if overlap > 0.0:
				covered += overlap
				if not is_zero_approx(wall.rotation):
					choke_is_unbroken = false
		var seams: float = BesprenWorldMap2D.STREET_WALL_CHOKE_SEAM * float(BesprenWorldMap2D.STREET_WALL_CHOKE_BLOCKS - 1)
		if covered < choke_half * 2.0 - seams - 1.0:
			choke_is_unbroken = false
	_check(choke_is_unbroken, "At the city choke both frontages run unbroken and square for the landmark's whole diameter")

	var samples: int = 0
	var side_hits: Array[int] = [0, 0]
	var either_hits: int = 0
	var sample_y: float = BesprenWorldMap2D.STREET_WALL_SPAN.x
	while sample_y <= BesprenWorldMap2D.STREET_WALL_SPAN.y:
		samples += 1
		var hit: Array[bool] = [false, false]
		for obstacle: WorldObstacle2D in world_map.get_obstacle_nodes():
			if obstacle.get_visual_kind() != WorldObstacle2D.VisualKind.CITY_BUILDING:
				continue
			var bounds: Rect2 = obstacle.get_world_bounds(0.0)
			if sample_y < bounds.position.y or sample_y > bounds.end.y:
				continue
			var west_face: float = spine_x - bounds.end.x
			var east_face: float = bounds.position.x - spine_x
			hit[0] = hit[0] or (west_face > 0.0 and west_face <= GAMEPLAY_HALF_FRAME_WIDTH)
			hit[1] = hit[1] or (east_face > 0.0 and east_face <= GAMEPLAY_HALF_FRAME_WIDTH)
		side_hits[0] += 1 if hit[0] else 0
		side_hits[1] += 1 if hit[1] else 0
		either_hits += 1 if hit[0] or hit[1] else 0
		sample_y += 50.0
	var west_share: float = float(side_hits[0]) / float(maxi(samples, 1))
	var east_share: float = float(side_hits[1]) / float(maxi(samples, 1))
	var either_share: float = float(either_hits) / float(maxi(samples, 1))
	_check(
		either_share >= MINIMUM_CITY_FRONTAGE_EITHER_SIDE
		and west_share >= MINIMUM_CITY_FRONTAGE_EACH_SIDE
		and east_share >= MINIMUM_CITY_FRONTAGE_EACH_SIDE,
		"A building face stands inside the gameplay frame along %.1f%% of the spine (west %.1f%%, east %.1f%%)" % [
			either_share * 100.0, west_share * 100.0, east_share * 100.0
		]
	)

	var fabric: WorldUrbanFabric2D = world_map.get_node_or_null("%UrbanFabric") as WorldUrbanFabric2D
	_check(fabric != null, "World map owns the urban fabric layer")
	if fabric == null:
		return
	_check_absolute_z(fabric, WorldUrbanFabric2D.FABRIC_Z, "Urban fabric")
	var terrain_details: Node = world_map.get_node_or_null("%TerrainDetails")
	_check(
		terrain_details != null and fabric.get_index() > terrain_details.get_index(),
		"Urban fabric draws after the roads, so the kerb sits on the shoulder's last units"
	)
	_check(fabric.find_children("*", "CollisionObject2D", true, false).is_empty(), "Urban fabric owns no physics")
	var bed_half: float = WorldRoadNetwork2D.ASPHALT_INNER_WIDTH * 0.5
	var pavement_stays_off_the_bed: bool = fabric.get_pavement_chunk_count() > 0
	var spill_stays_on_the_pavement: bool = false
	var rows_stay_off_the_road: bool = true
	var rows_clear_of_buildings: bool = true
	var rows: Array[Rect2] = []
	for chunk: Node2D in fabric.get_chunks():
		var bounds: Rect2 = chunk.call(&"get_draw_bounds") as Rect2
		match int(chunk.get(&"kind")):
			WorldUrbanFabricChunk2D.Kind.PAVEMENT:
				var inner: float = minf(absf(bounds.position.x - spine_x), absf(bounds.end.x - spine_x))
				var outer: float = maxf(absf(bounds.position.x - spine_x), absf(bounds.end.x - spine_x))
				if inner < bed_half or outer > BesprenWorldMap2D.STREET_WALL_FACE_OFFSET + 1.0:
					pavement_stays_off_the_bed = false
			WorldUrbanFabricChunk2D.Kind.SPILL:
				var inner: float = minf(absf(bounds.position.x - spine_x), absf(bounds.end.x - spine_x))
				spill_stays_on_the_pavement = int(chunk.call(&"get_piece_count")) > 0 and inner >= bed_half
			WorldUrbanFabricChunk2D.Kind.PARKING:
				rows.append(bounds)
				if absf(bounds.position.y - BesprenWorldMap2D.OSTARI_ROAD_Y) < WorldRoadNetwork2D.ASPHALT_OUTER_WIDTH * 0.5 or absf(bounds.end.y - BesprenWorldMap2D.OSTARI_ROAD_Y) < WorldRoadNetwork2D.ASPHALT_OUTER_WIDTH * 0.5:
					rows_stay_off_the_road = false
				for obstacle: WorldObstacle2D in world_map.get_obstacle_nodes():
					var kind: int = obstacle.get_visual_kind()
					if (kind == WorldObstacle2D.VisualKind.MALL_SHELL or kind == WorldObstacle2D.VisualKind.CITY_BUILDING) and obstacle.get_world_bounds(0.0).intersects(bounds):
						rows_clear_of_buildings = false
	_check(pavement_stays_off_the_bed, "Kaupunki pavement lies between the asphalt bed and the kerb line")
	_check(spill_stays_on_the_pavement, "The choke's rubble spill lies on the pavement, off the carriageway")
	_check(
		fabric.get_parking_bay_count() == EXPECTED_OSTARI_PARKING_BAYS and rows.size() == 2,
		"Ostari's mall road is flanked by two rows of %d parking bays" % (EXPECTED_OSTARI_PARKING_BAYS / 2)
	)
	_check(rows_stay_off_the_road, "Parking rows open onto the mall road without painting over it")
	_check(rows_clear_of_buildings, "No parking row runs under a shell, pylon or ruin")
	var parked_cars: int = 0
	var cars_are_cars_in_bays: bool = true
	for obstacle: WorldObstacle2D in world_map.get_obstacle_nodes():
		if not String(obstacle.name).begins_with(BesprenWorldMap2D.OSTARI_PARKED_CAR_PREFIX):
			continue
		parked_cars += 1
		var in_a_row: bool = false
		for row: Rect2 in rows:
			in_a_row = in_a_row or row.has_point(obstacle.position)
		if not in_a_row or not obstacle.has_node("ImportedVehicleWreckVisual"):
			cars_are_cars_in_bays = false
	_check(
		parked_cars == BesprenWorldMap2D.OSTARI_PARKED_CARS.size() and cars_are_cars_in_bays,
		"%d abandoned cars stand in Ostari's bays, drawn as cars rather than barriers" % parked_cars
	)

	var yards: WorldVillageYards2D = world_map.get_node_or_null("%VillageYards") as WorldVillageYards2D
	_check(yards != null, "World map owns the village yards layer")
	if yards == null:
		return
	_check_absolute_z(yards, WorldVillageYards2D.YARDS_Z, "Village yards")
	_check(yards.find_children("*", "CollisionObject2D", true, false).is_empty(), "Village yards own no physics")
	var houses: int = 0
	for obstacle: WorldObstacle2D in world_map.get_obstacle_nodes():
		if String(obstacle.name).contains("VillageHouse_"):
			houses += 1
	_check(
		yards.get_yard_count() >= houses - 2 and yards.get_item_count(&"woodpile") >= 5 and yards.get_item_count(&"plot") >= 2,
		"%d of %d village houses have a yard, with %d woodpiles and %d garden plots" % [
			yards.get_yard_count(), houses, yards.get_item_count(&"woodpile"), yards.get_item_count(&"plot")
		]
	)
	var every_item_on_open_ground: bool = yards.get_yard_count() > 0
	for chunk: Node2D in yards.get_chunks():
		for footprint: Vector3 in chunk.call(&"get_item_footprints") as Array[Vector3]:
			var at: Vector2 = Vector2(footprint.x, footprint.y)
			if (
				not world_map.is_position_walkable(at, footprint.z)
				or world_map.get_minimum_road_edge_distance(at) <= footprint.z
			):
				every_item_on_open_ground = false
	_check(every_item_on_open_ground, "Every yard item lies on open ground, clear of every footprint and off every road")


func _check_absolute_z(canvas_item: CanvasItem, expected_z: int, label: String) -> void:
	_check(canvas_item.z_index == expected_z, "%s uses z=%d" % [label, expected_z])
	_check(not canvas_item.z_as_relative, "%s z-index is absolute" % label)


func _rect_is_equal_approx(left: Rect2, right: Rect2) -> bool:
	return left.position.is_equal_approx(right.position) and left.size.is_equal_approx(right.size)


func _get_texture_source_path(texture: Texture2D) -> String:
	var atlas_texture: AtlasTexture = texture as AtlasTexture
	if atlas_texture != null:
		if atlas_texture.atlas == null:
			return ""
		return atlas_texture.atlas.resource_path
	return texture.resource_path


func _finish() -> void:
	if _failures == 0:
		print("WORLD MAP VALIDATION OK (%d checks)" % _checks)
		quit(0)
		return
	push_error("WORLD MAP VALIDATION FAILED (%d/%d checks failed)" % [_failures, _checks])
	quit(1)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("PASS | %s" % message)
		return
	_failures += 1
	push_error("FAIL | %s" % message)
