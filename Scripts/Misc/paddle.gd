extends Node3D

var is_in_water:bool
@onready var boat =$"../../RigidBody3D"
var last_tip_position:Vector3 = Vector3.ZERO
@export var force_strength := 20.0


func _physics_process(delta):
	var tip = global_transform.origin
	var paddle_velocity = (tip - last_tip_position) / delta
	var velocity = (tip - last_tip_position) / delta
	last_tip_position = tip 
	if is_in_water and velocity.length() > 0.1:
		print("applying force: ", paddle_velocity)
		apply_paddle_force(paddle_velocity)
func _process(delta):
	check_is_in_water()

func check_is_in_water():
	is_in_water = global_position.y < 0.0
func apply_paddle_force(paddle_velocity: Vector3):
	var horizontal_velocity = Vector3(paddle_velocity.x, 0, paddle_velocity.z)
	if horizontal_velocity.length() < 0.1:
		return
	var boat_forward = -boat.global_transform.basis.z.normalized()
	var thrust = boat_forward.dot(horizontal_velocity)
	if thrust < -0.5:
		var force = boat_forward * abs(thrust) * force_strength
		var offset = global_transform.origin - boat.global_transform.origin
		boat.apply_impulse(force,offset )
	var side_offset = (global_transform.origin - boat.global_transform.origin).x
	var sideways_motion = horizontal_velocity.dot(boat.global_transform.basis.x)

	
	if abs(sideways_motion) > 0.5:
		var torque = side_offset * sideways_motion * 0.3
		boat.apply_torque_impulse(Vector3.UP * torque)
	
