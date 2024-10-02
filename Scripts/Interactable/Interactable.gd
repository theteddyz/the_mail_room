extends Node3D
class_name Interactable
@export_enum("grab", "light", "deliverable","key","tape") var icon_type: String = "grab"
# Overridable function used for typing
func interact():
	print("CLICKED")
