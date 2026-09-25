class_name WorldVillageYardChunk2D
extends Node2D
## One homestead's yard for `WorldVillageYards2D`, drawn in world coordinates.
##
## Sized for the 0.38 gameplay zoom, where a screen pixel is 2.6 world units: a
## log end of radius 11 is an 8-pixel round, a furrow ridge of 14 is five
## pixels, a plot post of 12 is a four-pixel square. The ground items - apron,
## trail, plot - are translucent over the terrain so its grain still carries
## the surface, and everything is lit, so the yard falls to the blue hour with
## the village around it.

## The camp clearing's packed-earth pair, so a lived-in yard and the refuge's
## trodden bowl are one ground language.
const EARTH_COLOR: Color = WorldCampClearing2D.EARTH_COLOR
const PATH_COLOR: Color = WorldCampClearing2D.PATH_COLOR
## Stacked to about 0.45 at the core, which lifts the village dirt by five to
## six luma: at the first pass's 0.30 the apron added three and could not be
## found in a capture, and a yard nobody can see is not doing its job.
const APRON_STEPS: Array[Vector2] = [
	Vector2(1.00, 0.17),
	Vector2(0.78, 0.19),
	Vector2(0.52, 0.19),
]
const TRAIL_WIDTH: float = 58.0
const TRAIL_ALPHA: float = 0.36

const SOIL: Color = Color(0.13, 0.10, 0.075, 0.62)
const FURROW_RIDGE: Color = Color(0.36, 0.28, 0.19, 0.50)
const FURROW_PITCH: float = 48.0
const FURROW_WIDTH: float = 14.0
const SPROUT: Color = Color(0.27, 0.42, 0.19, 0.90)
const SPROUT_SHARE: float = 0.55
const POST_SIDE: Color = Color(0.17, 0.12, 0.085, 1.0)
const POST_TOP: Color = Color(0.44, 0.34, 0.22, 1.0)
const RAIL: Color = Color(0.32, 0.24, 0.16, 0.85)
const POST_PITCH: float = 86.0

const LOG_FACE: Color = Color(0.63, 0.49, 0.31, 1.0)
const LOG_RING: Color = Color(0.34, 0.24, 0.15, 1.0)
const LOG_HEART: Color = Color(0.45, 0.33, 0.20, 1.0)
const LOG_RADIUS: float = 11.0
const BLOCK_FACE: Color = Color(0.56, 0.43, 0.28, 1.0)
const AXE_HANDLE: Color = Color(0.40, 0.30, 0.19, 1.0)
const AXE_HEAD: Color = Color(0.46, 0.47, 0.45, 1.0)

const LINE_CORD: Color = Color(0.74, 0.71, 0.64, 0.70)
const CLOTHES: Array[Color] = [
	Color(0.62, 0.64, 0.60, 0.95),
	Color(0.32, 0.42, 0.52, 0.95),
	Color(0.55, 0.30, 0.20, 0.95),
	Color(0.70, 0.66, 0.52, 0.95),
]

var _items: Array[Dictionary] = []


func add_apron(center: Vector2, radii: Vector2, angle: float, salt: int) -> void:
	_items.append({&"kind": &"apron", &"center": center, &"radii": radii, &"angle": angle, &"salt": salt})
	queue_redraw()


func add_trail(points: PackedVector2Array, salt: int) -> void:
	_items.append({&"kind": &"trail", &"points": points, &"salt": salt})
	queue_redraw()


func add_woodpile(center: Vector2, salt: int) -> void:
	_items.append({&"kind": &"woodpile", &"center": center, &"salt": salt})
	queue_redraw()


func add_plot(center: Vector2, size: Vector2, salt: int) -> void:
	_items.append({&"kind": &"plot", &"center": center, &"size": size, &"salt": salt})
	queue_redraw()


func add_line(from: Vector2, to: Vector2, salt: int) -> void:
	_items.append({&"kind": &"line", &"from": from, &"to": to, &"salt": salt})
	queue_redraw()


