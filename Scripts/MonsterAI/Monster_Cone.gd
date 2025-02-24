extends Area3D
@export var parent: CharacterBody3D
@export var vision_blocker_raycast: RayCast3D
@export var timer: Timer

func _ready():
	timer.timeout.connect(_on_vision_timer_timeout)
	
func _on_vision_timer_timeout() -> void:
	if parent.visible:
		var overlaps = get_overlapping_bodies()
		if overlaps.size() > 0:
			for overlap in overlaps:
				if overlap.name == "Player" or (overlap.name == "Mailcart" and GameManager.player_reference.state is CartingState):
					var playerPosition = overlap.global_transform.origin
					vision_blocker_raycast.look_at(playerPosition)
					if vision_blocker_raycast.is_colliding():
						var col = vision_blocker_raycast.get_collider()
						if col.name == "Player" or col.name == "Mailcart":
							parent.on_player_in_vision()
							return
						else:
							parent.on_player_out_of_vision()
							return
				else:
					#if overlaps.find(overlap) == overlaps.size() - 1:
					parent.on_player_out_of_vision()
		else:
			parent.on_player_out_of_vision()
