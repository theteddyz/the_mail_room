extends Node
#This holds data to refrence
@export var should_freeze:bool = false
@export_enum("grab", "light", "package") var icon_type: int
@export_enum("dynamic","door","drawer") var grab_type:int
#@export_enum("monitor","desk1","desk2","mouse","chair","lamp","mailbox","bin","keyboard") var object_name:String
@export var modified:bool = false
@export var on_screen:bool = false
@export var is_door:bool = false
####only needed if this is a door or drawer
@export var open_sound: AudioStreamPlayer3D
@export var close_sound: AudioStreamPlayer3D
@export var loop_sound: AudioStreamPlayer3D
####
var frozen:bool = true
var freeze_timer_started: bool = false
var freeze_timer_ref: SceneTreeTimer = null
#@export var special_object:bool = false
## Weird fix needed so it knows its attached to a rigidbody
var self_body
func _ready():
	#enabler = rb_controller.instantiate()
	#add_child(enabler)
	#enabler.setup()
	self_body = self
	var layers = [1, 2, 3, 4, 13,15]
	for layer in layers:
		self_body.set_collision_mask_value(layer, true)
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	connect("body_entered",Callable(self,"unfreeze_object"))
	EventBus.connect("toggle_shadow_on_dynamic_objects",Callable(self,"toggle_shadows"))
	self_body.freeze = false
	await get_tree().create_timer(3.0).timeout
	self_body.freeze = true
	self_body.contact_monitor = true
	self_body.set_max_contacts_reported(1)
	set_physics_process(false)
	set_process(false)


func toggle_shadows(b: bool):
	for child in get_children():
		if child is MeshInstance3D:
			child.set_cast_shadows_setting(b) 
			for child2 in child.get_children():
				if child2 is MeshInstance3D:
					child2.set_cast_shadows_setting(b) 



func start_freeze_timer():
	if !freeze_timer_started and GrabbingManager.current_grabbed_object != self:
		freeze_timer_started = true
		freeze_timer_ref = get_tree().create_timer(100.0)
		await freeze_timer_ref.timeout
		if self_body.linear_velocity.length() < 0.00001 and self_body.angular_velocity.length() < 0.00001 and self_body.get_contact_count() > 0:
			
			self_body.freeze = true
			frozen = true
		freeze_timer_started = false

func unfreeze():
	self_body.freeze = false
	frozen = false
	stop_freeze_timer()
	start_freeze_timer()

func stop_freeze_timer():
	freeze_timer_ref = null
	freeze_timer_started = false

func _physics_process(delta: float) -> void:
	if should_freeze and not frozen:
		if GrabbingManager.current_grabbed_object != self:
			if self_body.linear_velocity.length() < 0.001 and self_body.angular_velocity.length() < 0.001:
				if not freeze_timer_started:
					start_freeze_timer()
			else:
				stop_freeze_timer()
func unfreeze_object(col):
	if col is RigidBody3D:
		if "grab_type" in col:
			if grab_type == 1:
				var current_parent = col.get_parent()
				col.freeze = false
				for body in self_body.get_colliding_bodies():
					if body is RigidBody3D:
						#body.apply_impulse(Vector3(0,430,0))
						body.freeze = false
			else:
				if !col.should_freeze:
					var current_parent = col.get_parent()
					col.freeze = false
					for body in self_body.get_colliding_bodies():
						if body is RigidBody3D:
							body.freeze = false
 
