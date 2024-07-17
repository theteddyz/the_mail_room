extends Interactable

@export var locked:bool

var parent:RigidBody3D
@export var unlock_number:int
@onready var hinge:JoltHingeJoint3D = $"../../JoltHingeJoint3D"
func _ready():
	parent = get_parent()
	if locked:
		parent.lock_axes(true)


func interact():
	print("CLICKED")


func check_key(key):
	if key.unlock_num == unlock_number:
		EventBus.emitCustomSignal("dropped_object", [key.mass,key])
		EventBus.emitCustomSignal("dropped_key")
		key.queue_free()
		locked = false
		parent.lock_axes(false)
		queue_free()
	else:
		print("FALED")

