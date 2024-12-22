extends Node

var object:RigidBody3D
var grab_offset: Vector3 = Vector3.ZERO
var player_raycast:RayCast3D
var player
var camera
var player_head
var holding_door:bool =false
var _mass
var previous_mouse_position = Vector2.ZERO
var mouse_velocity:Vector2 = Vector2.ZERO
var initial_basis = Basis()
const DOOR_TORQUE_MULTIPLIER: float = 0.02
var door_forward_position
var door_global_position
func _physics_process(delta):
	if holding_door:
		update_position(delta)
		#update_rotation(delta)


func _ready():
	player = GameManager.get_player()
	camera = player.find_child("Camera")
	player_head = player.find_child("Head")
	player_raycast = player.find_child("InteractableFinder")

func grab():
	set_physics_process(true)
	set_process(true)
	object = get_parent().current_grabbed_object
	object.freeze = false
	object.sleeping = false
	object.set_collision_layer_value(2,false)
	door_forward_position = object.global_transform.basis.z.normalized()
	door_global_position = object.global_transform.origin
	_mass = object.mass
	grab_offset = player_raycast.get_collision_point() - object.global_transform.origin
	EventBus.emitCustomSignal("disable_player_movement",[true,false])
	holding_door = true
	enable_collision_detection()
	EventBus.emitCustomSignal("show_icon",[object])
	#if pickup_timer.is_stopped():
		#if !timerAdded:
			#add_child(pickup_timer)
			#timerAdded=true


func move_door_with_mouse(_event):
	var player_inside = is_player_inside_room()
	var adjusted_relative = _event.relative
	if player_inside:
		adjusted_relative.y = -_event.relative.y
	previous_mouse_position = adjusted_relative

func drop_object():
	holding_door = false
	object.set_collision_layer_value(2,true)
	EventBus.emitCustomSignal("disable_player_movement",[false,false])
	EventBus.emitCustomSignal("dropped_object", [object.mass,self])
	object = null
	#EventBus.emitCustomSignal("hide_icon",["grabClosed"])

func update_position(delta):
	mouse_velocity = previous_mouse_position / delta
	if !mouse_velocity.is_finite():
		print("Invalid mouse velocity:", mouse_velocity)
	apply_door_torque(mouse_velocity * 0.5)




func apply_door_torque(_mouse_velocity: Vector2):
	var player_inside = is_player_inside_room()
	var torque_direction = -1
	var torque
	if player_inside:
		torque_direction = 1 
	if player_inside:
		torque = _mouse_velocity.y * DOOR_TORQUE_MULTIPLIER * torque_direction
	else: torque =  _mouse_velocity.y * DOOR_TORQUE_MULTIPLIER
	var torque_force = Vector3(0, torque * _mass, 0) 
	object.apply_torque_impulse(torque_force)
	object.apply_torque_impulse(-object.angular_velocity * 0.05) 


func is_player_inside_room()-> bool:
	var door_forward: Vector3 = door_forward_position
	var door_to_player: Vector3 = (player.global_transform.origin - door_global_position).normalized()
	return door_forward.dot(door_to_player) < 0

func enable_collision_detection():
	var _object = object
	await get_tree().create_timer(1).timeout
	_object.set_contact_monitor(true)
	_object.set_max_contacts_reported(10)
