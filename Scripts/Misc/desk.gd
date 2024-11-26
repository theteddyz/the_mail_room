extends Node3D
@export var monitor_on:bool = true



func _ready():
	if monitor_on == false:
		var on = $GrabableObjectTemplate/ComputerOn
		on.visible = false
		var off = $GrabableObjectTemplate/ComputerOff
		off.visible = true


func _on_visible_on_screen_notifier_3d_screen_entered():
	if visible:
		visible = false


func _on_visible_on_screen_notifier_3d_screen_exited():
	if !visible:
		visible = true
