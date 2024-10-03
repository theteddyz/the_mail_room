extends Node3D

var has_been_executed = false
@onready var door_slam_anim: AnimationPlayer = $AnimationPlayer
@onready var doorlock = $"../../NavigationRegion3D/Walls/StaticBody3D127/RigidBody3D2/Door_Lock"
@onready var flickeranimationplayer:AnimationPlayer = $"../../CeilingLights/CeilingLightOn52/AnimationPlayer"
@onready var hallwayflickeranimationplayer:AnimationPlayer = $"../../CeilingLights/CeilingLightOn8/FlickeringLight"
@onready var monster_run_soundplayer:AudioStreamPlayer3D = $MonsterRunSoundPlayer
@onready var monsterCollisionShape:CollisionShape3D = $godot_rig/JohnCharacterBody/CollisionShape3D
var scare_active: bool = false
@onready var monster_body = $godot_rig
@onready var wall_to_nuke: StaticBody3D = $"../../Cubicle_Door"
var monster_anim:AnimationPlayer
var closed_ambiance
@onready var door = $"../../NavigationRegion3D/Walls/StaticBody3D127/RigidBody3D2"
@onready var john_typing_sound: AudioStreamPlayer3D = $"../CUBICLE SCARE/JohnTypingSoundPlayer"
@onready var ambience_starter: Area3D = $"../../AmbienceTriggers/darkroom_ambiences_triggers/ambience_starter"
@onready var ambience_starter_2: Area3D = $"../../AmbienceTriggers/darkroom_ambiences_triggers/ambience_starter2"
@onready var ambience_ender: Area3D = $"../../AmbienceTriggers/darkroom_ambiences_triggers/ambience_ender"
@onready var ambience_ender_2: Area3D = $"../../AmbienceTriggers/darkroom_ambiences_triggers/ambience_ender2"
@onready var ambience_ender_3: Area3D = $"../../AmbienceTriggers/darkroom_ambiences_triggers/ambience_ender3"

# Called when the node enters the scene tree for the first time.
func _ready():
	closed_ambiance = preload("res://Assets/Audio/SoundFX/AmbientScares/DoorSlamAmbience4.ogg")
	monster_anim = monster_body.find_child("AnimationPlayer")
	monsterCollisionShape.disabled = true
	ScareDirector.connect("key_pickedup", activate_scare)
	ScareDirector.connect("monster_seen", monster_seen_event)

func activate_scare(key_num:int):
	if key_num == 1 and has_been_executed == false:
		if john_typing_sound != null:
			john_typing_sound.playing = false
		monsterCollisionShape.disabled = false
		monster_anim.play("DoorSlam")
		monster_anim.speed_scale = 0
		monster_anim.seek(0.3)
		monster_body.visible = true
		has_been_executed = true	# Variable necessary for all scares, tells other scares which ones have been executed
		door_slam_anim.play("door_open")
		door_slam_anim.seek(0.3)
		scare_active = true
		print("SCARE ACTIVATED!")
		
func monster_seen_event(test):
	if(scare_active):
		scare_active = false
		if wall_to_nuke != null:
			wall_to_nuke.queue_free()
		doorlock.lock_door()
		await get_tree().create_timer(0.68).timeout
		print("DOOR LOCKING!")
		flickeranimationplayer.pause()
		flickeranimationplayer.play("RESET")
		flickeranimationplayer.speed_scale = 100
		monster_anim.current_animation = ""
		monster_anim.speed_scale = 1.25
		monster_anim.seek(0.3)
		door_slam_anim.play("door_lock")
		door_slam_anim.speed_scale = 1.125
		door_slam_anim.seek(0.3)
		hallwayflickeranimationplayer.play("flicker")
		monster_run_soundplayer.playing = true
		
		ambience_starter.monitoring = true
		ambience_starter_2.monitoring = true
		ambience_ender.monitoring = true
		ambience_ender_2.monitoring = true
		ambience_ender_3.monitoring = true

		var kill_monster_timer = get_tree().create_timer(1)
		kill_monster_timer.timeout.connect(_hide_monster)
		
		var timer = get_tree().create_timer(10.0)
		timer.timeout.connect(_end_scare)

func _on_slam():
	AudioController.play_resource(closed_ambiance)
	ScareDirector.emit_signal("monster_seen", false)


func _hide_monster():
	monster_body.queue_free()
	
func _door_opened(grabbable:String):
	if grabbable == door.name:
		AudioController.stop_resource("res://Assets/Audio/SoundFX/AmbientScares/DoorSlamAmbience4.ogg", 2)
		queue_free()

func _end_scare():
	ScareDirector.connect("grabbable", _door_opened)
	doorlock.unlock()
