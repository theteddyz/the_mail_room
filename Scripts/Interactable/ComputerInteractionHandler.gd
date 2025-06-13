extends Interactable

class_name Monitor
var player_camera:Camera3D
var player_camera_parent
var camera_position:Vector3 = Vector3(0,0.29,-1.988)
var camera_rotation:Vector3 = Vector3(0,-180,0)
var being_used
var look_icon 
var interactableFinder:RayCast3D
var collision_shape:CollisionShape3D
@onready var monitor_handler = $"../MonitorHandler"
@onready var usb_handler = $"../MonitorHandler/SubViewport/Player_USB_Handler"
@onready var mail_pong = $"../MonitorHandler/SubViewport/GUI/MailPongBackground/MailPong"
@onready var main_parent = $"../../.."
@onready var usb_mesh_scene:PackedScene = preload("res://Scenes/Prefabs/usb_drive_MESH.tscn")
@onready var start_marker = $"../Screen/Marker3D2"
@onready var end_marker = $"../Screen/Marker3D2"
func _ready():
	collision_shape = get_child(0)
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
	monitor_handler.is_mouse_inside = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var col:CollisionShape3D = get_child(0)
	col.disabled = false

func interact():
	if !being_used:
		Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)
		player_camera.reparent(self)
		interactableFinder.enabled = false
		EventBus.emitCustomSignal("disable_player_movement",[true,true])
		look_icon.hide()
		var icon = Gui.icon_manager
		var d
		await load_unadded_usbs()
		icon.hide_all_icons(d)
		var camera_tween_position:Tween = create_tween()
		var camera_tween_rotation:Tween = create_tween()
		camera_tween_position.tween_property(player_camera, "position", camera_position, 1.5).set_ease(Tween.EASE_IN_OUT)
		camera_tween_position.set_parallel(true)
		camera_tween_rotation.tween_property(player_camera,"rotation_degrees",camera_rotation,1.5).set_ease(Tween.EASE_IN_OUT)
		camera_tween_rotation.set_parallel(true)
		await camera_tween_position.finished
		being_used = true
		monitor_handler.is_mouse_inside = true
		var col:CollisionShape3D = get_child(0)
		col.disabled = true
		Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)




func load_unadded_usbs() -> void:
	
	var file_name = GameManager.FILE_NAME

	if not FileAccess.file_exists(file_name):
		return

	var save_game = FileAccess.open(file_name, FileAccess.READ)
	if not save_game:
		return

	var save_string = save_game.get_as_text()
	var parsed = JSON.parse_string(save_string)
	save_game.close()

	if typeof(parsed) != TYPE_DICTIONARY:
		return

	var data = parsed
	var updated = false

	if not data.has("USB_DATA"):
		return

	for usb in data["USB_DATA"]:
		if typeof(usb) == TYPE_DICTIONARY:
			var id = int(usb.get("id", -1))
			if not usb.get("added_to_computer", false) and usb_handler.usb_list.has(id):
				print("LOADING")
				await animate_usb_insert()
				GameManager.mark_usb_as_added_to_computer(id)

	# Save the updated flag if needed
	#if updated:
		#var save_game_ = FileAccess.open(file_name, FileAccess.WRITE)
		#if save_game_:
			#var json_string = JSON.stringify(data, "\t")
			#save_game.store_string(json_string)
			#save_game.close()


func animate_usb_insert() -> void:
	var usb_mesh = usb_mesh_scene.instantiate()
	start_marker.add_child(usb_mesh)  # Keep it locally parented
	usb_mesh.position = Vector3.ZERO  # Start at local origin
	usb_mesh.reparent(end_marker)
	var tween = create_tween()
	tween.tween_property(usb_mesh, "position", Vector3(0,0,-0.65), 1)
	await tween.finished
	usb_handler.load_usb_data()
