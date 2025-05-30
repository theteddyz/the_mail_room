extends Node3D

var tapes_collected = []
var base_position = Vector3(-0.331, 0.5, 0.03)
var tape_size = Vector3(0.1, 0.015, 0.12) 
var x_padding = 0.15
var y_padding = 0.12
var player_camera_parent
var player_camera:Camera3D
var using_box:bool
var interactableFinder:RayCast3D
var look_icon 
var camera_rotation:Vector3 = Vector3(-34.8,90,0)
var current_index = 0
var gui_anim
var text_displayer
var player
var box_dimensions = Vector3(0.324, 0.09, 0.29)  # width, height, depth
var wall_thickness = Vector3(0.01, 0, 0)  # Define wall thickness for the x-axis

@onready var camera_position:Node3D = $Camera_Position
var highlight_lerp_speed:float = 8.2
var unhighlight_lerp_speed:float = 8.2
func _ready():
	player = GameManager.get_player()
	text_displayer = Gui.get_address_displayer()
	player_camera_parent = player.find_child("Neck").find_child("Head").find_child("HeadbopRoot")
	player_camera = player_camera_parent.find_child("Camera")
	interactableFinder = player.find_child("Neck").find_child("Head").find_child("InteractableFinder")
	look_icon = Gui.look_icon
	gui_anim = Gui.get_control_displayer()



func _process(delta):
	if !using_box:
		lower_all_tapes(delta)
		gui_anim.show_icon(false)
	else:
		tape_hover(delta)
func tape_hover(delta):
	if tapes_collected.size() != 0:
		gui_anim.show_icon(true)
		highlight_current_tape(delta)
		lower_other_tapes(delta)
		text_displayer.show_text()
		text_displayer.set_text(tapes_collected[current_index].tape_name)
		#text_displayer.show_text()
		#text_displayer.set_text(game_objects[current_index].package_partial_address)


func _input(event):
	if using_box:
		if event.is_action_pressed("inspect"):
			stop_interaction()
		if event.is_action_pressed("scroll package down"):
			scroll_tape_down()
			gui_anim.scroll_down()
		elif event.is_action_pressed("scroll package up"):
			scroll_tape_up()
			gui_anim.scroll_up()
		if event.is_action_pressed("interact"):
			grab_current_tape()
func lower_all_tapes(delta):
	for index in tapes_collected.size():
		var tape = tapes_collected[index]
		if !tape.inside_radio:
			tape.position.y = lerp(tape.position.y, tape.box_position.y, unhighlight_lerp_speed * delta)

func lower_other_tapes(delta):
	for index in tapes_collected.size():
		if index != current_index:
			var tape = tapes_collected[index]
			if !tape.inside_radio:
				tape.position.y = lerp(tape.position.y, tape.box_position.y, unhighlight_lerp_speed * delta)

func highlight_current_tape(delta):
	if !tapes_collected[current_index].inside_radio:
		tapes_collected[current_index].position.y = lerp(tapes_collected[current_index].position.y, 0.55, highlight_lerp_speed * delta)

func scroll_tape_up():
	if current_index < tapes_collected.size() - 1:
		current_index += 1
		if tapes_collected[current_index].inside_radio:
			current_index += 1
	else:
		current_index = 0

# Function to scroll the package down
func scroll_tape_down():
	if tapes_collected.size() != 0:
		if current_index > 0:
			current_index -= 1
		else:
			current_index = tapes_collected.size() - 1



func add_tape(tape):
	tape.reparent(self)
	tapes_collected.append(tape)
	
	var tape_index = tapes_collected.size() - 1
	var tapes_per_row = (floor(box_dimensions.x / (tape_size.x * x_padding)))  # Width of the box along the x-axis now determines number of tapes per row
	#var internal_box_width = box_dimensions.x - (2 * wall_thickness.x) 
	var row = floor(tape_index / tapes_per_row)
	var col = tape_index % tapes_per_row
	var new_position = base_position + Vector3(
		col * (tape_size.x * x_padding),   
		row * (tape_size.y * y_padding), 
		0  
	)
	
	var new_transform = tape.transform
	new_transform.origin = new_position
	new_transform.basis = Basis(Vector3(0, 0, 1), deg_to_rad(90))  # Rotate 90 degrees on Z
	tape.freeze = true
	tape.transform = new_transform
	tape.box_position = new_position
	tape.show()
	
	print("Tape positioned in the box at position: ", new_position)


func grab_current_tape():
	var radio = GameManager.get_player_radio()
	if !radio.has_tape:
		if tapes_collected.size() > 0:
			var current_tape = tapes_collected[current_index]
			#var box_position  = current_tape.position
			#var box_rotation = current_tape.rotation
			current_index = 0
			using_box = false
			await current_tape.insert_tape(player_camera)
			stop_interaction()
			#current_package.reparent(player, false)
		else:
			print("No tapes to grab")

func stop_interaction():
	using_box = false
	player_camera.reparent(player_camera_parent)
	var camera_tween_position:Tween = create_tween()
	var camera_tween_rotation:Tween = create_tween()
	camera_tween_position.tween_property(player_camera,"position",Vector3.ZERO,1).set_ease(Tween.EASE_IN)
	camera_tween_rotation.tween_property(player_camera,"rotation",Vector3.ZERO,1).set_ease(Tween.EASE_IN)
	await camera_tween_position.finished
	interactableFinder.enabled = true
	EventBus.emitCustomSignal("disable_player_movement",[false,false])
	look_icon.show()

func start_interaction():
	if !using_box:
		EventBus.emitCustomSignal("disable_player_movement",[true,true])
		#var original_global_transform = player_camera.global_transform
		interactableFinder.enabled = false
		look_icon.hide()
		var icon = Gui.icon_manager
		var d
		icon.hide_all_icons(d)
		player_camera.reparent(camera_position)
		var camera_tween_position:Tween = create_tween()
		var camera_tween_rotation:Tween = create_tween()
		camera_tween_position.tween_property(player_camera, "position", Vector3.ZERO, 1).set_ease(Tween.EASE_IN_OUT)
		camera_tween_position.set_parallel(true)
		camera_tween_rotation.tween_property(player_camera, "rotation_degrees", Vector3.ZERO, 1).set_ease(Tween.EASE_IN_OUT)
		camera_tween_rotation.set_parallel(true)
		await camera_tween_position.finished
		using_box = true
		
