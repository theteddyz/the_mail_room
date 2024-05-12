extends Control

var is_paused = false
# Called when the node enters the scene tree for the first time.
func _ready():
	hide()
	is_paused = false
	get_tree().paused = false


func _on_continue_pressed():
	if is_paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		get_tree().paused = false
		is_paused = false
		hide()


func _on_options_pressed():
	if is_paused:
		print("No options yet bother Jakob XD")


func _on_restart_pressed():
	if is_paused:
		var current_scene = get_tree().current_scene
		get_tree().reload_current_scene()


func _on_quit_button_pressed():
	if is_paused:
		get_tree().quit()

func game_paused():
	is_paused = !is_paused
	is_paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = true
	show()
