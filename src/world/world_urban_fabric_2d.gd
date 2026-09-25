class_name WorldUrbanFabric2D
extends Node2D
## Visual-only ground fabric of the two urban districts (DIST-01): Kaupunki's
## kerbs and pavements along the asphalt spine, the rubble a collapsed frontage
## spilled across the pavement at the city choke, and Ostari's parking bays on
## either side of the mall road.
##
## A street reads as a street at 1x through the edge between carriageway and
## pavement, and a mall through the one ground pattern nothing else makes -
## rows of painted bays. Both are drawn here on the ground layer, under every
## dress layer and every obstacle. It owns no physics, flow, resource or
## gameplay state and is configured after the canonical obstacle and flow
## pipeline, like every other dress layer.

const FABRIC_Z: int = -20
## Pavement is chunked along the street so each chunk culls on its own; 2,048
## units is one macro cell and about three gameplay frames.
const PAVEMENT_CHUNK_LENGTH: float = 2048.0
const CHUNK_SCRIPT: Script = preload("res://src/world/world_urban_fabric_chunk_2d.gd")

var _pavement_chunk_count: int = 0
var _parking_bay_count: int = 0
var _spill_piece_count: int = 0


func _ready() -> void:
	z_index = FABRIC_Z
	z_as_relative = false


## [param street_span] runs the pavement along the spine in world y, from x to
## y. [param choke] is the landmark's pinch in world y, where the frontage steps
## in to [param choke_face_offset]. [param parking_rows] are the bay rows as
## rectangles, each opening toward the road it borders: a row above its road
## has its heads on its top edge.
func configure(
	spine_x: float,
	street_span: Vector2,
	road_half_width: float,
	face_offset: float,
	choke: Vector2,
	choke_face_offset: float,
	parking_rows: Array[Rect2],
	parking_road_y: float
) -> void:
	_clear()
	z_index = FABRIC_Z
	z_as_relative = false
	var salt: int = 0
	for side: int in [-1, 1]:
		var cursor: float = street_span.x
		while cursor < street_span.y - 1.0:
			var chunk_end: float = minf(cursor + PAVEMENT_CHUNK_LENGTH, street_span.y)
			var chunk: Node2D = _add_chunk("Pavement_%02d" % _pavement_chunk_count)
			chunk.call(
				&"configure_pavement",
				spine_x, side, Vector2(cursor, chunk_end), road_half_width,
				face_offset, choke, choke_face_offset, salt
			)
			_pavement_chunk_count += 1
			salt += 101
			cursor = chunk_end
	var spill: Node2D = _add_chunk("ChokeSpill")
	spill.call(
		&"configure_spill",
		Vector2(spine_x, (choke.x + choke.y) * 0.5), -1, road_half_width, choke_face_offset, choke.y - choke.x
	)
	_spill_piece_count = int(spill.call(&"get_piece_count"))
	for row_index: int in range(parking_rows.size()):
		var row: Rect2 = parking_rows[row_index]
		var chunk: Node2D = _add_chunk("ParkingRow_%02d" % row_index)
		chunk.call(&"configure_parking", row, -1 if row.get_center().y < parking_road_y else 1, 7001 + row_index * 97)
		_parking_bay_count += int(chunk.call(&"get_bay_count"))


func get_pavement_chunk_count() -> int:
	return _pavement_chunk_count


func get_parking_bay_count() -> int:
	return _parking_bay_count


func get_spill_piece_count() -> int:
	return _spill_piece_count


func get_chunks() -> Array[Node2D]:
	var chunks: Array[Node2D] = []
	for child: Node in get_children():
		if child is Node2D:
			chunks.append(child as Node2D)
	return chunks


func _add_chunk(chunk_name: String) -> Node2D:
	var chunk: Node2D = Node2D.new()
	chunk.set_script(CHUNK_SCRIPT)
	chunk.name = chunk_name
	add_child(chunk)
	return chunk


func _clear() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	_pavement_chunk_count = 0
	_parking_bay_count = 0
	_spill_piece_count = 0
