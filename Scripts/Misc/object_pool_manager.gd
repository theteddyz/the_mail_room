extends Node

@onready var pool_pos = $"../pool_position"
@export var pooled_objects:Array
var signal_queue: Array = []
var is_processing: bool = false
var world
func _ready():
	var root = get_tree().root
	world = root.get_child(root.get_child_count() - 1)
	EventBus.connect("request_object",enqueue_signal)
	EventBus.connect("register_object",register_object)
	EventBus.connect("return_object",return_object)
	EventBus.connect("modified_object",remove_object_from_pool)


func enqueue_signal(object_requested: String, notifier: VisibleOnScreenNotifier3D):
	signal_queue.append([object_requested, notifier])
	process_next_signal()

func process_next_signal():
	if is_processing or signal_queue.is_empty():
		return
	is_processing = true
	var signal_data = signal_queue.pop_front()
	var object_requested = signal_data[0]
	var notifier = signal_data[1]
	print("Processing request:", object_requested)
	fufill_request(object_requested, notifier)

func fufill_request(object_requested: String, notifier: VisibleOnScreenNotifier3D):
	var fufilled = false
	for obj in pooled_objects:
		if obj.object == object_requested and not obj.on_screen and not obj.modified:
			obj.on_screen = true
			obj.reparent(notifier)
			obj.transform = Transform3D()
			obj.visible = true
			print("Assigned object:", obj.name, "to notifier:", notifier)
			notifier.handle_fufilled_request(obj)
			is_processing = false
			fufilled = true
			process_next_signal()
			break
	if fufilled == false:
		print("No available object found for:", object_requested)
		print("Spawning new object: ", object_requested)
		for obj in pooled_objects:
			if obj.object == object_requested:
				var scene_path = obj.get_scene_file_path()
				var new_instance = load(scene_path).instantiate()
				new_instance.transform = Transform3D()
				new_instance.on_screen = true
				notifier.add_child(new_instance)
				pooled_objects.append(new_instance)
				notifier.handle_fufilled_request(obj)
				print("SPAWNED NEW OBJECT")
				break
		is_processing = false
		process_next_signal()

func return_object(object):
	object.reparent(pool_pos)
	object.on_screen = false
	object.transform = pool_pos.transform
	object.freeze = true
	object.visible = false
	print("Object returned to pool:", object.name,object.on_screen)

func remove_object_from_pool(object):
	var index = pooled_objects.find(object)
	var object_parent = object.get_parent()
	object.modified = true
	pooled_objects.remove_at(index)
	object.reparent(world)
	object_parent.queue_free()
	print("removed")

func register_object(object):
	object.on_screen = false
	pooled_objects.append(object)
