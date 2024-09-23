extends Interactable

class_name Monitor
var player_camera:Camera3D
var player_camera_parent
var camera_position:Vector3 = Vector3(0,0.29,-1.988)
var camera_rotation:Vector3 = Vector3(0,-180,0)
var being_used
var look_icon 
var interactableFinder:RayCast3D
@onready var mail_pong = $"../MonitorHandler/SubViewport/GUI/MailPongBackground/MailPong"
func _ready():
	var player = GameManager.get_player()
	look_icon = Gui.look_icon
	player_camera_parent = player.find_child("Neck").find_child("Head").find_child("HeadbopRoot")
	player_camera = player_camera_parent.find_child("Camera")
	interactableFinder = player.find_child("Neck").find_child("Head").find_child("InteractableFinder")

func _input(event):
	if being_used and event.is_action_pressed("inspect"):
		stop_using_pc()

func stop_using_pc():
	player_camera.reparent(player_camera_parent)
	var camera_tween_position:Tween = create_tween()
	var camera_tween_rotation:Tween = create_tween()
	camera_tween_position.tween_property(player_camera,"position",Vector3.ZERO,1.5).set_ease(Tween.EASE_IN)
	camera_tween_rotation.tween_property(player_camera,"rotation",Vector3.ZERO,1.5).set_ease(Tween.EASE_IN)
	await camera_tween_position.finished
	interactableFinder.enabled = true
	EventBus.emitCustomSignal("disable_player_movement",[false,false])
	look_icon.show()
	being_used = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var col:CollisionShape3D = get_child(0)
	col.disabled = false

func interact():
	if !being_used:
		player_camera.reparent(self)
		interactableFinder.enabled = false
		EventBus.emitCustomSignal("disable_player_movement",[true,true])
		look_icon.hide()
		var icon = Gui.icon_manager
		var d
		icon.hide_all_icons(d)
		var camera_tween_position:Tween = create_tween()
		var camera_tween_rotation:Tween = create_tween()
		camera_tween_position.tween_property(player_camera, "position", camera_position, 1.5).set_ease(Tween.EASE_IN_OUT)
		camera_tween_position.set_parallel(true)
		camera_tween_rotation.tween_property(player_camera,"rotation_degrees",camera_rotation,1.5).set_ease(Tween.EASE_IN_OUT)
		camera_tween_rotation.set_parallel(true)
		await camera_tween_position.finished
		Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)
		being_used = true
		var col:CollisionShape3D = get_child(0)
		col.disabled = true
