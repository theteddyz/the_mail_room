extends Node3D

class_name State

# Privates
var current_speed = 0
var change_state: Callable
var persistent_state: Node3D
var mouse_sense = 0.25

# Called when a new instance of any state is created
func setup(_change_state, _persistent_state):
	self.change_state = _change_state
	self.persistent_state = _persistent_state
