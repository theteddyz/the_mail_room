extends State
class_name CartingState

@onready var head = get_parent().get_node("Head")
@onready var headbop_root = head.get_node("HeadbopRoot")
@onready var crosshair = headbop_root.get_node("Camera").get_node("Control").get_node("Crosshair")
@onready var mailcart = get_parent().get_parent().get_node("Mailcart")

@export var cart_movement_lerp_speed = 3.85
@export var cart_sprinting_speed = 5.2
@export var cart_walking_speed = 3.8
@export var cart_turning_speed_modifier = 0.15

var directionX = Vector3.ZERO
var directionZ = Vector3.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	print("Carting State Ready")
	mailcart.reparent(persistent_state, true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_pressed("drive"):
		releaseCart()
		
	persistent_state.move_and_slide()

func releaseCart():
	mailcart.reparent(persistent_state.get_parent())
	persistent_state.set_collision_mask_value(5, true)
	head.position = Vector3(0, 1.8, 0)
	change_state.call("walking")

func _physics_process(delta):
		if Input.is_action_pressed("sprint"):
			current_speed = cart_sprinting_speed
		else: 
			current_speed = cart_walking_speed
		
		var input_dir_steering = Input.get_axis("left", "right")
		var input_dir_acceleration = Input.get_axis("forward", "backward")
		var turning_delta = min(abs(persistent_state.velocity.x), 2.75)
		
		directionX = lerp(directionX, Vector3(input_dir_acceleration, 0, 0).normalized(), delta * cart_movement_lerp_speed)
		directionZ = lerp(directionZ, Vector3(0, 0, input_dir_steering * turning_delta * cart_turning_speed_modifier), delta * cart_movement_lerp_speed)
		
		if directionX or directionZ:
			persistent_state.velocity.x = directionX.x * current_speed
			persistent_state.velocity.z = -directionZ.z * current_speed
		else:
			persistent_state.velocity.x = move_toward(persistent_state.velocity.x, 0, current_speed)
			persistent_state.velocity.z = move_toward(persistent_state.velocity.z, 0, current_speed)

