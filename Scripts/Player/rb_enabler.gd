extends Area3D




func _on_timer_timeout():
	for body in get_overlapping_bodies():
		if body is RigidBody3D and body.has_method("update_position"):
			if !body.should_freeze:
				body.freeze = false
