extends cutscene
func _input(event):
	if event.is_action_pressed("p"):
		start_cutscene()
		var move_tween:Tween = create_tween()
		move_tween.tween_property(self, "position", Vector3(300, 0,0), 5.0)
		move_tween.set_ease(Tween.EASE_IN)
		move_tween.tween_property(self, "rotation_degrees", 45.0, 0.5)
		await move_tween.finished
		reset()
