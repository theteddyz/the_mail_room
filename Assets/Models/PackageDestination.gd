extends Node3D

@export var accepts_package_named: String

# Called when the node enters the scene tree for the first time.
func _ready():
	
	print(accepts_package_named)

func deliver(package: Package):
	if(package.package_address == accepts_package_named):
		package.reparent(self, false)
		package.position =Vector3.ZERO
		package.rotation = Vector3.ZERO
		package.position = package.delivered_position
		package.rotation = package.delivered_rotation
		package.get_child(0).disabled = true
		EventBus.emit_signal("package_delivered",package.package_num)

