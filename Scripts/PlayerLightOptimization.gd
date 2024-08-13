extends Area3D

@export var counter = 0

func _on_area_entered(area):
	var light = area.get_parent()
	if(light is OmniLight3D or light is SpotLight3D):
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
		print(counter)


func _on_area_exited(area):
	var light = area.get_parent()
	var lights: Array = []
	if(light is OmniLight3D or light is SpotLight3D):
		if(!light.is_in_group("alwaysshadow")):
			light.shadow_enabled = false
			counter -= 1
			print(counter)
