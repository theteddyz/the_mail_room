extends Interactable
@export var light: SpotLight3D = null
var button_audio
@onready var audio_player = $AudioStreamPlayer3D
func _ready():
	button_audio = preload("res://Assets/Audio/SoundFX/LampButton2.mp3")
	audio_player.stream = button_audio
func interact():
	audio_player.play()
	if(light != null):
		light.visible = !light.visible
