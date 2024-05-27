extends CharacterBody3D

@onready var nav_agent = $NavigationAgent3D
var player
var SPEED = 3.0


func _ready():
	await get_tree().create_timer(0.1).timeout
	player = get_parent().find_child("Player")
func _physics_process(delta):
	if player:
		update_target_location(player.global_transform.origin)
		var current_location = global_transform.origin
		var next_location = nav_agent.get_next_path_position()
		var new_velocity = (next_location - current_location).normalized() * SPEED
		velocity = velocity.move_toward(new_velocity,.25)
		move_and_slide()
		for col_idx in get_slide_collision_count():
			var col := get_slide_collision(col_idx)
			if col.get_collider() is RigidBody3D:
				col.get_collider().apply_central_impulse(-col.get_normal() * 2)
				col.get_collider().apply_impulse(-col.get_normal() * 0.01, col.get_position())

func update_target_location(target_location):
	nav_agent.target_position = target_location
