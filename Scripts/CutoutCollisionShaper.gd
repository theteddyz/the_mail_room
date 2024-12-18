@tool
extends StaticBody3D

@export var collision_area: CollisionShape3D
@export var cutout: CSGBox3D
@export var axis_to_adjust: Vector3
@export var sign: int

var leftmost_point = 2.9
var rightmost_point = -2.9
var topmost_point = 7.763
var lowestmost_point = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	assert(collision_area != null && cutout != null && axis_to_adjust != null, "You are required to add these in the inspector")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		_adjust_shape()
		
func _adjust_shape():
	var cutout_size = cutout.size * axis_to_adjust
	var cutout_position = cutout.position * axis_to_adjust
	
	# Based on the position and size of the cutout in the given axis, adjust the size of the collider
	if sign == 1:
		# Calculate the limiting coordinate (left side of cutout)
		var limit_coord = cutout_position.x + (cutout_size.x/2)
		var halfway_coord = (leftmost_point + limit_coord) / 2
		collision_area.position.x = halfway_coord
		collision_area.shape.size.x = abs(leftmost_point - limit_coord)
		
	elif sign == 2:
		var limit_coord = cutout_position.x - (cutout_size.x/2)
		var halfway_coord = (rightmost_point + limit_coord) / 2
		collision_area.position.x = halfway_coord
		collision_area.shape.size.x = abs(rightmost_point - limit_coord)
		
	elif sign == 3:
		var limit_coord = cutout_position.y + (cutout_size.y/2)
		var halfway_coord = (topmost_point + limit_coord) / 2
		collision_area.position.y = halfway_coord
		collision_area.shape.size.y = abs(topmost_point - limit_coord)
	else:
		var limit_coord = cutout_position.y - (cutout_size.y/2)
		var halfway_coord = (lowestmost_point + limit_coord) / 2
		collision_area.position.y = halfway_coord
		collision_area.shape.size.y = abs(lowestmost_point - limit_coord)
