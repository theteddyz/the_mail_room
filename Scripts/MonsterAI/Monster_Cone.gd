extends Area3D
var parent
func _ready():
	parent = get_parent()
func _on_vision_timer_timeout():
	if parent.visible:
		var overlaps = get_overlapping_bodies()
		if overlaps.size() > 0:
			for overlap in overlaps:
				if overlap.name == "Player" or (overlap.name == "Mailcart" and GameManager.player_reference.state is CartingState):
					var playerPosition = overlap.global_transform.origin
					$VisionRayCast.look_at(playerPosition)
					$VisionRayCast.force_raycast_update()
					if $VisionRayCast.is_colliding():
						var col = $VisionRayCast.get_collider()
						if col.name == "Player" or col.name == "Mailcart":
							print("PLAYER IN AND SEEABLE!")
							parent.on_player_in_vision()
							return
						else:
							print("PLAYER IN!")
							parent.on_player_out_of_vision()
							return
				else:
					#if overlaps.find(overlap) == overlaps.size() - 1:
					print("PLAYER NOT EVEN IN!")
					parent.on_player_out_of_vision()
		else:
			print("PLAYER NOT EVEN IN!")
			parent.on_player_out_of_vision()
