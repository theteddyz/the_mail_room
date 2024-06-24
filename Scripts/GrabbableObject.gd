extends Grabbable

@export var throw_strength: float = 700.0  
@export var weightLimit: float = 1000.0  
@export var max_lift_height: float = 100.0
@export var max_force:float = 300.0
@export var distance_threshold: float = 1.0
@export var drop_time_threshold: float = 0.5
@export var regrab_cooldown: float = 0.5
@export var should_freeze:bool = false


var pickup_timer: Timer
var force_above_threshold_time: float = 0.0 
var is_picked_up = false
var player: CharacterBody3D
var itemPos
var playerHead
var camera:Camera3D
var throw_direction = Vector3.ZERO
var force:Vector3 = Vector3.ZERO
var timerAdded:bool = false
var Interpolator 

func _ready():
	Interpolator = find_child("Interpolator")
	var root = get_tree().root
	var current_scene = root.get_child(root.get_child_count() - 1)
	player = current_scene.find_child("Player")
	if !should_freeze:
		freeze = false
	else:
		freeze = true
	if player:
		camera = player.find_child("Camera")
	pickup_timer = Timer.new()
	pickup_timer.connect("timeout", Callable(self, "_on_pickup_timer_timeout"))

func _physics_process(delta):
	if  Interpolator:
		Interpolator.setUpdate(true)
	if  is_picked_up:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			update_position(delta)
			if Input.is_action_just_pressed("drive"):
				dropMe(true)
				apply_force(throw_direction * throw_strength, throw_direction)
				is_picked_up = false
		else:
			dropMe(false)
	if !is_picked_up and should_freeze:
		if linear_velocity.length_squared() > 0.0001 or angular_velocity.length_squared() > 0.0001:
			pass
		else:
			freeze = true

func interact():
	if pickup_timer.is_stopped():
		if !timerAdded:
			add_child(pickup_timer)
			timerAdded=true
		itemPos = player.find_child("ItemHolder")
		camera = player.find_child("Camera")
		playerHead = player.find_child("Head")
		if should_freeze:
			freeze = false
		pickmeUp()


func pickmeUp():
	if is_picked_up:
		return
	#if parent.mass <= weightLimit:
	#TODO: Switch "null" to something "more" correct
	set_collision_mask_value(3, false)
	EventBus.emitCustomSignal("object_held", [mass, get_parent()])
	is_picked_up = true


func dropMe(throw:bool):
	if is_picked_up and throw == false:
		EventBus.emitCustomSignal("dropped_object", [mass,self])
		#linear_damp = 10
		var currentPos = global_position
		is_picked_up = false
		global_position = currentPos
		#linear_damp = 0.1
		force_above_threshold_time = 0.0
		set_collision_mask_value(3, false)
		if should_freeze:
			sleeping = true
	else:
		throw_direction = (playerHead.global_transform.basis.z * -1).normalized()
		EventBus.emitCustomSignal("dropped_object",[mass,self])
		start_pickup_timer()
		force_above_threshold_time = 0.0
		set_collision_mask_value(3, false)
		if should_freeze:
			sleeping = true

func update_position(delta):
	if is_picked_up:
		var targetPosition:Vector3 = itemPos.global_transform.origin
		var currentPosition:Vector3 = global_transform.origin
		var directionTo:Vector3 = targetPosition - currentPosition
		var distance:float = currentPosition.distance_to(targetPosition)
		#parent.linear_damp = 55;
		force = directionTo.normalized()*(pow(distance * 600,1))#/max(1,(parent.mass*0.15)))
		#force.x = clamp(force.x, -(max_force+player.velocity.length()), (max_force+player.velocity.length()))
		#force.y = clamp(force.y, -(max_force+player.velocity.length()), (max_force+player.velocity.length()))
		#force.y -= parent.mass * 0.07
		#force.z = clamp(force.z, -(max_force+player.velocity.length()), (max_force+player.velocity.length()))
		
		force = force.limit_length(max_force + (mass * 4) + player.velocity.length())
		apply_central_force(force)
		var angleBetweenForceAndVelocity = min(90,force.angle_to(linear_velocity))*2
		
		apply_central_force(-linear_velocity * 20) #* angleBetweenForceAndVelocity)		
		if distance > distance_threshold:
			force_above_threshold_time += delta
			if force_above_threshold_time >= drop_time_threshold:
				dropMe(false)
		else:
			force_above_threshold_time = 0.0

func start_pickup_timer():
	pickup_timer.start(regrab_cooldown)


func _on_pickup_timer_timeout():
	pickup_timer.stop()

