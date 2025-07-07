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
@export var min_distance_to_player: float = 10.0
@export var is_picked_up = false
var is_being_tracked
var package_material:MeshInstance3D
var shader_material
var text_displayer

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
var should_freeze = true
var package_holder: Node3D
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
var hint_controller 

func _ready():
	#top_level = true
	package_material = get_child(0)
	starting_path =  get_parent().name + "/" + name
	player = get_parent().find_child("Player")
	package_holder = player.find_child("PackageHolder")
	text_displayer = Gui.get_address_displayer()
	EventBus.connect("object_looked_at",on_seen)
	EventBus.connect("no_object_found",on_unseen)
	hint_controller = Gui.get_hint_controller()

func on_seen(node):
	if node == self:
		is_being_looked_at = true

func on_unseen(_node):
	if is_being_looked_at:
		is_being_looked_at = false

func expDecay(a:float, b:float, decay:float, dt:float):
	return b + (a - b) * exp(-decay * dt)

func _process(delta):
	
	if is_being_looked_at:
		highlight(delta)
	else:
		reset_highlight()
		
	#if not package_holder:
		#push_error("package_holder is null!")
		#return
	
		##var parent_transform = player.global_transform
#
		## Apply rotation offset first if needed
		##var rotated_offset = player.basis * hand_position
	#if is_picked_up and !is_inspecting:
		## Create a rotation basis from the Euler angles
		#var hand_basis = Basis.from_euler(hand_rotation)
#
		## Create a Transform3D using the hand's local rotation and position
		#var hand_transform = Transform3D(hand_basis, hand_position)
#
		## Combine the global transform of the package_holder with the local hand transform
		#var target_transform = package_holder.get_global_transform_interpolated() * hand_transform
#
		## --- Smooth interpolation ---
#
		## Interpolate position
		##global_position.x = expDecay(global_position.x, package_holder.get_global_transform_interpolated().origin.x, 16.0, delta);
		##global_position.y = expDecay(global_position.y, package_holder.get_global_transform_interpolated().origin.y, 16.0, delta);
		##global_position.z = expDecay(global_position.z, package_holder.get_global_transform_interpolated().origin.z, 16.0, delta);
#
		#var global_transform_2 = package_holder.global_transform * hand_transform
		#global_position = global_transform_2.origin
#
		## Interpolate rotation using Quat.slerp()
		#var current_quat = Quaternion(global_transform.basis).normalized()
		#var target_quat = Quaternion(target_transform.basis).normalized()
#
		#var slerped_quat = current_quat.slerp(target_quat, min(delta*20,1))
#
		## Or if you're manually managing transforms:
		#global_transform.basis = Basis(slerped_quat)
	#if is_picked_up and is_inspecting:
		## Create a rotation basis from the Euler angles
		#var inspect_basis = Basis.from_euler(inspect_rotation)
#
		## Create a Transform3D using the hand's local rotation and position
		#var inspect_transform = Transform3D(inspect_basis, inspect_position)
#
		## Combine the global transform of the package_holder with the local hand transform
		#var target_transform = package_holder.global_transform * inspect_transform
#
		## --- Smooth interpolation ---
#
		## Interpolate position
		##global_position.x = expDecay(global_position.x, package_holder.get_global_transform_interpolated().origin.x, 16.0, delta);
		##global_position.y = expDecay(global_position.y, package_holder.get_global_transform_interpolated().origin.y, 16.0, delta);
		##global_position.z = expDecay(global_position.z, package_holder.get_global_transform_interpolated().origin.z, 16.0, delta);
#
		#var global_transform_2 = package_holder.global_transform * inspect_transform
		#global_position = global_transform_2.origin
#
		## Interpolate rotation using Quat.slerp()
		#var current_quat = Quaternion(global_transform.basis).normalized()
		#var target_quat = Quaternion(target_transform.basis).normalized()
#
		#var slerped_quat = current_quat.slerp(target_quat, min(delta*20,1))
#
		## Or if you're manually managing transforms:
		#global_transform.basis = Basis(slerped_quat)



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
	is_picked_up = true
	hint_controller.display_hint("inspect",3)
	if is_being_tracked:
		var pager = Gui.get_pager()
		pager.remove_package(self)
		is_being_tracked = false
	if player:
		# this here broke once upon a time, but please do NOT try to reapply the packageholder variable here, it doesnt always find itself, for whatever reason. Use specific 
		# and clean code if you do. No find child bs
		assert(package_holder != null, "THIS SHOULD NEVER OCCUR; PACKAGEHOLDER HAS DISSAPEARED? FIGURE OUT WHY ASAP")
		reparent(package_holder)
	else :
		player = GameManager.get_player()
		package_holder = player.find_child("PackageHolder")
		reparent(package_holder, false)
	EventBus.emitCustomSignal("object_held", [self.mass,self])
	position = hand_position
	rotation = hand_rotation
	self.freeze = true
	collision_shape_3d.set_disabled(true)
	await get_tree().create_timer(2.0).timeout
	can_be_dropped_into_cart = false

func dropped():
	is_picked_up = false
	collision_shape_3d.set_disabled(false)
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
		check_distance_to_player()
	else:
		is_inspecting = false
		is_returning = false
		self.freeze = false
		reparent(player.get_parent(), true)
		EventBus.emitCustomSignal("dropped_object",[self.mass,self])
		check_distance_to_player()

func inspect():
	var _s
	is_inspecting = true
	is_returning = false
	inspect_tween = create_tween()
	inspect_tween.tween_property(self, "position",inspect_position, 0.25).set_ease(Tween.EaseType.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	inspect_tween.set_parallel(true)
	inspect_tween.tween_property(self, "rotation",inspect_rotation, 0.25).set_ease(Tween.EaseType.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	await inspect_tween.finished
	highlight(_s)
	show_label(package_full_address)

func stop_inspect():
	is_returning = true
	is_inspecting = false
	hide_label()
	stop_inspect_tween = create_tween()
	stop_inspect_tween.tween_property(self, "position",hand_position, 0.25).set_ease(Tween.EaseType.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	stop_inspect_tween.set_parallel(true)
	stop_inspect_tween.tween_property(self, "rotation",hand_rotation, 0.25).set_ease(Tween.EaseType.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	await stop_inspect_tween.finished
	reset_highlight()
	is_returning = false
	

func check_distance_to_player():
	if !is_being_tracked and !inside_mail_cart:
		var distance = global_transform.origin.distance_to(player.global_transform.origin)
		if distance > min_distance_to_player:
			var pager = Gui.get_pager()
			pager.add_package_to_queue(self)
			is_being_tracked = true
		else:
			await get_tree().create_timer(1.0).timeout
			check_distance_to_player()

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
	
