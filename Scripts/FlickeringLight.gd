extends Node3D

@onready var anim:AnimationPlayer = $AnimationPlayer


func _ready():
	anim.play("flickering")
