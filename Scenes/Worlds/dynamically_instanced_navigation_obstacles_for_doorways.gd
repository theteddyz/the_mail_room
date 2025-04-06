extends Node3D

var obstacle

func _ready() -> void:
	var obs_scene = preload("res://Scenes/Worlds/navigation_obstacles.tscn")
	obstacle = obs_scene.instantiate()
	get_parent().get_node("NavigationRegion3D").add_child(obstacle)
	#obstacle.enabled = false  # start unlocked
