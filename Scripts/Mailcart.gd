extends Node3D

# Array to hold game objects
var game_objects = []

var player

# Pointer to track the current index in the game_objects array
var current_index = 0

# If we want to highlight packages
var is_being_looked_at = false

var highlight_lerp_speed = 8.2
var unhighlight_lerp_speed = 8.2

func _ready():
	# Initialize the array with game objects if needed
	# For example, game_objects.append(some_game_object)
	is_being_looked_at = false
	player = get_parent().find_child("Player")	

func _process(delta):
	if is_being_looked_at and game_objects.size() != 0:
		game_objects[current_index].position.y = lerp(game_objects[current_index].position.y, 0.5, highlight_lerp_speed * delta)
		lowerOtherPackages(delta)
	else:
		lowerAllPackages(delta)
	
func lowerAllPackages(delta):
	for index in game_objects.size():
		var package = game_objects[index]
		package.position.y = lerp(package.position.y, package.cart_position.y, unhighlight_lerp_speed * delta)

func lowerOtherPackages(delta):
	for index in game_objects.size():
		if index != current_index:
			var package = game_objects[index]
			package.position.y = lerp(package.position.y, package.cart_position.y, unhighlight_lerp_speed * delta)

func remove_package():
	pass

# Function to scroll the package up
func scroll_package_up():
	if current_index < game_objects.size() - 1:
		current_index += 1
	else:
		current_index = 0
	print("Current Index after scrolling up: ", current_index)

# Function to scroll the package down
func scroll_package_down():
	if game_objects.size() != 0:
		if current_index > 0:
			current_index -= 1
		else:
			current_index = game_objects.size() - 1
	print("Current Index after scrolling down: ", current_index)

# Function to grab the current package
func grab_current_package():
	if game_objects.size() > 0:
		var current_package = game_objects[current_index]
		game_objects.remove_at(current_index)
		current_index = 0
		player.state.grabbed_package(current_package)
		if game_objects.size() > 0:
			calculate_spacing() 
		#current_package.reparent(player, false)
	else:
		print("No packages to grab")

# Function to add a package to the game_objects array
func add_package(package: Package):
	game_objects.append(package)
	calculate_spacing()

func calculate_spacing():
	# Calculate the spacing
	var total_packages = game_objects.size()
	if total_packages > 1:
		var step = 1.5 / (total_packages - 1)  # Total range is 1.5 (from 0.75 to -0.75)
		for i in range(total_packages):
			var position = 0.75 - i * step
			print("Package ", i, " position: ", position)
			move_package_to_cart(game_objects[i], position)
			
	else:
		print("Package 0 position: 0")
		move_package_to_cart(game_objects[0], 0)

# Placeholder function to move package to cart
func move_package_to_cart(package: Package, position: float):
	package.reparent(self, false)
	package.rotation_degrees = package.cart_rotation
	package.position = Vector3(position, package.cart_position.y, 0)
	pass
