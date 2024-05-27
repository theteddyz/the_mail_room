extends Interactable
class_name Package

@export var drop_time_threshold: float = 0.5
@export var regrab_cooldown: float = 0.5
@export var cart_rotation = Vector3.ZERO
@export var cart_position = Vector3.ZERO
var is_picked_up = false
var itemPos
var playerHead
var player: CharacterBody3D

func _ready():
	player = get_parent().find_child("Player")
	itemPos = player.find_child("PackageHolder")

func interact():
	player.state.grabbed_package(self)

func drop():
	pass
		
func update_position(delta):
	pass
