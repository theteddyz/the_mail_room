extends Area3D

@export var ambience_index = 1

@export var cluster : Array[Node] = []

func _on_body_entered(body: Node3D) -> void:
	AudioController.play_ambience(ambience_index)
	for object in cluster:
		object.queue_free()
	queue_free()
