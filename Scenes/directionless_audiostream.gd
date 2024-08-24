extends Node
class stream_interface:
	var owner: String = ""
	var player: AudioStreamPlayer
	# Constructor
	func _init(player: AudioStreamPlayer, owner: String) -> void:
		self.player = player
		self.owner = owner

var players
#TODO: These maybe, who knows
enum SoundModifiers {
	none = 0,
	fade_in = 1,   
	fade_out = 2,
}

var ambiences = []

func _ready():
	players = [stream_interface.new($stream, ""), stream_interface.new($stream2, ""), stream_interface.new($stream3, "")]

func _get_free_player() -> stream_interface:
	for object in players:
		if !object.player.playing:
			return object
	print("NO FREE AUDIO PLAYERS; DEFAULTING TO FIRST ONE")
	return players[0]
	
func play_resource(sound, modifiers = 0):
	var interface = _get_free_player()
#	# At a certain point here we want to check ownerships and set new ones
	var player = interface.player
	player.stream = sound
	player.playing = true
	
func stop_resource(resource_name):
	for object in players:
		if object.player.get_stream() != null:
			var parts = object.player.get_stream().get_path().split("/")
			if parts[parts.size()-1] == resource_name:
				object.player.playing = false
				
				
func play_ambience(index):
	var interface = _get_free_player()
	var player = interface.player
	if ambiences[index] != null:
		player.stream = ambiences[index]
		player.playing = true
