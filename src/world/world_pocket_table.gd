class_name WorldPocketTable
extends Resource
## One dress layer's pockets for one zone, as a row of the world composition.
##
## A pocket is `Vector4(centre_x, centre_y, radius_x, radius_y)`: an ellipse the
## layer samples candidates inside. Three layers used to author their own tables
## in their own scripts - background decor, ambient scenery and the wilderness
## accent - so a pocket could be moved in one and not the others, which is how
## wilderness pocket 2 came to sit under the Ostari shell's foundation. They now
## all live in `WorldCompositionContract.pocket_tables`, keyed by layer and zone.

@export var layer: StringName = &""
@export var zone: StringName = &""
@export var pockets: PackedVector4Array = PackedVector4Array()
