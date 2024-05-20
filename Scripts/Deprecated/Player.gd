extends CharacterBody3D



#UI Nodes
@onready var pause_menu = $"../GUI/pauseMenu"
#Need this to check for the item reader so we cannot move the head

@export var mailcart: Node

# Speed variables
@export var jump_velocity = 4.5 

@export var cart_movement_lerp_speed = 3.85
@export var cart_sprinting_speed = 5.2
@export var cart_walking_speed = 3.8

# Privates


func _ready():
	#TODO: Continue from here
	
func driveCart():
	crosshair.visible = false
	driving = true
	is_assuming_cart_position = true
	
func releaseCart():
	driving = false
	mailcart.reparent(get_parent())
	set_collision_mask_value(5, true)
	

func _input(event):
	






func regularMove(delta):
	
	# Input / State checks
	if(Input.is_action_pressed("crouch")):
		standing_collision_shape.disabled = true
		crouching_collision_shape.disabled = false
		current_speed = crouching_speed
		head.position.y = lerp(head.position.y, crouching_depth, crouching_lerp_speed)
		head_bopping_current = head_bopping_crouching_intensity
		head_bopping_index += head_bopping_crouching_speed * delta
	else:
		# if standing would collide
		if !standing_is_blocked:
			standing_collision_shape.disabled = false
			crouching_collision_shape.disabled = true
			head.position.y = lerp(head.position.y, starting_height, crouching_lerp_speed)
			if Input.is_action_pressed("sprint"):
				current_speed = sprinting_speed
				head_bopping_current = head_bopping_sprinting_intensity
				head_bopping_index += head_bopping_sprinting_speed * delta
			else:
				current_speed = walking_speed
				head_bopping_current = head_bopping_walking_intensity
				head_bopping_index += head_bopping_walking_speed * delta

func cartMove(delta):
	if is_assuming_cart_position:
		var playerpos = mailcart.get_node("Node3D/Handlebar/PlayerPosition")
		var targetPosition = Vector3(playerpos.global_position.x, position.y, playerpos.global_position.z)
		position = position.lerp(targetPosition, assuming_cart_lerp_factor)
		assuming_cart_lerp_factor += delta * 2.25
		if assuming_cart_lerp_factor > 1:
			mailcart.reparent(self, true)
			set_collision_mask_value(5, false)
			is_assuming_cart_position = false
			assuming_cart_lerp_factor = 0
	else: 
		# Release the cart if we are driving it
		if Input.is_action_pressed("drive") and driving:
			releaseCart()
			
		if Input.is_action_pressed("sprint"):
			current_speed = cart_sprinting_speed
		else: 
			current_speed = cart_walking_speed
		
		# Add the gravity.
		if not is_on_floor():
			velocity.y -= gravity * delta
		
		var input_dir = Input.get_vector("left", "right", "forward", "backward")
		direction = lerp(direction, (transform.basis * Vector3(input_dir.x * 0.2, 0, input_dir.y)).normalized(), delta * cart_movement_lerp_speed)

		if direction:
			velocity.x = direction.x * current_speed
			velocity.z = direction.z * current_speed
		else:
			velocity.x = move_toward(velocity.x, 0, current_speed)
			velocity.z = move_toward(velocity.z, 0, current_speed)
		
		move_and_slide()
