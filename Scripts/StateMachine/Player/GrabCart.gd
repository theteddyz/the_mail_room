extends State
class_name GrabCartState

@onready var neck = get_parent().get_node("Neck")
@onready var head = neck.get_node("Head")
@onready var headbop_root = head.get_node("HeadbopRoot")
@onready var mailcart

var is_assuming_cart_position = true
var assuming_cart_lerp_factor = 0
var initial_cart_rotation = Vector3.ZERO
var initial_head_position = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	mailcart = GameManager.get_mail_cart()
	print("Grab Cart State Ready")
	mailcart.reparent(persistent_state.get_parent())
	initial_cart_rotation = mailcart.rotation
	initial_head_position = neck.position
	persistent_state.set_collision_mask_value(5, false)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_assuming_cart_position:
		var playerpos = mailcart.get_node("Node3D/Handlebar/PlayerPosition")
		var targetPosition = Vector3(playerpos.global_position.x, persistent_state.position.y, playerpos.global_position.z)
		#var targetRotation = initial_cart_rotation 
		var targetHeadPosition = initial_head_position.y - 0.15
		
		# Actual Lerps
		persistent_state.position = persistent_state.position.lerp(targetPosition, assuming_cart_lerp_factor)
		persistent_state.rotation = persistent_state.rotation.slerp(Vector3(0, mailcart.rotation.y, 0), assuming_cart_lerp_factor)
		neck.position = neck.position.lerp(Vector3(initial_head_position.x, targetHeadPosition, initial_head_position.z), assuming_cart_lerp_factor)
		
		assuming_cart_lerp_factor += delta * 2.25
		if assuming_cart_lerp_factor > 1:
			persistent_state.velocity = Vector3.ZERO
			is_assuming_cart_position = false
			change_state.call("carting")
	
	
	#if Input.is_action_pressed("drive"):
		#is_assuming_cart_position = false
		#neck.position.y = initial_head_position.y
		#persistent_state.set_collision_mask_value(5, true)	
		#change_state.call("walking")
	
#func _physics_process(delta):
	

