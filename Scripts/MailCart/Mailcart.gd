extends Node3D

# Array to hold game objects
var game_objects:Array = []
var radio_position:Node3D
var player:CharacterBody3D

# Pointer to track the current index in the game_objects array
var current_index:int = 0
var text_displayer:Node
# If we want to highlight packages
var is_being_looked_at:bool = false
var highlight_lerp_speed:float = 8.2
var unhighlight_lerp_speed:float = 8.2

func _ready():
	# Initialize the array with game objects if needed
	# For example, game_objects.append(some_game_object)
	GameManager.register_mail_cart(self)
	radio_position = find_child("RadioPosition")
	is_being_looked_at = false
	player = GameManager.get_player()
	text_displayer = Gui.get_address_displayer()
	

func _process(delta):
	if is_being_looked_at and game_objects.size() != 0:
		game_objects[current_index].position.y = lerp(game_objects[current_index].position.y, 0.8, highlight_lerp_speed * delta)
		text_displayer.show_text()
		text_displayer.set_text(game_objects[current_index].package_address)
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

func sort_packages_by_order():
	game_objects.sort_custom(Callable(self,"_sort_packages"))

func _sort_packages(a: Package, b: Package) -> bool:
	return a.package_num > b.package_num
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
		print(game_objects.size())
		current_index = 0
		player.state.grabbed_package(current_package)
		if game_objects.size() > 0:
			calculate_spacing() 
		#current_package.reparent(player, false)
	else:
		print("No packages to grab")

# Function to add a package to the game_objects array
func add_package(package: Package):
		if !game_objects.has(package):
			package.set_collision_layer_value(2,false)
			game_objects.append(package)
			sort_packages_by_order()
			calculate_spacing()

func calculate_spacing():
	# Calculate the spacing
	var total_packages = game_objects.size()
	if total_packages > 1:
		var step = 1.1 / (total_packages - 1)  # Total range is 1.5 (from 0.75 to -0.75)
		for i in range(total_packages):
			var _position = 0.45 - i * step
			print("Package ", i, " position: ", _position)
			move_package_to_cart(game_objects[i], _position)
			
	else:
		print("Package 0 position: 0")
		move_package_to_cart(game_objects[0], 0)

# Placeholder function to move package to cart
func move_package_to_cart(package: Package, _position: float):
	package.reparent(self, false)
	package.rotation_degrees = package.cart_rotation
	package.position = Vector3(0, package.cart_position.y, _position)
	pass


func add_radio(radio:RigidBody3D):
	var root = get_tree().root.get_child(1)
	root.remove_child(radio)
	radio_position.add_child(radio)
	radio.global_position = radio_position.global_position
	radio.set_gravity_scale(0)
	radio.attached_to_cart = true
	
func save():
	var save_dict = {
		"nodepath" : get_parent().name + "/" + name,
		"pos_x" : position.x, # Vector2 is not supported by JSON
		"pos_y" : position.y,
		"pos_z" : position.z,
		"rotation.y" : rotation.y,
	}
	return save_dict
