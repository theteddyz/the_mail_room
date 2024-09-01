extends Interactable
class_name Radio
@onready var audio:AudioStreamPlayer3D = $"../../Radio_Sound_Player"
@onready var collider:CollisionShape3D = $CollisionShape3D
@export var has_tape = false
var held_tape
var power = false
var radio_stations = []
var current_index = 0
var attached_to_cart = false
var is_being_looked_at = false
var delievery_sound
func _ready():
	delievery_sound = preload("res://Assets/Audio/SoundFX/GamifiedSounds/Package Deliver.ogg")
	EventBus.connect("object_looked_at",on_seen)
	EventBus.connect("no_object_found",on_unseen)
	ScareDirector.connect("package_delivered", delivery_sound)
	GameManager.register_player_radio(self)

func get_stream_player() -> AudioStreamPlayer3D:
	return audio

func on_seen(node):
	if node == self:
		is_being_looked_at = true

func on_unseen(_node):
	if is_being_looked_at:
		is_being_looked_at = false

func interact():
	if !power:
		power = true
		print("power on")
	else:
		power = false
		print("power off")

func _input(event):
	if event.is_action("scroll package up"):
		change_station_up()
	if event.is_action("scroll package down"):
		change_station_down()

func change_station_up():
	if current_index < radio_stations.size() - 1:
		current_index += 1
	else:
		current_index = 0
	print("Current Index after scrolling up: ", current_index)

# Function to scroll the package down
func change_station_down():
	if radio_stations.size() != 0:
		if current_index > 0:
			current_index -= 1
		else:
			current_index = radio_stations.size() - 1
	print("Current Index after scrolling down: ", current_index)

func playTape(tape):
	if power:
		held_tape = tape
		var sound  = held_tape.sound
		print(held_tape)
		has_tape = true
		audio.set_stream(sound)
		audio.play()
func play_narrator_sound(sound):
	if audio.playing:
		await audio.finished
		audio.stream = sound
		audio.play()
	else:
		audio.stream = sound
		audio.play()
	
func check_tape():
	if has_tape:
		eject_tape()
	else:
		toggle_power()

func eject_tape():
	audio.stop()
	held_tape.show()
	has_tape = false
	held_tape = null
	audio.stream = null

func toggle_power():
	if power:
		audio.play()
	else:
		audio.stop()

func delivery_sound(i):
	power = true
	audio.stream = delievery_sound
	audio.play()
