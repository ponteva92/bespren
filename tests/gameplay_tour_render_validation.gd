extends Node2D
## Mobile/Vulkan capture gate that tours the world at the live 0.38 gameplay zoom.
##
## `world_render_validation` frames most of its places between zoom 0.055 and
## 0.45, which is right for reading a district's layout and wrong for judging
## what a player sees: at 0.18 a mall shell is a thumbnail and a crack is a
## hairline, while at 0.38 the same crack is a seven-pixel black bar. CLAUDE.md 9
## says to judge a bake at the size it delivers, so this gate delivers every stop
## at exactly the camera the game ships, with a survivor standing in frame as the
## scale reference and no HUD or minimap in the way.
##
## Stops are resolved from the live world wherever an authored node exists - an
## obstacle's own position, the camp constant - so a layout change moves the
## camera with it instead of leaving a stale frame that still passes.

const NETWORK_PLAYER_SCENE: PackedScene = preload("res://scenes/characters/network_player.tscn")
const OUTPUT_DIRECTORY: String = "res://artifacts/gameplay_tour"
const METADATA_PATH: String = "res://artifacts/gameplay_tour/gameplay_tour.json"
const GAMEPLAY_CAMERA_ZOOM: float = 0.38
## Beside the frame centre rather than on it, so the survivor never hides the
## thing a stop is aimed at.
const SCALE_REFERENCE_OFFSET: Vector2 = Vector2(-250.0, 170.0)

@onready var camera: Camera2D = %ValidationCamera
@onready var validation_lighting: CanvasModulate = %ValidationLighting
@onready var y_sort_world: Node2D = $YSortWorld
@onready var world_map: BesprenWorldMap2D = $YSortWorld/WorldMap2D as BesprenWorldMap2D
@onready var base_core: Node2D = $YSortWorld/BaseCore as Node2D

var _scale_reference: Node2D
var _outputs: Array[Dictionary] = []


func _ready() -> void:
	world_map.ensure_built()
	base_core.global_position = world_map.get_core_position()
	_scale_reference = NETWORK_PLAYER_SCENE.instantiate() as Node2D
	if _scale_reference == null:
		_fail("could not instantiate the scale reference survivor")
		return
	_scale_reference.call(&"configure", 1, &"heikki", Vector2.ZERO, false)
	y_sort_world.add_child(_scale_reference)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIRECTORY))
	await get_tree().process_frame

	var stops: Array[Dictionary] = _build_stops()
	for stop: Dictionary in stops:
		validation_lighting.color = (
			NightAtmosphere2D.SAPPHIRE_NIGHT_COLOR if stop[&"night"] else Color.WHITE
		)
		if not await _capture_stop(stop):
			return
	validation_lighting.color = Color.WHITE

	var metadata: Dictionary = {
		"rendering_method": RenderingServer.get_current_rendering_method(),
		"rendering_driver": RenderingServer.get_current_rendering_driver_name(),
		"zoom": GAMEPLAY_CAMERA_ZOOM,
		"camp": [world_map.get_core_position().x, world_map.get_core_position().y],
		"capture_count": _outputs.size(),
		"stops": _outputs,
	}
	var metadata_file: FileAccess = FileAccess.open(METADATA_PATH, FileAccess.WRITE)
	if metadata_file == null:
		_fail("could not write metadata")
		return
	metadata_file.store_string(JSON.stringify(metadata, "\t"))
	metadata_file.close()
	if RenderingServer.get_current_rendering_method() != "mobile":
		_fail("rendered with %s, not the Mobile renderer" % RenderingServer.get_current_rendering_method())
		return
	print(
		"GAMEPLAY TOUR RENDER OK | method=%s | driver=%s | zoom=%.2f | captures=%d"
		% [
			RenderingServer.get_current_rendering_method(),
			RenderingServer.get_current_rendering_driver_name(),
			GAMEPLAY_CAMERA_ZOOM,
			_outputs.size(),
		]
	)
	get_tree().quit(0)


