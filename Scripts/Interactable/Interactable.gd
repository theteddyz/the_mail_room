extends Node3D
class_name Interactable
@export_enum("grab", "light","package", "deliverable","key","tape") var icon_type:int
# Overridable function used for typing
func interact():
	print("CLICKED")
