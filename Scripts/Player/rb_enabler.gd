extends Area3D

var rb:RigidBody3D 

func _ready():
	rb = get_parent()

func _on_body_exited(body):
	if body.name == "Player":
		rb.freeze = true


func _on_body_entered(body):
	if body.name == "Player":
		rb.freeze = false
