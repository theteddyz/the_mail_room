extends Node3D
@onready var anim = $AnimationPlayer

var closed:bool = false




func _on_area_3d_body_entered(body):
	if !closed:
		anim.play("door_close")
		closed = true
