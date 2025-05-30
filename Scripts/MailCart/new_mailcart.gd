extends RigidBody3D

var velocity_gain = 4.55 # "Kp" – Determines how fast the cart wants to move based on distance to the target
var force_gain = 5.25  # "Kd" – Determines how strongly the cart reacts to the difference between its actual and desired velocity
var game_objects:Array = []
var current_index:int = 0
var text_displayer:Node
var is_being_looked_at:bool = false
var gui_anim: Node
var unhighlight_lerp_speed:float = 8.2
var highlight_lerp_speed:float = 8.2

@onready var cart_move_audio: AudioStreamPlayer3D = $cart_move_audio
@onready var base_pitch = cart_move_audio.pitch_scale
@onready var basket = find_child("Basket")
@onready var player: CharacterBody3D = GameManager.get_player()
@onready var target: Marker3D = player.find_child("mailcart_target_position")
@onready var target_sprint: Marker3D = player.find_child("mailcart_target_position_sprint")

var is_grabbed = false
var is_weak_grabbed = false
var force := Vector3.ZERO
var target_position := Vector3.ZERO

func _ready():
	text_displayer = Gui.get_address_displayer()
	GameManager.register_mail_cart(self)
	gui_anim = Gui.get_control_displayer()
	text_displayer = Gui.get_address_displayer()
	EventBus.connect("object_looked_at",on_being_looked_at)
	EventBus.connect("no_object_found",not_being_looked_at)

func _process(delta):
	if !is_being_looked_at:
		lowerAllPackages(delta)
	else:
		mailcart_hover(delta)

func _input(event):
	if is_weak_grabbed:
		if event.is_action_released("interact"):
			is_weak_grabbed = false

func _physics_process(delta):
	if is_grabbed and player:
		if !cart_move_audio.playing:
			cart_move_audio.volume_db = -35
			cart_move_audio.playing = true
		_move_towards_target(delta)
		_rotate_towards_target(delta)
		adjust_volume_based_on_velocity(cart_move_audio, linear_velocity.length(), delta)
	elif is_weak_grabbed and player:
		if !cart_move_audio.playing:
			cart_move_audio.volume_db = -35
			cart_move_audio.playing = true
		_move_towards_target(delta)
		adjust_volume_based_on_velocity(cart_move_audio, linear_velocity.length(), delta)
		
	if !is_grabbed and !is_weak_grabbed:
		cart_move_audio.playing = false

func _move_towards_target(delta):
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var is_holding_forward := false
	if input_dir.y < 0:
		is_holding_forward = true
	var sprint_target_elegible_check = player.state.is_sprinting && is_holding_forward
	
	if player.state.is_sprinting != null && sprint_target_elegible_check:
		target_position = Vector3(target_sprint.global_position.x, global_position.y, target_sprint.global_position.z)
	else:
		target_position = Vector3(target.global_position.x, global_position.y, target.global_position.z)
	
	var player_velocity = player.get_real_velocity()
	
	var position_error := target_position - global_position
	
	# Optional: Exponential scaling for responsiveness, seperate the direction from the distance (length) and scale it
	var scaled_error := position_error.normalized() * pow(position_error.length(), 1.88)
	
	# PD control
	var desired_velocity = scaled_error * velocity_gain + (player_velocity * 0.75)
	var velocity_error = desired_velocity - linear_velocity
	var force = velocity_error * mass * force_gain # We add mass here to make this a mass-independant system
	apply_force(force * (0.23 if is_weak_grabbed else 1.0))

func _rotate_towards_target(delta):
	# Step 1: Get the yaw (Y-axis) angle to the target direction
	var target_forward = player.global_transform.basis.z
	var target_yaw = atan2(target_forward.x, target_forward.z)
	# Step 2: Get current yaw of the rigidbody
	var current_yaw = rotation.y
	# Step 3: Calculate the shortest angle difference
	var angle_diff = wrapf(target_yaw - current_yaw, -PI, PI)
	# Step 4: Calculate angular velocity to rotate toward target (tweak multiplier as needed)
	var rotation_speed = 3.15 # How fast to rotate toward target
	angular_velocity = Vector3.UP * angle_diff * rotation_speed

# Mailcart functionality unrelated to movement go BELOW here. Plz.
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

func lowerOtherPackages(delta):
	for index in game_objects.size():
		if index != current_index:
			var package = game_objects[index]
			package.position.y = lerp(package.position.y, package.cart_position.y, unhighlight_lerp_speed * delta)

func highlight_current_package(delta):
	game_objects[current_index].position.y = lerp(game_objects[current_index].position.y, 0.8, highlight_lerp_speed * delta)

func lowerAllPackages(delta):
	for index in game_objects.size():
		var package = game_objects[index]
		package.position.y = lerp(package.position.y, package.cart_position.y, unhighlight_lerp_speed * delta)

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
	if node == basket:
		is_being_looked_at = true

func not_being_looked_at(_node):
	if is_being_looked_at:
		gui_anim.show_icon(false)
		text_displayer.hide()
		is_being_looked_at = false

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

func perform_package_replacement(new_scene):
	var obj : Array[Package]
	for i in game_objects:
		var test_package = new_scene.find_child(i.name)
		if test_package != null:
			obj.append(test_package)
	
	for i in obj:
		i.queue_free()

func _on_basket_body_entered(body: Node3D) -> void:
	if body is Package and body.can_be_dropped_into_cart:
		body.can_be_dropped_into_cart = false
		add_package(body,false)

func adjust_volume_based_on_velocity(audio: AudioStreamPlayer3D, velocity: float, delta: float, max_velocity: float = 4.2,
		pitch_threshold: float = 6.0, 
		base_pitch: float = 0.83,
		max_pitch: float = 1.18,
		pitch_lerp_speed: float = 5.0):
	# Clamp velocity between 0 and max_velocity
	var clamped_velocity = clamp(abs(velocity), 0, max_velocity)
	
	# Normalize to a 0.0 - 1.0 range
	var normalized = clamped_velocity / max_velocity
	# Convert to decibels: range from -80 dB (silent) to 0 dB (full volume)
	# You can tweak the min dB to fit your needs
	var db_volume = lerp(-80.0, -3.81, normalized)
	# Set the volume
	audio.volume_db = db_volume
	
	# --- Pitch Control ---
	var target_pitch = base_pitch
	if abs(velocity) > pitch_threshold:
		# Only compute if range is valid
		var high_range_velocity = clamp((velocity - pitch_threshold) / (velocity - pitch_threshold + 1.5), 0.0, 1.0)
		target_pitch = lerp(base_pitch, max_pitch, high_range_velocity)
	# Lerp pitch smoothly over time
	audio.pitch_scale = lerp(audio.pitch_scale, target_pitch, delta * pitch_lerp_speed)
	#print(velocity)
	print(audio.pitch_scale)

func save():
	var save_dict = {
		"nodepath" : get_parent().name + "/" + name,
		"pos_x" : position.x, # Vector2 is not supported by JSON
		"pos_y" : position.y,
		"pos_z" : position.z,
		"rotation.y" : rotation.y,
	}
	return save_dict