## (x, y, radius) of every piece of furniture and ground item, for the gate
## that proves each one lies on open ground.
func get_item_footprints() -> Array[Vector3]:
	var footprints: Array[Vector3] = []
	for item: Dictionary in _items:
		match item[&"kind"] as StringName:
			&"apron":
				var apron_center: Vector2 = item[&"center"]
				footprints.append(Vector3(apron_center.x, apron_center.y, 120.0))
			&"woodpile":
				var pile: Vector2 = item[&"center"]
				footprints.append(Vector3(pile.x, pile.y, WorldVillageYards2D.WOODPILE_RADIUS))
			&"plot":
				var plot_center: Vector2 = item[&"center"]
				footprints.append(Vector3(plot_center.x, plot_center.y, (item[&"size"] as Vector2).length() * 0.5))
			&"line":
				for end: Vector2 in [item[&"from"] as Vector2, item[&"to"] as Vector2]:
					footprints.append(Vector3(end.x, end.y, 30.0))
			&"trail":
				for point: Vector2 in item[&"points"] as PackedVector2Array:
					footprints.append(Vector3(point.x, point.y, WorldVillageYards2D.TRAIL_CLEARANCE))
	return footprints


func get_item_kinds() -> Array[StringName]:
	var kinds: Array[StringName] = []
	for item: Dictionary in _items:
		kinds.append(item[&"kind"] as StringName)
	return kinds


func _draw() -> void:
	# Ground first, furniture after, whatever order the items arrived in.
	for pass_kinds: Array in [[&"apron", &"trail"], [&"plot"], [&"woodpile", &"line"]]:
		for item: Dictionary in _items:
			if not pass_kinds.has(item[&"kind"]):
				continue
			match item[&"kind"] as StringName:
				&"apron":
					_draw_apron(item[&"center"], item[&"radii"], item[&"angle"], item[&"salt"])
				&"trail":
					_draw_trail(item[&"points"], item[&"salt"])
				&"plot":
					_draw_plot(item[&"center"], item[&"size"], item[&"salt"])
				&"woodpile":
					_draw_woodpile(item[&"center"], item[&"salt"])
				&"line":
					_draw_line(item[&"from"], item[&"to"], item[&"salt"])


func _draw_apron(center: Vector2, radii: Vector2, angle: float, salt: int) -> void:
	for step: Vector2 in APRON_STEPS:
		var outline: PackedVector2Array = PackedVector2Array()
		for vertex: int in range(15):
			var theta: float = TAU * float(vertex) / 15.0
			var wobble: float = 0.86 + _noise(salt, vertex + int(step.x * 100.0)) * 0.14
			var local: Vector2 = Vector2(cos(theta) * radii.x, sin(theta) * radii.y) * step.x * wobble
			outline.append(center + local.rotated(angle))
		draw_colored_polygon(outline, Color(EARTH_COLOR.r, EARTH_COLOR.g, EARTH_COLOR.b, step.y))


func _draw_trail(points: PackedVector2Array, salt: int) -> void:
	var colors: PackedColorArray = PackedColorArray()
	for index: int in range(points.size()):
		# Fades out along its length: a trail thins where fewer feet went.
		var fade: float = 1.0 - float(index) / float(maxi(points.size() - 1, 1))
		colors.append(Color(PATH_COLOR.r, PATH_COLOR.g, PATH_COLOR.b, TRAIL_ALPHA * (0.35 + 0.65 * fade)))
	draw_polyline_colors(points, colors, TRAIL_WIDTH)


func _draw_plot(center: Vector2, size: Vector2, salt: int) -> void:
	var plot: Rect2 = Rect2(center - size * 0.5, size)
	draw_rect(plot.grow(-6.0), SOIL)
	var ridge_y: float = plot.position.y + FURROW_PITCH * 0.5
	var row: int = 0
	while ridge_y < plot.end.y - 10.0:
		draw_line(Vector2(plot.position.x + 18.0, ridge_y), Vector2(plot.end.x - 18.0, ridge_y), FURROW_RIDGE, FURROW_WIDTH)
		var sprout_x: float = plot.position.x + 34.0
		var column: int = 0
		while sprout_x < plot.end.x - 30.0:
			if _noise(salt, row * 31 + column) < SPROUT_SHARE:
				draw_circle(Vector2(sprout_x, ridge_y - 4.0), 5.0, SPROUT)
			sprout_x += 38.0
			column += 1
		ridge_y += FURROW_PITCH
		row += 1
	# A low timber border, one post short on a corner where it has fallen.
	var corners: Array[Vector2] = [plot.position, Vector2(plot.end.x, plot.position.y), plot.end, Vector2(plot.position.x, plot.end.y)]
	var missing: int = int(_noise(salt, 97) * 4.0)
	for side: int in range(4):
		var from: Vector2 = corners[side]
		var to: Vector2 = corners[(side + 1) % 4]
		if side != missing:
			draw_line(from, to, RAIL, 5.0)
		var posts: int = maxi(int(from.distance_to(to) / POST_PITCH), 1)
		for post: int in range(posts):
			var at: Vector2 = from.lerp(to, float(post) / float(posts))
			draw_rect(Rect2(at - Vector2(6.0, 2.0), Vector2(12.0, 14.0)), POST_SIDE)
			draw_rect(Rect2(at - Vector2(6.0, 6.0), Vector2(12.0, 8.0)), POST_TOP)


