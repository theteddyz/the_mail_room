extends Control

var is_paused = false
var is_reading = false
var world
var Icon_Manager 
@onready var item_reader = $"../ItemReader"
# Called when the node enters the scene tree for the first time.
func _ready():
	var parent = get_parent()
	Icon_Manager = parent.find_child("IconManager")
	world = get_tree().root.get_child(3)
	hide()
	is_paused = false
	get_tree().paused = false
	EventBus.connect("player_reading",is_player_reading)
	EventBus.connect("game_paused",game_paused)

func _on_continue_pressed():
	if is_paused and !is_reading:
		Icon_Manager.show()
		_reset_pause_state()
		hide()
	else:
		Icon_Manager.show()
		_reset_pause_state()
		hide()


func _on_options_pressed():
	if is_paused:
		print("No options yet bother Jakob XD")


func _on_restart_pressed():
	if is_paused:
		var current_scene = get_tree().get_current_scene()
		current_scene.queue_free()
		var world:Node3D = GameManager.get_world()
		var scene_path = world.scene_file_path
		print(scene_path)
		var new_scene:PackedScene = load(scene_path)
		var _new_scene = new_scene.instantiate()
		get_tree().get_root().add_child(_new_scene)
		GameManager._ready()
		Gui.call_ready()
		get_tree().set_current_scene(_new_scene)
		_reset_pause_state()


func _on_quit_button_pressed():
	if is_paused:
		get_tree().quit()

func game_paused():
	is_paused = !is_paused
	is_paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = true
	var controls = get_parent().find_child("Controls")
	
	Icon_Manager.hide()
	item_reader.hide()
	if controls.visible == true:
		controls.hide()
	
	show()

func is_player_reading(_is_reading:bool):
	is_reading = _is_reading

func _reset_pause_state():
	is_paused = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	hide()
