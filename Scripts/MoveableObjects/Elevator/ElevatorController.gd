extends Node3D

var current_floor:int = 4
var previous_floor:int
var floors:Dictionary = {-2: 81.5, -1: 64, 0: 49, 1: 30.5, 2: 10.5, 3: -7, 4: -27, 5: -46, 6: -64, 7: -84}
var is_called:bool = false
@onready var anim:AnimationPlayer = $AnimationPlayer
@onready var Elevator_Wall = $Elevator_Wall
@onready var Elevator = $Elevator
@onready var detector = $Elevator/ObjectDetectionShape
var elevator_anim:AnimationPlayer
var wall_anim:AnimationPlayer
var cart:bool = false
var floor_mesh
var current_scene
@export var locked = false
#@onready var floor_indicator: MeshInstance3D = $WallWithElevatorEntrance/ElevatorEntrance/ElevatorEntranceIndicator
# Called when the node enters the scene tree for the first time.


func _ready():
	elevator_anim = Elevator.find_child("Elevator_Anim")
	wall_anim = Elevator_Wall.find_child("wall_anim")
	GameManager.register_elevator(self)
	EventBus.connect("moved_to_floor",set_floor)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func call_elevator():
	var player_floor = get_tree().root.get_child(5).floor_num
	if !is_called:
		is_called = true
		if current_floor != player_floor:
			if current_floor > player_floor:
				anim.play("elevator_call_down")
				current_floor = player_floor
				await anim.animation_finished
				elevator_anim.play("door_open")
				wall_anim.play("wall_door_open")
				await elevator_anim.animation_finished
			else:
				anim.play("elevator_call_up")
				current_floor = player_floor
				await anim.animation_finished
				elevator_anim.play("door_open")
				wall_anim.play("wall_door_open")
				await elevator_anim.animation_finished
		else:
			elevator_anim.play("door_open")
			wall_anim.play("wall_door_open")
			await elevator_anim

func move_floors():
	swap_floor_collider(false)
	if previous_floor > current_floor:
		await close_doors()
		var player = GameManager.get_player()
		#var elevatorbody = Elevator.find_child("Elevator_body")
		player.reparent(Elevator,true)
		if detector.mailcart_exists_in_elevator == true:
			var mail_cart = GameManager.get_mail_cart()
			mail_cart.reparent(Elevator,true)
		if Elevator_Wall.visible:
			await wall_anim.animation_finished
		else:
			await elevator_anim.animation_finished
		anim.play("elevator_move_down")
		await anim.animation_finished
		if current_floor < 0:
			#var elevator_wall_anim = Elevator_Wall.find_child("wall_anim")
			wall_anim.active = false
			Elevator_Wall.visible = false
			
		else:
			elevator_anim.active = true
			Elevator_Wall.visible = true
	else:
		await close_doors()
		
		if detector.mailcart_exists_in_elevator == true:
			var mail_cart = GameManager.get_mail_cart()
			mail_cart.reparent(Elevator,true)
		var player = GameManager.get_player()
		player.reparent(Elevator,true)
		if Elevator_Wall.visible:
			await wall_anim.animation_finished
		else:
			await elevator_anim.animation_finished
			
		anim.play("elevator_move_up")
		await anim.animation_finished
		if current_floor < 0:
			wall_anim.active = true
			Elevator_Wall.visible = true
		else:
			wall_anim.active = true
			Elevator_Wall.visible = true

func set_floor(path,new_floor:int):
	previous_floor = current_floor
	current_floor = new_floor
	await move_floors()
	var loading_screen = Gui.get_loading_screen()
	if loading_screen:
		loading_screen.visible = true
		loading_screen.show()
		loading_screen.load_screen(path)
	await get_tree().create_timer(5.0).timeout
	GameManager.goto_scene(path,new_floor)
	

func load_floor():
	
	swap_floor_collider(false)
	var player = GameManager.get_player()
	player.reparent(Elevator,true)
	print(detector.mailcart_exists_in_elevator)
	if detector.mailcart_exists_in_elevator == true:
		var mail_cart = GameManager.get_mail_cart()
		mail_cart.reparent(Elevator,true)
	if previous_floor > current_floor:
		wall_anim.play("RESET")
		elevator_anim.play("RESET")
		anim.play("elevator_call_down")
		await anim.animation_finished
		var root = get_tree().root
		current_scene = root.get_child(root.get_child_count() - 1)
		player.reparent(current_scene)
		swap_floor_collider(true)
		elevator_anim.play("door_open")
		wall_anim.play("wall_door_open")
	else:
		elevator_anim.play("RESET")
		wall_anim.play("RESET")
		anim.play("elevator_call_up")
		await anim.animation_finished
		var root = get_tree().root
		current_scene = root.get_child(root.get_child_count() - 1)
		player.reparent(current_scene)
		swap_floor_collider(true)
		elevator_anim.play("door_open")
		wall_anim.play("wall_door_open")
		
		

func swap_floor_collider(on:bool):
	if on:
		for floor in get_tree().get_nodes_in_group("Real_Floor"):
			if floor is CollisionShape3D:
				var collider:StaticBody3D = floor.get_parent()
				collider.set_collision_layer_value(3,true)
				collider.set_collision_layer_value(5,true)
			floor.visible = true
		for floors in get_tree().get_nodes_in_group("Fake_Floor"):
			floors.visible = false
	else:
		for floor in get_tree().get_nodes_in_group("Real_Floor"):
			if floor is CollisionShape3D:
				var collider:StaticBody3D = floor.get_parent()
				collider.set_collision_layer_value(5,false)
				collider.set_collision_layer_value(3,false)
			floor.visible = false
	for floors in get_tree().get_nodes_in_group("Fake_Floor"):
		floors.visible = true

func close_doors():
	elevator_anim.play("door_close")
	wall_anim.play("RESET")
	await wall_anim.animation_finished
	wall_anim.play("wall_door_close")
	
#func move_indicator(floor:int):
	#if floor in floors:
		#var target_rotation = floors[floor]
		#var tween = get_tree().create_tween()
		#tween.tween_property(floor_indicator, "rotation_degrees:z", target_rotation, 5.0).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
