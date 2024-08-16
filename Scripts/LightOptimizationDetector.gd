extends Area3D

@export var counter = 0

func _on_area_entered(area):
	var light = area.get_parent()
	if((light is OmniLight3D or light is SpotLight3D) and !light.shadow_enabled):
		light.shadow_enabled = true
		var l = light as Light3D
		l.distance_fade_enabled = true
		counter += 1
		print(counter)

		# Apply Shadow Properties
		if l.shadow_property != null:
			l.shadow_bias = l.shadow_property["bias"]
			l.shadow_normal_bias = l.shadow_property["normal_bias"]
			l.shadow_reverse_cull_face = l.shadow_property["reverse_cull_face"]
			l.shadow_transmittance_bias = l.shadow_property["transmittance_bias"]
			l.shadow_opacity = l.shadow_property["opacity"]
			l.shadow_blur = l.shadow_property["blur"]
			l.distance_fade_shadow = l.shadow_property["distance_fade_shadow"]

		else:
			# Just a fallback case
			l.shadow_bias = 0.095
			l.shadow_normal_bias = 1
			l.shadow_reverse_cull_face = false
			l.shadow_transmittance_bias = 0.05
			l.shadow_opacity = 1
			l.shadow_blur = 1
				
			# Distance Fade Properties
			l.distance_fade_begin = 50
			l.distance_fade_shadow = 15.0
			l.distance_fade_length = 13.45

func _on_area_exited(area):
	var light = area.get_parent()
	var lights: Array = []
	if((light is OmniLight3D or light is SpotLight3D) and light.shadow_enabled):
		if(!light.is_in_group("alwaysshadow")):
			light.shadow_enabled = false
			counter -= 1
			print(counter)
