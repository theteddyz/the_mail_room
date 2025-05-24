extends StaticBody3D
var startMoving:bool = false
@export var rigidbody: RigidBody3D
var timer:float = 0.0
func _input(event):
	handle_keyboard_press(event)

func handle_keyboard_press(event: InputEvent):
	if event.is_action_pressed("p") and startMoving == false:
		startMoving = true
	elif event.is_action_pressed("p") and startMoving == true:	
		startMoving = false

func _physics_process(delta: float) -> void:
	if startMoving:
		timer += delta
		rigidbody.apply_torque_impulse(Vector3(0,-50,0))
	if timer > 0.15:
		timer = 0
		startMoving = false
