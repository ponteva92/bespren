class_name WorldForestUnderstoryChunk2D
extends Node2D
## One spatially bounded draw batch of [WorldForestUnderstory2D].
##
## Everything here is drawn once and retained: the chunk redraws only when
## sealed, and a 2,048-unit chunk holds a few dozen elements, so the handful the
## gameplay camera can see cost a few hundred retained commands under one
## shared material.

const SLEEK_CANVAS_SHADER: Shader = preload("res://shaders/sleek_canvas_grade.gdshader")
const WILD_ATLAS: Texture2D = preload(
	"res://assets/2d/environment/polyhaven_wild/polyhaven_wild_atlas.png"
)
const POLYHAVEN_ATLAS: Texture2D = preload(
	"res://assets/2d/environment/polyhaven/polyhaven_environment_atlas.png"
)

## A sapling is the canopy [WorldObstacle2D] draws for a real tree, a size
## smaller and a step darker, so the understory is the same species as the stand
## it grows under. The ambient family value is reused rather than restated.
const SAPLING_TINT: Color = WorldAmbientSceneryChunk2D.WILD_TREE_TINT * Color(0.92, 0.94, 0.90, 1.0)
const ATLAS_PROP_TINT: Color = Color(0.74, 0.80, 0.70, 0.94)
## The two dense firs, cropped above their trunks: `fir_tree_01` yaws 0 and 1
## from `WorldAmbientSceneryChunk2D.WILD_TREE_REGIONS`, at 84 percent of their
## height, which is where the canopy mass ends and the bole begins.
const SHRUB_CANOPY_REGIONS: Array[Rect2] = [
	Rect2(76.0, 54.0, 104.0, 114.0),
	Rect2(314.0, 49.0, 137.0, 118.0),
]
const SHRUB_SQUASH: float = 0.78
## A shade under the saplings, because a bush sits in the stand's shadow.
const SHRUB_TINT: Color = SAPLING_TINT * Color(0.86, 0.88, 0.86, 1.0)
const FERN_DARK: Color = Color("1f3524")
const FERN_LIGHT: Color = Color("3b5a33")
const FERN_FROND_MIN: int = 6
const FERN_FROND_MAX: int = 9

static var _shared_material: ShaderMaterial

var _positions: PackedVector2Array = PackedVector2Array()
var _spans: PackedFloat32Array = PackedFloat32Array()
var _kinds: PackedInt32Array = PackedInt32Array()
var _seeds: PackedInt32Array = PackedInt32Array()
var _world_render_bounds: Rect2 = Rect2()
var _has_bounds: bool = false


func _ready() -> void:
	z_index = WorldForestUnderstory2D.UNDERSTORY_Z
	z_as_relative = false
	material = _get_shared_material()


static func _get_shared_material() -> ShaderMaterial:
	if _shared_material == null:
		_shared_material = ShaderMaterial.new()
		_shared_material.shader = SLEEK_CANVAS_SHADER
	return _shared_material


func configure_origin(world_origin: Vector2) -> void:
	position = world_origin
	z_index = WorldForestUnderstory2D.UNDERSTORY_Z
	z_as_relative = false
	material = _get_shared_material()


func add_element(world_position: Vector2, span: float, kind: int, seed_value: int) -> void:
	_positions.append(world_position - position)
	_spans.append(span)
	_kinds.append(kind)
	_seeds.append(seed_value)
	# A sapling is lifted by a fifth of its span so its base meets the ground.
	var reach: float = span * 0.75 + GroundShadow.MAX_CONTACT_DEPTH
	var area: Rect2 = Rect2(world_position - Vector2.ONE * reach, Vector2.ONE * reach * 2.0)
	if not _has_bounds:
		_world_render_bounds = area
		_has_bounds = true
	else:
		_world_render_bounds = _world_render_bounds.merge(area)


func seal() -> void:
	queue_redraw()


func get_element_count() -> int:
	return _positions.size()


func get_world_render_bounds() -> Rect2:
	return _world_render_bounds


func _draw() -> void:
	for index: int in range(_positions.size()):
		var center: Vector2 = _positions[index]
		var span: float = _spans[index]
		var seed_value: int = _seeds[index]
		match _kinds[index]:
			WorldForestUnderstory2D.UnderstoryKind.SAPLING:
				var region: Rect2 = WorldAmbientSceneryChunk2D.WILD_TREE_REGIONS[
					posmod(seed_value, WorldAmbientSceneryChunk2D.WILD_TREE_REGIONS.size())
				]
				_draw_atlas(WILD_ATLAS, region, center, span, SAPLING_TINT, seed_value, 0.40, 0.52, 0.22)
			WorldForestUnderstory2D.UnderstoryKind.SHRUB:
				_draw_shrub(center, span, seed_value)
			WorldForestUnderstory2D.UnderstoryKind.FERN:
				_draw_fern(center, span, seed_value)
			WorldForestUnderstory2D.UnderstoryKind.STUMP:
				_draw_atlas(
					POLYHAVEN_ATLAS,
					WorldAmbientSceneryChunk2D.POLYHAVEN_STUMP_REGION,
					center,
					span,
					ATLAS_PROP_TINT,
					seed_value,
					0.80,
					0.45,
					0.10
				)
			WorldForestUnderstory2D.UnderstoryKind.MOSS_ROCK:
				var rocks: Array[Rect2] = WorldAmbientSceneryChunk2D.POLYHAVEN_MOSS_ROCK_REGIONS
				_draw_atlas(
					POLYHAVEN_ATLAS,
					rocks[posmod(seed_value, rocks.size())],
					center,
					span,
					ATLAS_PROP_TINT,
					seed_value,
					0.85,
					0.55,
					0.08
				)
			WorldForestUnderstory2D.UnderstoryKind.DEADFALL:
				_draw_atlas(
					POLYHAVEN_ATLAS,
					WorldAmbientSceneryChunk2D.POLYHAVEN_DEAD_TRUNK_REGION,
					center,
					span,
					ATLAS_PROP_TINT,
					seed_value,
					0.88,
					0.30,
					0.06
				)


