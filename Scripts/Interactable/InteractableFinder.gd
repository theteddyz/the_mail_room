extends RayCast3D
var object_being_looked_at
func _ready():
	pass

func _process(_delta):
	_check_for_interactables()


func _check_for_interactables():
	var current_interactable = get_interactable()
	if current_interactable:
		if object_being_looked_at != current_interactable:
			EventBus.emitCustomSignal("object_looked_at", [current_interactable])
			object_being_looked_at = current_interactable
	elif object_being_looked_at:
		EventBus.emitCustomSignal("no_object_found", [object_being_looked_at])
		object_being_looked_at = null

func get_interactable():
	if is_colliding() :
		var collider = get_collider()
		if collider and (collider.collision_layer & 2) != 0:
			return collider
	return null


func is_interactable():
	var collider = get_interactable()
	return collider


func interact():
	var collider = get_interactable()
	if collider and collider.has_method("interact"):
		collider.interact()
