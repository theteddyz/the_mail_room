extends RigidBody3D
class_name Grabbable
@export_enum("grab", "light", "package") var icon_type: String = "grab"

func interact():
	print("CLICKED")
