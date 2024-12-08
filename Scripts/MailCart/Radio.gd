extends Interactable
class_name Radio
@onready var audio:AudioStreamPlayer3D = $"../../Radio_Sound_Player"
@onready var collider:CollisionShape3D = $CollisionShape3D
var has_tape = false
var held_tape
var power = false
var radio_stations = []
var current_index = 0
var delievery_sound
func _ready():
	delievery_sound = preload("res://Assets/Audio/SoundFX/GamifiedSounds/Package Deliver.ogg")
	ScareDirector.connect("package_delivered", delivery_sound)
	GameManager.register_player_radio(self)

func get_stream_player() -> AudioStreamPlayer3D:
	return audio

func interact():
	if has_tape:
		eject_tape()
func play_tape(tape):
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
	


func eject_tape():
	audio.stop()
	held_tape.eject()
	has_tape = false
	held_tape = null
	audio.stream = null


func delivery_sound(_i):
	power = true
	audio.stream = delievery_sound
	audio.play()
