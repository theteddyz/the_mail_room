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
var package_material:MeshInstance3D
var shader_material
var text_displayer
var is_picked_up = false
var player: CharacterBody3D
var is_inspecting = false
var is_returning = false
var lerp_speed = 5.0
var inside_mail_cart:bool
var starting_path
var is_being_looked_at:bool
var can_be_dropped_into_cart:bool = true
var inspect_tween:Tween
var stop_inspect_tween:Tween
func _ready():
	package_material = get_child(0)
	starting_path =  get_parent().name + "/" + name
	player = get_parent().find_child("Player")
	text_displayer = Gui.get_address_displayer()
	EventBus.connect("object_looked_at",on_seen)
	EventBus.connect("no_object_found",on_unseen)

func on_seen(node):
	if node == self:
		is_being_looked_at = true

func on_unseen(_node):
	if is_being_looked_at:
		is_being_looked_at = false

func _process(delta):
	if is_being_looked_at:
		highlight(delta)
	else:
		reset_highlight()


func _on_object_hovered(node):
	if node == self:
		is_being_looked_at = true

func _on_object_unhovered(_node):
	is_being_looked_at = false


func interact():
	grabbed()

func highlight(_delta):
	if !is_inspecting:
		is_being_looked_at = true
		if shader_material == null:
			shader_material = package_material.material_overlay.duplicate()
			package_material.material_overlay = shader_material
			package_material.material_overlay.set_shader_parameter("outline_width",5)
		else:
			package_material.material_overlay.set_shader_parameter("outline_width",5)

func reset_highlight():
	if shader_material:
		package_material.material_overlay.set_shader_parameter("outline_width", 0)
func grabbed():
	if player:
		var package_holder = player.find_child("PackageHolder")
		reparent(player.find_child("PackageHolder"))
	else :
		player = GameManager.get_player()
		var package_holder = player.find_child("PackageHolder")
		reparent(package_holder, false)
	EventBus.emitCustomSignal("object_held", [self.mass,self])
	position = hand_position
	rotation = hand_rotation
	self.freeze = true
	await get_tree().create_timer(2.0).timeout
	can_be_dropped_into_cart = true

func dropped():
	if is_inspecting or is_returning:
		if inspect_tween != null:
			inspect_tween.kill()
		if stop_inspect_tween != null:
			stop_inspect_tween.kill()
		is_inspecting = false
		is_returning = false
		self.linear_velocity = Vector3.ZERO 
		self.angular_velocity = Vector3.ZERO
		self.freeze = false
		reparent(player.get_parent(), true)
		EventBus.emitCustomSignal("dropped_object",[self.mass,self])
	else:
		is_inspecting = false
		is_returning = false
		self.freeze = false
		reparent(player.get_parent(), true)
		EventBus.emitCustomSignal("dropped_object",[self.mass,self])

func inspect():
	var _s
	is_inspecting = true
	is_returning = false
	inspect_tween = create_tween()
	inspect_tween.tween_property(self, "position",inspect_position, 0.25).set_ease(Tween.EASE_IN_OUT)
	inspect_tween.set_parallel(true)
	inspect_tween.tween_property(self, "rotation",inspect_rotation, 0.25).set_ease(Tween.EASE_IN_OUT)
	await inspect_tween.finished
	highlight(_s)
	show_label(package_full_address)

func stop_inspect():
	is_returning = true
	is_inspecting = false
	hide_label()
	stop_inspect_tween = create_tween()
	stop_inspect_tween.tween_property(self, "position",hand_position, 0.25).set_ease(Tween.EASE_IN_OUT)
	stop_inspect_tween.set_parallel(true)
	stop_inspect_tween.tween_property(self, "rotation",hand_rotation, 0.25).set_ease(Tween.EASE_IN_OUT)
	await stop_inspect_tween.finished
	reset_highlight()
	

func hide_label():
	text_displayer.hide_text()

func show_label(text:String):
	text_displayer.show_text()
	text_displayer.set_text(text)

func save():
	if !inside_mail_cart:
		var save_dict = {
		"nodepath" : get_parent().name + "/" + name,
		"pos_x" : position.x, # Vector2 is not supported by JSON
		"pos_y" : position.y,
		"pos_z" : position.z,
		"rotation.y" : rotation.y,
		"inside_mail_cart":inside_mail_cart
		}
		return save_dict
	else:
		var save_dict = {
		"nodepath" : starting_path,
		"pos_x" : cart_position.x, # Vector2 is not supported by JSON
		"pos_y" : cart_position.y,
		"pos_z" : cart_position.z,
		"rotation.y" : rotation.y,
		"inside_mail_cart":inside_mail_cart,
		}
		return save_dict
	
