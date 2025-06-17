extends Node

# DEVMODE, CHANGE THIS WHEN WE BUILD
var devmode = false

const FILE_NAME = "user://game-data.json"
@export var blacklist = ["pos_x", "pos_y", "pos_z", "nodepath"]
var current_scene : Node
var player_reference: Node
var camera_reference: Camera3D
var elevator_reference: Node
var mail_cart_reference: Node
var scare_director_reference: Node
var world_reference: Node
var current_scene_root:Node
var we_reference: WorldEnvironment
var player_radio:Node
var _threaded_scene_path = ""
var _threaded_loading_complete = false
var _threaded_loaded_scene : PackedScene


func preload_scene_in_background(scene_path: String) -> void:
	_threaded_scene_path = scene_path
	_threaded_loading_complete = false
	ResourceLoader.load_threaded_request(scene_path)

func poll_scene_loading() -> bool:
	if _threaded_loading_complete:
		return true
	var status = ResourceLoader.load_threaded_get_status(_threaded_scene_path)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		_threaded_loaded_scene = ResourceLoader.load_threaded_get(_threaded_scene_path)
		_threaded_loading_complete = true
		return true
	return false


#Quite a few script rely on these setter getter, proceed with caution if deleted
func register_player(new_player):
	player_reference = new_player
	
func register_camera(new_camera):
	print(new_camera)
	camera_reference = new_camera
	
func register_mail_cart(cart):
	mail_cart_reference = cart
	
func register_elevator(elevator):
	elevator_reference = elevator
	
func register_scaredirector(director):
	scare_director_reference = director
	
func register_player_radio(radio):
	player_radio = radio
	
func register_world_environment(we):
	we_reference = we
	
func register_world(world):
	world_reference = world
	
func get_mail_cart()->Node:
	return mail_cart_reference
	
func get_player()->Node:
	return player_reference
	
func get_elevator()->Node:
	return elevator_reference
	
func get_player_radio() ->Node:
	return player_radio
	
func get_world() ->Node:
	return world_reference
	
func get_player_camera() ->Node:
	return camera_reference

func _ready():
	var root = get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)
	if mail_cart_reference == null:
		mail_cart_reference = current_scene.find_child("Mailcart")
	if player_reference == null:
		player_reference = current_scene.find_child("Player")
	load_game()

func save_usb_data(new_value: int) -> void:
	var data := {}
	
	# Load existing data if the file exists
	if FileAccess.file_exists(FILE_NAME):
		var save_game = FileAccess.open(FILE_NAME, FileAccess.READ)
		if save_game:
			var save_string = save_game.get_as_text()
			var parsed = JSON.parse_string(save_string)
			if typeof(parsed) == TYPE_DICTIONARY:
				data = parsed
			save_game.close()

	# Ensure USB_DATA exists and is an array
	if not data.has("USB_DATA"):
		data["USB_DATA"] = []

	var usb_data_array = data["USB_DATA"]

	# Check if the USB is already in the list
	var already_exists := false
	for usb in usb_data_array:
		if typeof(usb) == TYPE_DICTIONARY and usb.get("id", -1) == new_value:
			already_exists = true
			break

	# If not already present, add it with the flag
	if not already_exists:
		usb_data_array.append({
			"id": new_value,
			"added_to_computer": false
		})

	# Save updated data
	var save_game = FileAccess.open(FILE_NAME, FileAccess.WRITE)
	if save_game:
		var json_string = JSON.stringify(data, "\t")  # "\t" for pretty print
		save_game.store_string(json_string)
		save_game.close()



func mark_usb_as_added_to_computer(target_id: int) -> void:
	var data := {}
	print("UPDATING BOOL")
	if FileAccess.file_exists(FILE_NAME):
		var save_game = FileAccess.open(FILE_NAME, FileAccess.READ)
		if save_game:
			var save_string = save_game.get_as_text()
			var parsed = JSON.parse_string(save_string)
			if typeof(parsed) == TYPE_DICTIONARY:
				data = parsed
			save_game.close()

	if data.has("USB_DATA"):
		for usb in data["USB_DATA"]:
			if typeof(usb) == TYPE_DICTIONARY and usb.get("id", -1) == target_id:
				usb["added_to_computer"] = true
				break

	# Save the updated data
	var save_game = FileAccess.open(FILE_NAME, FileAccess.WRITE)
	if save_game:
		var json_string = JSON.stringify(data, "\t")
		save_game.store_string(json_string)
		save_game.close()


