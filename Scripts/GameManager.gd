extends Node

const FILE_NAME = "user://game-data.json"

@export var blacklist = ["pos_x", "pos_y", "pos_z", "nodepath"]
var current_scene : Node
var player_reference: Node
var elevator_reference: Node
var mail_cart_reference:Node

func register_player(new_player):
	player_reference = new_player
func register_mail_cart(cart):
	mail_cart_reference = cart
func register_elevator(elevator):
	elevator_reference = elevator
	
func get_mail_cart()->Node:
	return mail_cart_reference
func get_player()->Node:
	return player_reference
func get_elevator()->Node:
	return elevator_reference
	
func _ready():
	var root = get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)
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

func goto_scene(path, floor = null):
	if current_scene.get_scene_file_path() != path:
		var elevatorMove = false
		if(floor != null):
			call_deferred("_deferred_goto_scene", path, true)
		else:
			call_deferred("_deferred_goto_scene", path)
		

func _deferred_goto_scene(path, is_not_scene_load = false):
	# Load the new scene. New scene exists "in limbo"
	var s = ResourceLoader.load(path)
	
	if(s == null):
		assert(false, "Could not load scene: " + path + ", not valid path?")
	
	var mailcart_in_elevator = elevator_reference.get_node("Elevator").get_node("ObjectDetectionShape").mailcart_exists_in_elevator
	var elevator_reference_origin = elevator_reference.get_node("Elevator").get_node("ElevatorOrigin")
	var player_relative_to_elevator = player_reference.global_position - elevator_reference_origin.global_position
	var player_relativerotation_to_elevator = player_reference.rotation - elevator_reference.rotation
	var mailcart_relative_to_elevator = mail_cart_reference.global_position - elevator_reference_origin.global_position
	var mailcart_relativerotation_to_elevator = mail_cart_reference.rotation - elevator_reference.rotation
	
	# Change to the new scene
	var old_scene = current_scene
	current_scene = s.instantiate()
	
	# Find and replace any potential player node in new scene
	var new_player = current_scene.find_child("Player")
	if(new_player != null):
		new_player.free()
	if(!is_not_scene_load):
		player_reference.reparent(current_scene, false)
		player_reference.owner = current_scene
		player_reference._ready()
	
	# Find and replace any potential mailcart node in new scene
	var new_mailcart = current_scene.find_child("Mailcart")
	if(new_mailcart != null):
		new_mailcart.free()
	# We do not want to add the mailcart to the new scene in some cases
	if(mailcart_in_elevator):
		#mail_cart_reference.reparent(current_scene, false)
		#mail_cart_reference.owner = current_scene
		#mail_cart_reference._ready()
		pass
	
	
	# Find and replace the elevator node
	var new_elevator = current_scene.find_child("Elevator")
	var new_elevator_rotation = new_elevator.rotation
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
	
	# Reparent player and cart to elevator if necessary
	if(is_not_scene_load):
		pass
		#player_reference.reparent(elevator_reference.find_child("Elevator").get_node("ElevatorOrigin"), false)
		#player_reference.position = player_relative_to_elevator
		#player_reference.rotation = player_relativerotation_to_elevator
		
		#if(mailcart_in_elevator):
			#mail_cart_reference.reparent(elevator_reference.find_child("Elevator"), false)
			#mail_cart_reference.position = mailcart_relative_to_elevator
			#mail_cart_reference.rotation = mailcart_relativerotation_to_elevator
	
	if(is_not_scene_load):
		elevator_reference.load_floor()

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
