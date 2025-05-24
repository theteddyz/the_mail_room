extends Node3D
@export var animationPlayer: AnimationPlayer
@export var animationTree: AnimationTree

var timer: float = 0.0
var velocity: float = 0.0
var target_velocity := -1.0  # downward
var acceleration := 0.0
var randomDuration := 1.0
var forward
var origin: Vector3
var originRotation: Vector3
var randomRotation: Vector3
func _ready():
	origin = global_position
	originRotation = rotation
	pass
	
func _input(event):
	handle_keyboard_press(event)

func handle_keyboard_press(event: InputEvent):
	if event.is_action_pressed("p"):
		global_position = origin
	
func _process(delta: float) -> void:
	timer += delta
	if timer < randomDuration*0.45:
		target_velocity = -10.0
		
		if animationTree:
			animationTree["parameters/Blend2/blend_amount"] = lerpf(animationTree["parameters/Blend2/blend_amount"],1,delta*10);
	elif timer < randomDuration:
		target_velocity = 10.0
		if animationTree:
			animationTree["parameters/Blend2/blend_amount"] = lerpf(animationTree["parameters/Blend2/blend_amount"],0,delta*10);
	else:
		timer = 0
		var rng = RandomNumberGenerator.new()
		randomDuration = rng.randf_range(0.5, 1.0)
		randomRotation.x = originRotation.x + rng.randf_range(-1.0, 1.0)
		randomRotation.y = originRotation.y + rng.randf_range(-1.0, 1.0)
		randomRotation.z = originRotation.z + rng.randf_range(-1.0, 1.0)
	rotation.x = lerpf(rotation.x,randomRotation.x,delta*2);
	rotation.y = lerpf(rotation.y,randomRotation.y,delta*2);
	rotation.z = lerpf(rotation.z,randomRotation.z,delta*2);
	# Smooth acceleration toward the target velocity
	var accel_strength := 2.0
	acceleration = (target_velocity - velocity) * accel_strength
	velocity += acceleration * delta
	#global_position.y += velocity * delta	
	rotation.z = -velocity*0.2	

	forward = -global_transform.basis.x
	global_position += forward * 120 * delta
