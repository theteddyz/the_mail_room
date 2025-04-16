extends Label

func _ready() -> void:
	set_process_input(true)

func _input(event: InputEvent):
	if event.is_action_pressed("DEBUG_DOWN"):
		get_tree().paused = !get_tree().paused
		visible = !visible
