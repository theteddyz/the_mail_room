extends Node3D

var current_floor = 4
var previous_floor
var floors:Dictionary = {-2: 81.5, -1: 64, 0: 49, 1: 30.5, 2: 10.5, 3: -7, 4: -27, 5: -46, 6: -64, 7: -84}
var is_called = false
@onready var anim:AnimationPlayer = $AnimationPlayer
@onready var Elevator_Wall = $Elevator_Wall
@onready var Elevator = $Elevator
@onready var detector = $Elevator/ObjectDetectionShape
var elevator_anim:AnimationPlayer
var wall_anim:AnimationPlayer
var target_path
var cart:bool = false
#@onready var floor_indicator: MeshInstance3D = $WallWithElevatorEntrance/ElevatorEntrance/ElevatorEntranceIndicator
# Called when the node enters the scene tree for the first time.


func _ready():
	elevator_anim = Elevator.find_child("Elevator_Anim")
	#wall_anim = Elevator_Wall.find_child("wall_anim")
	GameManager.register_elevator(self)
	EventBus.connect("moved_to_floor",set_floor)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func call_elevator():
	var player_floor = get_tree().root.get_child(3).floor_num
	if !is_called:
		is_called = true
		if current_floor != player_floor:
			if current_floor > player_floor:
				anim.play("elevator_call_down")
				current_floor = player_floor
				await anim.animation_finished
				elevator_anim.play("door_open")
				wall_anim.play("wall_door_open")
				await wall_anim.animation_finished
			else:
				anim.play("elevator_call_up")
				current_floor = player_floor
				await anim.animation_finished
				elevator_anim.play("door_open")
				wall_anim.play("wall_door_open")
				await wall_anim.animation_finished
		else:
			elevator_anim.play("door_open")
			wall_anim.play("wall_door_open")

func move_floors():
	if previous_floor > current_floor:
		elevator_anim.play("door_close")
		wall_anim.play("wall_door_close")
		var player = GameManager.get_player()
		var elevatorbody = Elevator.find_child("Elevator_body")
		player.reparent(Elevator,true)
		if detector.mailcart_exists_in_elevator == true:
			var mail_cart = GameManager.get_mail_cart()
			mail_cart.reparent(Elevator,true)
		await wall_anim.animation_finished
		anim.play("elevator_move_down")
		await anim.animation_finished
		if current_floor < 0:
			var elevator_wall_anim = Elevator_Wall.find_child("wall_anim")
			wall_anim.active = false
			Elevator_Wall.visible = false
			
		else:
			elevator_anim.active = true
			Elevator_Wall.visible = true
	else:
		elevator_anim.play("door_close")
		wall_anim.play("wall_door_close")
		if detector.mailcart_exists_in_elevator == true:
			var mail_cart = GameManager.get_mail_cart()
			mail_cart.reparent(Elevator,true)
		var player = GameManager.get_player()
		player.reparent(Elevator,true)
		await wall_anim.animation_finished
		anim.play("elevator_move_up")
		await anim.animation_finished
		if current_floor < 0:
			wall_anim.active = false
			Elevator_Wall.visible = false
			
		else:
			wall_anim.active = true
			Elevator_Wall.visible = true

func set_floor(path,new_floor:int):
	previous_floor = current_floor
	current_floor = new_floor
	await move_floors()
	GameManager.goto_scene(path,new_floor)

func load_floor():
	var player = GameManager.get_player()
	player.reparent(Elevator,true)
	print(detector.mailcart_exists_in_elevator)
	if detector.mailcart_exists_in_elevator == true:
		var mail_cart = GameManager.get_mail_cart()
		mail_cart.reparent(Elevator,true)
	if previous_floor > current_floor:
		anim.play("elevator_call_down")
		await anim.animation_finished
		player.reparent(get_tree().root.get_child(3),true)
		elevator_anim.play("door_open")
		wall_anim.play("wall_door_open")
	else:
		anim.play("elevator_call_up")
		await anim.animation_finished
		player.reparent(get_tree().root.get_child(3),true)
		elevator_anim.play("door_open")
		wall_anim.play("wall_door_open")
#func move_indicator(floor:int):
	#if floor in floors:
		#var target_rotation = floors[floor]
		#var tween = get_tree().create_tween()
		#tween.tween_property(floor_indicator, "rotation_degrees:z", target_rotation, 5.0).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
