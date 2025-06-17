extends Control

var title: Label
@export var delay: float = 2
@export var duration: float = 2.5
var timer: float = 0
var sound: Resource
var hasTriggered: bool = false

func _ready():
	sound = load("res://Assets/Audio/SoundFX/GamifiedSounds/mail room cello impact.ogg")
	title = find_child("Label")
	title.visible = false
	
func _process(delta: float) -> void:
	timer += delta
	if timer > delay and hasTriggered == false:
		hasTriggered = true
		AudioController.play_resource(sound)
		
	if timer > (delay+0.2):
		title.visible = true
		
	if timer > (delay + duration):
		title.visible = false
		queue_free()
	
