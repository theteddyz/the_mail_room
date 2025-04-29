extends Area3D
var we: WorldEnvironment
var tween: Tween
var starting_ambient_light_energy

func _on_body_entered(body: Node3D) -> void:
	if we == null:
		we = GameManager.we_reference
		starting_ambient_light_energy = we.environment.ambient_light_energy
	if tween != null:
		tween.kill()
	tween = get_tree().create_tween()
	tween.tween_property(we.environment, "ambient_light_energy", 0.0, 0.88);

func _on_body_exited(body: Node3D) -> void:
	if we == null:
		we = GameManager.we_reference
		starting_ambient_light_energy = we.environment.ambient_light_energy
	if tween != null:
		tween.kill()
	tween = get_tree().create_tween()
	tween.tween_property(we.environment, "ambient_light_energy", starting_ambient_light_energy, 0.88);
