extends Node3D
var has_been_executed = false
var scare_played = false
@onready var mailcart: RigidBody3D = GameManager.get_mail_cart()
@onready var player: CharacterBody3D = GameManager.get_player()
@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D
const HR_WING_WARNING = preload("res://Assets/Audio/SoundFX/VoiceLines/HrWingWarning.ogg")
@onready var door_lock: Node = $"../../NavigationRegion3D/human_resources_primary_wing/WALLS/HR_ArchwayWall/Door_Lock"
@onready var ceiling_tile_nolight_5: Node3D = $"../../NavigationRegion3D/HumanResourcesLobbyRoom/CEILING/ceiling_tile_nolight5"
@onready var animation_player: AnimationPlayer = $"../../NavigationRegion3D/HumanResourcesLobbyRoom/CEILING/ceiling_tile_nolight4/CeilingBroken3/OmniLight3D/AnimationPlayer"
@onready var ceiling_broken_3: MeshInstance3D = $"../../NavigationRegion3D/HumanResourcesLobbyRoom/CEILING/ceiling_tile_nolight4/CeilingBroken3"
@onready var spark_animater: AnimationPlayer = $"../../NavigationRegion3D/HumanResourcesLobbyRoom/CEILING/ceiling_tile_nolight4/CeilingBroken3/spark_emitter/spark_animater"
const QUAKING_HUM_1 = preload("res://Assets/Audio/SoundFX/AmbientNeutral/QuakingHum1.ogg")
func _ready():
	mailcart = GameManager.get_mail_cart()
	player = GameManager.get_player()
	ScareDirector.connect("package_delivered", activate_scare)

func activate_scare(package_num:int):
	if package_num == 1:
		animation_player.play("flicker")
		ceiling_tile_nolight_5.queue_free()
		ceiling_broken_3.visible = true
		spark_animater.play("random_sparks")
		has_been_executed = true
		await get_tree().create_timer(1.88).timeout
		audio_stream_player_3d.play()
		await audio_stream_player_3d.finished
		audio_stream_player_3d.pitch_scale = 0.77
		audio_stream_player_3d.play()
		AudioController.play_resource(QUAKING_HUM_1, 0)
		await audio_stream_player_3d.finished
		await get_tree().create_timer(2.75).timeout
		scare_played = true
		door_lock.unlock()

func _process(delta: float) -> void:
	if scare_played and player.global_position.distance_to(mailcart.global_position) < 11.5:
		GameManager.get_player_radio().play_narrator_sound(HR_WING_WARNING)
		queue_free()
