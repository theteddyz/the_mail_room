extends State
class_name CartingState

@onready var head = get_parent().get_node("Head")
@onready var headbop_root = head.get_node("HeadbopRoot")
@onready var crosshair = headbop_root.get_node("Camera").get_node("Control").get_node("Crosshair")
@onready var mailcart = get_parent().get_parent().get_node("Mailcart")

@export var cart_movement_lerp_speed = 3.85
@export var cart_sprinting_speed = 5.2
@export var cart_walking_speed = 3.8

#TODO: Un-link mouse-rotation when cart-movement is happening, input right and left should cause rotation

# Called when the node enters the scene tree for the first time.
func _ready():
	print("Carting State Ready")
	persistent_state.set_collision_mask_value(5, false)	
	mailcart.reparent(persistent_state, true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_pressed("drive"):
		releaseCart()
		
	persistent_state.move_and_slide()

func releaseCart():
	mailcart.reparent(persistent_state.get_parent())
	persistent_state.set_collision_mask_value(5, true)
	change_state.call("walking")

func _physics_process(delta):
		if Input.is_action_pressed("sprint"):
			current_speed = cart_sprinting_speed
		else: 
			current_speed = cart_walking_speed
		
		#var input_dir = Input.get_vector("left", "right", "forward", "backward")
		#direction = lerp(direction, (transform.basis * Vector3(input_dir.x * 0.2, 0, input_dir.y)).normalized(), delta * cart_movement_lerp_speed)
#
		#if direction:
			#velocity.x = direction.x * current_speed
			#velocity.z = direction.z * current_speed
		#else:
			#velocity.x = move_toward(velocity.x, 0, current_speed)
			#velocity.z = move_toward(velocity.z, 0, current_speed)