func load_game():
	if not FileAccess.file_exists(FILE_NAME):
		return # Error! We don't have a save to load.
		
	var file = FileAccess.open(FILE_NAME, FileAccess.READ)
	if file:
		var save_string = file.get_as_text()
		var data = JSON.parse_string(save_string)
		file.close()
		# Check if it's only USB_DATA or completely empty/invalid
		if typeof(data) != TYPE_DICTIONARY:
			return # Corrupted or invalid save
			
		var keys = data.keys()
		if keys.size() == 1 and "USB_DATA" in keys:
			return # Only USB_DATA exists; skip loading game
			
	# Proceed with loading game state from `data`
	elevator_reference = current_scene.find_child("Elevator")
	while file.get_position() < file.get_length():
		var json_string = file.get_line()
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if not parse_result == OK:
			print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
			continue
		# Get the data from the JSON object
		var node_data = json.get_data()
		if(node_data.has("levelpath")):
			for i in node_data.keys():
				if blacklist.has(i):
					continue
				var istr = (i as String)
				if(istr.contains("levelpath")):
					var root = get_tree().root
					current_scene = root.get_child(root.get_child_count() - 1)
					if current_scene.get_scene_file_path() != node_data["levelpath"]:
						call_deferred("_deferred_goto_scene", node_data["levelpath"])
					continue
		else:
			continue
	call_deferred("load_node_variables")

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save()
		get_tree().quit() # default behavior
		
func save():
	var save_game = FileAccess.open(FILE_NAME, FileAccess.WRITE)
	var save_nodes = get_tree().get_nodes_in_group("Persist")
	print(save_nodes)
	for node in save_nodes:
		# Check the node has a save function.
		if !node.has_method("save"):
			print("persistent node '%s' is missing a save() function, skipped" % node.name)
			continue

		# Call the node's save function.
		var node_data = node.call("save")

		# JSON provides a static method to serialized JSON string.
		var json_string = JSON.stringify(node_data)

		# Store the save dictionary as a new line in the save file.
		save_game.store_line(json_string)

func goto_scene(path, _floor):
	elevator_reference.show_or_hide_door()
	if current_scene == null:
		var root = get_tree().root
		current_scene = root.get_child(root.get_child_count() - 1)
	if current_scene.get_scene_file_path() != path:
		if(_floor != null):
			call_deferred("_deferred_goto_scene", path, true)
		else:
			call_deferred("_deferred_goto_scene", path)
		

