extends Area3D
@onready var light:OmniLight3D = $".."


func _on_area_entered(area):
	light.shadow_enabled = true


func _on_area_exited(area):
	light.shadow_enabled = false
