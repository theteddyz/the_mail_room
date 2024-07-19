extends Interactable
class_name Package

@export_multiline var package_full_address: String = ""
@export_multiline var package_partial_address: String = ""
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
	player = get_parent().find_child("Player")

func interact():
	grabbed()


func grabbed():
	reparent(player.find_child("PackageHolder"), false)
	EventBus.emitCustomSignal("object_held", [self.mass,self])
	position = hand_position
	rotation = hand_rotation
	self.freeze = true

func dropped():
	self.freeze = false
	reparent(player.get_parent(), true)
	EventBus.emitCustomSignal("dropped_object",[self.mass,self])
