extends Interactable
class_name Radio
@onready var radio_sound_player: AudioStreamPlayer3D = $"../../Radio_Sound_Player"

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
	return radio_sound_player

func interact():
	if has_tape:
		eject_tape()
func play_tape(tape):
	if power:
		held_tape = tape
		var sound  = held_tape.sound
		print(held_tape)
		has_tape = true
		radio_sound_player.set_stream(sound)
		radio_sound_player.play()
func play_narrator_sound(sound):
	if radio_sound_player.playing:
		await radio_sound_player.finished
		radio_sound_player.stream = sound
		radio_sound_player.play()
	else:
		radio_sound_player.stream = sound
		radio_sound_player.play()
	


func eject_tape():
	radio_sound_player.stop()
	held_tape.eject()
	has_tape = false
	held_tape = null
	radio_sound_player.stream = null


func delivery_sound(_i):
	power = true
	radio_sound_player.stream = delievery_sound
	radio_sound_player.play()
