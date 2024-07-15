extends Control

var is_paused = false
var is_reading = false
var world
# Called when the node enters the scene tree for the first time.
func _ready():
	world = get_tree().root.get_child(3)
	hide()
	is_paused = false
	get_tree().paused = false
	EventBus.connect("player_reading",is_player_reading)
	EventBus.connect("game_paused",game_paused)

func _on_continue_pressed():
	if is_paused and !is_reading:
		_reset_pause_state()
		hide()
	else:
		_reset_pause_state()
		hide()


func _on_options_pressed():
	if is_paused:
		print("No options yet bother Jakob XD")


func _on_restart_pressed():
	if is_paused:
		_reset_pause_state()
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

func is_player_reading(_is_reading:bool):
	is_reading = _is_reading

func _reset_pause_state():
	is_paused = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	hide()
