extends Node3D
#Objects need for tweens
@onready var Left_Wall_Door:StaticBody3D = $Elevator_Wall/Elevator_Wall/Left_Door
@onready var Right_Wall_Door:StaticBody3D = $Elevator_Wall/Elevator_Wall/Right_Door
@onready var Elevator_Wall:StaticBody3D = $Elevator_Wall
@onready var Elevator:Node3D = $Elevator
@onready var Elevator_Collider:StaticBody3D = $Elevator/Elevator/Elevator_body/StaticBody3D
@onready var Elevator_Door:MeshInstance3D = $Elevator/Elevator/Elevator_body/ElevatorDoor_002
@onready var detector = $Elevator/ObjectDetectionShape
@onready var elevator_audio:AudioStreamPlayer3D = $Elevator/AudioStreamPlayer3D
@onready var wall_door_audio:AudioStreamPlayer3D = $Elevator_Wall/AudioStreamPlayer3D
@onready var elevator_shafts:Array = [$ElevatorShaft/ElevatorShaft2,$ElevatorShaft4/ElevatorShaft2,$ElevatorShaft3]
@onready var music_player:AudioStreamPlayer3D = $Elevator/Music_Player
var wall_door_close = preload("res://Assets/Audio/SoundFX/ElevatorDoorClose.mp3")
var wall_door_open = preload("res://Assets/Audio/SoundFX/ElevatorDoorOpen.mp3")
var elevator_entrance_open = preload("res://Assets/Audio/SoundFX/ElevatorEntranceDoorOpen.mp3")
var elevator_entrance_close = preload("res://Assets/Audio/SoundFX/ElevatorEntranceDoorClose.mp3")
var elevator_moving = preload("res://Assets/Audio/SoundFX/ElevatorSound.mp3")
var elevator_ding = preload("res://Assets/Audio/SoundFX/ElevatorDing.mp3")
var current_floor:int = 4
var previous_floor:int
var floors:Dictionary = {-2: 81.5, -1: 64, 0: 49, 1: 30.5, 2: 10.5, 3: -7, 4: -27, 5: -46, 6: -64, 7: -84}
var is_called:bool = false
var cart:bool = false
var floor_mesh
var current_scene
var mail_room:bool = false
@export var locked = false
# Called when the node enters the scene tree for the first time.


func _ready():
	GameManager.register_elevator(self)
	EventBus.connect("moved_to_floor",set_floor)
	if mail_room:
		for i in elevator_shafts:
			i.visible= false
	else:
		for i in elevator_shafts:
			i.visible= true


func call_elevator():
	var world = get_tree().get_first_node_in_group("world")
	if !world:
		assert(true,"NO WORLD WAS FOUND MAKE SURE ROOT NODE IS IN GROUP WORLD" )
	var player_floor = world.floor_num
	if !is_called:
		is_called = true
		if current_floor != player_floor:
			if current_floor > player_floor:
				await call_elevator_down()
				await open_doors()
				current_floor = player_floor
			else:
				await call_elevator_up()
				current_floor = player_floor
		else:
			open_doors()

func move_floors()->void:
	swap_floor_collider(false)
	if previous_floor > current_floor:
		await close_doors()
		#var player = GameManager.get_player()
		#player.reparent(Elevator,true)
		#if detector.mailcart_exists_in_elevator == true:
			#var mail_cart = GameManager.get_mail_cart()
			#mail_cart.reparent(Elevator,true)
		await move_elevator_down()
		return
	else:
		await close_doors()
		if detector.mailcart_exists_in_elevator == true:
			var mail_cart = GameManager.get_mail_cart()
			#mail_cart.reparent(Elevator,true)
		#var player = GameManager.get_player()
		#player.reparent(Elevator,true)
		for ceiling in get_tree().get_nodes_in_group("Ceiling"):
			ceiling.hide()
		await move_elevator_up()
		return

func set_floor(path,new_floor:int):
	music_player.play()
	previous_floor = current_floor
	current_floor = new_floor
	
	await move_floors()
	#var loading_screen = Gui.get_loading_screen()
	#if loading_screen:
		#loading_screen.visible = true
		#loading_screen.show()
		#loading_screen.load_screen(path)
	#await get_tree().create_timer(5.0).timeout
	GameManager.goto_scene(path,new_floor)
	

func load_floor():
	swap_floor_collider(false)
	
	#var player = GameManager.get_player()
	var mail_cart = GameManager.get_mail_cart()
	var map_instance = mail_cart.get_node("Map_Position").get_child(0)
	map_instance.set_map()
	#player.reparent(Elevator,true)
	if detector.mailcart_exists_in_elevator == true:
		pass
		#mail_cart.reparent(Elevator,true)
	if previous_floor > current_floor:
		
		await call_elevator_down()
		var root = get_tree().root
		current_scene = root.get_child(root.get_child_count() - 1)
		#player.reparent(current_scene)
		#mail_cart.reparent(current_scene)
		swap_floor_collider(true)
		await open_doors()
	else:
		
		await call_elevator_up()
		var root = get_tree().root
		current_scene = root.get_child(root.get_child_count() - 1)
		#player.reparent(current_scene)
		#mail_cart.reparent(current_scene)
		swap_floor_collider(true)
		open_doors()

