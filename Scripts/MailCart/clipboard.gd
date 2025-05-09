extends Interactable

var interacting:bool = false
var cart_position:Vector3
var cart_rotation
var cart
var player_camera:Camera3D
var player_camera_parent
var parent:Node3D
var player
@onready var map_display:MeshInstance3D = $"../MeshInstance3D/MeshInstance3D2"
var mail_room_map = preload("res://Assets/Textures/MailRoomFloorLayout.png")
var finance_map = preload("res://Assets/Textures/FinanceFloorLayout2.png")
func _ready():
	parent = get_parent()
	cart_position = parent.position
	cart_rotation = parent.rotation_degrees
	cart = GameManager.get_mail_cart()
	player = GameManager.get_player()
	player_camera_parent = player.find_child("Neck").find_child("Head").find_child("HeadbopRoot")
	player_camera = player_camera_parent.find_child("Camera")
	set_map()

func interact():
	var icon = Gui.icon_manager
	var _d
	icon.hide_all_icons(_d)
	EventBus.emitCustomSignal("disable_player_movement",[false,true])
	interacting = true
	parent.reparent(player_camera,true)
	var goto_tween_position = create_tween()
	var goto_tween_rotation = create_tween()
	goto_tween_position.tween_property(parent, "position", Vector3(0,0,-0.6,), 0.5).set_ease(Tween.EASE_IN_OUT)
	goto_tween_position.set_parallel(true)
	goto_tween_rotation.tween_property(parent, "rotation_degrees", Vector3(-90,90,0,), 0.5).set_ease(Tween.EASE_IN_OUT)
	goto_tween_rotation.set_parallel(true)
	await goto_tween_position.finished


func _input(event):
	if interacting and event.is_action_pressed("inspect"):
		returnMap()

func set_map():
	var root = get_tree().root
	var world = root.get_child(root.get_child_count() - 1)
	var floor_number
	#floor_number = world.floor_num
	print(floor_number)
	if floor_number:
		match floor_number:
			-1:
				var material = StandardMaterial3D.new()
				material.albedo_texture = mail_room_map
				material.unshaded = true
				map_display.set_surface_override_material(0, material)
			6:
				var material = StandardMaterial3D.new()
				material.unshaded = true
				material.albedo_texture = finance_map
				map_display.set_surface_override_material(0, material)
func returnMap():
	EventBus.emitCustomSignal("disable_player_movement",[false,false])
	parent.reparent(cart,true)
	interacting = false
	var return_tween_position = create_tween()
	#var return_tween_rotation = create_tween()
	return_tween_position.tween_property(parent, "position", cart_position, 0.5).set_ease(Tween.EASE_IN_OUT)
	return_tween_position.set_parallel(true)
	return_tween_position.tween_property(parent, "rotation_degrees", cart_rotation, 0.5).set_ease(Tween.EASE_IN_OUT)
	return_tween_position.set_parallel(true)
	await return_tween_position.finished
