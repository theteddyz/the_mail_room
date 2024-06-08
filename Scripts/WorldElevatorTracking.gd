extends Node

@export var elevatorPosition: Vector3 = Vector3.ZERO

func _ready():
	var elevator = find_child("Elevator")
	if elevator != null:
		elevatorPosition = elevator.position;