func swap_floor_collider(on:bool):
	if on:
		for floor_ in get_tree().get_nodes_in_group("Real_Floor"):
			if floor_ is CollisionShape3D:
				var collider:StaticBody3D = floor_.get_parent()
				collider.set_collision_layer_value(4,true)
				collider.set_collision_layer_value(3,true)
			floor_.visible = true
		for _floors in get_tree().get_nodes_in_group("Fake_Floor"):
			_floors.visible = false
	else:
		for _floor in get_tree().get_nodes_in_group("Real_Floor"):
			if _floor is CollisionShape3D:
				var collider:StaticBody3D = _floor.get_parent()
				collider.set_collision_layer_value(4,false)
				collider.set_collision_layer_value(3,false)
			_floor.visible = false
	for _floors in get_tree().get_nodes_in_group("Fake_Floor"):
		_floors.visible = true

func close_doors(_reparent = true)-> void:
	var player = GameManager.get_player()
	var mailcart = GameManager.get_mail_cart()
	if _reparent:
		player.reparent(Elevator,true)
		player.set_axis_lock(PhysicsServer3D.BodyAxis.BODY_AXIS_LINEAR_Y, true)	
		mailcart.reparent(Elevator,true)
		mailcart.set_axis_lock(PhysicsServer3D.BodyAxis.BODY_AXIS_LINEAR_Y, true)
	if !mail_room:
		var close_door_tween = create_tween()
		close_door_tween.tween_property(Left_Wall_Door, "position", Vector3(-0.867,0,0), 3).set_ease(Tween.EASE_IN_OUT)
		close_door_tween.set_parallel(true)
		close_door_tween.tween_property(Right_Wall_Door, "position", Vector3(0,0,0), 3).set_ease(Tween.EASE_IN_OUT)
		close_door_tween.set_parallel(true)
		close_door_tween.tween_property(Elevator_Door,"blend_shapes/ElevatorDoor",1,3)
		wall_door_audio.play()
		await close_door_tween.finished
		return

func open_doors()->void:
	var player = GameManager.get_player()
	if Elevator.is_ancestor_of(player):
		player.reparent(GameManager.current_scene,true)
		player.set_axis_lock(PhysicsServer3D.BodyAxis.BODY_AXIS_LINEAR_Y, false)

	var mailcart = GameManager.get_mail_cart()
	if Elevator.is_ancestor_of(mailcart):
		mailcart.reparent(GameManager.current_scene,true)
		mailcart.set_axis_lock(PhysicsServer3D.BodyAxis.BODY_AXIS_LINEAR_Y, false)
		mailcart.calculate_spacing()
	if !mail_room:
		var open_door_tween = create_tween()
		open_door_tween.tween_property(Left_Wall_Door, "position", Vector3(-1.705,0,0), 3).set_ease(Tween.EASE_IN_OUT)
		open_door_tween.set_parallel(true)
		open_door_tween.tween_property(Right_Wall_Door, "position", Vector3(0.832,0,0), 3).set_ease(Tween.EASE_IN_OUT)
		open_door_tween.set_parallel(true)
		open_door_tween.tween_property(Elevator_Door,"blend_shapes/ElevatorDoor",0,3)
		elevator_audio.stream = elevator_entrance_open
		elevator_audio.play()
		wall_door_audio.stream = wall_door_open
		wall_door_audio.play()
		await open_door_tween.finished
		Elevator_Collider.get_child(0).disabled = true
		return 
	
func call_elevator_down()->void:
	Elevator.position = Vector3(1.987,8.82,0.696)
	var elevator_called_down_tween = create_tween()
	elevator_called_down_tween.tween_property(Elevator, "position", Vector3(1.987,0.8,0.696), 5).set_ease(Tween.EASE_IN_OUT)
	elevator_audio.stream = elevator_moving
	elevator_audio.play()
	await elevator_called_down_tween.finished
	elevator_audio.stream = elevator_ding
	elevator_audio.play()
	music_player.stop()
	await elevator_audio.finished
	return 
func call_elevator_up()->void:
	Elevator.position = Vector3(1.987,-6.90,0.696)
	var elevator_called_up_tween = create_tween()
	elevator_called_up_tween.tween_property(Elevator, "position", Vector3(1.987,0.8,0.696), 5).set_ease(Tween.EASE_IN_OUT)
	elevator_audio.stream = elevator_moving
	elevator_audio.play()
	await elevator_called_up_tween.finished
	elevator_audio.stream = elevator_ding
	elevator_audio.play()
	music_player.stop()
	await elevator_audio.finished
	await open_doors()
	return 
func move_elevator_down()-> void:
	
	var mailcart = GameManager.get_mail_cart()
	mailcart.calculate_spacing()
	var move_elevator_down_tween = create_tween()
	move_elevator_down_tween.tween_property(Elevator, "position", Vector3(1.987,-6.944,0.696), 5).set_ease(Tween.EASE_IN_OUT)
	elevator_audio.stream = elevator_moving
	elevator_audio.play()
	await move_elevator_down_tween.finished
	return 
func move_elevator_up()-> void:
	var mailcart = GameManager.get_mail_cart()
	mailcart.calculate_spacing()
	var move_elevator_up_tween = create_tween()
	move_elevator_up_tween.tween_property(Elevator, "position", Vector3(1.987,9.304,0.696), 5).set_ease(Tween.EASE_IN_OUT)
	elevator_audio.stream = elevator_moving
	elevator_audio.play()
	await move_elevator_up_tween.finished
	return 

func show_or_hide_door():
	if current_floor == -1:
		Elevator_Wall.visible = false
		for i in elevator_shafts:
				i.visible= false
	else:
		Elevator_Wall.visible = true
		for i in elevator_shafts:
			i.visible= true
