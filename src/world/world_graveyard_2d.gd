class_name WorldGraveyard2D
extends Node2D
## The grave rows inside East Kylat's walled plot.
##
## The contract gives the two villages one quiet family and two jobs (D-13,
## D-14): West keeps the yards, East is "graveyard / abandoned rest". East was
## built as West translated about +16,100 in X, so at the gameplay zoom the two
## were the same pole run, the same fence ring and the same four house corners.
## The plot and its walls are colliding obstacles authored by
## `BesprenWorldMap2D._build_village_east`; this layer draws what stands inside
## them - rows of headstones and crosses over sunken mounds, some fallen, some
## missing, with a path left down the middle from the road gate - because a row
## of small regular markers is the one silhouette that reads as a graveyard at
## 17 by 22 screen pixels without a label, which the contract forbids.
##
## Visual only, like every dress layer: drawn at the decor z under gameplay
## participants, walkable, owning no physics, flow or gameplay state, and
## seeded by position so it rebuilds identically.

const GRAVEYARD_Z: int = -5
const ROW_SPACING: float = 150.0
const COLUMN_SPACING: float = 112.0
## Share of grave sites left empty, and of the rest drawn as crosses or as a
## bare mound. Abandonment is what separates this from a war memorial.
const MISSING_SHARE: float = 0.18
const CROSS_SHARE: float = 0.28
const BARE_MOUND_SHARE: float = 0.14
const MAX_TILT: float = 0.16
## Half-width of the path kept clear from the gate side through the middle.
const PATH_HALF_WIDTH: float = 110.0
## Stone and timber held inside the world's value band: the brightest face lands
## near luma 96, well under the Metal node and the refuge.
const STONE_FACE: Color = Color(0.360, 0.372, 0.352, 1.0)
const STONE_SIDE: Color = Color(0.205, 0.214, 0.202, 1.0)
const STONE_CAP: Color = Color(0.455, 0.462, 0.438, 1.0)
const STONE_OUTLINE: Color = Color(0.040, 0.050, 0.047, 0.85)
const TIMBER: Color = Color(0.300, 0.236, 0.172, 1.0)
const TIMBER_SHADE: Color = Color(0.170, 0.132, 0.095, 1.0)
const MOUND: Color = Color(0.205, 0.168, 0.128, 0.72)
const MOUND_GRASS: Color = Color(0.180, 0.240, 0.150, 0.55)

var _plot: Rect2 = Rect2()
var _sites: PackedVector2Array = PackedVector2Array()
var _site_kinds: PackedInt32Array = PackedInt32Array()
var _site_tilts: PackedFloat32Array = PackedFloat32Array()

enum MarkerKind {
	HEADSTONE,
	CROSS,
	BARE_MOUND,
}


func _ready() -> void:
	z_index = GRAVEYARD_Z
	z_as_relative = false


## [param plot] is the walled plot's interior in world space; the gate side is
## its west edge, where the road runs.
func configure(plot: Rect2) -> void:
	_plot = plot
	position = plot.get_center()
	z_index = GRAVEYARD_Z
	z_as_relative = false
	material = WorldBackgroundDecorChunk2D._get_sleek_material()
	_sites.clear()
	_site_kinds.clear()
	_site_tilts.clear()
	var rows: int = maxi(int(plot.size.y / ROW_SPACING), 1)
	var columns: int = maxi(int(plot.size.x / COLUMN_SPACING), 1)
	var cell: Vector2 = Vector2(plot.size.x / float(columns), plot.size.y / float(rows))
	for row: int in range(rows):
		for column: int in range(columns):
			var site: Vector2 = plot.position + Vector2(
				(float(column) + 0.5) * cell.x,
				(float(row) + 0.5) * cell.y
			)
			if absf(site.y - plot.get_center().y) < PATH_HALF_WIDTH:
				continue
			var roll: float = _noise(site, 1.0)
			if roll < MISSING_SHARE:
				continue
			site += Vector2((_noise(site, 2.0) - 0.5) * 34.0, (_noise(site, 3.0) - 0.5) * 22.0)
			var kind: int = MarkerKind.HEADSTONE
			var kind_roll: float = _noise(site, 4.0)
			if kind_roll < BARE_MOUND_SHARE:
				kind = MarkerKind.BARE_MOUND
			elif kind_roll < BARE_MOUND_SHARE + CROSS_SHARE:
				kind = MarkerKind.CROSS
			_sites.append(site - position)
			_site_kinds.append(kind)
			_site_tilts.append((_noise(site, 5.0) - 0.5) * 2.0 * MAX_TILT)
	queue_redraw()


