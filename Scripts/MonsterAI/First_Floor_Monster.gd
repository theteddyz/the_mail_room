extends Node3D
@onready var monster_body:CharacterBody3D = $CharacterBody3D
@onready var black_out_light = $"../CeilingLights/BlackOutLight"
@onready var cubicle_wall = $"../LowWalls/Cubicle_wall_monster"
@onready var hallwayLight1 = $"../CeilingLights/HallwayLight1"
@onready var hallwayLight2 = $"../CeilingLights/HallwayLight2"
@onready var scare_2_location_light = $"../CeilingLights/CeilingLightOn32"
@export var rotation_speed: float = 1.0
@onready var audio_player:AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var anim:AnimationPlayer = $"../CeilingLights/BlackOutLight/AnimationPlayer"
@onready var anim_scare_2:AnimationPlayer = $"../CeilingLights/CeilingLightOn23/AnimationPlayer"
@onready var scare_1_location = $Scare_1_Monster_location
@onready var scare_2_location = $Scare_2_Monster_location
var player: Node = null
var peak_monster_scare:bool = false
func _ready():
	monster_body.visible = false
	player = GameManager.player_reference
	EventBus.connect("peaking_monster",enable_monster)
	EventBus.connect("package_delivered",update_monster)

func update_monster(pack_num):
	if pack_num == 2:
		peak_monster_scare = true

func _input(event):
	if event.is_action_pressed("sprint"):
		close_up_monster_scare()
		monster_body.visible = true
		#peak_monster_scare = true
		#enable_monster()
	#if event.is_action_pressed("crouch") and peak_monster_scare:
		#black_out_scare()

func _process(delta):
	if peak_monster_scare:
		peak_monster(delta)
func enable_monster():
	visible = true
	peak_monster_scare = true
func peak_monster(delta: float):
	monster_body.position = scare_1_location.position
	monster_body.visible = true
	var direction_to_player = (player.global_transform.origin - monster_body.global_transform.origin).normalized()
	var current_forward = -monster_body.global_transform.basis.z.normalized()
	var target_rotation = current_forward.slerp(direction_to_player, rotation_speed * delta)
	var new_basis = Basis(target_rotation.cross(Vector3.UP).normalized(),Vector3.UP, -target_rotation).orthonormalized()
	monster_body.global_transform.basis = new_basis

func black_out_scare():
	monster_body.visible = false
	cubicle_wall.queue_free()
	anim.play("black_out_scare_anim")
	hallwayLight1.visible = false
	hallwayLight2.visible = false
	await anim.animation_finished
	audio_player.play()

func close_up_monster_scare():
	monster_body.position = scare_2_location.position
	monster_body.rotation = scare_2_location.rotation
	peak_monster_scare = true
	anim_scare_2.play("monster_scare_2")

func _on_area_3d_body_entered(body):
	if body.name == "Player" and peak_monster_scare:
		#visible = false
		peak_monster_scare = false