## An atlas frame standing on its contact. `lift` raises the art by that share
## of its span so a tall frame's base, not its middle, meets the ground point;
## a mirrored frame on odd seeds doubles the silhouettes for free.
func _draw_atlas(
	texture: Texture2D,
	region: Rect2,
	center: Vector2,
	span: float,
	tint: Color,
	seed_value: int,
	contact_width: float,
	contact_flatten: float,
	lift: float
) -> void:
	var source_span: float = maxf(region.size.x, region.size.y)
	var size: Vector2 = region.size * span / maxf(source_span, 1.0)
	var art_center: Vector2 = center - Vector2(0.0, span * lift)
	var radius_x: float = size.x * 0.5 * contact_width
	GroundShadow.draw_ellipse(
		self,
		art_center + Vector2(0.0, size.y * 0.5),
		Vector2(radius_x, minf(radius_x * contact_flatten, GroundShadow.MAX_CONTACT_DEPTH)),
		GroundShadow.PROP_STRENGTH
	)
	var mirrored: bool = seed_value % 2 == 1
	draw_set_transform(art_center, 0.0, Vector2(-1.0 if mirrored else 1.0, 1.0))
	draw_texture_rect_region(texture, Rect2(-size * 0.5, size), region, tint, false, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## A shrub is the canopy of one of the two dense firs with its trunk cropped
## away, drawn wider than tall. The first pass drew notched lobes over a dark
## rim in the ambient foliage's flat colours, and at 36 to 63 screen pixels
## those read as mossy stones - a flat fill has no leaf structure to read, and a
## rim around it is a rock's outline. The approved tree bakes carry that
## structure already, and cropping them keeps every shrub inside the five
## frames the contract lets the world draw; the wild family's own shrub and
## fern frames remain unpromoted pending the human 1x veto.
func _draw_shrub(center: Vector2, span: float, seed_value: int) -> void:
	var region: Rect2 = SHRUB_CANOPY_REGIONS[posmod(seed_value, SHRUB_CANOPY_REGIONS.size())]
	var width: float = span
	var height: float = span * region.size.y / region.size.x * SHRUB_SQUASH
	var art_center: Vector2 = center - Vector2(0.0, height * 0.32)
	GroundShadow.draw_ellipse(
		self,
		center + Vector2(0.0, height * 0.12),
		Vector2(width * 0.40, minf(width * 0.40 * 0.45, GroundShadow.MAX_CONTACT_DEPTH)),
		GroundShadow.PROP_STRENGTH
	)
	var mirrored: bool = (seed_value / 3) % 2 == 1
	draw_set_transform(art_center, 0.0, Vector2(-1.0 if mirrored else 1.0, 1.0))
	draw_texture_rect_region(
		WILD_ATLAS,
		Rect2(Vector2(-width, -height) * 0.5, Vector2(width, height)),
		region,
		SHRUB_TINT,
		false,
		true
	)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Fronds radiating from a dark crown, the lower ring darker than the upper, so
## the clump has a lit side at 27 to 46 screen pixels without a single circle.
func _draw_fern(center: Vector2, span: float, seed_value: int) -> void:
	var fronds: int = FERN_FROND_MIN + posmod(seed_value, FERN_FROND_MAX - FERN_FROND_MIN + 1)
	var spin: float = WorldForestUnderstory2D.hash_unit(seed_value + 17) * TAU
	GroundShadow.draw_ellipse(
		self,
		center + Vector2(0.0, span * 0.10),
		Vector2(span * 0.30, minf(span * 0.30 * 0.5, GroundShadow.MAX_CONTACT_DEPTH)),
		GroundShadow.PROP_STRENGTH * 0.8
	)
	for layer: int in range(2):
		var color: Color = FERN_DARK if layer == 0 else FERN_LIGHT
		var reach_scale: float = 1.0 if layer == 0 else 0.72
		for frond: int in range(fronds):
			var angle: float = spin + TAU * (float(frond) + 0.5 * float(layer)) / float(fronds)
			var reach: float = span * 0.5 * reach_scale * (
				0.75 + WorldForestUnderstory2D.hash_unit(seed_value + frond * 3 + layer * 31) * 0.25
			)
			var direction: Vector2 = Vector2(cos(angle), sin(angle) * 0.72)
			var across: Vector2 = Vector2(-direction.y, direction.x) * span * 0.055
			var tip: Vector2 = center + direction * reach
			var middle: Vector2 = center + direction * reach * 0.45
			draw_colored_polygon(
				PackedVector2Array([center, middle + across, tip, middle - across]),
				color
			)
