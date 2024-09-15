extends Node3D
@onready var anim:AnimationPlayer = $AnimationPlayer
@onready var john_laugh:AudioStreamPlayer3D = $AudioStreamPlayer3D2
@onready var door_slam_audio:AudioStreamPlayer3D = $DoorSlamming
@onready var eyes = $Eyes
var closed:bool = false
var trigger_3_Ambience
var trigger_1_Ambience
var triggered = false
var player:Node3D
var spawned = false
var scare_finished = false
@onready var flicker_light_sound = $"../../Roof/CeilingLightOn3/AudioStreamPlayer3D"
@onready var john_body = $John_Bathroom
@onready var john_anim = $John_Bathroom/godot_rig/AnimationPlayer
@onready var trigger_bathroom_door = $"../../Bathroom/StaticBody3D2/RigidBody3D"
@onready var second_bathroom_light = $"../../Roof/CeilingLightOn5/OmniLight3D"
@onready var second_bathroom_light_mesh = $"../../Roof/CeilingLightOn5/CeilingLightOnLight"
@onready var door_lock = $"../../NavigationRegion3D/Walls/StaticBody3D42/RigidBody3D2/Door_Lock"
func _ready():
	player = GameManager.get_player()
	trigger_3_Ambience = preload("res://Assets/Audio/SoundFX/AmbientScares/AmbienceScary.ogg")
	trigger_1_Ambience = preload("res://Assets/Audio/SoundFX/FirstFloorAmbience2.mp3")
	ScareDirector.connect("monster_seen", monster_seen_function)


func _on_area_3d_body_entered(body):
	if !closed and !scare_finished:
		flicker_light_sound.stop()
		anim.play("first_trigger")
		door_slam_audio.play()
		await anim.animation_finished
		closed = true
func monster_seen_function(b:bool):
	if spawned and b == true and !scare_finished:
		await get_tree().create_timer(1).timeout
		second_bathroom_light.visible = false
		second_bathroom_light_mesh.transparency = 1
		await get_tree().create_timer(0.1).timeout
		eyes.queue_free()
		john_body.queue_free()
		$BloodScares.visible = false
		await get_tree().create_timer(0.1).timeout
		door_lock.unlock()
		scare_finished = true
		flicker_light_sound.play()

func _second_trigger(body):
	if !triggered and body.name == "Player" and !scare_finished:
		
		triggered = true
		$BloodScares.visible = true
		second_bathroom_light.visible = true
		second_bathroom_light_mesh.transparency = 0
		AudioController.play_resource(trigger_1_Ambience)


func _third_trigger(body):
	if body.name == "bathroom_door" and triggered and !scare_finished:
		
		await get_tree().create_timer(1.0).timeout
		second_bathroom_light.visible = false
		second_bathroom_light_mesh.transparency = 1
		await get_tree().create_timer(0.5).timeout
		second_bathroom_light_mesh.transparency = 0
		second_bathroom_light.visible = true
		second_bathroom_light.light_color = Color.FIREBRICK
		if eyes != null:
			eyes.visible = true
		spawn_monster_behind_player()

func spawn_monster_behind_player():
	spawned = true
	john_body.global_position = Vector3(player.global_position.x,(player.global_position.y) ,(player.global_position.z -1))
	john_body.visible = true
	john_anim.play("Idle")
	john_laugh.play()
	AudioController.play_resource(trigger_3_Ambience)
