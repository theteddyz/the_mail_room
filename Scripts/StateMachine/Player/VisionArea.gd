extends Area3D


func _on_vision_timer_timeout():
	var overlaps = get_overlapping_bodies()
	if overlaps.size() > 0:
		for overlap in overlaps:
			if overlap.name == "monster":
				var monsterPosition = overlap.global_transform.origin
				$VisionRayCast.look_at(monsterPosition)
				$VisionRayCast.force_raycast_update()
				if $VisionRayCast.is_colliding():
					var col = $VisionRayCast.get_collider()
					if col.name == "monster":
						EventBus.emitCustomSignal("monster_seen")
