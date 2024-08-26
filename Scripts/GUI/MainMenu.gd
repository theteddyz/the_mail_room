extends Control
@onready var first_cut_scene = preload("res://Scenes/Worlds/testcutscene.tscn")


func _on_start_pressed():
	get_tree().change_scene_to_packed(first_cut_scene)


func _on_quit_pressed():
	get_tree().quit()
