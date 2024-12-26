extends VisibleOnScreenNotifier3D

@export_enum("monitor","desk1","desk2","mouse","chair","lamp","mailbox","garabage_can","keyboard") var object:String
func _ready():
	EventBus.connect("modified_object",check_object)
	connect("screen_entered",Callable(self,"_on_screen_entered"))
	connect("screen_exited",Callable(self,"_on_screen_exited"))

func _on_screen_entered():
	if get_child_count() == 0:
		print("Requesting object:", object, "from instance:", self)
		EventBus.emitCustomSignal("request_object",[object,self])
	

func handle_fufilled_request(_object):
	print("Assigning new object:", _object.name, "to instance:", self)

func check_object(grabbed_object):
	pass
	#if grabbed_object == current_object:
		#queue_free()

func _on_screen_exited():
	if get_child_count() > 0:
		var current_object = get_child(0)
		if current_object and current_object.freeze == true:
			print("Returning object to pool:", current_object.name)
			EventBus.emitCustomSignal("return_object", [current_object])
			current_object = null
