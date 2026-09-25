class_name GroundRubble
extends RefCounted

## One language for broken material lying on the world floor.
##
## The Ostari lot needed rubble that reads at the 0.38 gameplay zoom and built
## it here: a drop shadow falling the way every contact in the world falls, a
## darker broken side, and a lit top facet, on an irregular seven-point outline
## squashed on y so a flat piece reads as lying down. The background decor drew
## its 300 rubble pieces as single flat triangles at one alpha, which at that
## zoom are translucent grey shards up to 38 pixels across - geometry with no
## top, no side and no ground under it. Both now draw through this class, so a
## heap on the mall lot and a heap on a city street are the same material.
##
## Every offset is a fixed fraction of the piece's own size, so a caller that
## publishes a render envelope can bound it: see [constant MAX_REACH].

## Shadow direction, matching the contact shadows' top-left world light.
const SHADOW_DIRECTION: Vector2 = Vector2(0.6, 0.8)
const SHADOW_DISTANCE: float = 0.55
const SHADOW_ALPHA: float = 0.39
const SIDE_DROP: float = 0.34
const SQUASH: float = 0.72
## Farthest any pixel of a piece lands from its centre, as a multiple of its size:
## the outline reaches 1.0 and the shadow is displaced a further 0.55.
const MAX_REACH: float = 1.0 + SHADOW_DISTANCE


## Draws one broken piece of [param size] world units at [param center].
## [param salt] fixes the outline; [param top_color] is the lit facet and
## [param side_color] the broken side under it.
static func draw_chunk(
	canvas: CanvasItem,
	center: Vector2,
	size: float,
	salt: float,
	top_color: Color,
	side_color: Color
) -> void:
	if canvas == null or size <= 0.0:
		return
	var top: PackedVector2Array = outline(center, size, SQUASH, salt)
	var shadow_offset: Vector2 = SHADOW_DIRECTION * size * SHADOW_DISTANCE
	var side_offset: Vector2 = Vector2(0.0, size * SIDE_DROP)
	var shadow: PackedVector2Array = PackedVector2Array()
	var side: PackedVector2Array = PackedVector2Array()
	for point: Vector2 in top:
		shadow.append(point + shadow_offset)
		side.append(point + side_offset)
	canvas.draw_colored_polygon(
		shadow,
		Color(GroundShadow.COLOR.r, GroundShadow.COLOR.g, GroundShadow.COLOR.b, SHADOW_ALPHA)
	)
	canvas.draw_colored_polygon(side, side_color)
	canvas.draw_colored_polygon(top, top_color)


## An irregular closed outline: seven vertices, each at its own reach between 0.62
## and 1.0 of [param radius], squashed on y by [param squash].
static func outline(center: Vector2, radius: float, squash: float, salt: float) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	var spin: float = unit_noise(salt, 11) * TAU
	for vertex: int in range(7):
		var angle: float = spin + TAU * float(vertex) / 7.0
		var reach: float = radius * (0.62 + unit_noise(salt, 13 + vertex) * 0.38)
		points.append(center + Vector2(cos(angle) * reach, sin(angle) * reach * squash))
	return points


static func unit_noise(salt: float, index: int) -> float:
	return fposmod(sin(salt * 12.9898 + float(index) * 78.233) * 43758.5453, 1.0)
