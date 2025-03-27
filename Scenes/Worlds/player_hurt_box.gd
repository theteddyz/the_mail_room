extends Area3D
@onready var player_sparked_sound: AudioStreamPlayer3D = $"../spark_emitter/PlayerSparkedSound"

func _on_body_entered(body: Node3D) -> void:
	if body.name == "Player" or body.name == "Mailcart":
			body.extra_life = 0
			player_sparked_sound.playing = true
			body.hit_by_entity()
