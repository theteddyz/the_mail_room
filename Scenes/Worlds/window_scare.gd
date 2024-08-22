extends Node3D

var has_been_executed = false
var ready_to_start = false
@onready var monster_body = $godot_rig
@onready var door_lock = $"../../NavigationRegion3D/Walls/meeting_room_wall_Door13/RigidBody3D2/Door_Lock"
@onready var light_flicker_firstroom = $"../../CeilingLights/CeilingLightOn23/LightFlickering"
@onready var door_close = $"../../NavigationRegion3D/Walls/meeting_room_wall_Door13/DoorClose"
@onready var light_toner = $"../../CeilingLights/CeilingLightOn32/Toner"
@onready var scare_anim = $jumpscare
@onready var sighting_sound = $SightingSound
@onready var sighting_ambience = $SightingAmbiance
var monster_anim
@onready var john_typing_sound_player: AudioStreamPlayer3D = $"../CUBICLE SCARE/JohnTypingSoundPlayer"

# Called when the node enters the scene tree for the first time.
func _ready():
	monster_body.visible = false
	monster_anim = monster_body.find_child("AnimationPlayer")
	ScareDirector.connect("package_delivered", activate_scare)
	ScareDirector.connect("monster_seen", monster_seen_function)

func monster_seen_function(boolean: bool):
	if(ready_to_start):
		ready_to_start = false
		start_scare()

func activate_scare(package_num):
	if package_num == 4:
		john_typing_sound.playing = false
		ready_to_start = true
		has_been_executed = true	# Variable necessary for all scares, tells other scares which ones have been executed
		monster_body.visible = true
		monster_anim.play("Idle")
		door_lock.locked = true	
		door_close.play("close")

func start_scare():
	sighting_sound.play()
	sighting_ambience.play()
	light_toner.play("tone")
	light_flicker_firstroom.play("flicker")
	var timer = get_tree().create_timer(4.77)
	timer.timeout.connect(_jumpscare)

func _jumpscare():
	light_flicker_firstroom.stop()
	scare_anim.play("scare")
