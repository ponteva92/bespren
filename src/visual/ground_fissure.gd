class_name GroundFissure
extends RefCounted

## One crack language for every ground-plane surface.
##
## Three places drew cracks and all three drew them as straight strokes of one
## width in near-black: the district decor (`18` units wide, with a perpendicular
## `85`-unit branch at 0.56 of its length), the road's transverse surface breaks
## (a `5`-unit bar with a branch off its centre) and the road's longitudinal
## fatigue lines. At the 0.38 gameplay zoom the decor stroke is a seven-pixel
## black bar and the T it makes with its branch is the silhouette of a dropped
## stick; the road breaks read as twigs standing on the carriageway. The
## gameplay tour caught all three.
##
## What separates a crack from a stick is not its darkness but its depth cue. A
## stick lying on the ground casts its shadow down and to the right, away from
## the world light; a crack is a groove, so its far wall catches that light and
## the lit edge sits down and to the right of the dark core. That lip is the
## whole trick, and it costs one faint line. The rest is what a fracture does
## and a ruled line cannot: it wanders a few units either side of its course,
## and it is widest in the middle and closes to a hairline at both tips.
##
## Widths are authored in world units against the 0.38 gameplay zoom, where
## `CORE_WIDTH` is 2.3 screen pixels at the widest point and `TIP_WIDTH` under
## one. Every offset is bounded - jag, lip and half-width together stay under
## `MAX_REACH` - so a caller that publishes a render envelope can bound it
## without knowing the geometry.

## Darker than any ground it lands on, never black: over the 58 to 61 urban
## ground it composites to about luma 27, where the old strokes reached 19.
const CORE_COLOR: Color = Color(0.035, 0.040, 0.038, 0.60)
## Warm-grey concrete lit by the world light. Over the same ground it lifts
## about 9 luma, which is enough to read as an edge and not enough to be a line.
const LIP_COLOR: Color = Color(0.66, 0.63, 0.57, 0.16)
const CORE_WIDTH: float = 6.0
const TIP_WIDTH: float = 1.6
const LIP_WIDTH: float = 2.2
## Down and to the right, the far wall of the groove from a top-left light, the
## same direction every contact shadow in the world falls.
const LIP_OFFSET: Vector2 = Vector2(2.0, 2.0)
## Length of one straight piece of fracture. At 0.38 that is ten screen pixels,
## short enough that the jag reads as a crack and long enough that a 90-unit
## crack still has four pieces.
const SEGMENT_LENGTH: float = 26.0
const MAX_JAG: float = 4.5
## The farthest any pixel of a fissure lands from its authored course.
const MAX_REACH: float = MAX_JAG + LIP_OFFSET.x * 1.4142 + LIP_WIDTH * 0.5 + CORE_WIDTH * 0.5


## Draws one fissure along a straight course from [param from] to [param to].
## [param salt] makes the jag deterministic; [param width_scale] thins a branch.
static func draw_segment(
	canvas: CanvasItem,
	from: Vector2,
	to: Vector2,
	salt: float,
	width_scale: float = 1.0,
	core_color: Color = CORE_COLOR
) -> void:
	draw_path(canvas, PackedVector2Array([from, to]), salt, width_scale, core_color)


## Draws one fissure along [param course], a polyline the caller has already
## given its large-scale wander. Each leg is broken into pieces of about
## `SEGMENT_LENGTH` with a bounded perpendicular jag, and the width tapers along
## the whole path rather than per leg, so a multi-leg crack still has two tips.
static func draw_path(
	canvas: CanvasItem,
	course: PackedVector2Array,
	salt: float,
	width_scale: float = 1.0,
	core_color: Color = CORE_COLOR
) -> void:
	if canvas == null or course.size() < 2:
		return
	var points: PackedVector2Array = _jagged(course, salt)
	if points.size() < 2:
		return
	var total: float = 0.0
	for index: int in range(1, points.size()):
		total += points[index].distance_to(points[index - 1])
	if total <= 0.0:
		return
	# Lip first, so the dark core sits on top of it along the shared edge.
	var walked: float = 0.0
	for index: int in range(1, points.size()):
		var a: Vector2 = points[index - 1]
		var b: Vector2 = points[index]
		var piece: float = a.distance_to(b)
		var t: float = (walked + piece * 0.5) / total
		walked += piece
		var body: float = sin(PI * clampf(t, 0.0, 1.0))
		canvas.draw_line(
			a + LIP_OFFSET,
			b + LIP_OFFSET,
			LIP_COLOR,
			LIP_WIDTH * width_scale * (0.35 + 0.65 * body)
		)
	walked = 0.0
	for index: int in range(1, points.size()):
		var a: Vector2 = points[index - 1]
		var b: Vector2 = points[index]
		var piece: float = a.distance_to(b)
		var t: float = (walked + piece * 0.5) / total
		walked += piece
		var body: float = sin(PI * clampf(t, 0.0, 1.0))
		canvas.draw_line(a, b, core_color, lerpf(TIP_WIDTH, CORE_WIDTH, body) * width_scale)


static func _jagged(course: PackedVector2Array, salt: float) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array([course[0]])
	var vertex: int = 0
	for leg: int in range(1, course.size()):
		var a: Vector2 = course[leg - 1]
		var b: Vector2 = course[leg]
		var leg_length: float = a.distance_to(b)
		if leg_length <= 0.0:
			continue
		var across: Vector2 = (b - a).normalized().orthogonal()
		var pieces: int = maxi(int(ceil(leg_length / SEGMENT_LENGTH)), 1)
		for piece: int in range(1, pieces + 1):
			var t: float = float(piece) / float(pieces)
			var point: Vector2 = a.lerp(b, t)
			# The authored vertices stay where the caller put them; only the
			# points between them jag, so a course's corners and tips are exact.
			if piece < pieces:
				vertex += 1
				point += across * (_hash(salt, vertex) * 2.0 - 1.0) * MAX_JAG
			points.append(point)
	return points


static func _hash(salt: float, index: int) -> float:
	return fposmod(sin(salt * 12.9898 + float(index) * 78.233) * 43758.5453, 1.0)
