extends Node
#This holds data to refrence
@export var should_freeze:bool = false
@export_enum("grab", "light", "package") var icon_type: String = "grab"
@export_enum("dynamic","door","drawer") var grab_type:String = "dynamic"

func _ready():
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
