extends AudioStreamPlayer3D

@export var open_angle = 90.0
@export var open_speed = 1.0
@export var close_threshold = 2.0 
var door_open 
var door_close_1  
var door_close_2 
var door_close_3 
var initial_angle = 0.0
var current_angle = 0.0
var previous_angle = 0.0
var parent_node: RigidBody3D = null
var is_playing_open = false
var is_playing_close = false
# Called when the node enters the scene tree for the first time.
func _ready():
	door_open = preload("res://Assets/Audio/SoundFX/DoorOpened.mp3")
	door_close_1 = preload("res://Assets/Audio/SoundFX/DoorClosed.mp3")
	door_close_2 = preload("res://Assets/Audio/SoundFX/DoorClosed2.mp3")
	door_close_3 =  preload("res://Assets/Audio/SoundFX/DoorClosed3.mp3")
	parent_node = get_parent()
	if parent_node:
		initial_angle = parent_node.rotation_degrees.y


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if parent_node:
		parent_node.angular_damp = 5
		parent_node.linear_damp = 5
		update_door_audio(parent_node.rotation_degrees.y)

func update_door_audio(_current_angle: float):
	var _angle_difference = _current_angle - initial_angle
	var open_ratio = clamp(abs(_angle_difference) / open_angle, 0.0, 1.0)
	pitch_scale = lerp(1.0, 1.5, open_ratio)
	volume_db = lerp(-30, -16, open_ratio)
	if _current_angle > previous_angle and open_ratio > 0.1 and not is_playing_open:
		play_door_open_sound()
	elif abs(_angle_difference) <= close_threshold and not is_playing_close:
		play_door_close_sound()
	elif open_ratio <= 0.1 and not abs(_angle_difference) <= close_threshold:
		stop_door_sounds()
	previous_angle = _current_angle


func play_door_open_sound():
	stream = door_open
	play()
	is_playing_open = true
	is_playing_close = false

func play_door_close_sound():
	var close_sounds = [door_close_1, door_close_2, door_close_3]
	stream = close_sounds[randi() % close_sounds.size()]
	play()
	stop_parent_velocity()
	is_playing_open = false
	is_playing_close = true

func stop_door_sounds():
	stop()
	is_playing_open = false
	is_playing_close = false

func stop_parent_velocity():
	if parent_node:
		parent_node.linear_velocity = Vector3.ZERO
		parent_node.angular_velocity = Vector3.ZERO


