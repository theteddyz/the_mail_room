extends Node3D

# Array to store nodes with the specific script
var objects = []

# Path to the script you're looking for
var script_path = "res://Scripts/MoveableObjects/GrabbableObject.gd"
var player: CharacterBody3D

var index = 0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = GameManager.get_player()
	# Load the script you are looking for
	var specific_script = load(script_path)
	
	# Start traversing the scene tree from the root
	var root = get_tree().root
	
	# Recursively find and store nodes with the specific script
	find_nodes_with_script(root, specific_script)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	for n in 20:
		var object = objects[index]
		checkOptimization(object)
		index += 1
		if(index >= objects.size()):
			index = 0
# Function to recursively find nodes with a specific script
func find_nodes_with_script(node, script):
	# Check if the current node has the specific script
	if node.get_script() == script:
		node.freeze = true
		disable_shadows(node)
		objects.append(node)
	
	# Recurse into children
	for child in node.get_children():
		find_nodes_with_script(child, script)

func disable_shadows(rigid_body):
	for child in rigid_body.get_children():
		if child is MeshInstance3D:  # Check if the child is a MeshInstance3D (or MeshInstance in older versions)
			child.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			#child.visible = false
			
func enable_shadows(rigid_body):
	for child in rigid_body.get_children():
		if child is MeshInstance3D:  # Check if the child is a MeshInstance3D (or MeshInstance in older versions)
			child.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			#child.visible = true
func unFreeze(body):
	if body.freeze:
		body.freeze = false
		body.sleeping = true
		enable_shadows(body)
		body.setShouldOptimize(false)

func freeze(body):
	if not body.freeze:
		body.sleeping = true
		body.freeze = true
		disable_shadows(body)
		body.setShouldOptimize(true)


func checkOptimization(body):
	# Calculate the distance once and store it
	pass

	if player:
		var distance = player.global_transform.origin.distance_to(body.global_transform.origin)
		if distance < 5:
			unFreeze(body)
		elif distance > 25:
			freeze(body)
		else:
			if is_occluded(body):
				freeze(body)
			else:
				unFreeze(body)
	else:
		pass

	#freeze(body)
# Function to check if an object is occluded
func is_occluded(object) -> bool:
	var space_state = get_world_3d().direct_space_state
	var from_position = player.global_transform.origin
	var to_position = object.global_transform.origin
	
	# Create raycast parameters
	var raycast_params = PhysicsRayQueryParameters3D.new()
	raycast_params.from = from_position
	raycast_params.to = to_position
	
	# Set the collision mask to only check against layer 8
	raycast_params.collision_mask = 1 << 15  # Layer 16 corresponds to bit 15

	# Perform the raycast
	var result = space_state.intersect_ray(raycast_params)
	
	# Check if the ray hit something that isn't the object itself
	if result.has("collider") and result["collider"] != object:
		return true
	
	return false
