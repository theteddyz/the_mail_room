extends Area3D
var parent
func _ready():
	parent = get_parent()
func _on_vision_timer_timeout():
	var overlaps = get_overlapping_bodies()
	if overlaps.size() > 0:
		for overlap in overlaps:
			if overlap.name == "Player":
				var playerPosition = overlap.global_transform.origin
				$VisionRayCast.look_at(playerPosition)
				$VisionRayCast.force_raycast_update()
				if $VisionRayCast.is_colliding():
					var col = $VisionRayCast.get_collider()
					if col.name == "Player":
						if !parent.chasing:
							parent.on_player_in_vision()
						return
					else:
						parent.on_player_out_of_vision()
