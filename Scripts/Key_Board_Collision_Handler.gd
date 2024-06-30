extends Node3D



@onready var broken_model = preload("res://Assets/Models/keyboard_broken_low_poly.tscn")
@onready var single_key_model = preload("res://Assets/Models/key_broken.tscn")
var collision_threshold = 5.0
var parent_node
func _ready():
	parent_node = get_parent()
func _on_grabbable_body_entered(body):
	var collision_force = calculate_collision_force(body)
	if collision_force > collision_threshold:
		break_keyboard()



func calculate_collision_force(body):
	var impulse = 0.0
	var other_body_velocity = body.linear_velocity if body is RigidBody3D else Vector3.ZERO
	var relative_velocity = get_parent().linear_velocity - other_body_velocity
	impulse = parent_node.mass * relative_velocity.length()
	return impulse


func break_keyboard():
	var broken_instance = broken_model.instantiate()
	parent_node.get_parent().add_child(broken_instance)
	broken_instance.global_transform = parent_node.global_transform  # Match the transform of the original keyboard
	broken_instance.apply_impulse(Vector3(0, 3, 0), Vector3(0, 3, 0))
	for i in range(10):
		var key_instance = single_key_model.instantiate()
		broken_instance.add_child(key_instance)
		var key_position = global_transform.origin + Vector3(randf() * 2 - 1, randf(), randf() * 2 - 1)
		key_instance.global_transform.origin = key_position
		var random_impulse = Vector3(randf() * 10 - 5, randf() * 10, randf() * 10 - 5)
		key_instance.apply_impulse(random_impulse, Vector3.ZERO)
	var biAudio = broken_instance.find_child("AudioStreamPlayer3D")
	biAudio.play()
	parent_node.queue_free()

