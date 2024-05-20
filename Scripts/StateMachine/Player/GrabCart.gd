extends State
class_name GrabCartState

@onready var head = get_parent().get_node("Head")
@onready var headbop_root = head.get_node("HeadbopRoot")
@onready var crosshair = headbop_root.get_node("Camera").get_node("Control").get_node("Crosshair")
@onready var mailcart = get_parent().get_parent().get_node("Mailcart")

var is_assuming_cart_position = true
var assuming_cart_lerp_factor = 0
var initial_cart_rotation = Vector3.ZERO
var initial_head_position = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	print("Grab Cart State Ready")
	crosshair.visible = false
	initial_cart_rotation = mailcart.rotation
	initial_head_position = head.position.y

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_pressed("drive"):
		is_assuming_cart_position = false
		change_state.call("walking")
	
func _physics_process(delta):
	# Mouse
	#if event is InputEventMouseMotion && !is_reading:
		#persistent_state.rotate_y(deg_to_rad(-event.relative.x * mouse_sense))
		#head.rotate_x(deg_to_rad(-event.relative.y * mouse_sense))
		#head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
		#get_viewport().set_input_as_handled()	

	if is_assuming_cart_position:
		var playerpos = mailcart.get_node("Node3D/Handlebar/PlayerPosition")
		var targetPosition = Vector3(playerpos.global_position.x, persistent_state.position.y, playerpos.global_position.z)
		var targetRotation = initial_cart_rotation + Vector3(0, 90, 0)
		var targetHeadPosition = initial_head_position - 0.15
		
		# Actual Lerps
		persistent_state.position = persistent_state.position.lerp(targetPosition, assuming_cart_lerp_factor)
		persistent_state.rotation = persistent_state.rotation.lerp(Vector3(0, mailcart.rotation.y + deg_to_rad(90), 0), assuming_cart_lerp_factor)
		#head.position = head.position.lerp(Vector3(initial_head_position.x, targetHeadPosition, initial_head_position.z), assuming_cart_lerp_factor)
		
		assuming_cart_lerp_factor += delta * 2.25
		if assuming_cart_lerp_factor > 1:
			is_assuming_cart_position = false
			change_state.call("carting")

