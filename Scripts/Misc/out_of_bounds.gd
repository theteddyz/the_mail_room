extends Node3D
@onready var anim:AnimationPlayer = $AnimationPlayer
@onready var laugh:AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var mail_room_level = preload("res://Scenes/Worlds/main_menu_scene.tscn")

func _on_area_3d_body_entered(body):
	if body.name == "Player":
		print("HELLOOOO")
		anim.play("kill_player")
		await laugh.finished
		get_tree().change_scene_to_packed(mail_room_level)
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		body.queue_free()
		get_parent().queue_free()
