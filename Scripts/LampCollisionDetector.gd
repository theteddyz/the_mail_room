extends Node3D


var collision_threshold = 0.8
@onready var hinge_joint = $"../JoltHingeJoint3D"
@onready var lamp_arm = $"../LampArm"
@onready var lamp_break_sound = $"../AudioStreamPlayer3D"
@onready var lamp_break_sound_2 = $"../AudioStreamPlayer3D2"
var broken:bool
var grabbable_script = preload("res://Scripts/GrabbableObject.gd")
func _on_lamp_base_body_entered(body):
	if !broken:
		var collision_force = get_parent().linear_velocity.length()
		if collision_force > collision_threshold:
			break_lamp()
			broken = true


func break_lamp():
	lamp_arm.reparent(get_parent().get_parent())
	lamp_arm.gravity_scale = 1
	lamp_arm.set_collision_layer_value(2,true)
	lamp_arm.set_script(grabbable_script)
	lamp_arm.call("_ready")
	if !broken:
		lamp_break_sound.play()
		lamp_break_sound_2.play()
		hinge_joint.queue_free()
		get_parent().apply_impulse(Vector3(0, 10, 0), Vector3(0, 10, 0))
		lamp_arm.apply_impulse(Vector3(0, 10, 0), Vector3(0, 10, 0))
