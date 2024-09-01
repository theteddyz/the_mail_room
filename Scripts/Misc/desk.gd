extends Node3D
@export var monitor_on:bool = true



func _ready():
	if monitor_on == false:
		var on = $GrabableObjectTemplate/Interpolator/ComputerOn
		on.visible = false
		var off = $GrabableObjectTemplate/Interpolator/ComputerOff
		off.visible = true
