extends Node3D

@onready var lock_door_area: Area3D = $door_slam_starter
@onready var door_slam_anim: AnimationPlayer = $AnimationPlayer
@onready var doorlock = $"../../NavigationRegion3D/Walls/StaticBody3D127/RigidBody3D2/Door_Lock"
@onready var flickeranimationplayer:AnimationPlayer = $"../../CeilingLights/CeilingLightOn52/AnimationPlayer"
@onready var hallwayflickeranimationplayer:AnimationPlayer = $"../../CeilingLights/CeilingLightOn8/FlickeringLight"
@onready var monster_run_soundplayer:AudioStreamPlayer3D = $MonsterRunSoundPlayer
var scare_active: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	lock_door_area.monitoring = false
	hallwayflickeranimationplayer
	ScareDirector.connect("key_pickedup", activate_scare)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	

func activate_scare(key_num:int):
	if key_num == 1:
		
		door_slam_anim.play("door_open")
		lock_door_area.monitoring = true
		print("SCARE ACTIVATED!")

# Sent when player walks forward into area in the middle of the room
func _on_door_slam_starter_body_entered(body):
	if(!scare_active):
		doorlock.locked = true
		scare_active = true
		print("DOOR LOCKING!")
		flickeranimationplayer.pause()		
		flickeranimationplayer.play("RESET")
		door_slam_anim.play("door_lock")
		hallwayflickeranimationplayer.play("flicker")
		monster_run_soundplayer.playing = true
		var timer = get_tree().create_timer(5.0)
		timer.timeout.connect(_end_scare)

func _end_scare():
	doorlock.locked = false
	queue_free()
