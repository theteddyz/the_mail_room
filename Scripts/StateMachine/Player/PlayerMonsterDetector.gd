extends Area3D

var called = false
var bit = 0
@onready var raycaster = $VisionRayCast
signal visiontimer_signal(nodes)

func _on_vision_timer_timeout():	
	var monster_overlaps = get_overlapping_bodies()
	
	#if monster_overlaps.size() != 0:
		#monster_overlaps[0].is_in_group("meme")
	var allbodies = monster_overlaps.filter(func(body): return body.is_in_group("scarevision"))
	allbodies.append_array(get_overlapping_areas().filter(func(body): return body.is_in_group("scarevision")))
	visiontimer_signal.emit(allbodies)
	
	if monster_overlaps.size() > 0:
		for overlap in monster_overlaps:
			if overlap.is_in_group("monster"):
				var monsterPosition = overlap.global_transform.origin
				if overlap.find_child("raycast_look_position") != null:
					monsterPosition = overlap.get_node("raycast_look_position").global_transform.origin
				raycaster.look_at(monsterPosition)
				raycaster.force_raycast_update()
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
