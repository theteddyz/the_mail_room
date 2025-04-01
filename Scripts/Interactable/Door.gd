extends Node

@export var locked:bool
@export var door1:RigidBody3D
@export var door2:RigidBody3D
var parent_is_looked_at
var can_be_unlocked:bool = false
@export var unlock_number:int
@export var audio_player:AudioStreamPlayer3D
var door_unlocked
var has_played_sound:bool = false

func _ready():
	if locked:
		EventBus.connect("picked_up_key",check_key)
	EventBus.connect("object_looked_at",door_opened)
	EventBus.connect("no_object_found",not_looked_at)
	door_unlocked = preload("res://Assets/Audio/SoundFX/Door/DoorUnlocked.ogg")

	if locked:
		door1.should_freeze = true
		door1.freeze = true
		door1.lock_rotation = true
		if door2:
			door2.should_freeze = true
			door2.freeze = true
			door2.lock_rotation = true
	else:
		has_played_sound = true

func lock_door():
	door1.should_freeze = true
	door1.freeze = true
	door1.lock_rotation = true
	locked = true
	if door2:
		door2.should_freeze = true
		door2.freeze = true
		door2.lock_rotation = true

func unlock():
	door1.should_freeze = false
	door1.freeze = false
	door1.lock_rotation = false
	locked = false
	if door2:
		door2.should_freeze = false
		door2.freeze = false
		door2.lock_rotation = false

func _input(event):
	if parent_is_looked_at:
		if event.is_action_pressed("interact"):
			var gui = Gui.get_item_icon_displayer()
			gui.hide_icon()
			if !locked and !has_played_sound:
				audio_player.stream = door_unlocked
				audio_player.play()
				has_played_sound = true
			elif locked:
				audio_player.play()

func door_opened(node):
	if node == door1 or node == door2:
		parent_is_looked_at = true

func not_looked_at(node):
	if node == door1 and parent_is_looked_at or node == door2 and parent_is_looked_at :
		parent_is_looked_at = false
func check_key(key):
	if key.unlock_num == unlock_number:
		can_be_unlocked = true
		locked = false
		unlock()
