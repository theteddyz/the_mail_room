extends Node

@export var locked:bool
var parent
var parent_is_looked_at
var can_be_unlocked:bool = false
@export var unlock_number:int
@onready var audio_player:AudioStreamPlayer3D = $"../AudioStreamPlayer3D"
var door_unlocked
var has_played_sound:bool = false


func _ready():
	parent = get_parent()
	EventBus.connect("picked_up_key",check_key)
	EventBus.connect("object_looked_at",door_opened)
	EventBus.connect("no_object_found",not_looked_at)
	door_unlocked = preload("res://Assets/Audio/SoundFX/Door/DoorUnlocked.ogg")
	if locked:
		parent.should_freeze = true
		parent.freeze = true
		parent.lock_rotation = true
	else:
		has_played_sound = true

func unlock():
	parent.should_freeze = false
	parent.freeze = false
	parent.lock_rotation = false

func _input(event):
	if event.is_action_pressed("interact") and parent_is_looked_at:
		var gui = Gui.get_item_icon_displayer()
		gui.hide_icon()
		if !locked and !has_played_sound:
			audio_player.stream = door_unlocked
			has_played_sound = true
			audio_player.play()
		elif locked:
			audio_player.play()

func door_opened(node):
	if node == parent:
		parent_is_looked_at = true

func not_looked_at(node):
	if node == parent and parent_is_looked_at:
		parent_is_looked_at = false
func check_key(key):
	if key.unlock_num == unlock_number:
		can_be_unlocked = true
		locked = false
		parent.freeze = false
		parent.should_freeze = false
		parent.lock_rotation = false
