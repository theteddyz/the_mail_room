extends Control
@onready var first_cut_scene = preload("res://Scenes/Worlds/testcutscene.tscn")

func _ready():
	var player = get_parent().find_child("Player")
	if player != null:
		player.queue_free()

func _on_start_pressed():
	get_tree().change_scene_to_packed(first_cut_scene)


func _on_quit_pressed():
	get_tree().quit()
