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
		print("Requesting object:", object, "from instance:", self)
		ObjectPoolManager.fufill_request(object,self)
	

func handle_fufilled_request(_object):
	print("Assigning new object:", _object.name, "to instance:", self)

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
						print("Returning object to pool:", child.name)
						ObjectPoolManager.return_object(child)
						child.on_screen = false
						current_object = null
		elif current_object and current_object.freeze:
			print("Returning object to pool:", current_object.name)
			ObjectPoolManager.return_object(current_object)
			current_object.on_screen = false
			current_object = null