func _draw_woodpile(center: Vector2, salt: int) -> void:
	draw_colored_polygon(
		GroundRubble.outline(center + Vector2(10.0, 18.0), 92.0, 0.42, float(salt)),
		Color(GroundShadow.COLOR.r, GroundShadow.COLOR.g, GroundShadow.COLOR.b, 0.30)
	)
	# Rounds stacked end-on in a stepped pile, the back row highest.
	var rows: Array[int] = [4, 5, 6]
	for row: int in range(rows.size()):
		var count: int = rows[row]
		var row_y: float = center.y - float(rows.size() - 1 - row) * LOG_RADIUS * 1.55
		for log_index: int in range(count):
			var x: float = center.x + (float(log_index) - float(count - 1) * 0.5) * LOG_RADIUS * 2.05
			var jitter: Vector2 = Vector2(_noise(salt, row * 11 + log_index) - 0.5, _noise(salt, row * 13 + log_index + 50) - 0.5) * 3.0
			var at: Vector2 = Vector2(x, row_y) + jitter
			draw_circle(at, LOG_RADIUS, LOG_RING)
			draw_circle(at, LOG_RADIUS * 0.78, LOG_FACE)
			draw_circle(at, LOG_RADIUS * 0.28, LOG_HEART)
	var block: Vector2 = center + Vector2(LOG_RADIUS * 9.0, LOG_RADIUS * 2.5)
	draw_circle(block + Vector2(4.0, 6.0), 21.0, Color(GroundShadow.COLOR.r, GroundShadow.COLOR.g, GroundShadow.COLOR.b, 0.30))
	draw_circle(block, 20.0, LOG_RING)
	draw_circle(block, 16.0, BLOCK_FACE)
	draw_line(block + Vector2(-2.0, -2.0), block + Vector2(26.0, -30.0), AXE_HANDLE, 4.0)
	draw_rect(Rect2(block + Vector2(-8.0, -9.0), Vector2(14.0, 9.0)), AXE_HEAD)


func _draw_line(from: Vector2, to: Vector2, salt: int) -> void:
	for post: Vector2 in [from, to]:
		draw_rect(Rect2(post - Vector2(6.0, 8.0), Vector2(12.0, 16.0)), POST_SIDE)
		draw_rect(Rect2(post - Vector2(6.0, 12.0), Vector2(12.0, 7.0)), POST_TOP)
	var sag: Vector2 = Vector2(0.0, 18.0)
	var middle: Vector2 = from.lerp(to, 0.5) + sag
	draw_polyline(PackedVector2Array([from, middle, to]), LINE_CORD, 2.5)
	var pieces: int = 3 + int(_noise(salt, 5) * 2.0)
	for piece: int in range(pieces):
		var t: float = (float(piece) + 0.7) / float(pieces + 0.4)
		var anchor: Vector2 = from.lerp(to, t) + sag * (1.0 - absf(t - 0.5) * 2.0)
		var cloth: Color = CLOTHES[(piece + int(_noise(salt, 9) * 4.0)) % CLOTHES.size()]
		var cloth_size: Vector2 = Vector2(28.0 + _noise(salt, 20 + piece) * 16.0, 34.0 + _noise(salt, 30 + piece) * 14.0)
		draw_rect(Rect2(anchor + Vector2(-cloth_size.x * 0.5, 0.0), cloth_size), cloth)


func _noise(salt: int, index: int) -> float:
	return WorldForestUnderstory2D.hash_unit(salt * 131 + index * 17)
