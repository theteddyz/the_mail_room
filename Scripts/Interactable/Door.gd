extends Interactable

@export var locked:bool

var parent:RigidBody3D
@export var unlock_number:int
@onready var hinge:JoltHingeJoint3D = $"../../JoltHingeJoint3D"
func _ready():
	parent = get_parent()
	if locked:
		parent.lock_axes(true)


func interact():
	print("CLICKED")


func _on_area_entered(area):
	if area and "unlock_num" in area:
		if area.unlock_num == unlock_number:
			area.get_parent().queue_free()
			locked = false
			parent.lock_axes(false)
