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
	
func load_game():
	if not FileAccess.file_exists(FILE_NAME):
		return # Error! We don't have a save to load.
	# Load the file line by line and process that dictionary to restore
	# the object it represents.
	var save_game = FileAccess.open(FILE_NAME, FileAccess.READ)
	
	elevator_reference = current_scene.find_child("Elevator")
	while save_game.get_position() < save_game.get_length():
		var json_string = save_game.get_line()
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
		

func _deferred_goto_scene(path, is_not_scene_load = false):
	# Load the new scene. New scene exists "in limbo"
	var s = ResourceLoader.load(path)
	
	if(s == null):
		assert(false, "Could not load scene: " + path + ", not valid path?")
	
	var mailcart_in_elevator = elevator_reference.get_node("Elevator").get_node("ObjectDetectionShape").mailcart_exists_in_elevator
	#var elevator_reference_origin = elevator_reference.get_node("Elevator").get_node("ElevatorOrigin")
	#var player_relative_to_elevator = player_reference.global_position - elevator_reference_origin.global_position
	#var player_relativerotation_to_elevator = player_reference.rotation - elevator_reference.rotation
	#if mail_cart_reference:
		#var mailcart_relative_to_elevator = mail_cart_reference.global_position - elevator_reference_origin.global_position
		#var mailcart_relativerotation_to_elevator = mail_cart_reference.rotation - elevator_reference.rotation
	
	# Change to the new scene
	var old_scene = current_scene
	current_scene = s.instantiate()
	# Find and replace any potential player node in new scene
	var new_player = current_scene.find_child("Player")
	if(new_player != null):
		new_player.free()
		
	# If this is not a save-load
	if(!is_not_scene_load):
		player_reference.reparent(current_scene, false)
		player_reference.owner = current_scene
		player_reference._ready()
	
	
	# We do not want to add the mailcart to the new scene in some cases
	if(mailcart_in_elevator):
		var mailcart = elevator_reference.get_node("Elevator").get_node("Mailcart")
		mailcart.perform_package_replacement(current_scene)
		# Find and replace any potential mailcart node in new scene
		var new_mailcart = current_scene.find_child("Mailcart")
		if(new_mailcart != null):
			new_mailcart.free()
	# Find and replace the elevator node
	var new_elevator = current_scene.find_child("Elevator")
	#var new_elevator_rotation = new_elevator.rotation
	elevator_reference.reparent(current_scene, false)
	elevator_reference.owner = current_scene
	
	# Position the elevator
	elevator_reference.position = new_elevator.position
	elevator_reference.rotation = new_elevator.rotation
	new_elevator.free()
	elevator_reference.name = "Elevator"
	
	# Time to delete the old scene
	old_scene.free()

	# Add it to the active scene, as child of root.
	get_tree().root.add_child(current_scene)
	
	# FIX FOR VOLUMETRIC BLEEDING THROUGH WALLS WHEN SCENESWITCHING
	if current_scene.get_node("WorldEnvironment") != null:
		var we = current_scene.get_node("WorldEnvironment")
		var timer = get_tree().create_timer(0.2)
		timer.timeout.connect(setWorldEnvironmentFog.bind(false, we))
		var timer2 = get_tree().create_timer(0.4)
		timer2.timeout.connect(setWorldEnvironmentFog.bind(true, we))
	 
	
	if(is_not_scene_load):
		elevator_reference.load_floor()

# FIX FOR VOLUMETRIC BLEEDING THROUGH WALLS WHEN SCENESWITCHING
func setWorldEnvironmentFog(flag, we):
	we.environment.volumetric_fog_enabled = flag

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
