extends Node3D
@export var parent: CharacterBody3D
@export var timer: Timer
@export var vision_blocks: Array[RayCast3D] = []

func _ready():
	timer.timeout.connect(_on_vision_refresh_timer_timeout)

#func reset_all_vision_blocks():
	#for i in vision_blocks.size():
		#var block = vision_blocks[i]
		#block.reset()

func _on_vision_refresh_timer_timeout() -> void:
	if parent.visible:
		# In order from first prio to least prio
		for i in vision_blocks.size():
			var block = vision_blocks[i]
			if block.detect_player:
				print("Player Detected!")
				parent.on_detect_player()
				block.detect_player = false
				return
			elif block.player_in_vision:
				print("Player in vision...!")
				#Softer version of on_player_seen, for removing aggrotimers
				parent.on_player_in_vision()
				return
		print("NOT in vision...!")	
		parent.on_player_unseen()


#func _process(delta: float) -> void:
	#if !should_instant_detect:
		#if seeing_player:
			#_time_spent_seen += delta
			#if _time_spent_seen > time_to_detect:
				##if _get_priority_is_clean():
					##parent.on_player_in_vision()
				#_time_spent_seen = 0
		#else:
			#_time_spent_seen = 0

#func _on_vision_timer_timeout() -> void:
	#if parent.visible:
		#var overlaps = get_overlapping_bodies()
		#if overlaps.size() > 0:
			#for overlap in overlaps:
				#if overlap.name == "Player" or (overlap.name == "Mailcart" and GameManager.player_reference.state is CartingState):
					#var playerPosition = overlap.global_transform.origin
					#vision_blocker_raycast.look_at(playerPosition)
					#if vision_blocker_raycast.is_colliding():
						#var col = vision_blocker_raycast.get_collider()
						#if col.name == "Player" or col.name == "Mailcart":
							#seeing_player = true
							##if _get_priority_is_clean():
							#_check_for_instant_detection(col)
							#return
						#else:
							#seeing_player = false
							##if _get_priority_is_clean():
							#parent.on_player_out_of_vision()
							#return
				#else:
					#seeing_player = false
					##if _get_priority_is_clean():
					#parent.on_player_out_of_vision()
		#else:
			#seeing_player = false
			##if _get_priority_is_clean():
			#parent.on_player_out_of_vision()
#
#func _check_for_instant_detection(col: Object):
	#if should_instant_detect:
		#parent.on_player_in_vision()
	#else:
		#pass
		##do nothing, setting the seeing_player flag is enough
		
#func _get_priority_is_clean() -> bool:
	#for i in priority_array.size():
		#var object = priority_array[i]
		#if !object.seeing_player:
			#if object.name == self.name:
				#return true
		#else:
			#return false
	#return true
