extends Interactable

var cart
func _ready():
	cart = get_parent()

func interact():
	cart.is_grabbed = true 

func _input(event):
	if cart.is_grabbed:
		if event.is_action_released("interact"):
			cart.is_grabbed = false
