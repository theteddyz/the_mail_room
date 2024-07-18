extends Interactable
class_name Key
@export var unlock_num:int
var player: CharacterBody3D
func _ready():
	player = get_parent().find_child("Player")

func interact():
	player.state.grabbed_key(self)
	
	EventBus.emit_signal("picked_up_key")
