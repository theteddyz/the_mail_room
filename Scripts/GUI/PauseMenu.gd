extends Control

var is_paused = false
var is_reading = false
var world
var Icon_Manager

@onready var item_reader = $"../ItemReader"
@onready var options = $"../Options"
@onready var continue_button =$PauseMenu/VBoxContainer/Continue
@onready var options_button = $PauseMenu/VBoxContainer/Options
@onready var button_container = $PauseMenu/VBoxContainer
var buttons: Array[Button]
func _ready():
	for child in button_container.get_children():
		if child is Button:
			buttons.append(child)
	var parent = get_parent()
	Icon_Manager = parent.find_child("IconManager")
	world = get_tree().root.get_child(3)
	hide()
	is_paused = false
	get_tree().paused = false
	EventBus.connect("player_reading", is_player_reading)
	EventBus.connect("game_paused", game_paused)

func _on_continue_pressed():
	if is_paused and !is_reading:
		# Reset scale just in case
		await animate_button_press(continue_button)
		Icon_Manager.show()
		_reset_pause_state()
		hide()
		_reset_button_alpha()
	else:
		await animate_button_press(continue_button)
		Icon_Manager.show()
		_reset_pause_state()
		hide()
		_reset_button_alpha()

func _on_options_pressed():
	if is_paused:
		await animate_button_press(options_button)
		#hide()
		options.show()


func _on_restart_pressed():
	if is_paused:
		var current_scene = get_tree().get_current_scene()
		current_scene.queue_free()

		var world: Node3D = GameManager.get_world()
		var scene_path = world.scene_file_path
		var new_scene: PackedScene = load(scene_path)
		var _new_instance = new_scene.instantiate()
		get_tree().get_root().add_child(_new_instance)

		GameManager._ready()
		Gui.call_ready()
		get_tree().set_current_scene(_new_instance)

		_reset_pause_state()

func _on_quit_button_pressed():
	if is_paused:
		get_tree().quit()

func game_paused():
	is_paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = true

	Icon_Manager.hide()
	item_reader.hide()

	var controls = get_parent().find_child("Controls")
	if controls and controls.visible:
		controls.hide()

	show()

func is_player_reading(_is_reading: bool):
	is_reading = _is_reading


func _reset_button_alpha():
	for btn in buttons:
		btn.modulate.a = 1.0
		btn.disabled = false

func _reset_pause_state():
	is_paused = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Restore other button opacities
	_reset_button_alpha()

	hide()







func animate_button_press(button: Control) -> void:
	# Reset the pressed button scale
	button.scale = Vector2.ONE
	# Create a tween for the animation
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Fade out other buttons (slightly faster than button scale anim)
	for other_button in buttons:
		if other_button != button:
			other_button.disabled = true
			var tween2 =  create_tween()
			tween2.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween2.tween_property(other_button, "modulate:a", 0.2, 0.1)
	# Squish and unsquish the pressed button
	tween.tween_property(button, "scale", Vector2(0.9, 0.9), 0.1)
	tween.tween_property(button, "scale", Vector2.ONE, 0.15)
	await tween.finished
