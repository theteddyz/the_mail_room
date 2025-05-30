extends Node3D

# Array to hold game objects
var game_objects:Array = []
var player:CharacterBody3D

# Pointer to track the current index in the game_objects array
var current_index:int = 0
var text_displayer:Node
# If we want to highlight packages
var is_being_looked_at:bool = false
var highlight_lerp_speed:float = 8.2
var unhighlight_lerp_speed:float = 8.2
var gui_anim
func _ready():
	# Initialize the array with game objects if needed
	# For example, game_objects.append(some_game_object)
	GameManager.register_mail_cart(self)
	is_being_looked_at = false
	player = GameManager.get_player()
	text_displayer = Gui.get_address_displayer()
	gui_anim = Gui.get_control_displayer()
	EventBus.connect("object_looked_at",on_being_looked_at)
	EventBus.connect("no_object_found",not_being_looked_at)
	# Single handedly the most retarded line of code, who the fuck wrote this
	#self.angular_velocity.y = 1.5
func _process(delta):
	if !is_being_looked_at:
		lowerAllPackages(delta)
	else:
		mailcart_hover(delta)
func mailcart_hover(delta):
	if game_objects.size() != 0:
		gui_anim.show_icon(true)
		highlight_current_package(delta)
		text_displayer.show_text()
		text_displayer.set_text(game_objects[current_index].package_partial_address)
		lowerOtherPackages(delta)
	else:
		gui_anim.show_icon(false)
		lowerAllPackages(delta)
func highlight_current_package(delta):
	game_objects[current_index].position.y = lerp(game_objects[current_index].position.y, 0.8, highlight_lerp_speed * delta)

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

# Function to scroll the package down
func scroll_package_down():
	if game_objects.size() != 0:
		if current_index > 0:
			current_index -= 1
		else:
			current_index = game_objects.size() - 1

# Function to grab the current package
func grab_current_package():
	if game_objects.size() > 0:
		var current_package = game_objects[current_index]
		game_objects.remove_at(current_index)
		current_index = 0
		current_package.set_collision_layer_value(2,true)
		current_package.set_collision_layer_value(7,true)
		current_package.set_collision_mask_value(1,true)
		current_package.set_collision_mask_value(2,true)
		current_package.set_collision_mask_value(3,true)
		current_package.set_collision_mask_value(4,true)
		current_package.inside_mail_cart = false
		current_package.grabbed()
		text_displayer.hide_text()
		if game_objects.size() > 0:
			calculate_spacing() 
		#current_package.reparent(player, false)
	else:
		print("No packages to grab")

# Function to add a package to the game_objects array
func add_package(package: Package,dropped:bool):
		if !game_objects.has(package):
			package.global_position = Vector3.ZERO
			package.global_rotation = Vector3.ZERO
			package.inside_mail_cart = true
			package.can_be_dropped_into_cart = false
			package.set_collision_mask(0)
			package.set_collision_layer(0)
			game_objects.append(package)
			if dropped:
				EventBus.emitCustomSignal("dropped_object", [0,package])
			sort_packages_by_order()
			calculate_spacing()

func calculate_spacing():
	# Calculate the spacing
	var total_packages = game_objects.size()
	if total_packages > 1:
		var step = 1.1 / (total_packages - 1)  # Total range is 1.5 (from 0.75 to -0.75)
		for i in range(total_packages):
			var _position = 0.45 - i * step
			move_package_to_cart(game_objects[i], _position)
	else:
		if total_packages > 0:
			move_package_to_cart(game_objects[0], 0)

# Placeholder function to move package to cart
func move_package_to_cart(package: Package, _position: float):
	if package.get_parent() != self:
		package.reparent(self)
	package.rotation_degrees = package.cart_rotation
	package.position = Vector3(0, package.cart_position.y, _position)
	package.set_freeze_enabled(true)
	package.set_sleeping(true)

func on_being_looked_at(node):
	if node == self:
		is_being_looked_at = true

func not_being_looked_at(_node):
	if is_being_looked_at:
		gui_anim.show_icon(false)
		text_displayer.hide()
		is_being_looked_at = false

func perform_package_replacement(new_scene):
	var obj : Array[Package]
	for i in game_objects:
		var test_package = new_scene.find_child(i.name)
		if test_package != null:
			obj.append(test_package)
	
	for i in obj:
		i.queue_free()
		
func save():
	var save_dict = {
		"nodepath" : get_parent().name + "/" + name,
		"pos_x" : position.x, # Vector2 is not supported by JSON
		"pos_y" : position.y,
		"pos_z" : position.z,
		"rotation.y" : rotation.y,
	}
	return save_dict


func _on_area_3d_body_entered(body):
	print(body)
	if body is Package and body.can_be_dropped_into_cart:
		body.can_be_dropped_into_cart = false
		add_package(body,false)
