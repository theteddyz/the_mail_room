extends Node3D
var has_been_executed = false
# Variable necessary for all scares, tells other scares which ones have been executed
@onready var scare_trigger: Area3D = $scare_trigger
@onready var monster_spawn_location: Marker3D = $monster_spawn_location
@onready var cutter_ai: CharacterBody3D = $"../../cutter_ai"
@onready var trigger_col: CollisionShape3D = $scare_trigger/CollisionShape3D
@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D

func _ready():
	trigger_col.disabled = true
	ScareDirector.connect("package_delivered", activate_scare)

func activate_scare(package_num:int):
	if package_num == 1:
		audio_stream_player_3d.play()
		trigger_col.disabled = false

func _on_scare_trigger_body_entered(body: Node3D) -> void:
	if !has_been_executed:
		cutter_ai.global_position = monster_spawn_location.global_position
		cutter_ai.set_enabled(true)
		cutter_ai.can_see_player = true
		cutter_ai.aggro()
		trigger_col.queue_free()
