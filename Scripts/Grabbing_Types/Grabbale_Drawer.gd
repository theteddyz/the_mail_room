extends Node

var object:RigidBody3D
var grab_offset: Vector3 = Vector3.ZERO
var player_raycast:RayCast3D
var player
var camera
var player_head
var holding_drawer:bool =false
var _mass
var previous_mouse_position = Vector2.ZERO
var mouse_velocity:Vector2 = Vector2.ZERO
var initial_basis = Basis()
const DOOR_TORQUE_MULTIPLIER: float = 0.02
func _physics_process(delta):
	if holding_drawer:
		update_position(delta)
func _enter_tree():
	request_ready()

func _ready():
	player = GameManager.get_player()
	if player:
		camera = player.find_child("Camera")
		player_head = player.find_child("Head")
		player_raycast = player.find_child("InteractableFinder")

func grab():
	if !player:
		player = GameManager.get_player()
		camera = player.find_child("Camera")
		player_head = player.find_child("Head")
		player_raycast = player.find_child("InteractableFinder")
	set_physics_process(true)
	set_process(true)
	object = get_parent().current_grabbed_object
	object.freeze = false
	object.sleeping = false
	_mass = object.mass
	grab_offset = player_raycast.get_collision_point() - object.global_transform.origin
	EventBus.emitCustomSignal("disable_player_movement",[true,false])
	holding_drawer = true
	enable_collision_detection()
	EventBus.emitCustomSignal("show_icon",[object])
	#if pickup_timer.is_stopped():
		#if !timerAdded:
			#add_child(pickup_timer)
			#timerAdded=true


func move_drawer_with_mouse(_event):
	previous_mouse_position = _event.relative

func drop_object():
	holding_drawer = false
	EventBus.emitCustomSignal("disable_player_movement",[false,false])
	EventBus.emitCustomSignal("dropped_object", [object.mass,self])
	object = null
	#EventBus.emitCustomSignal("hide_icon",["grabClosed"])

func update_position(delta):
	mouse_velocity = previous_mouse_position / delta
	if !mouse_velocity.is_finite():
			print("Invalid mouse velocity:", mouse_velocity)
	apply_drawer_impluse(mouse_velocity)

func apply_drawer_impluse(_mouse_velocity:Vector2):
	var impulse_amount = _mouse_velocity.y * DOOR_TORQUE_MULTIPLIER
	var local_motion_axis = Vector3(0, 0, 1)
	var global_motion_axis = (object.global_transform.basis * local_motion_axis).normalized()
	var linear_impulse = global_motion_axis * impulse_amount * _mass
	object.apply_central_impulse(linear_impulse * 0.1)
	object.apply_central_impulse(-object.linear_velocity * 0.1)

func enable_collision_detection():
	var _object = object
	await get_tree().create_timer(1).timeout
	_object.set_contact_monitor(true)
	_object.set_max_contacts_reported(10)
