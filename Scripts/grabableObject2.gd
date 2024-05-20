extends Interactable
@onready var player = $"../../Player"
@onready var original_parent
@export var throw_strength: float = 10.0  # Define the throw strength
@export var weightLimit: float = 10.0  # Define the throw strength
@export var max_lift_height: float = 100.0
var is_picked_up = false
var is_dragged = false
var startPosition = Vector3.ZERO
var itemPos
var playerHead
var camera:Camera3D
var throw_direction = Vector3.ZERO
var is_moving_to_item_holder:bool = false
var force = Vector3.ZERO
@export var lerp_speed: float = 20.0  # Define the speed of lerping
@onready var collisionShape:CollisionShape3D = $"../CollisionShape3D"
@onready var parent: RigidBody3D = self.get_parent()
var original_collision_layer: int
var original_collision_mask: int
func _ready():
	startPosition = position
	original_collision_layer = parent.collision_layer
	original_collision_mask = parent.collision_mask
	original_parent = parent.get_parent()
	camera = player.find_child("Camera")


func _physics_process(delta):
	if is_moving_to_item_holder or is_picked_up or is_dragged:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			update_position(delta)
			if Input.is_action_just_pressed("drive"):
				throwMe()
				parent.apply_impulse(throw_direction * throw_strength, parent.position)
		else:
			dropMe()

func interact():
	itemPos = player.find_child("ItemHolder")
	camera = player.find_child("Camera")
	playerHead = player.find_child("Head")
	pickmeUp()



func pickmeUp():
	if is_picked_up:
		return
	if parent.mass <= weightLimit:
		EventBus.emitCustomSignal("object_held", parent.mass)
		is_moving_to_item_holder = true
	else:
		var currentPos = parent.global_position
		if  original_parent == parent.get_parent():
			original_parent.remove_child(parent)
			player.add_child(parent)
		is_dragged = true
		parent.global_position = currentPos


func dropMe():
	if is_dragged:
		var currentPos = parent.global_position
		is_dragged = false
		parent.global_position = currentPos
	parent.collision_layer = original_collision_layer
	parent.collision_mask = original_collision_mask
	is_picked_up = false
	if is_moving_to_item_holder:
		is_moving_to_item_holder = false

func throwMe():
	if not is_picked_up:
		return
	is_picked_up = false
	is_moving_to_item_holder = false
	throw_direction = (playerHead.global_transform.basis.z * -1).normalized()
	parent.collision_layer = original_collision_layer
	parent.collision_mask = original_collision_mask
	#EventBus.emit_custom_signal("object_held", -mass)


func update_position(delta):
	if is_moving_to_item_holder:
		var targetPosition:Vector3 = itemPos.global_transform.origin
		var currentPosition = parent.global_transform.origin
		var directionTo:Vector3 = targetPosition - currentPosition
		var distance:float = currentPosition.distance_to(targetPosition)
		force = directionTo.normalized()*pow(distance*10,2)
		#var velocity = parent.get_linear_velocity()
		#var newVelocity = velocity/(1+(100000*delta))
		#parent.set_linear_velocity(newVelocity)
		#parent.linear_damp = 59
		

func _process(delta):
	parent.set_linear_velocity(force)

#func _integrate_forces():
#	parent.set_linear_velocity(force)
