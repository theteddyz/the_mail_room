extends RigidBody3D
#This holds data to refrence
@export var should_freeze:bool = false
@export_enum("grab", "light", "package") var icon_type: String = "grab"
@export_enum("dynamic","door","drawer") var grab_type:String = "dynamic"
var rb_controller = preload("res://Scenes/Prefabs/MoveableObjects/rb_enabler.tscn")
var enabler
func _ready():
	enabler = rb_controller.instantiate()
	add_child(enabler)
	enabler.setup()
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	connect("body_entered",Callable(self,"unfreeze_object"))



func unfreeze_object(col):
	if col is RigidBody3D:
		if "grab_type" in col:
			if !col.should_freeze:
				col.freeze = false
 
