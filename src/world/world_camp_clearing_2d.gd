class_name WorldCampClearing2D
extends Node2D
## The trodden ground of the camp's hero clearing.
##
## The redesign contract calls the camp "one empty bowl" (D-03): Base Core,
## three satellites as furniture, and the teaching pocket, with the forest wall
## as its rim. At the gameplay zoom the bowl did not read, because the ground
## under the refuge was the same forest floor as the ground a screen away - the
## camp sat on the terrain like a decal. A clearing reads when the ground inside
## it is different: packed, warmer and lighter where people have walked, worn
## into paths toward the things they walk to.
##
## So this draws a soft patch of packed earth under the bowl and a worn path to
## each satellite, on the ground layer above the terrain and below the roads,
## every decoration and every prop. It is built the way `GroundShadow` and the
## moss patches are: stacked low-alpha steps with irregular outlines, so the
## patch has a core and no edge. It wears the dirt road's grain material, so the
## clearing, the paths and the dirt spur are one surface, and like that material
## it is lit and falls to the blue hour with the world.
##
## Visual only: no collision, flow, resource or gameplay state, configured after
## the canonical pipeline like every dress layer.

## On the ground layer itself, ordered in the map scene after the terrain and
## before `TerrainDetails`, so the trodden earth lies over the forest floor and
## under the roads: the camp's dirt spur starts inside the bowl and has to read
## as the path leaving it, not as ground the clearing has painted over.
const CLEARING_Z: int = -20
## Packed earth: warmer and a step lighter than the forest floor it replaces.
## Stacked, the core lands near luma 55 over the floor's 50 - a clearing, and
## still well under the refuge's amber, which stays the only warm focal mass.
## It is held there rather than lighter because the camp's `AmberLight` lands on
## this ground: a first pass at luma 57 turned the whole bowl into an orange disc
## by day, the light's own footprint made visible by the albedo under it.
const EARTH_COLOR: Color = Color(0.276, 0.234, 0.180, 1.0)
const PATH_COLOR: Color = Color(0.292, 0.248, 0.190, 1.0)
const CORE_RADIUS: float = 760.0
## Radius and alpha of each step, outermost first.
const STEPS: Array[Vector2] = [
	Vector2(1.30, 0.07),
	Vector2(1.12, 0.09),
	Vector2(0.94, 0.11),
	Vector2(0.76, 0.12),
	Vector2(0.56, 0.13),
	Vector2(0.36, 0.10),
]
const PATH_WIDTH: float = 74.0
const PATH_ALPHA: float = 0.26
const OUTLINE_VERTICES: int = 17

var _camp_position: Vector2 = Vector2.ZERO
var _path_targets: PackedVector2Array = PackedVector2Array()


func _ready() -> void:
	z_index = CLEARING_Z
	z_as_relative = false


## [param path_targets] are world positions the camp's paths lead to - today the
## three satellites.
func configure(camp_position: Vector2, path_targets: PackedVector2Array) -> void:
	_camp_position = camp_position
	_path_targets = path_targets.duplicate()
	position = camp_position
	z_index = CLEARING_Z
	z_as_relative = false
	material = WorldRoadSegmentChunk2D._get_detail_material(true)
	queue_redraw()


func get_path_target_count() -> int:
	return _path_targets.size()


func get_clearing_radius() -> float:
	return CORE_RADIUS * STEPS[0].x


func _draw() -> void:
	for step_index: int in range(STEPS.size()):
		var step: Vector2 = STEPS[step_index]
		draw_colored_polygon(
			_outline(CORE_RADIUS * step.x, 0.80, float(step_index) * 3.7),
			Color(EARTH_COLOR.r, EARTH_COLOR.g, EARTH_COLOR.b, step.y)
		)
	for target_index: int in range(_path_targets.size()):
		_draw_path(_path_targets[target_index] - _camp_position, float(target_index))


## A path bows a little off the straight line and fades at the far end, where
## the satellite's own contact takes over.
func _draw_path(target: Vector2, salt: float) -> void:
	var length: float = target.length()
	if length <= 1.0:
		return
	var direction: Vector2 = target / length
	var across: Vector2 = direction.orthogonal()
	var bow: float = (_noise(salt, 1) - 0.5) * length * 0.18
	var samples: int = 12
	var points: PackedVector2Array = PackedVector2Array()
	var colors: PackedColorArray = PackedColorArray()
	for sample: int in range(samples + 1):
		var t: float = float(sample) / float(samples)
		points.append(direction * length * t + across * bow * sin(PI * t))
		var fade: float = 1.0 - smoothstep(0.7, 1.0, t)
		colors.append(Color(PATH_COLOR.r, PATH_COLOR.g, PATH_COLOR.b, PATH_ALPHA * (0.35 + 0.65 * fade)))
	# One strip rather than a line per sample: separate quads overlap at every
	# joint and double their alpha into a string of beads.
	draw_polyline_colors(points, colors, PATH_WIDTH)

func _outline(radius: float, squash: float, salt: float) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	var lobe_phase: float = _noise(salt, 2) * TAU
	var fine_phase: float = _noise(salt, 3) * TAU
	for vertex: int in range(OUTLINE_VERTICES):
		var angle: float = TAU * float(vertex) / float(OUTLINE_VERTICES)
		var reach: float = radius * (
			1.0 + 0.10 * sin(angle * 3.0 + lobe_phase) + 0.05 * sin(angle * 7.0 + fine_phase)
		)
		points.append(Vector2(cos(angle) * reach, sin(angle) * reach * squash))
	return points


static func _noise(salt: float, index: int) -> float:
	return fposmod(sin(salt * 12.9898 + float(index) * 78.233) * 43758.5453, 1.0)