func _build_stops() -> Array[Dictionary]:
	var camp: Vector2 = world_map.get_core_position()
	var stops: Array[Dictionary] = [
		_stop(&"camp_day", camp, false, "Base Core clearing, satellites, teaching nodes"),
		_stop(&"camp_night", camp, true, "Amber Gold must stay the dominant warm source"),
		_stop(&"camp_outskirts", camp + Vector2(-900.0, 250.0), false, "Edge of the hero bowl"),
		_stop(&"city_street", Vector2(-8150.0, -7900.0), false, "Kaupunki street on the asphalt branch"),
		_stop(&"city_block", _obstacle_position(&"CityBuilding_02") + Vector2(900.0, 500.0), false, "Shell corner and ground dress"),
		_stop(&"city_choke", Vector2(-9200.0, -6000.0), false, "Dense ruin choke"),
		_stop(&"mall_corridor", Vector2(4850.0, -5500.0), false, "Ostari corridor between the shells"),
		_stop(&"mall_shell_edge", _obstacle_position(&"OstariNorthShell") + Vector2(0.0, 700.0), false, "Long shell front and its foundation"),
		_stop(&"mall_pylon", _obstacle_position(&"OstariWestPylon") + Vector2(300.0, 0.0), false, "Mall approach"),
		_stop(&"west_village_yard", Vector2(-8050.0, 8350.0), false, "West Kylat fenced yard"),
		_stop(&"west_village_house", _obstacle_position(&"WestVillageHouse_00") + Vector2(550.0, 250.0), false, "Homestead silhouette"),
		_stop(&"east_village_yard", Vector2(8050.0, 8350.0), false, "East Kylat"),
		_stop(&"east_village_night", Vector2(8050.0, 8350.0), true, "East Kylat at night"),
		_stop(&"road_junction", Vector2.ZERO, false, "Asphalt cross"),
		_stop(&"road_shoulder", Vector2(2100.0, 0.0), false, "Asphalt spine shoulder"),
		_stop(&"dirt_branch", Vector2(-8192.0, 6000.0), false, "Village dirt branch"),
		_stop(&"perimeter_track", Vector2(12288.0, -2000.0), false, "Wilderness perimeter"),
		_stop(&"forest_interior", Vector2(-12000.0, 3000.0), false, "Metsa interior"),
		_stop(&"wilderness", Vector2(-5200.0, 1800.0), false, "Far wilderness belt"),
		_stop(&"wilderness_night", Vector2(-5200.0, 1800.0), true, "Far wilderness at night"),
	]
	return stops


func _stop(stop_id: StringName, focus: Vector2, night: bool, intent: String) -> Dictionary:
	return {&"id": stop_id, &"focus": focus, &"night": night, &"intent": intent}


func _obstacle_position(obstacle_name: StringName) -> Vector2:
	for obstacle: WorldObstacle2D in world_map.get_obstacle_nodes():
		if obstacle.name == obstacle_name:
			return obstacle.global_position
	push_error("GAMEPLAY TOUR: obstacle %s is missing; using origin" % obstacle_name)
	return Vector2.ZERO


func _capture_stop(stop: Dictionary) -> bool:
	var focus: Vector2 = stop[&"focus"]
	_scale_reference.call(&"apply_authoritative_state", focus + SCALE_REFERENCE_OFFSET, Vector2.ZERO)
	_scale_reference.global_position = focus + SCALE_REFERENCE_OFFSET
	camera.position = focus
	camera.zoom = Vector2.ONE * GAMEPLAY_CAMERA_ZOOM
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		_fail("empty viewport for %s" % stop[&"id"])
		return false
	var logical_size: Vector2i = Vector2i(
		int(ProjectSettings.get_setting("display/window/size/viewport_width")),
		int(ProjectSettings.get_setting("display/window/size/viewport_height"))
	)
	if image.get_size() != logical_size:
		image.resize(logical_size.x, logical_size.y, Image.INTERPOLATE_LANCZOS)
	var output_path: String = "%s/tour_%02d_%s.png" % [OUTPUT_DIRECTORY, _outputs.size(), stop[&"id"]]
	var save_error: Error = image.save_png(ProjectSettings.globalize_path(output_path))
	if save_error != OK:
		_fail("%s (%s)" % [output_path, error_string(save_error)])
		return false
	_outputs.append({
		"id": String(stop[&"id"]),
		"focus": [focus.x, focus.y],
		"lighting": "sapphire_night" if stop[&"night"] else "day",
		"intent": stop[&"intent"],
		"output": output_path,
	})
	return true


func _fail(reason: String) -> void:
	push_error("GAMEPLAY TOUR RENDER FAILED: %s" % reason)
	print("GAMEPLAY TOUR RENDER FAILED: %s" % reason)
	get_tree().quit(1)
