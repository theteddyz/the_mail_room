extends Node
var players

enum SoundModifiers {
	none = 0,
	fade_in = 1,   
	fade_out = 2,
}

# "1A2" = First Floor (1) Ambience (A) Index (2, 3, 4 etc.)
var sounds_dictionary = {
	"1A2": "res://Assets/Audio/SoundFX/FirstFloorAmbience2.mp3",
	"1A3": "res://Assets/Audio/SoundFX/FirstFloorAmbience3.mp3",
	"1A4": "res://Assets/Audio/SoundFX/FirstFloorAmbience4.mp3",
}

var sounds: Array[Resource] = []
func _ready():
	players = [$stream, $stream2, $stream3]
	for path in sounds_dictionary:
		sounds.append(load(path))

func _get_free_player() -> AudioStreamPlayer:
	for p in players:
		if !p.playing:
			return p
	print("NO FREE AUDIO PLAYERS; DEFAULTING TO FIRST ONE")
	return players[0]
	
func play_resource(sound, modifiers = 0):
	var p = _get_free_player()
	if sound is Resource:
		p.stream = sound
	else:
		print("play_resource expects a resource... sound not fired!")
		return
	apply_effector(modifiers, p)
	p.playing = true
	
func stop_resource(resource_name, modifiers = 0):
	for p in players:
		if p.get_stream() != null:
			var parts = p.get_stream().get_path().split("/")
			if parts[parts.size()-1] == resource_name:
				if modifiers == SoundModifiers.fade_out:
					apply_effector(modifiers, p)
				else:
					p.playing = false

func apply_effector(modifier, player: AudioStreamPlayer):
	match modifier:
		SoundModifiers.fade_in:
			var tween = get_tree().create_tween()
			player.volume_db = -35
			tween.tween_property(player, "volume_db", 0, 4.85).set_ease(Tween.EASE_OUT)
		SoundModifiers.fade_out:
			var tween = get_tree().create_tween()
			tween.tween_property(player, "volume_db", -45, 4.85).set_ease(Tween.EASE_OUT)
			tween.tween_callback(func(): player.playing = false)
