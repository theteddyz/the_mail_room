extends Control

var title: Label
@export var delay: float = 2
@export var duration: float = 2.5
var timer: float = 0
var sound: AudioStreamPlayer
var hasTriggered: bool = false

func _ready():
	title = find_child("Label")
	sound = find_child("AudioStreamPlayer")
	title.visible = false
	
func _process(delta: float) -> void:
	timer += delta
	if timer > delay and hasTriggered == false:
		hasTriggered = true
		sound.play()
		
	if timer > (delay+0.2):
		title.visible = true
		
	if timer > (delay + duration):
		title.visible = false
	
