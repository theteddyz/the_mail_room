extends Node3D

var current_floor = 4
var previous_floor
var floors:Dictionary = {-2: 81.5, -1: 64, 0: 49, 1: 30.5, 2: 10.5, 3: -7, 4: -27, 5: -46, 6: -64, 7: -84}
var is_called = false
@onready var anim:AnimationPlayer = $AnimationPlayer
@onready var floor_indicator: MeshInstance3D = $WallWithElevatorEntrance/ElevatorEntrance/ElevatorEntranceIndicator
# Called when the node enters the scene tree for the first time.


func _ready():
	GameManager.register_elevator(self)
	EventBus.connect("moved_to_floor",set_floor)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func call_elevator():
	var player_floor = get_tree().root.get_child(3).floor_num
	print(player_floor)
	if !is_called:
		is_called = true
		if current_floor != player_floor:
			if current_floor > player_floor:
				anim.play("call_elevator_down")
				move_indicator(player_floor)
				current_floor = player_floor
				await anim.animation_finished
				#anim.play("door_open_outside")
			else:
				anim.play("call_elevator_up")
				move_indicator(player_floor)
				current_floor = player_floor
				await anim.animation_finished
				#anim.play("door_open_outside")
		else:
			anim.play("door_open_outside")

func move_floors():
	if previous_floor > current_floor:
		print("PLAYING")
		anim.play("call_elevator_down")
		await anim.animation_finished
		var player = GameManager.get_player()
		player.reparent(get_parent(),true)
	else:
		print("PLAYINGd")
		anim.play("call_elevator_up")
		await anim.animation_finished
		var player = find_child("Player")
		player.reparent(get_parent(),true)

func set_floor(path,new_floor:int):
	previous_floor = current_floor
	current_floor = new_floor

func move_indicator(floor:int):
	if floor in floors:
		var target_rotation = floors[floor]
		var tween = get_tree().create_tween()
		tween.tween_property(floor_indicator, "rotation_degrees:z", target_rotation, 5.0).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
