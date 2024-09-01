extends Node3D
var player:Node3D = null

func _ready():
	player = GameManager.get_player()
	

"""
func _process(delta):
	if player and visible == true:
		look_at(player.global_transform.origin, Vector3.UP)
"""
