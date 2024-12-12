extends Area3D

var called = false
var bit = 0
@onready var raycaster = $VisionRayCast
signal visiontimer_signal(nodes)

var tracked_gameobjects: Array = []

func _on_vision_timer_timeout():	
	var monster_overlaps = get_overlapping_bodies()
	var allbodies = monster_overlaps.filter(func(body): return body.is_in_group("scarevision"))
	allbodies.append_array(get_overlapping_areas().filter(func(body): return body.is_in_group("scarevision")))
	visiontimer_signal.emit(allbodies)
	
	var counter = 0
	for gameobject in tracked_gameobjects:
		if gameobject != null:
			if !monster_overlaps.has(gameobject):
				tracked_gameobjects.erase(gameobject)
				ScareDirector.emit_signal("monster_seen", false)
		else:
			tracked_gameobjects.pop_at(counter)
			ScareDirector.emit_signal("monster_seen", false)
		counter += 1
	if monster_overlaps.size() > 0:
		for overlap in monster_overlaps:
			if overlap.is_in_group("monster"):
				var monsterPosition = overlap.global_transform.origin
				if overlap.find_child("raycast_look_position") != null:
					monsterPosition = overlap.get_node("raycast_look_position").global_transform.origin
				raycaster.look_at(monsterPosition)
				raycaster.force_raycast_update()
				if (raycaster.is_colliding() and raycaster.get_collider().name == overlap.name) and !tracked_gameobjects.has(raycaster.get_collider()):
					var _col = raycaster.get_collider()
					if(_col.is_visible_in_tree()):
						tracked_gameobjects.append(overlap)
						ScareDirector.emit_signal("monster_seen", true)
