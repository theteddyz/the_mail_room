extends Node3D

var current_floor = 0
var floors:Dictionary = {-2: 81.5, -1: 64, 0: 49, 1: 30.5, 2: 10.5, 3: -7, 4: -27, 5: -46, 6: -64, 7: -84}
var is_called = false
@onready var left_door:MeshInstance3D = $ElevatorEntrance/ElevatorEntranceDoor
@onready var right_door:MeshInstance3D = $ElevatorEntrance/ElevatorEntranceDoor_001
@onready var anim:AnimationPlayer = $AnimationPlayer
@onready var floor_indicator: MeshInstance3D = $ElevatorEntrance/ElevatorEntranceIndicator
# Called when the node enters the scene tree for the first time.
func _ready():
	left_door.set_position(Vector3.ZERO)
	right_door.set_position(Vector3.ZERO)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func call_elevator():
	var player_floor = get_tree().root.get_child(2).floor_num
	if !is_called:
		is_called = true
		if current_floor != player_floor:
			if current_floor > player_floor:
				anim.play("call_elevator_down")
				move_indicator(player_floor)
				await anim.animation_finished
				anim.play("door_open_outside")
			else:
				anim.play("call_elevator_up")
				move_indicator(player_floor)
				await anim.animation_finished
				anim.play("door_open_outside")
		else:
			anim.play("door_open_outside")


func move_indicator(floor:int):
	if floor in floors:
		var target_rotation = floors[floor]
		var tween = get_tree().create_tween()
		tween.tween_property(floor_indicator, "rotation_degrees:z", target_rotation, 5.0).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
