extends Node3D

var has_been_executed = false
@onready var scare_5_vent_sound: AudioStreamPlayer3D = $"../../Scare5VentSound"

func _ready():
	ScareDirector.connect("package_delivered", activate_scare)

func activate_scare(package_num:int):
	if package_num == 5:
		has_been_executed = true	# Variable necessary for all scares, tells other scares which ones have been executed
		scare_5_vent_sound.playing = false
		print("SCARE ACTIVATED!")
