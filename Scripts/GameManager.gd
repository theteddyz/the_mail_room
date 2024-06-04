extends Node

const FILE_NAME = "user://game-data.json"

@export var ACTUAL = false
@export var blacklist = ["pos_x", "pos_y", "pos_z", "name"] 

func _ready():
	if(ACTUAL):
		load_game()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if(ACTUAL):
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

#TODO!: Adapt the below load function!
# Note: This can be called from anywhere inside the tree. This function
# is path independent.
func load_game():
	if not FileAccess.file_exists(FILE_NAME):
		return # Error! We don't have a save to load.

	# We need to revert the game state so we're not cloning objects
	# during loading. This will vary wildly depending on the needs of a
	# project, so take care with this step.
	# For our example, we will accomplish this by deleting saveable objects.
	var save_nodes = get_tree().get_nodes_in_group("Persist")
	for i in save_nodes:
		#i.queue_free()
		pass

	# Load the file line by line and process that dictionary to restore
	# the object it represents.
	var save_game = FileAccess.open(FILE_NAME, FileAccess.READ)
	while save_game.get_position() < save_game.get_length():
		var json_string = save_game.get_line()

		# Creates the helper class to interact with JSON
		var json = JSON.new()

		# Check if there is any error while parsing the JSON string, skip in case of failure
		var parse_result = json.parse(json_string)
		if not parse_result == OK:
			print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
			continue

		# Get the data from the JSON object
		var node_data = json.get_data()

		# Get the object, update it
		var new_object = get_node("/root/testworld/" + node_data["nodepath"])
		new_object.position = Vector3(node_data["pos_x"], node_data["pos_y"], node_data["pos_z"])

		# Now we set the remaining variables.
		for i in node_data.keys():
			if blacklist.has(i):
				continue
				
			var istr = (i as String)
			var split = istr.split(".")
			if(istr.contains("find")):
				#new_object.find_child(split[1])[split[2]][split[3]] = node_data[i]
				pass
			else: 
				# If the propery is further down, like rotation.y
				if(istr.contains(".")):
					new_object[split[0]][split[1]] = node_data[i]
				else:
					new_object.set(i, node_data[i])
