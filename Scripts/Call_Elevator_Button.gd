extends Interactable

@onready var root = $".."
func interact():
	root.call_elevator()
	
