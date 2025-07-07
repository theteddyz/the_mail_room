extends ColorRect

var effect_amount = 0.0
var current_amount = 0.0
var target_amount = 1000.0
var lerp_speed = 7
func _input(event: InputEvent):
	if event.is_action_pressed("testing"):
		target_amount = clamp(target_amount,0,200);
		target_amount-= 100.0
		

func _process(delta: float) -> void:
	target_amount = clamp(target_amount,0,1024);
	material.set_shader_parameter("vhs_resolution", Vector2(current_amount,1024))
	current_amount = lerpf(current_amount,target_amount,delta*lerp_speed);
	#print("Target AMount: ", current_amount)
	target_amount += 50*delta
