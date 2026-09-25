class_name WorldUrbanFabricChunk2D
extends Node2D
## One culled piece of `WorldUrbanFabric2D`: a run of pavement on one side of
## Kaupunki's spine, the rubble spilled at the city choke, or one row of Ostari
## parking bays. Presentation only; it draws in world coordinates.
##
## Every stroke here is sized for the 0.38 gameplay zoom, where one screen pixel
## is 2.6 world units: a slab joint of 3 units is a hairline, a kerb of 6 is two
## pixels, bay paint of 9 is three. Paint and pavement are translucent over the
## terrain so the concrete grain underneath still carries the surface, and all
## of it is lit, so it falls to the blue hour with the ground it lies on.

enum Kind { PAVEMENT, SPILL, PARKING }

## A lift over the city concrete rather than a colour of its own: at 0.26 over
## the delivered ground it adds about eight luma, enough to separate pavement
## from carriageway without competing with anything standing on it.
const PAVEMENT_TINT: Color = Color(0.46, 0.47, 0.45, 0.26)
const SLAB_JOINT: Color = Color(0.04, 0.05, 0.05, 0.42)
const SLAB_PITCH: float = 96.0
const SLAB_JOINT_WIDTH: float = 3.0
## The kerb is the edge the eye reads a street by: a lit top on the pavement
## side and a gutter shadow on the carriageway side.
const KERB_TOP: Color = Color(0.60, 0.60, 0.56, 0.50)
const KERB_TOP_WIDTH: float = 6.0
const GUTTER: Color = Color(0.02, 0.03, 0.03, 0.46)
const GUTTER_WIDTH: float = 8.0
## Where the pavement starts, measured in from the road's outer edge, so the
## kerb overlaps the shoulder's last units and no seam shows between them.
const KERB_OVERLAP: float = 6.0
const BROKEN_SLAB: Color = Color(0.03, 0.035, 0.035, 0.30)
const BROKEN_SLAB_SHARE: float = 0.12
const WEED: Color = Color(0.20, 0.28, 0.16, 0.70)
const WEED_SHARE: float = 0.16
const DRAIN_PITCH: float = 640.0
const DRAIN: Color = Color(0.03, 0.035, 0.035, 0.78)
const DRAIN_BAR: Color = Color(0.36, 0.37, 0.35, 0.60)

const SPILL_TOP: Color = Color(0.40, 0.40, 0.37, 1.0)
const SPILL_SIDE: Color = Color(0.20, 0.20, 0.19, 1.0)
const SPILL_BRICK_TOP: Color = Color(0.40, 0.24, 0.17, 1.0)
const SPILL_BRICK_SIDE: Color = Color(0.20, 0.12, 0.09, 1.0)
## Pieces stay under 34 units - 13 screen pixels - so the spill reads as debris
## on the pavement a survivor walks over, never as a wall that would collide.
const SPILL_PIECE_SIZE: Vector2 = Vector2(12.0, 34.0)
const SPILL_PIECES: int = 26

## A bay is 300 wide: a car here is 280 wide, so the bay just fits one. The
## asphalt wash darkens the lot so faded paint reads against it.
const BAY_WIDTH: float = 300.0
const LOT_ASPHALT: Color = Color(0.05, 0.06, 0.06, 0.34)
const BAY_PAINT: Color = Color(0.80, 0.76, 0.60, 0.44)
const BAY_PAINT_WIDTH: float = 9.0
const BAY_PAINT_WORN_SHARE: float = 0.22
const WHEEL_STOP: Color = Color(0.52, 0.52, 0.49, 0.62)
const WHEEL_STOP_SHADOW: Color = Color(0.02, 0.03, 0.03, 0.40)
const OIL_STAIN: Color = Color(0.02, 0.025, 0.025, 0.26)
const OIL_STAIN_SHARE: float = 0.30

var kind: int = Kind.PAVEMENT
var _spine_x: float = 0.0
var _side: int = -1
var _span: Vector2 = Vector2.ZERO
var _road_half_width: float = 270.0
var _face_offset: float = 420.0
var _choke: Vector2 = Vector2.ZERO
var _choke_face_offset: float = 360.0
var _salt: int = 0
var _center: Vector2 = Vector2.ZERO
var _length: float = 0.0
var _row: Rect2 = Rect2()
var _head_direction: int = -1
var _piece_count: int = 0
var _bay_count: int = 0


func configure_pavement(
	spine_x: float,
	side: int,
	span: Vector2,
	road_half_width: float,
	face_offset: float,
	choke: Vector2,
	choke_face_offset: float,
	salt: int
) -> void:
	kind = Kind.PAVEMENT
	_spine_x = spine_x
	_side = side
	_span = span
	_road_half_width = road_half_width
	_face_offset = face_offset
	_choke = choke
	_choke_face_offset = choke_face_offset
	_salt = salt
	queue_redraw()


func configure_spill(
	center: Vector2, side: int, road_half_width: float, choke_face_offset: float, length: float
) -> void:
	kind = Kind.SPILL
	_center = center
	_side = side
	_road_half_width = road_half_width
	_choke_face_offset = choke_face_offset
	_length = length
	_piece_count = SPILL_PIECES
	queue_redraw()


