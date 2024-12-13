extends Area3D

var new_crouch_depth:float
var old_crouch_depth:float
var old_croching_collider:CollisionShape3D
var new_crouching_collider:CollisionShape3D
func _ready():
	var player = GameManager.get_player()
	old_croching_collider = player.find_child("crouching_collision_shape")
	new_crouching_collider = player.find_child("crouching_collision_addition")
	old_crouch_depth = (1.8 - 0.5)
	new_crouch_depth = old_crouch_depth - 0.5
func _on_body_entered(body):
	if body.name == "Player":
		body.state.crouching_depth = new_crouch_depth
		body.state.crouch_assist = true
		new_crouching_collider.disabled = false
		old_croching_collider.disabled = true


func _on_body_exited(body):
	if body.name == "Player":
		body.state.crouching_depth = old_crouch_depth
		body.state.crouch_assist = false
		old_croching_collider.disabled = false
		new_crouching_collider.disabled = true
