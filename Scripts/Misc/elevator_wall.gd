extends StaticBody3D
@onready var left_door_collider = $Elevator_Wall/Left_Door/CollisionShape3D
@onready var right_door_collider = $Elevator_Wall/Right_Door/CollisionShape3D
@onready var col1 = $CollisionShape3D
@onready var col2 = $CollisionShape3D2
@onready var col3 = $CollisionShape3D3
func disable_wall_collision():
	left_door_collider.disabled = true
	right_door_collider.disabled = true
	col1.disabled = true
	col2.disabled = true
	col3.disabled = true


func enable_wall_collision():
	left_door_collider.disabled = false
	right_door_collider.disabled = false
	col1.disabled = false
	col2.disabled = false
	col3.disabled = false
