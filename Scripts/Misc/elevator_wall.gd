extends StaticBody3D
@onready var left_door_collider = $Elevator_Wall/Left_Door/CollisionShape3D
@onready var right_door_collider = $Elevator_Wall/Right_Door/CollisionShape3D
func disable_wall_collision():
	left_door_collider.disabled = true
	right_door_collider.disabled = true


func enable_wall_collision():
	left_door_collider.disabled = false
	right_door_collider.disabled = false
