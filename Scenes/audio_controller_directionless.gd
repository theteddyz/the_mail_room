extends Node
var players

enum SoundModifiers {
	none = 0,
	fade_in = 1,   
	fade_out = 2,
	set_db = 3
}

@onready var spatial_audio_controller = $SpatialAudioController

func _ready():
	players = [$stream, $stream2, $stream3]

func _get_free_player() -> AudioStreamPlayer:
	for p in players:
		if !p.playing:
			return p
	print("NO FREE AUDIO PLAYERS; DEFAULTING TO FIRST ONE")
	return players[0]
	
func play_resource(sound, modifiers = 0, callback = (func(): {}), db_offset = 0):
	var p = _get_free_player()
	if sound is Resource:
		p.stream = sound
	else:
		print("play_resource expects a resource... sound not fired!")
		return
	apply_effector(modifiers, p)
	p.finished.connect(callback)
	if db_offset != null:
		p.volume_db = db_offset
	else:
		p.volume_db = 0
	p.playing = true
	
func play_spatial_resource(sound, pos: Vector3 = Vector3.ZERO, modifiers = 0, callback: Callable = (func(): {})):
	spatial_audio_controller.play_spatial_resource(sound, pos, modifiers, callback)

func stop_resource(resource_name, modifiers = 0):
	for p in players:
		if p.get_stream() != null:
			var path = p.get_stream().get_path()
			if path == resource_name:
				if modifiers == SoundModifiers.fade_out:
					apply_effector(modifiers, p)
				else:
					p.playing = false

func apply_effector(modifier, player: AudioStreamPlayer):
	var set_db = 0
	if modifier is Array:
		for m in modifier:
			match m:
				SoundModifiers.fade_in:
					var tween = get_tree().create_tween()
					player.volume_db = -35
					tween.tween_property(player, "volume_db", set_db, 4.85).set_ease(Tween.EASE_OUT)
				SoundModifiers.fade_out:
					var tween = get_tree().create_tween()
					tween.tween_property(player, "volume_db", -45, 4.85).set_ease(Tween.EASE_OUT)
					tween.tween_callback(func(): player.playing = false)
					tween.tween_property(player, "volume_db", set_db, 0)
				#SoundModifiers.set_db:
					## Currently just sets the DB to a "loud"-ish value
					#player.volume_db = 13
					#set_db = 13
	else:
		match modifier:
			SoundModifiers.fade_in:
				var tween = get_tree().create_tween()
				player.volume_db = -35
				tween.tween_property(player, "volume_db", set_db, 4.85).set_ease(Tween.EASE_OUT)
			SoundModifiers.fade_out:
				var tween = get_tree().create_tween()
				tween.tween_property(player, "volume_db", -45, 4.85).set_ease(Tween.EASE_OUT)
				tween.tween_callback(func(): player.playing = false)
				tween.tween_property(player, "volume_db", set_db, 0)
			#SoundModifiers.set_db:
				## Currently just sets the DB to a "loud"-ish value
				#player.volume_db = 13
				#set_db = 13
		
