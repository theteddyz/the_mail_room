extends Node3D

var scare_index = 2
var has_been_executed = false
var ready_to_start = false
@onready var monster_body = $godot_rig
@onready var door_lock = $"../../NavigationRegion3D/Walls/meeting_room_wall_Door13/RigidBody3D3/Door_Lock"
@onready var light_flicker_firstroom = $"../../CeilingLights/CeilingLightOn23/LightFlickering"
@onready var door_close = $"../../NavigationRegion3D/Walls/meeting_room_wall_Door13/DoorClose"
@onready var window_scare_toner: AnimationPlayer = $"../../CeilingLights/CeilingLightOn32/WINDOW_SCARE_TONER"

@onready var scare_anim: AnimationPlayer = $jumpscare
@onready var sighting_sound = $SightingSound
@onready var sighting_ambience = $SightingAmbiance
var monster_anim
var monster_seen = false
@onready var john_typing_sound: AudioStreamPlayer3D = $"../CUBICLE SCARE/JohnTypingSoundPlayer"
var window_scare_initial_sound
# Called when the node enters the scene tree for the first time.
func _ready():
	monster_body.visible = false
	window_scare_initial_sound = preload("res://Assets/Audio/SoundFX/AmbientScares/WindowScareInitial.ogg")
	monster_anim = monster_body.find_child("AnimationPlayer")
	ScareDirector.connect("package_delivered", activate_scare)
	ScareDirector.connect("monster_seen", monster_seen_function)

func monster_seen_function(_boolean: bool):
	monster_seen = _boolean
	if(_boolean and ready_to_start):
		ready_to_start = false
		start_scare()

func activate_scare(package_num):
	if package_num == 4:
		if john_typing_sound != null:
			john_typing_sound.playing = false
		ready_to_start = true
		has_been_executed = true	# Variable necessary for all scares, tells other scares which ones have been executed
		monster_body.visible = true
		monster_anim.play("Idle")
		door_lock.locked = true	
		door_close.play("close")
		if monster_seen == true:
			ready_to_start = false
			start_scare()

func start_scare():
	ScareDirector.emit_signal("scare_activated", scare_index)
	AudioController.play_resource(window_scare_initial_sound, 0, func():, 8.5)
	window_scare_toner.play("tone")
	light_flicker_firstroom.play("flicker")
	var timer = get_tree().create_timer(8.7)
	timer.timeout.connect(_jumpscare)

func _jumpscare():
	light_flicker_firstroom.stop()
	sighting_ambience.stop()
	scare_anim.play("scare")
	scare_anim.animation_finished.connect(_delete_scare)

func _delete_scare(anim):
	queue_free()
