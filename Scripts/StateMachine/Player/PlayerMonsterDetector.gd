extends Area3D

var called = false
var bit = 0
@onready var raycaster = $VisionRayCast

func _on_vision_timer_timeout():
	var overlaps = get_overlapping_bodies()
	if overlaps.size() > 0:
		for overlap in overlaps:
			if overlap.is_in_group("monster"):
				var monsterPosition = overlap.global_transform.origin
				raycaster.look_at(monsterPosition)
				raycaster.force_raycast_update()
				if raycaster.is_colliding():
					print(raycaster.get_collider().name)
				if raycaster.is_colliding() and raycaster.get_collider().name == overlap.name:
					if(bit == 1):
						bit = 0
						called = false
						var _col = $VisionRayCast.get_collider()
						if(!called and _col.is_visible_in_tree()):
							ScareDirector.emit_signal("monster_seen", true)
	else:
		if(bit == 0):
			bit = 1
			called = false
			if(!called):
				ScareDirector.emit_signal("monster_seen", false)
				called = true
