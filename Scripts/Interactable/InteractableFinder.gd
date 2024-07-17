extends RayCast3D



func get_interactable():
	if is_colliding():
		return get_collider()
	return null


func is_interactable():
	var collider = get_interactable()
	return collider


func interact():
	var collider = get_interactable()
	if collider and collider.has_method("interact"):
		collider.interact()
