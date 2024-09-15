extends Marker3D

var observed = false

func _on_visible_on_screen_notifier_3d_screen_entered() -> void:
	observed = true


func _on_visible_on_screen_notifier_3d_screen_exited() -> void:
	observed = false
