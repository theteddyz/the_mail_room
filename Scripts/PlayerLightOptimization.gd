extends Area3D

@export var counter = 0

func _on_area_entered(area):
	var tile = area.get_parent()
	var lights: Array = []
	for child in tile.get_children():
		if child is SpotLight3D or child is OmniLight3D:
			lights.append(child)
			
	if !lights.is_empty():
		for light in lights:
			light.shadow_enabled = true
			counter += 1
			print(counter)
			


func _on_area_exited(area):
	var tile = area.get_parent()
	var lights: Array = []
	for child in tile.get_children():
		if child is SpotLight3D or child is OmniLight3D:
			lights.append(child)
			
			
	if !lights.is_empty():
		for light in lights:
			light.shadow_enabled = false
			counter -= 1
			print(counter)
