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
@export var inspect_position = Vector3.ZERO
@export var inspect_rotation = Vector3.ZERO
@export var package_num:int = 0
var text_displayer
var is_picked_up = false
var playerHead
var player: CharacterBody3D
var is_inspecting = false
var is_returning = false
var lerp_speed = 2.0
func _ready():
	player = get_parent().find_child("Player")
	text_displayer = Gui.get_address_displayer()

func _process(delta):
	if is_inspecting:
		
		position = position.lerp(inspect_position, lerp_speed * delta)
		rotation = rotation.lerp(inspect_rotation, lerp_speed * delta)
		if position.distance_to(inspect_position) < 0.1 and rotation.distance_to(inspect_rotation) < 0.1:
			is_inspecting = false
			show_label(package_full_address)
	elif is_returning:
		hide_label()
		position = position.lerp(hand_position, lerp_speed * delta)
		rotation = rotation.lerp(hand_rotation, lerp_speed * delta)
		if position.distance_to(hand_position) < 0.01 and rotation.distance_to(hand_rotation) < 0.01:
			is_returning = false
	

func interact():
	grabbed()


func grabbed():
	reparent(player.find_child("PackageHolder"), false)
	EventBus.emitCustomSignal("object_held", [self.mass,self])
	position = hand_position
	rotation = hand_rotation
	self.freeze = true

func dropped():
	if is_inspecting or is_returning:
		self.linear_velocity = Vector3.ZERO 
		self.angular_velocity = Vector3.ZERO
		is_inspecting = false
		is_returning = false
	self.freeze = false
	reparent(player.get_parent(), true)
	EventBus.emitCustomSignal("dropped_object",[self.mass,self])

func inspect():
	is_inspecting = true
	is_returning = false

func stop_inspect():
	is_returning = true
	is_inspecting = false

func hide_label():
	text_displayer.hide_text()

func show_label(text:String):
	text_displayer.show_text()
	text_displayer.set_text(text)