func _deferred_goto_scene(scene_or_path: Variant, is_not_scene_load: bool = false) -> void:
	var s: PackedScene = ResourceLoader.load(scene_or_path) if typeof(scene_or_path) == TYPE_STRING else scene_or_path
	if s == null:
		push_error("Could not load scene: " + str(scene_or_path))
		return

	# --- References ---
	var elevator: Node3D = get_elevator()
	var player: Node3D = get_player()
	var mailcart: Node3D = get_mail_cart()
	var camera = get_player_camera()
	var old_scene
	# --- Detach elevator (with its contents) from current scene ---
	elevator.reparent(get_tree().root)  # Temporarily keep elevator in scene tree

	# --- Move old scene far away ---
	if current_scene:
		current_scene.global_position += Vector3(0, -500, 0)

	# --- Instantiate new scene ---
	var new_scene: Node = s.instantiate()
	old_scene = current_scene
	current_scene = new_scene

	# --- Remove default player and mailcart if they exist ---
	var new_player: Node = new_scene.find_child("Player", true, false)
	if new_player:
		new_player.queue_free()
	if mailcart:
		var new_mailcart: Node = new_scene.find_child("Mailcart", true, false)
		if new_mailcart:
			new_mailcart.queue_free()

	# --- Replace new elevator with our existing one ---
	var new_elevator: Node3D = new_scene.find_child("Elevator", true, false)
	var new_elevator_pos: Vector3 = new_elevator.position
	var new_elevator_rot: Vector3 = new_elevator.rotation

		# Delete the placeholder elevator
	new_elevator.queue_free()
	register_elevator(elevator)
		# Reattach the real elevator


		# Store target landing position so elevator can snap there
	elevator.target_landing_position = new_elevator_pos
	# --- Add new scene to the tree ---
	get_tree().root.add_child(new_scene)
	elevator.reparent(new_scene, false)
	elevator.owner = new_scene
	elevator.position = new_elevator_pos
	elevator.rotation = new_elevator_rot
	old_scene.queue_free()
	EventBus.emitCustomSignal("loaded_new_floor")
	register_camera(camera)
	register_player(player)
	if mailcart:
		register_mail_cart(mailcart)
	register_elevator(elevator)
	# --- Restore fog (optional visual fix) ---
	if new_scene.has_node("WorldEnvironment"):
		var we: WorldEnvironment = new_scene.get_node("WorldEnvironment")
		var timer1: SceneTreeTimer = get_tree().create_timer(0.2)
		timer1.timeout.connect(setWorldEnvironmentFog.bind(false, we))
		var timer2: SceneTreeTimer = get_tree().create_timer(0.4)
		timer2.timeout.connect(setWorldEnvironmentFog.bind(true, we))
	# --- Final load step for scenes from save ---
	if is_not_scene_load:
		elevator.load_floor()

# FIX FOR VOLUMETRIC BLEEDING THROUGH WALLS WHEN SCENESWITCHING
func setWorldEnvironmentFog(flag, we):
	we.environment.volumetric_fog_enabled = flag


func replace_with_threaded_scene():
	if !_threaded_loading_complete or _threaded_loaded_scene == null:
		push_error("Scene not fully loaded!")
		return
	_deferred_goto_scene(_threaded_loaded_scene)


func auto_register_scene_objects(scene: Node) -> void:
	# You can customize these names if needed
	var new_player = scene.find_child("Player", true, false)
	if new_player:
		register_player(new_player)

	var new_elevator = scene.find_child("Elevator", true, false)
	if new_elevator:
		register_elevator(new_elevator)

	var new_mailcart = scene.find_child("Mailcart", true, false)
	if new_mailcart:
		register_mail_cart(new_mailcart)

	var new_radio = scene.find_child("PlayerRadio", true, false)
	if new_radio:
		register_player_radio(new_radio)

	var new_we = scene.find_child("WorldEnvironment", true, false)
	if new_we:
		register_world_environment(new_we)

	register_world(scene)


func clear_all_registered_objects():
	player_reference = null
	camera_reference = null
	elevator_reference = null
	mail_cart_reference = null
	scare_director_reference = null
	world_reference = null
	current_scene_root = null
	we_reference = null
	player_radio = null



func load_node_variables():
	if not FileAccess.file_exists(FILE_NAME):
		return # Error! We don't have a save to load.
	# Load the file line by line and process that dictionary to restore
	# the object it represents.
	var save_game = FileAccess.open(FILE_NAME, FileAccess.READ)
	
	while save_game.get_position() < save_game.get_length():
		var json_string = save_game.get_line()
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if not parse_result == OK:
			print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
			continue
		var node_data = json.get_data()

		# Get the object, update it
		if(!node_data.has("levelpath")):
			var new_object = get_node("/root/" + node_data["nodepath"])
			if node_data.has("inside_mail_cart"):
				if node_data["inside_mail_cart"] == true:
					mail_cart_reference.add_package(new_object)
					print(mail_cart_reference.game_objects.size())
				else:
					new_object.position = Vector3(node_data["pos_x"], node_data["pos_y"], node_data["pos_z"])
			# Now we set the remaining variables.
			for i in node_data.keys():
				if blacklist.has(i):
					continue
				
				var istr = (i as String)
				var split = istr.split(".")
				# If the propery is further down, like rotation.y
				if(istr.contains(".")):
					new_object[split[0]][split[1]] = node_data[i]
				else:
					new_object.set(i, node_data[i])
	save()
