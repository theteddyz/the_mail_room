extends Interactable
#This is a duplicate to use for any object using CSGD BOX ones with actually meshes should use regular script
@export var throw_strength: float = 700.0  
@export var weightLimit: float = 1000.0  
@export var max_lift_height: float = 100.0
@export var max_force:float = 300.0
@onready var parent: RigidBody3D = self.get_parent()
@export var distance_threshold: float = 1.0
@export var drop_time_threshold: float = 0.5
@export var regrab_cooldown: float = 0.5
var pickup_timer: Timer
var force_above_threshold_time: float = 0.0 
var is_picked_up = false
var itemPos
var playerHead
var camera:Camera3D
var throw_direction = Vector3.ZERO
var force:Vector3 = Vector3.ZERO
var player: CharacterBody3D
var timerAdded:bool = false

var update = false
var prevPosition
var currentPositon
var originScale
func _ready():
	player = parent.get_parent().find_child("Player")
	camera = player.find_child("Camera")
	pickup_timer = Timer.new()
	pickup_timer.connect("timeout", Callable(self, "_on_pickup_timer_timeout"))
	originScale = scale
	prevPosition = parent.global_transform
	currentPositon = parent.global_transform

func _update_transform():
	prevPosition = currentPositon
	currentPositon = parent.global_transform

func _process(delta):
	scale = originScale
	if update:
		_update_transform()
		update = false
	var f = clamp(Engine.get_physics_interpolation_fraction(),0,1)
	global_transform = prevPosition.interpolate_with(currentPositon,f)
	#Stupid temp fix for now
	scale = originScale

func _physics_process(delta):
	update = true
	if  is_picked_up:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			update_position(delta)
			if Input.is_action_just_pressed("drive"):
				throwMe()
				parent.apply_force(throw_direction * throw_strength, throw_direction)
				is_picked_up = false
		else:
			dropMe()

func interact():
	if pickup_timer.is_stopped():
		if !timerAdded:
			parent.add_child(pickup_timer)
			timerAdded=true
		itemPos = player.find_child("ItemHolder")
		camera = player.find_child("Camera")
		playerHead = player.find_child("Head")
		pickmeUp()



func pickmeUp():
	if is_picked_up:
		return
	#if parent.mass <= weightLimit:
	#TODO: Switch "null" to something "more" correct
	EventBus.emitCustomSignal("object_held", [parent.mass, null])
	is_picked_up = true



func dropMe():
	if is_picked_up:
		EventBus.emitCustomSignal("dropped_object", [parent.mass])
		parent.linear_damp = 10
		var currentPos = parent.global_position
		is_picked_up = false
		parent.global_position = currentPos
		parent.linear_damp = 0.1
		force_above_threshold_time = 0.0

func throwMe():
	if not is_picked_up:
		return
	throw_direction = (playerHead.global_transform.basis.z * -1).normalized()
	EventBus.emitCustomSignal("dropped_object",[parent.mass])
	start_pickup_timer()
	force_above_threshold_time = 0.0


func update_position(delta):
	if is_picked_up:
		var targetPosition:Vector3 = itemPos.global_transform.origin
		var currentPosition:Vector3 = parent.global_transform.origin
		var directionTo:Vector3 = targetPosition - currentPosition
		var distance:float = currentPosition.distance_to(targetPosition)
		#parent.linear_damp = 55;
		force = directionTo.normalized()*(pow(distance * 600,1))#/max(1,(parent.mass*0.15)))
		
		#force.x = clamp(force.x, -(max_force+player.velocity.length()), (max_force+player.velocity.length()))
		#force.y = clamp(force.y, -(max_force+player.velocity.length()), (max_force+player.velocity.length()))
		#force.y -= parent.mass * 0.07
		#force.z = clamp(force.z, -(max_force+player.velocity.length()), (max_force+player.velocity.length()))
		
		force = force.limit_length(max_force + (parent.mass * 2) + player.velocity.length())
		parent.apply_central_force(force)
		var angleBetweenForceAndVelocity = min(90,force.angle_to(parent.linear_velocity))*2
		
		parent.apply_central_force(-parent.linear_velocity * 20) #* angleBetweenForceAndVelocity)		
		if distance > distance_threshold:
			force_above_threshold_time += delta
			if force_above_threshold_time >= drop_time_threshold:
				dropMe()
		else:
			force_above_threshold_time = 0.0
		

#func _process(delta):
	#global_transform = parent.global_transform


func start_pickup_timer():
	pickup_timer.start(regrab_cooldown)


func _on_pickup_timer_timeout():
	pickup_timer.stop()
#func _integrate_forces():
	#parent.set_linear_velocity(force)
