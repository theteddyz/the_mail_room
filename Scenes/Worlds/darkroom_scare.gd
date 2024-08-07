extends Node3D

var has_been_executed = false
@onready var lock_door_area: Area3D = $door_slam_starter
@onready var door_slam_anim: AnimationPlayer = $AnimationPlayer
@onready var doorlock = $"../../NavigationRegion3D/Walls/StaticBody3D127/RigidBody3D2/Door_Lock"
@onready var flickeranimationplayer:AnimationPlayer = $"../../CeilingLights/CeilingLightOn52/AnimationPlayer"
@onready var hallwayflickeranimationplayer:AnimationPlayer = $"../../CeilingLights/CeilingLightOn8/FlickeringLight"
@onready var monster_run_soundplayer:AudioStreamPlayer3D = $MonsterRunSoundPlayer
var scare_active: bool = false
@onready var monster_body = $godot_rig
var monster_anim:AnimationPlayer
# Called when the node enters the scene tree for the first time.
func _ready():
	monster_anim = monster_body.get_child(1)
	ScareDirector.connect("key_pickedup", activate_scare)
	ScareDirector.connect("monster_seen", monster_seen_event)


func activate_scare(key_num:int):
	if key_num == 1:
		monster_anim.play("DoorSlam")
		monster_anim.speed_scale = 0
		monster_body.visible = true
		has_been_executed = true	# Variable necessary for all scares, tells other scares which ones have been executed
		door_slam_anim.play("door_open")
		scare_active = true
		print("SCARE ACTIVATED!")
func monster_seen_event(test):
	if(scare_active):
		doorlock.locked = true
		print("DOOR LOCKING!")
		flickeranimationplayer.pause()		
		flickeranimationplayer.play("RESET")
		monster_anim.current_animation = ""
		monster_anim.speed_scale = 1
		door_slam_anim.play("door_lock")
		hallwayflickeranimationplayer.play("flicker")
		monster_run_soundplayer.playing = true
		var timer = get_tree().create_timer(5.0)
		timer.timeout.connect(_end_scare)
# Sent when player walks forward into area in the middle of the room
func _on_door_slam_starter_body_entered(_body):
	pass
	#if(!scare_active):
		#doorlock.locked = true
		#scare_active = true
		#print("DOOR LOCKING!")
		#flickeranimationplayer.pause()		
		#flickeranimationplayer.play("RESET")
		#monster_anim.current_animation = ""
		#monster_anim.speed_scale = 1
		#door_slam_anim.play("door_lock")
		#hallwayflickeranimationplayer.play("flicker")
		#monster_run_soundplayer.playing = true
		#var timer = get_tree().create_timer(5.0)
		#timer.timeout.connect(_end_scare)

func _end_scare():
	doorlock.locked = false
	queue_free()
