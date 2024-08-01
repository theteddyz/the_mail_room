extends Node3D
@onready var monster_body:CharacterBody3D = $monster
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
@onready var scare_1_anim:AnimationPlayer = $"../NavigationRegion3D/Walls/StaticBody3D161/Scare1"

func _ready():
	monster_body.visible = false
	player = GameManager.player_reference
	#EventBus.connect("peaking_monster",enable_monster)
	#EventBus.connect("package_delivered",update_monster)
	#EventBus.connect("monster_seen", monster_seen)

func update_monster(pack_num):
	#if pack_num == 2:
		peak_monster_scare = true
	#if pack_num == 3:
		#black_out_scare()
	#if pack_num == 4:
		#close_up_monster_scare()

func first_monster_event():
	if monster_seen_:
		scare_1_anim.play("slam_door")
		audio_player.play()
		await get_tree().create_timer(1).timeout
		disable_monster()
		
func _process(delta):
	if peak_monster_scare:
		peak_monster(delta)
		
func disable_monster():
	var col = monster_body.find_child("CollisionShape3D")
	col.position = Vector3.ZERO
	monster_body.visible = false
	peak_monster_scare = false
	
func peak_monster(delta: float):
	monster_body.visible = true
	var direction_to_player = (player.global_transform.origin - monster_body.global_transform.origin).normalized()
	var current_forward = -monster_body.global_transform.basis.z.normalized()
	var target_rotation = current_forward.slerp(direction_to_player, rotation_speed * delta)
	var new_basis = Basis(target_rotation.cross(Vector3.UP).normalized(),Vector3.UP, -target_rotation).orthonormalized()
	monster_body.global_transform.basis = new_basis

func _on_area_3d_body_entered(_body):
	first_monster_event()

func monster_seen():
	if monster_body.visible == true:
		monster_seen_ = true
