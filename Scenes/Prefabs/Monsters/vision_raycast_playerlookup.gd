#extends RayCast3D
#
#var player: CharacterBody3D
#@export var max_range = 5.75
#
#func _ready():
	#player = GameManager.get_player()
	#
#func _physics_process(_delta):
	#if !(abs(player.global_position.distance_to(global_position)) > max_range):
		#self.enabled = true
		#var player_origin = player.global_transform.origin
		#look_at(player_origin)
	#else:
		#self.enabled = false
