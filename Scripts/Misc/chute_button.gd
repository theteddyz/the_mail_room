extends Interactable

var parent

func _ready():
	parent = get_parent()
func interact():
	parent.drop_packages()
