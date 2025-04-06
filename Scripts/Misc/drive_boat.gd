extends Interactable
class_name boat

var grab_paddle:bool = false
@onready var camera_position = $"../../CameraPosition"
var player_camera
var mouse_sense = 0.25

func interact():
	
	start_interaction()
	print("grabbed")

func _input(event):
	if grab_paddle:
		handle_mouse_motion(event)

func handle_mouse_motion(event: InputEvent):
	if event is InputEventMouseMotion:
		camera_position.rotate_y(deg_to_rad(-event.relative.x * mouse_sense))
		var new_pitch = camera_position.rotation.x + deg_to_rad(-event.relative.y * mouse_sense)
		new_pitch = clamp(new_pitch, deg_to_rad(-80), deg_to_rad(80))
		camera_position.rotation.x = new_pitch

func start_interaction():
	if !grab_paddle:
		EventBus.emitCustomSignal("disable_player_movement",[false,true])
		#var original_global_transform = player_camera.global_transform
		#interactableFinder.enabled = false
		#look_icon.hide()
		var icon = Gui.icon_manager
		var d
		icon.hide_all_icons(d)
		player_camera = GameManager.get_player_camera()
		player_camera.reparent(camera_position)
		var camera_tween_position:Tween = create_tween()
		var camera_tween_rotation:Tween = create_tween()
		camera_tween_position.tween_property(player_camera, "position", Vector3.ZERO, 1).set_ease(Tween.EASE_IN_OUT)
		camera_tween_position.set_parallel(true)
		camera_tween_rotation.tween_property(player_camera, "rotation_degrees", Vector3.ZERO, 1).set_ease(Tween.EASE_IN_OUT)
		camera_tween_rotation.set_parallel(true)
		await camera_tween_position.finished
		grab_paddle = true
		


func enable_player_movement():
	pass
	#EventBus.emitCustomSignal("disable_player_movement",[false,false])
