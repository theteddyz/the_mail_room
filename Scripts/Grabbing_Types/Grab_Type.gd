extends RigidBody3D
#This holds data to refrence
@export var should_freeze:bool = false
@export_enum("grab", "light", "package") var icon_type: String = "grab"
@export_enum("dynamic","door","drawer") var grab_type:String = "dynamic"
#@export_enum("monitor","desk1","desk2","mouse","chair","lamp","mailbox","bin","keyboard") var object_name:String
@export var modified:bool = false
@export var on_screen:bool = false
####only needed if this is a door or drawer
@export var open_sound: AudioStreamPlayer3D
@export var close_sound: AudioStreamPlayer3D
@export var loop_sound: AudioStreamPlayer3D
####
var frozen:bool = true
var freeze_timer_started: bool = false
var freeze_timer_ref: SceneTreeTimer = null
#@export var special_object:bool = false
func _ready():
	#enabler = rb_controller.instantiate()
	#add_child(enabler)
	#enabler.setup()
	var layers = [1, 2, 3, 4, 13]
	for layer in layers:
		set_collision_mask_value(layer, true)
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	connect("body_entered",Callable(self,"unfreeze_object"))
	freeze = false
	await get_tree().create_timer(3.0).timeout
	freeze = true
	contact_monitor = true
	set_max_contacts_reported(1)

func start_freeze_timer():
	if !freeze_timer_started:
		freeze_timer_started = true
		freeze_timer_ref = get_tree().create_timer(10.0)
		await freeze_timer_ref.timeout
		if linear_velocity.length() < 0.001 and angular_velocity.length() < 0.001 and get_contact_count() > 0:
			
			freeze = true
			frozen = true
		freeze_timer_started = false

func unfreeze():
	freeze = false
	frozen = false
	stop_freeze_timer()
	start_freeze_timer()

func stop_freeze_timer():
	freeze_timer_ref = null
	freeze_timer_started = false

func _physics_process(delta: float) -> void:
	if should_freeze and not frozen:
		if GrabbingManager.current_grabbed_object != self:
			if linear_velocity.length() < 0.001 and angular_velocity.length() < 0.001:
				if not freeze_timer_started:
					start_freeze_timer()
			else:
				stop_freeze_timer()
func unfreeze_object(col):
	if col is RigidBody3D:
		if "grab_type" in col:
			if !col.should_freeze:
				var current_parent = col.get_parent()
				col.freeze = false
				for body in get_colliding_bodies():
					if body is RigidBody3D:
						freeze = false
 
#func get_relative_position_along_joint_axis() -> float:
	## Get the transform of body_a (the reference body)
	#var body_a_transform = body_a.global_transform
#
	## Get the transform of body_b (the moving body)
	#var body_b_transform = body_b.global_transform
#
	## Calculate the vector from body_a to body_b
	#var relative_position_vector = body_b_transform.origin - body_a_transform.origin
#
	## Get the joint axis in the local space of body_a (assuming the joint's local Z-axis)
	##var joint_axis_local = Vector3(0, 0, 1)  # This is usually the local Z-axis of the joint
#
	## Transform the local joint axis to the global space using body_a's basis
	#var joint_axis_global = body_a_transform.basis * joint_axis_local
#
	## Project the relative position vector onto the joint axis to get the scalar position
	#var relative_position = relative_position_vector.dot(joint_axis_global.normalized())
#
	#return relative_position
