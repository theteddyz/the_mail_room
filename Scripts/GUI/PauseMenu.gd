extends Control

var is_paused = false
var is_reading = false
var world
var Icon_Manager

@onready var item_reader = $"../ItemReader"
@onready var options = $"../Options"
@onready var continue_button =$VBoxContainer/Continue
@onready var options_button = $VBoxContainer/Options
@onready var button_container = $VBoxContainer
@onready var background:ColorRect = $"../ColorRect"
@onready var debug_menu = $FPSMeter
var buttons: Array[Button]
var parent
func _ready():
	for child in button_container.get_children():
		if child is Button:
			buttons.append(child)
	Icon_Manager = Gui.get_icon_manager()
	world = get_tree().root.get_child(3)
	is_paused = false
	get_tree().paused = false
	EventBus.connect("player_reading", is_player_reading)
	EventBus.connect("game_paused", game_paused)
	parent = get_parent()
	parent.hide()

func _input(event):
	if event.is_action_pressed("escape") and is_paused:
		if options.current_submenu.size() > 0:
			options._on_back_button_pressed()
		elif options.current_submenu.size() == 0 and options.visible:
			options.hide()
			show()
			_reset_pause_state()
		else:
			_on_continue_pressed()

func fade_background(out:bool):
	if out:
		var tween = create_tween()
		tween.tween_property(background, "modulate:a", 0, 0.5).set_ease(Tween.EASE_IN_OUT)
	else:
		var tween = create_tween()
		tween.tween_property(background, "modulate:a", 225, 0.5).set_ease(Tween.EASE_IN_OUT)


func _on_continue_pressed():
	if is_paused and !is_reading:
		# Reset scale just in case
		await animate_button_press(continue_button)
		get_icon_manger(true)
		_reset_pause_state()
		get_parent().hide()
		_reset_button_alpha()
	else:
		await animate_button_press(continue_button)
		get_icon_manger(true)
		_reset_pause_state()
		get_parent().hide()
		_reset_button_alpha()

func _on_options_pressed():
	if is_paused:
		await animate_button_press(options_button)
		hide()
		if options:
			options.show()
		else:
			printerr("NO OPTIONS MENU")
		#options.show_preview_scene()


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
	get_icon_manger(false)
	get_item_reader(false)

	var controls = get_parent().find_child("Controls")
	if controls and controls.visible:
		controls.hide()
	var parent = get_parent()
	parent.show()

func is_player_reading(_is_reading: bool):
	is_reading = _is_reading


func _reset_button_alpha():
	for btn in buttons:
		btn.modulate.a = 1.0
		btn.disabled = false
	show()

func _reset_pause_state():
	is_paused = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Restore other button opacities
	_reset_button_alpha()

	get_parent().hide()


func  get_icon_manger(show:bool):
	if !Icon_Manager:
		Icon_Manager = Gui.get_icon_manager()
	if show:
		Icon_Manager.show()
	else:
		Icon_Manager.hide()

func get_item_reader(show:bool):
	if !item_reader:
		item_reader = Gui.get_item_reader()
	if show:
		item_reader.show()
	else:
		item_reader.hide()


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


func _on_check_button_toggled(toggled_on):
	if !debug_menu:
		debug_menu = Gui.get_debug()
	if toggled_on:
		debug_menu.show()
	else:
		debug_menu.hide()
