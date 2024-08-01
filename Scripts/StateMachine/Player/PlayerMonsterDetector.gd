extends Area3D

var called = false
var bit = 0

func _on_vision_timer_timeout():
	var overlaps = get_overlapping_bodies()
	if overlaps.size() > 0:
		for overlap in overlaps:
			if overlap.is_in_group("monster"):
				var monsterPosition = overlap.global_transform.origin
				$VisionRayCast.look_at(monsterPosition)
				$VisionRayCast.force_raycast_update()
				if $VisionRayCast.is_colliding():
					if(bit == 1):
						bit = 0
						called = false
						var col = $VisionRayCast.get_collider()
						if(!called):
							ScareDirector.emit_signal("monster_seen", true)
	else:
		if(bit == 0):
			bit = 1
			called = false
			if(!called):
				ScareDirector.emit_signal("monster_seen", false)
				called = true
