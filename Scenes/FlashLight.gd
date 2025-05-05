extends Node3D

@export var spot_light: SpotLight3D
@export var raycast: RayCast3D
@export var omni_light: OmniLight3D
@export var audio: AudioStreamPlayer
@export var distance: float = 1.0
var is_on: bool = false
func _ready() -> void:
	omni_light.visible = false
	spot_light.visible = false

func _input(event):

	handle_keyboard_press(event)

func handle_keyboard_press(event: InputEvent):
	if event.is_action_pressed("drive"):
		if(is_on):
			is_on = false
			omni_light.visible = false
			spot_light.visible = false
		else:
			omni_light.visible = true
			spot_light.visible = true
			is_on = true
		audio.play()	

func _physics_process(delta: float) -> void:
	if raycast != null:
		if raycast.is_colliding():
			var origin = raycast.global_transform.origin
			var collision_point = raycast.get_collision_point()
			if omni_light != null:
				var forward = -global_transform.basis.z
				omni_light.global_position = collision_point - forward.normalized() * distance
				omni_light.light_energy = max(0,1 - collision_point.distance_to(global_position)*0.2)
