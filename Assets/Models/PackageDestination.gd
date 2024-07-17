extends Node3D

@export_multiline var accepts_package_named: String
@export var accepted_num: int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	
	print(accepts_package_named)

func deliver(package: Package):
	if(package.package_num == accepted_num):
		package.reparent(self, false)
		package.position =Vector3.ZERO
		package.rotation = Vector3.ZERO
		package.position = package.delivered_position
		package.rotation = package.delivered_rotation
		package.get_child(0).disabled = true
		EventBus.emit_signal("package_delivered",package.package_num)
	else:
		EventBus.emit_signal("package_failed_delivery")


