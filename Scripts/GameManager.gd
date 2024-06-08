extends Node

const FILE_NAME = "user://game-data.json"

@export var blacklist = ["pos_x", "pos_y", "pos_z", "nodepath"]
var current_scene : Node
var player_reference: Node
var elevator_reference: Node

func _ready():
	var root = get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)
	load_game()
	
func load_game():
	if not FileAccess.file_exists(FILE_NAME):
		player_reference = current_scene.find_child("Player")
		elevator_reference = current_scene.find_child("Elevator")
		return # Error! We don't have a save to load.
	# Load the file line by line and process that dictionary to restore
	# the object it represents.
	var save_game = FileAccess.open(FILE_NAME, FileAccess.READ)
	
	player_reference = current_scene.find_child("Player")
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

func goto_scene(path):
	if current_scene.get_scene_file_path() != path:
		call_deferred("_deferred_goto_scene", path)

func _deferred_goto_scene(path):
	# Load the new scene. New scene exists "in limbo"
	var s = ResourceLoader.load(path)
	
	var player_relative_to_elevator = player_reference.position - elevator_reference.position
	
	# Change to the new scene
	var old_scene = current_scene
	current_scene = s.instantiate()
	
	# Find and replace any potential player node in new scene
	var new_player = current_scene.find_child("Player")
	if(new_player != null):
		new_player.free()
	player_reference.reparent(current_scene, false)
	player_reference.owner = current_scene
	player_reference._ready()
	
	# Find and replace the elevator node
	var new_elevator = current_scene.find_child("Elevator")
	elevator_reference.reparent(current_scene, false)
	elevator_reference.owner = current_scene
	
	# Position the elevator
	elevator_reference.position = new_elevator.position
	
	#TEMPORARY AND SLOW WAY TO FIND THE LEVEL WE SHOULD TOGGLE TO NEXT TIME WE PRESS LOAD
	elevator_reference.find_child("Button").target_scene_path = new_elevator.find_child("Button").target_scene_path
	if(elevator_reference.find_child("Button").target_scene_path == path):
		elevator_reference.find_child("Button").target_scene_path = "res://Scenes/testworld.tscn"
	else:
		elevator_reference.find_child("Button").target_scene_path = "res://Scenes/testworld2.tscn"
	new_elevator.free()
	elevator_reference.name = "Elevator"

	# Position the player	
	player_reference.position = elevator_reference.position + player_relative_to_elevator
	
	# Time to delete the old scene
	old_scene.free()

	# Add it to the active scene, as child of root.
	get_tree().root.add_child(current_scene)

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
