extends Interactable
class_name tape_box
var parent

func _ready():
	parent = get_parent()
func interact():
	parent.start_interaction()
