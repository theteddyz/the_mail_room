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
var rb_controller = preload("res://Scenes/Prefabs/MoveableObjects/rb_enabler.tscn")
var enabler
#@export var special_object:bool = false
func _ready():
	#enabler = rb_controller.instantiate()
	#add_child(enabler)
	#enabler.setup()
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	connect("body_entered",Callable(self,"unfreeze_object"))
	freeze = false
	await get_tree().create_timer(3.0).timeout
	freeze = true

func _physics_process(delta: float) -> void:
	if should_freeze and freeze == false:
		if GrabbingManager.current_grabbed_object != self:
			if linear_velocity.length() < 0.001 and angular_velocity.length() < 0.001:
				freeze = true
			
func unfreeze_object(col):
	if col is RigidBody3D:
		if "grab_type" in col:
			if !col.should_freeze:
				var current_parent = col.get_parent()
				col.freeze = false
				for body in get_colliding_bodies():
					if body is RigidBody3D:
						freeze = false
 
