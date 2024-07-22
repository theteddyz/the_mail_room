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
			
			# Apply Shadow Properties
			var l = light as Light3D
			l.shadow_bias = 4
			l.shadow_normal_bias = 1
			l.shadow_reverse_cull_face = false
			l.shadow_transmittance_bias = 0.05
			l.shadow_opacity = 1
			l.shadow_blur = 1
			
			# Distance Fade Properties
			l.distance_fade_enabled = true
			l.distance_fade_begin = 50
			l.distance_fade_shadow = 15.0
			l.distance_fade_length = 13.45
			
			counter += 1
			


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
