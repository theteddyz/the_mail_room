extends RayCast3D

func _ready():
	EventBus.connect("picked_up_key",on_key_picked_up)
	EventBus.connect("dropped_key",on_key_dropped)

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

func on_key_picked_up():
	set_collision_mask_value(2,false)

func on_key_dropped():
	set_collision_mask_value(2,true)
