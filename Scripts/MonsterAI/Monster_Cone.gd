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
				if parent.get("state") != null:
					parent.state.on_detect_player() if parent.state.has_method("on_detect_player") else null
				else:
					parent.on_detect_player()
				block.detect_player = false
				return
			elif block.player_in_vision:
				#Softer version of on_player_seen, for removing aggrotimers
				if parent.get("state") != null:
					parent.state.on_player_in_vision() if parent.state.has_method("on_player_in_vision") else null
				else:
					parent.on_player_in_vision()
				return
		if parent.get("state") != null and parent.state.has_method("on_player_unseen"):
			parent.state.on_player_unseen()
		elif parent.has_method("on_player_unseen"):
			parent.on_player_unseen()
