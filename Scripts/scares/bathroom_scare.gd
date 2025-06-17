extends Node3D
var scare_index = 4
var has_been_executed = false

@onready var anim:AnimationPlayer = $AnimationPlayer
var player:Node3D
var floor_ambiance_sound: Resource
var bathroom_ambiance_riser: Resource
var bathroom_ambiance_riser_loop: Resource
var corpse_music: Resource
var end_ambience: Resource
var static_sfx: Resource
@onready var door_lock: Node = $"../../NavigationRegion3D/Walls/StaticBody3D42/RigidBody3D2/RigidBody3D2/Door_Lock"
@onready var animation_player_for_bathroom_scare: AnimationPlayer = $"../../Roof/CeilingLightOn4/AnimationPlayerForBathroomScare"
@onready var faucet_drip_sound: AudioStreamPlayer3D = $FaucetDripSound
@onready var corpse_model: Node3D = $corpse_model
@onready var corpse_animation_player: AnimationPlayer = $corpse_model/AnimationPlayer
@onready var omni_light_3d: OmniLight3D = $OmniLight3D
@onready var spot_light_3d: SpotLight3D = $SpotLight3D
@onready var end_trigger: Area3D = $EndTrigger
@onready var john_for_scare: CharacterBody3D = $guided_john_predator_missile
@onready var john_position_guide: Marker3D = $john_position_guide
@onready var blood_scares: Node3D = $BloodScares
@onready var visible_on_screen_notifier_3d: VisibleOnScreenNotifier3D = $corpse_model/VisibleOnScreenNotifier3D
@onready var overlay_static_effect: TextureRect = Gui.find_child("StaticOverlay")

func _ready():
	end_trigger.monitoring = false
	corpse_model.visible = false 
	visible_on_screen_notifier_3d.screen_entered.connect(_on_corpse_observed)
	corpse_animation_player.play_section("WindowScare", 0.2053, 0.2055, -1, 0, false)
	corpse_animation_player.speed_scale = 0
	floor_ambiance_sound = load("res://Assets/Audio/SoundFX/FirstFloorAmbience2.mp3")
	bathroom_ambiance_riser = load("res://Assets/Audio/Music/BathroomRiserStart.ogg")
	bathroom_ambiance_riser_loop = load("res://Assets/Audio/Music/BathroomRiserLoop.ogg")
	corpse_music = load("res://Assets/Audio/SoundFX/AmbientScares/BathroomDiscoverySound.ogg")
	end_ambience = load("res://Assets/Audio/SoundFX/AmbientScares/BathroomEndSound.ogg")
	static_sfx = load("res://Assets/Audio/SoundFX/ChaseLoops/CutterAggroStatic.ogg")
	player = GameManager.get_player()

func _on_first_trigger_entered(body: Node3D) -> void:
	if !has_been_executed:
		has_been_executed = true
		ScareDirector.grabbable.connect(spawn_end_trigger)
		omni_light_3d.visible = true
		spot_light_3d.visible = true
		corpse_model.visible = true 
		animation_player_for_bathroom_scare.play("turn_off_lights")
		animation_player_for_bathroom_scare.queue("flicker")
		door_lock.locked = true
		door_lock.get_parent().position = Vector3.ZERO
		door_lock.get_parent().rotation = Vector3.ZERO
		await get_tree().create_timer(0.85).timeout
		EventBus.emitCustomSignal("disable_player_movement",[false,true])

func animation_trigger_light():
	blood_scares.visible = true	
	EventBus.emitCustomSignal("disable_player_movement",[false,false])
	faucet_drip_sound.playing = true
	AudioController.play_resource(floor_ambiance_sound, 1)

func spawn_end_trigger(grabbable:String):
	if grabbable == "corpse_door":
		end_trigger.monitoring = true

func _on_corpse_observed():
	AudioController.play_resource(corpse_music)

func _on_end_trigger(body: Node3D) -> void:
	AudioController.play_resource(end_ambience)
	AudioController.stop_resource(bathroom_ambiance_riser_loop.resource_path)
	AudioController.stop_resource(bathroom_ambiance_riser.resource_path)

	#EventBus.emitCustomSignal("disable_player_movement",[false,true])
	john_for_scare.callback_for_playerhit.connect(end_scare)
	john_for_scare.speed = 10.55
	john_for_scare.find_child("laughsound").playing = true
	john_for_scare.set_new_nav_position(john_position_guide.global_position, func(): john_for_scare.set_new_nav_position(player.global_position))
	john_for_scare.disabled = false
	john_for_scare.visible = true
	john_for_scare.find_child("AnimationPlayer").play("Run")
	(john_for_scare.find_child("AnimationPlayer") as AnimationPlayer).speed_scale = 3.0

func end_scare():
	animation_player_for_bathroom_scare.play("RESET")
	door_lock.locked = false
	omni_light_3d.visible = false
	spot_light_3d.visible = false
	john_for_scare.queue_free()
	AudioController.stop_resource(floor_ambiance_sound.resource_path, 0)
	EventBus.emitCustomSignal("disable_player_movement",[true,true])
	overlay_static_effect.visible = true
	AudioController.play_resource(static_sfx, 0, func(): {}, 16)
	await get_tree().create_timer(0.42).timeout
	EventBus.emitCustomSignal("disable_player_movement",[false,false])
	overlay_static_effect.visible = false
	AudioController.stop_resource(static_sfx.resource_path)
	queue_free()


func _on_riser_trigger_body_entered(body: Node3D) -> void:
	AudioController.play_resource(bathroom_ambiance_riser, 0, func(): AudioController.play_resource(bathroom_ambiance_riser_loop, 0, func(): {}, 6), 6)
	await get_tree().create_timer(1).timeout
	AudioController.stop_resource(floor_ambiance_sound.resource_path, 2)
