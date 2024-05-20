extends Interactable

@export var throw_strength: float = 800.0  # Define the throw strength
@export var weightLimit: float = 10.0  # Define the throw strength
@export var max_lift_height: float = 100.0
var is_picked_up = false
var pickUpTimer:bool = false
var itemPos
var playerHead
var camera:Camera3D
var throw_direction = Vector3.ZERO
var force = Vector3.ZERO
var player
var original_parent
@onready var parent: RigidBody3D = self.get_parent()
func _ready():
	original_parent = parent.get_parent()
	player = parent.get_parent().find_child("Player")
	camera = player.find_child("Camera")


func _physics_process(delta):
	if  is_picked_up and !pickUpTimer:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			update_position(delta)
			if Input.is_action_just_pressed("drive"):
				throwMe()
				parent.apply_force(throw_direction * throw_strength, throw_direction)
				is_picked_up = false
		else:
			dropMe()

func interact():
	itemPos = player.find_child("ItemHolder")
	camera = player.find_child("Camera")
	playerHead = player.find_child("Head")
	pickmeUp()



func pickmeUp():
	if is_picked_up or pickUpTimer:
		return
	if parent.mass <= weightLimit:
		#EventBus.emitCustomSignal("object_held", parent.mass)
		parent.set_collision_mask_value(5, false)
		is_picked_up = true



func dropMe():
	if is_picked_up:
		var currentPos = parent.global_position
		is_picked_up = false
		parent.set_collision_mask_value(5, true)
		parent.global_position = currentPos

func throwMe():
	if not is_picked_up:
		return
	throw_direction = (playerHead.global_transform.basis.z * -1).normalized()
	parent.set_collision_mask_value(5, true)
	#EventBus.emit_custom_signal("object_held", -mass)


func update_position(delta):
	if is_picked_up:
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
	if is_picked_up:
		parent.set_linear_velocity(force)

#func _integrate_forces():
#	parent.set_linear_velocity(force)
