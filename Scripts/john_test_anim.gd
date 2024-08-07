extends Node3D

@onready var anim:AnimationPlayer = $AnimationPlayer


func _input(event):
	if event.is_action_pressed("interact"):
		anim.play("DoorSlam")
