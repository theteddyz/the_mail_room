extends Node3D

@onready var lock_door_area: Area3D = $door_slam_starter
@onready var door_slam_anim: AnimationPlayer = $AnimationPlayer
@onready var doorlock = $"../../NavigationRegion3D/Walls/StaticBody3D127/RigidBody3D2/Door_Lock"
@onready var flickeranimationplayer = $"../../CeilingLights/CeilingLightOn52/AnimationPlayer"
var scare_active: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	lock_door_area.monitoring = false
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


func _on_animation_player_animation_finished(anim_name):
	if(anim_name == "door_lock"):
		doorlock.locked = false
		queue_free()
