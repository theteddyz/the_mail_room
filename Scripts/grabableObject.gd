extends Interactable

@export var throw_strength: float = 700.0  
@export var weightLimit: float = 100.0  
@export var max_lift_height: float = 100.0
@export var max_force:float = 30.0
@onready var parent: RigidBody3D = self.get_parent()
@export var force_threshold: float = 10.0
@export var drop_time_threshold: float = 0.5
@export var regrab_cooldown: float = 0.5
var pickup_timer: Timer
var force_above_threshold_time: float = 0.0 
var is_picked_up = false
var itemPos
var playerHead
var camera:Camera3D
var throw_direction = Vector3.ZERO
var force = Vector3.ZERO
var player
var timerAdded:bool = false

func _ready():
	player = parent.get_parent().find_child("Player")
	camera = player.find_child("Camera")
	pickup_timer = Timer.new()
	pickup_timer.connect("timeout", Callable(self, "_on_pickup_timer_timeout"))
	


func _physics_process(delta):
	if  is_picked_up:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			update_position(delta)
			if Input.is_action_just_pressed("drive"):
				throwMe()
				parent.apply_force(throw_direction * throw_strength/parent.mass, throw_direction)
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
	if parent.mass <= weightLimit:
		EventBus.emitCustomSignal("object_held", parent.mass)
		is_picked_up = true



func dropMe():
	if is_picked_up:
		EventBus.emitCustomSignal("dropped_object",parent.mass)
		parent.linear_damp = 10
		var currentPos = parent.global_position
		is_picked_up = false
		parent.global_position = currentPos
		parent.linear_damp = 1
		force_above_threshold_time = 0.0

func throwMe():
	if not is_picked_up:
		return
	throw_direction = (playerHead.global_transform.basis.z * -1).normalized()
	EventBus.emitCustomSignal("dropped_object",parent.mass)
	start_pickup_timer()
	force_above_threshold_time = 0.0


func update_position(delta):
	if is_picked_up:
		var targetPosition:Vector3 = itemPos.global_transform.origin
		var currentPosition:Vector3 = parent.global_transform.origin
		var directionTo:Vector3 = targetPosition - currentPosition
		var distance:float = currentPosition.distance_to(targetPosition)
		force = directionTo.normalized()*(pow(distance*10,2)/parent.mass)
		force.x = clamp(force.x, -max_force, max_force)
		force.y = clamp(force.y, -max_force, max_force)
		force.y -= parent.mass * 0.25
		force.z = clamp(force.z, -max_force, max_force)
		parent.set_linear_velocity(force)
		if force.length() > force_threshold:
			force_above_threshold_time += delta
			if force_above_threshold_time >= drop_time_threshold:
				dropMe()
		else:
			force_above_threshold_time = 0.0
		

func _process(delta):
	if is_picked_up:
		parent.set_linear_velocity(force)


func start_pickup_timer():
	pickup_timer.start(regrab_cooldown)


func _on_pickup_timer_timeout():
	pickup_timer.stop()
#func _integrate_forces():
	#parent.set_linear_velocity(force)
