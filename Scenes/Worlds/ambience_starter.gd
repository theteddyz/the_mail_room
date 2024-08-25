extends Area3D

@export var starter: bool = true

@export var sound_resource_path = ""

@export var cluster : Array[Node] = []

@export var modifiers = 0

var sound: Resource

func _ready():
	sound = load(sound_resource_path)

func _on_body_entered(body: Node3D) -> void:
	if starter:
		AudioController.play_resource(sound, modifiers)
	else:
		AudioController.stop_resource(sound_resource_path, modifiers)
	for object in cluster:
		object.queue_free()
	queue_free()
