extends Interactable

@export var locked:bool
var parent
@export var unlock_number:int
func _ready():
	parent = get_parent()
	if locked:
		parent.should_freeze = true
		parent.freeze = true
		parent.lock_rotation = true
	else:
		#queue_free()
		pass

func unlock():
	parent.should_freeze = false
	parent.freeze = false
	parent.lock_rotation = false


func interact():
	print("CLICKED")


func check_key(key):
	if key.unlock_num == unlock_number:
		EventBus.emitCustomSignal("dropped_object", [key.mass,key])
		EventBus.emitCustomSignal("dropped_key")
		key.queue_free()
		locked = false
		parent.freeze = false
		parent.should_freeze = false
		parent.lock_rotation = false
		queue_free()
	else:
		print("FALED")