func get_marker_count() -> int:
	return _sites.size()


func get_plot() -> Rect2:
	return _plot


func _draw() -> void:
	# Mounds first, all of them, so no marker's base is overdrawn by the mound
	# of the grave in front of it.
	for index: int in range(_sites.size()):
		var site: Vector2 = _sites[index]
		draw_colored_polygon(GroundRubble.outline(site + Vector2(0.0, 26.0), 52.0, 0.42, site.x * 0.01 + site.y * 0.013), MOUND)
		draw_colored_polygon(GroundRubble.outline(site + Vector2(-6.0, 20.0), 30.0, 0.38, site.x * 0.017 + site.y * 0.011), MOUND_GRASS)
	for index: int in range(_sites.size()):
		var site: Vector2 = _sites[index]
		match _site_kinds[index]:
			MarkerKind.HEADSTONE:
				_draw_headstone(site, _site_tilts[index])
			MarkerKind.CROSS:
				_draw_cross(site, _site_tilts[index])


func _draw_headstone(base: Vector2, tilt: float) -> void:
	GroundShadow.draw_ellipse(self, base + Vector2(4.0, 4.0), Vector2(30.0, 11.0), GroundShadow.PROP_STRENGTH)
	draw_set_transform(base, tilt, Vector2.ONE)
	var half_width: float = 22.0
	var height: float = 56.0
	var face: PackedVector2Array = PackedVector2Array()
	face.append(Vector2(-half_width, 0.0))
	face.append(Vector2(half_width, 0.0))
	for step: int in range(7):
		var angle: float = float(step) / 6.0 * PI
		face.append(Vector2(cos(angle) * half_width, -height + 14.0 - sin(angle) * 14.0))
	var side: PackedVector2Array = PackedVector2Array()
	for point: Vector2 in face:
		side.append(point + Vector2(7.0, -4.0))
	draw_colored_polygon(side, STONE_SIDE)
	draw_colored_polygon(face, STONE_FACE)
	draw_polyline(face + PackedVector2Array([face[0]]), STONE_OUTLINE, 3.0)
	draw_line(Vector2(-half_width * 0.7, -height + 4.0), Vector2(half_width * 0.7, -height + 4.0), STONE_CAP, 4.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_cross(base: Vector2, tilt: float) -> void:
	GroundShadow.draw_ellipse(self, base + Vector2(3.0, 4.0), Vector2(20.0, 8.0), GroundShadow.PROP_STRENGTH)
	draw_set_transform(base, tilt * 1.4, Vector2.ONE)
	draw_rect(Rect2(Vector2(-6.0, -66.0), Vector2(12.0, 66.0)), TIMBER_SHADE)
	draw_rect(Rect2(Vector2(-7.0, -68.0), Vector2(10.0, 66.0)), TIMBER)
	draw_rect(Rect2(Vector2(-22.0, -52.0), Vector2(44.0, 11.0)), TIMBER_SHADE)
	draw_rect(Rect2(Vector2(-23.0, -54.0), Vector2(44.0, 9.0)), TIMBER)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _noise(site: Vector2, salt: float) -> float:
	return fposmod(sin(site.x * 12.9898 + site.y * 78.233 + salt * 37.719) * 43758.5453, 1.0)
