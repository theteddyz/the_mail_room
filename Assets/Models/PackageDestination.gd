extends Node3D

@export_multiline var accepts_package_named: String
@export var accepted_num: int = 0
var delivered = false
var sound

func _ready():
	sound = preload("res://Assets/Audio/SoundFX/GamifiedSounds/Package Deliver.ogg")

func deliver(package: Package):
	if(package.package_num == accepted_num):
		package.reparent(self, false)
		package.position = Vector3.ZERO
		package.rotation = Vector3.ZERO
		package.position = package.delivered_position
		package.rotation = package.delivered_rotation
		package.get_child(1).disabled = true
		delivered = true
		EventBus.emitCustomSignal("dropped_object",[package.mass,package])
		ScareDirector.emit_signal("package_delivered",package.package_num)
		AudioController.play_resource(sound)
	else:
		package.dropped()