## [param head_direction] is -1 when the bays' heads are on the row's top edge
## (a row above its road) and 1 when they are on its bottom edge.
func configure_parking(row: Rect2, head_direction: int, salt: int) -> void:
	kind = Kind.PARKING
	_row = row
	_head_direction = head_direction
	_salt = salt
	_bay_count = int(floor(row.size.x / BAY_WIDTH))
	queue_redraw()


func get_piece_count() -> int:
	return _piece_count


func get_bay_count() -> int:
	return _bay_count


## The world-space rectangle this chunk draws into, for the gates.
func get_draw_bounds() -> Rect2:
	match kind:
		Kind.PAVEMENT:
			var outer: float = maxf(_face_offset, _choke_face_offset)
			var inner: float = _road_half_width - KERB_OVERLAP - GUTTER_WIDTH
			var x_a: float = _spine_x + float(_side) * inner
			var x_b: float = _spine_x + float(_side) * outer
			return Rect2(minf(x_a, x_b), _span.x, absf(x_b - x_a), _span.y - _span.x)
		Kind.SPILL:
			var reach: float = SPILL_PIECE_SIZE.y * GroundRubble.MAX_REACH
			var x_a: float = _center.x + float(_side) * (_road_half_width - reach)
			var x_b: float = _center.x + float(_side) * (_choke_face_offset + reach)
			return Rect2(minf(x_a, x_b), _center.y - _length * 0.5, absf(x_b - x_a), _length)
		_:
			return _row


func _draw() -> void:
	match kind:
		Kind.PAVEMENT:
			_draw_pavement()
		Kind.SPILL:
			_draw_spill()
		Kind.PARKING:
			_draw_parking()


func _draw_pavement() -> void:
	var inner: float = _road_half_width - KERB_OVERLAP
	for segment: Vector3 in _pavement_segments():
		var x_a: float = _spine_x + float(_side) * inner
		var x_b: float = _spine_x + float(_side) * (segment.z - 4.0)
		var left: float = minf(x_a, x_b)
		var width: float = absf(x_b - x_a)
		draw_rect(Rect2(left, segment.x, width, segment.y - segment.x), PAVEMENT_TINT)
		var first_joint: float = ceilf(segment.x / SLAB_PITCH) * SLAB_PITCH
		var joint: float = first_joint
		while joint < segment.y:
			draw_line(Vector2(left, joint), Vector2(left + width, joint), SLAB_JOINT, SLAB_JOINT_WIDTH)
			var slab: int = int(roundf(joint / SLAB_PITCH))
			if _noise(slab, 1) < BROKEN_SLAB_SHARE:
				_draw_broken_slab(Rect2(left, joint, width, minf(SLAB_PITCH, segment.y - joint)), slab)
			if _noise(slab, 2) < WEED_SHARE:
				_draw_weed(Vector2(left + width * (0.2 + _noise(slab, 3) * 0.6), joint), slab)
			joint += SLAB_PITCH
		var middle: float = left + width * 0.5
		draw_line(Vector2(middle, segment.x), Vector2(middle, segment.y), SLAB_JOINT, SLAB_JOINT_WIDTH * 0.8)
	# The kerb runs unbroken past alleys and recesses: a pavement continues
	# across an alley mouth, and the edge is what says this is a street.
	var kerb_x: float = _spine_x + float(_side) * inner
	var gutter_x: float = kerb_x - float(_side) * GUTTER_WIDTH * 0.5
	var kerb_top_x: float = kerb_x + float(_side) * KERB_TOP_WIDTH * 0.5
	draw_line(Vector2(gutter_x, _span.x), Vector2(gutter_x, _span.y), GUTTER, GUTTER_WIDTH)
	draw_line(Vector2(kerb_top_x, _span.x), Vector2(kerb_top_x, _span.y), KERB_TOP, KERB_TOP_WIDTH)
	var drain: float = ceilf(_span.x / DRAIN_PITCH) * DRAIN_PITCH
	while drain < _span.y:
		var drain_center: Vector2 = Vector2(kerb_x - float(_side) * 14.0, drain)
		draw_rect(Rect2(drain_center - Vector2(11.0, 22.0), Vector2(22.0, 44.0)), DRAIN)
		for bar: int in range(3):
			var bar_y: float = drain - 12.0 + float(bar) * 12.0
			draw_line(Vector2(drain_center.x - 8.0, bar_y), Vector2(drain_center.x + 8.0, bar_y), DRAIN_BAR, 2.0)
		drain += DRAIN_PITCH


## (start y, end y, outer offset) runs of pavement: the choke's shallower kerb
## where it overlaps this chunk, the standard one elsewhere.
func _pavement_segments() -> Array[Vector3]:
	var segments: Array[Vector3] = []
	var cursor: float = _span.x
	if _choke.y > _span.x and _choke.x < _span.y:
		if _choke.x > cursor:
			segments.append(Vector3(cursor, _choke.x, _face_offset))
		segments.append(Vector3(maxf(_choke.x, cursor), minf(_choke.y, _span.y), _choke_face_offset))
		cursor = minf(_choke.y, _span.y)
	if cursor < _span.y:
		segments.append(Vector3(cursor, _span.y, _face_offset))
	return segments


