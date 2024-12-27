extends VisibleOnScreenNotifier3D

@export_enum("monitor","desk1","desk2","mouse","chair","lamp","mailbox","bin","keyboard") var object:String
func _ready():
	var child = get_child(0)
	if child:
		child.queue_free()
	EventBus.connect("modified_object",check_object)
	connect("screen_entered",Callable(self,"_on_screen_entered"))
	connect("screen_exited",Callable(self,"_on_screen_exited"))

func _on_screen_entered():
	if get_child_count() == 0:
		pass
		#ObjectPoolManager.fufill_request(object,self)
	

func handle_fufilled_request(_object):
	_object.freeze = false
	await get_tree().create_timer(1.0).timeout
	_object.freeze = true

func check_object(grabbed_object):
	pass
	#if grabbed_object == current_object:
		#queue_free()

func _on_screen_exited():
	if get_child_count() > 0:
		var current_object = get_child(0)
		if current_object is Node3D:
			for child in current_object.get_children():
				if "grab_type" in child:
					if child.freeze == true:
						#ObjectPoolManager.return_object(child)
						current_object = null
		elif current_object and current_object.freeze:
			#ObjectPoolManager.return_object(current_object)
			current_object = null
