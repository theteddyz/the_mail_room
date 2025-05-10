extends Node
var current_grabbed_object:RigidBody3D
var holding_object:bool = false
@onready var dynamic_type:Node = $Dynamic_object
@onready var door_type:Node = $Door
@onready var drawer_type:Node = $Drawer
@onready var grab_sound_manager:Node = $grab_sound_manager
func grabbed_object(object:RigidBody3D):
	holding_object = true
	current_grabbed_object = object
	match object.grab_type:
		0:
			dynamic_type.grab()
		1:
			door_type.grab()
			grab_sound_manager.enable_sound(current_grabbed_object)
		2:
			grab_sound_manager.enable_sound(current_grabbed_object)
			drawer_type.grab()

func _input(event):
	if current_grabbed_object:
		if event.is_action_released("interact"):
			match current_grabbed_object.grab_type:
				0:
					dynamic_type.drop_object()
				1:
					grab_sound_manager.isEnabled =false
					door_type.drop_object()
				2:
					grab_sound_manager.isEnabled =false
					drawer_type.drop_object()
			current_grabbed_object = null
			holding_object = false
		if current_grabbed_object != null:
			if current_grabbed_object.grab_type == 1 or 2:
				if event is InputEventMouseMotion:
					if current_grabbed_object.grab_type == 1:
						door_type.move_door_with_mouse(event)
					else:
						drawer_type.move_drawer_with_mouse(event)
		if event.is_action_pressed("drive") and current_grabbed_object.grab_type == 0:
			dynamic_type.throw_object()
			current_grabbed_object = null
			holding_object = false
