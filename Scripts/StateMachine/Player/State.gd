extends CharacterBody3D

class_name State

# Privates
var current_speed = 0
var change_state: Callable
var persistent_state
var mouse_sense = 0.25

# Called when a new instance of any state is created
func setup(change_state, persistent_state):
	self.change_state = change_state
	self.persistent_state = persistent_state

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

