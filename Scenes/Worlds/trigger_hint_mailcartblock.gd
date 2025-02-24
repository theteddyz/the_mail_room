extends Area3D


func _on_body_entered(body: Node3D) -> void:
	Gui.get_hint_controller().display_hint("mailcart_blocked",3)
