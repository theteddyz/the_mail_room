extends RigidBody3D
@export var animationPlayer: AnimationPlayer
@export var animationTree: AnimationTree

func _ready():
	pass
	
func _input(event):
	handle_keyboard_press(event)

func handle_keyboard_press(event: InputEvent):
	if event.is_action_pressed("crouch"):
		apply_central_force(Vector3(6,0,0))
		await get_tree().create_timer(0.2).timeout
		apply_central_force(Vector3(0,0,2))
	
