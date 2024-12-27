extends Node

@onready var pool_pos 
var object_paths:Dictionary = {
	"monitor":"res://Scenes/Prefabs/MoveableObjects/Monitor.tscn",
	"desk2":"res://Scenes/Prefabs/MoveableObjects/desk_2_Only.tscn",
	"desk1":"",
	"mouse":"res://Scenes/Prefabs/MoveableObjects/mouse.tscn",
	"chair":"res://Scenes/Prefabs/MoveableObjects/office_Chair.tscn",
	"lamp":"res://Scenes/Prefabs/MoveableObjects/lamp.tscn",
	"mailbox":"res://Assets/Models/mailbox_stand.tscn",
	"bin":"res://Scenes/Prefabs/MoveableObjects/garbage_can.tscn",
	"keyboard":"res://Scenes/Prefabs/MoveableObjects/keyboard_low_poly_2.tscn"
}
var signal_queue: Array = []
var is_processing: bool = false
var world
func _ready():
	
	var root = get_tree().root
	world = root.get_child(root.get_child_count() - 1)
	pool_pos = world.find_child("pool_position")
	#EventBus.connect("request_object",enqueue_signal)
	EventBus.connect("register_object",register_object)
	EventBus.connect("return_object",return_object)
	EventBus.connect("modified_object",remove_object_from_pool)



func fufill_request(object_requested: String, notifier: VisibleOnScreenNotifier3D):
	var fufilled = false
	for obj in pool_pos.get_children():
		if fufilled:
			break
		if obj is RigidBody3D:
			if obj.object_name == object_requested:
				reuse_object(obj, notifier)
				fufilled = true
				break
		else:
			for child in obj.get_children():
				if "grab_type" in child:
					if child.object_name == object_requested:
						reuse_object(child, notifier)
						fufilled = true
						break
	if not fufilled:
		print("No available object found for:", object_requested)
		create_new_object(object_requested, notifier)



func reuse_object(obj, notifier):
	if obj.special_object == false:
		obj.on_screen = true
		obj.reparent(notifier)
		obj.transform = Transform3D()
		obj.visible = true
		print("Assigned object:", obj.name, "to notifier:", notifier)
		notifier.handle_fufilled_request(obj)
	else:
		var obj_parent = obj.get_parent()
		obj.on_screen = true
		obj_parent.visible = true
		obj_parent.reparent(notifier)
		obj_parent.transform = Transform3D()
		print("Assigned object:", obj.name, "to notifier:", notifier)

func create_new_object(object_requested: String, notifier: VisibleOnScreenNotifier3D):
	var scene_path = object_paths.get(object_requested, "")
	if scene_path == "":
		print("Error: Path not found for object:", object_requested)
		return
	var new_instance = load(scene_path).instantiate()
	if new_instance is RigidBody3D:
		new_instance.on_screen = true
	else:
		for child in new_instance.get_children():
			if "grab_type" in child:
				child.on_screen = true
				break
	new_instance.transform = Transform3D()
	notifier.add_child(new_instance)
	print("Created and assigned new object:", new_instance.name)


func return_object(object):
	if object.special_object == false:
		object.on_screen = false
		object.on_screen = false
		object.freeze = true
		object.visible = false
		object.reparent(pool_pos)
		object.transform = pool_pos.transform
	else:
		
		var obj_parent = object.get_parent()
		obj_parent.reparent(pool_pos)
		object.on_screen = false
		obj_parent.transform = pool_pos.transform
		object.freeze = true
		obj_parent.visible = false
	print("Object returned to pool:", object.name,object.on_screen)

func remove_object_from_pool(object):
	if !object.special_object:
		var object_parent = object.get_parent()
		object.modified = true
		object.reparent(world)
		object_parent.queue_free()
	else:
		var object_parent = object.get_parent()
		var visual_node = object_parent.get_parent()
		object.modified = true
		object_parent.reparent(world)
		visual_node.queue_free()
	print("removed")

func register_object(object):
	object.on_screen = false
