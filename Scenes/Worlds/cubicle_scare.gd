extends Node3D

var has_been_executed = false
var player: Node = null
var door_slam_available: bool = false
var monster_seen: bool = false
var scare_finish_available: bool = false
@onready var monster_body = $godot_rig
@onready var door_slam_anim:AnimationPlayer = $"../../NavigationRegion3D/Walls/StaticBody3D156/DoorSlam"
@onready var audio_player:AudioStreamPlayer3D = $DoorSlamSoundPlayer
@onready var door_slam_area: Area3D = $door_slam_starter
@onready var darkroom_scare = $"../DARKROOM SCARE"
var anticipationSound
var impactSound
var packageholder
var anticipation_flag = false
var impact_flag = false

# todo : check if we spawn a collider on wall

func _ready():
	monster_body.visible = false
	player = GameManager.player_reference
	packageholder = player.find_child("PackageHolder")
	door_slam_area.monitoring = false
	anticipationSound = preload("res://Assets/Audio/SoundFX/AmbientScares/ScareCubicleAnticipation.ogg")
	impactSound = preload("res://Assets/Audio/SoundFX/AmbientScares/ScareCubicleImpact3.ogg")
	ScareDirector.connect("package_delivered", activate_scare)
	ScareDirector.connect("monster_seen", monster_seen_function)

func monster_seen_function(boolean: bool):		
	if(has_been_executed):
		monster_seen = boolean
		if !impact_flag:
			impact_flag = true
			AudioController.play_resource(impactSound)
			var anim = monster_body.find_child("AnimationPlayer")
			anim.play("PeakingOverCubicle2")
		
	
func activate_scare(package_num:int):
	if package_num == 2 and darkroom_scare != null and !darkroom_scare.has_been_executed:
		has_been_executed = true	# Variable necessary for all scares, tells other scares which ones have been executed
		monster_body.visible = true
		var anim = monster_body.find_child("AnimationPlayer")
		anim.play("PeakingOverCubicle")
		door_slam_area.monitoring = true
		print("SCARE ACTIVATED!")

func _process(_delta):
	if(door_slam_available and monster_seen and monster_body.visible):
		print("DOOR SLAMMED!")
		door_slam_anim.play("slam_door")
		audio_player.play()
		#var anim = monster_body.find_child("AnimationPlayer")
		#anim.play("PeakingOverCubicleDisappear")
		door_slam_available = false
		scare_finish_available = true
	
	if(scare_finish_available and !monster_seen):
		print("HIDING MONSTER!")
		scare_finish_available = false
		_hide_monster()

# Player has entered door_slam_started collider, sent from area3D
func _on_door_slam_starter_body_entered(_body):
	print("DOOR SLAM AVAILABLE.....!")
	door_slam_available = true
	
func _hide_monster():
	monster_body.visible = false
	queue_free()


func _on_anticipation_starter_body_entered(body: Node3D) -> void:
	var arr = packageholder.get_children()
	if arr.size() > 0 and arr[0].package_num == 2 and !anticipation_flag:
		anticipation_flag = true
		AudioController.play_resource(anticipationSound)
