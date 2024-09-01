extends State
class_name GrabCartState

@onready var neck = get_parent().get_node("Neck")
@onready var head = neck.get_node("Head")
@onready var headbop_root = head.get_node("HeadbopRoot")
@onready var mailcart

var assuming_cart_lerp_factor = 0
var initial_cart_rotation = Vector3.ZERO
var initial_head_position = 0
var playerpos = Vector3.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	mailcart = GameManager.get_mail_cart()
	print("Grab Cart State Ready")
	playerpos = mailcart.get_node("Node3D").get_node("Handlebar").get_node("PlayerPosition")
	mailcart.get_node("Node3D").get_node("Handlebar").set_collision_layer_value(2, false)
	#mailcart.set_collision_mask_value(3, false)
	persistent_state.set_collision_layer_value(3, false)
	initial_cart_rotation = mailcart.rotation
	initial_head_position = neck.position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var targetPosition = Vector3(playerpos.global_position.x, persistent_state.position.y, playerpos.global_position.z)
	#var targetRotation = initial_cart_rotation 
	var targetHeadPosition = initial_head_position.y - 0.05
	
	# Actual Lerps
	persistent_state.position = persistent_state.position.lerp(targetPosition, assuming_cart_lerp_factor)
	persistent_state.rotation = persistent_state.rotation.lerp(Vector3(0, mailcart.rotation.y, 0), assuming_cart_lerp_factor)
	neck.position = neck.position.lerp(Vector3(initial_head_position.x, targetHeadPosition, initial_head_position.z), assuming_cart_lerp_factor)
	
	assuming_cart_lerp_factor += delta * 2.25
	if assuming_cart_lerp_factor > 1:
		#persistent_state.set_collision_layer_value(3, true)
		persistent_state.velocity = Vector3.ZERO
		change_state.call("carting")
