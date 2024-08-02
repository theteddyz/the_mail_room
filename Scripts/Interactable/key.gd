extends Interactable
class_name Key
@export var unlock_num:int
var player: CharacterBody3D
func _ready():
	player = get_parent().find_child("Player")

func interact():
	grabbed()

func highlight():
	pass
func grabbed():
	reparent(player.find_child("PackageHolder"), false)
	EventBus.emitCustomSignal("object_held", [self.mass,self])
	EventBus.emitCustomSignal("picked_up_key")
	ScareDirector.emit_signal("key_pickedup", unlock_num)
	position =Vector3.ZERO
	rotation = Vector3.ZERO
	self.freeze = true

func dropped():
	self.freeze = false
	reparent(player.get_parent(), true)
	EventBus.emitCustomSignal("dropped_key")
	EventBus.emitCustomSignal("dropped_object",[self.mass,self])
