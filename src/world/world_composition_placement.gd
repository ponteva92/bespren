class_name WorldCompositionPlacement
extends Resource
## One authored colliding placement in the world composition: a name, a position
## relative to the anchor it belongs to, a footprint, a rotation and a
## `WorldObstacle2D.VisualKind`. Used for the camp's three satellites, whose
## positions are offsets from `WorldCompositionContract.camp_position`.

@export var placement_name: StringName = &""
@export var offset: Vector2 = Vector2.ZERO
@export var size: Vector2 = Vector2.ZERO
@export var rotation: float = 0.0
@export var visual_kind: int = 0
