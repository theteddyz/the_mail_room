extends Area3D
var sound: Resource
var has_launched = false
func _ready():
	sound = load("res://Assets/Audio/Music/Mail Room Soundtrack 3.1.ogg")

func _on_body_entered(body: Node3D) -> void:
	if !has_launched:
		has_launched = true
		AudioController.play_resource(sound, 1, func(): {}, 0)
		var timer = get_tree().create_timer(2.85)
		await timer.timeout
		AudioController.stop_resource(sound.resource_path, 2)
		queue_free()
