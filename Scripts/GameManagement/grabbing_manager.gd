extends Node
var current_grabbed_object:RigidBody3D
var holding_object:bool = false
@onready var dynamic_type:Node = $Dynamic_object
@onready var door_type:Node = $Door
@onready var drawer_type:Node = $Drawer

func grabbed_object(object:RigidBody3D):
	holding_object = true
	current_grabbed_object = object
	match object.grab_type:
		"dynamic":
			var current_parent = object.get_parent()
			if object.special_object:
				var _temp = object.get_parent()
				current_parent = _temp.get_parent()
				
			if current_parent is VisibleOnScreenNotifier3D:
				print("HELLO")
				EventBus.emitCustomSignal("modified_object", [object])
			dynamic_type.grab()
		"door":
			door_type.grab()
		"drawer":
			drawer_type.grab()

func _input(event):
	if current_grabbed_object:
		if event.is_action_released("interact"):
			match current_grabbed_object.grab_type:
				"dynamic":
					dynamic_type.drop_object()
				"door":
					door_type.drop_object()
				"drawer":
					drawer_type.drop_object()
			current_grabbed_object = null
			holding_object = false
		if current_grabbed_object != null:
			if current_grabbed_object.grab_type == "door" or "drawer":
				if event is InputEventMouseMotion:
					if current_grabbed_object.grab_type == "door":
						door_type.move_door_with_mouse(event)
					else:
						drawer_type.move_drawer_with_mouse(event)
		if event.is_action_pressed("drive") and current_grabbed_object.grab_type == "dynamic":
			dynamic_type.throw_object()
			current_grabbed_object = null
			holding_object = false