func _draw_broken_slab(slab: Rect2, index: int) -> void:
	var inset: float = 5.0
	var piece: Rect2 = Rect2(
		slab.position + Vector2(inset, inset),
		Vector2(slab.size.x * (0.35 + _noise(index, 4) * 0.4), slab.size.y - inset * 2.0)
	)
	if _noise(index, 5) < 0.5:
		piece.position.x = slab.end.x - piece.size.x - inset
	if piece.size.x <= 0.0 or piece.size.y <= 0.0:
		return
	draw_rect(piece, BROKEN_SLAB)
	GroundFissure.draw_segment(
		self,
		piece.position + Vector2(piece.size.x * _noise(index, 6), 0.0),
		piece.end - Vector2(piece.size.x * _noise(index, 7), 0.0),
		float(_salt + index),
		0.6
	)


func _draw_weed(root: Vector2, index: int) -> void:
	for blade: int in range(3):
		var lean: float = (_noise(index, 10 + blade) - 0.5) * 1.4
		var height: float = 10.0 + _noise(index, 20 + blade) * 8.0
		var base: Vector2 = root + Vector2(float(blade - 1) * 4.0, 0.0)
		draw_line(base, base + Vector2(sin(lean), -cos(lean)) * height, WEED, 2.2)


func _draw_spill() -> void:
	# The frontage came down onto the pavement on one side of the pinch: a heap
	# against the wall base thinning toward the kerb, concrete and brick mixed.
	var near_edge: float = _road_half_width + 8.0
	var far_edge: float = _choke_face_offset - 4.0
	for piece: int in range(SPILL_PIECES):
		var along: float = (_noise(piece, 30) - 0.5) * _length * 0.55
		var reach: float = pow(_noise(piece, 31), 1.8)
		var offset: float = lerpf(far_edge, near_edge, reach)
		var size: float = lerpf(SPILL_PIECE_SIZE.y, SPILL_PIECE_SIZE.x, reach) * (0.75 + _noise(piece, 32) * 0.25)
		var brick: bool = _noise(piece, 33) < 0.35
		GroundRubble.draw_chunk(
			self,
			_center + Vector2(float(_side) * offset, along),
			size,
			float(9001 + piece),
			SPILL_BRICK_TOP if brick else SPILL_TOP,
			SPILL_BRICK_SIDE if brick else SPILL_SIDE
		)


func _draw_parking() -> void:
	draw_rect(_row.grow(24.0), LOT_ASPHALT)
	var head_y: float = _row.position.y if _head_direction < 0 else _row.end.y
	var mouth_y: float = _row.end.y if _head_direction < 0 else _row.position.y
	draw_line(Vector2(_row.position.x, head_y), Vector2(_row.end.x, head_y), BAY_PAINT, BAY_PAINT_WIDTH)
	for line: int in range(_bay_count + 1):
		var x: float = _row.position.x + float(line) * BAY_WIDTH
		if _noise(line, 40) < BAY_PAINT_WORN_SHARE:
			# Worn to a stub at the head: the paint that is left is where no
			# tyre ever ran over it.
			var stub_end: float = lerpf(head_y, mouth_y, 0.25 + _noise(line, 41) * 0.25)
			draw_line(Vector2(x, head_y), Vector2(x, stub_end), BAY_PAINT, BAY_PAINT_WIDTH)
		else:
			draw_line(Vector2(x, head_y), Vector2(x, mouth_y), BAY_PAINT, BAY_PAINT_WIDTH)
	for bay: int in range(_bay_count):
		var bay_center_x: float = _row.position.x + (float(bay) + 0.5) * BAY_WIDTH
		var stop_y: float = head_y - float(_head_direction) * 46.0
		var stop: Rect2 = Rect2(Vector2(bay_center_x - 60.0, stop_y - 7.0), Vector2(120.0, 14.0))
		if _noise(bay, 42) > 0.18:
			draw_rect(Rect2(stop.position + Vector2(3.0, 5.0), stop.size), WHEEL_STOP_SHADOW)
			draw_rect(stop, WHEEL_STOP)
		if _noise(bay, 43) < OIL_STAIN_SHARE:
			var stain_center: Vector2 = Vector2(
				bay_center_x + (_noise(bay, 44) - 0.5) * 80.0,
				lerpf(head_y, mouth_y, 0.35 + _noise(bay, 45) * 0.3)
			)
			var stain: PackedVector2Array = GroundRubble.outline(
				stain_center, 46.0 + _noise(bay, 46) * 38.0, 0.8, float(_salt + bay)
			)
			draw_colored_polygon(stain, OIL_STAIN)


func _noise(index: int, channel: int) -> float:
	return WorldForestUnderstory2D.hash_unit(_salt * 131 + index * 17 + channel * 7919)
