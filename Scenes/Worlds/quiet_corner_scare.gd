extends Node3D

var scare_index = 5
var has_been_executed = false
@onready var scare_5_vent_sound: AudioStreamPlayer3D = $"../../Scare5VentSound"
@onready var john_typing_sound_player: AudioStreamPlayer3D = $"../CUBICLE SCARE/JohnTypingSoundPlayer"
@onready var cubicle_wall_monster: StaticBody3D = $"../../Cubicle_Door"
@onready var monitor: RigidBody3D = $"../../NavigationRegion3D/Objects/Desk37/GrabableObjectTemplate/Monitor"
@onready var screen_light_2: SpotLight3D = $"../../NavigationRegion3D/Objects/Desk37/GrabableObjectTemplate/Monitor/ComputerOn/ScreenLight"

@onready var monitor_flicker: AnimationPlayer = $"../../NavigationRegion3D/Objects/Desk37/monitor_flicker"

func _ready():
	monitor_flicker.play("flicker")

func activate_scare():
	ScareDirector.emit_signal("scare_activated", scare_index)
	has_been_executed = true	# Variable necessary for all scares, tells other scares which ones have been executed
	scare_5_vent_sound.playing = false
	if john_typing_sound_player != null:
		john_typing_sound_player.playing = false
	if cubicle_wall_monster != null:
		cubicle_wall_monster.queue_free()
	print("SCARE ACTIVATED!")
	var timer = get_tree().create_timer(4.38)
	timer.timeout.connect(_end_scare)

func _end_scare():
	monitor_flicker.active = false
	screen_light_2.visible = false
	monitor.get_node("Monitor_Collision_Handler").break_object()
	monitor.get_node("Monitor_Collision_Handler").destruction_audios.play()
	monitor.get_node("ComputerOn").visible = false
	monitor.get_node("ComputerOff").visible = true


func _on_quiet_scare_starter_body_entered(body: Node3D) -> void:
	activate_scare()
