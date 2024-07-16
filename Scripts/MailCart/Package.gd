extends Interactable
class_name Package

@export var package_address: String = ""
@export var drop_time_threshold: float = 0.5
@export var regrab_cooldown: float = 0.5
@export var cart_rotation = Vector3.ZERO
@export var cart_position = Vector3.ZERO
@export var hand_rotation = Vector3.ZERO
@export var hand_position = Vector3.ZERO
@export var delivered_rotation = Vector3.ZERO
@export var delivered_position = Vector3.ZERO
@export var package_num:int = 0

var is_picked_up = false
var playerHead
var player: CharacterBody3D

func _ready():
	print(get_parent())
	player = get_parent().find_child("Player")

func interact():
	player.state.grabbed_package(self)

func drop():
	pass
		
func update_position(delta):
	pass
