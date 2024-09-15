extends CharacterBody3D

@export var disabled:bool = false
@export var roaming: bool = false
@export var speed : float = 5.0
@export var push_force : float = 100.0
@onready var nav:NavigationAgent3D = $NavigationAgent3D
@onready var spawnpoints: Node = get_parent().find_child("MonsterSpawnPositions")
@onready var nav_timer:Timer = $NavigationAgent3D/Nav_timer
@export var aggro_timeout: float = 5.0
@onready var aggro_timer: Timer = $Aggro_Timer
@export var stop_threshold: float = 0.5
@onready var monster_body = $godot_rig
@onready var cooldown_timer: Timer = $Cooldown_Timer
@export var chase_sound: Resource
@export var sound_resource_path = ""
@onready var chase_sound_initial: AudioStreamPlayer3D = $Chase_Sound_Initial
@onready var navigation_region_3d: NavigationRegion3D = $"../NavigationRegion3D"
@onready var roaming_soundloop: AudioStreamPlayer3D = $Roaming_Soundloop
@onready var roaming_timer: Timer = $Roaming_Timer
@onready var turn_timer: Timer = $Turn_timer
@onready var hit_sound: AudioStreamPlayer3D = $Hit_Sound
@onready var hit_laugh: AudioStreamPlayer3D = $Hit_Laugh
var hit_death

var monster_anim:AnimationPlayer
var chasing:bool
var player
var player_in_vision_flag
@onready var col = $CollisionShape3D

func _ready():
	hit_death = load("res://Assets/Audio/SoundFX/AmbientScares/JohnScream1.ogg")
	chase_sound = load(sound_resource_path)
	player_in_vision_flag = false
	monster_anim = monster_body.find_child("AnimationPlayer")
	player = GameManager.get_player()
	aggro_timer.wait_time = aggro_timeout

func _input(event):
	if event.is_action_pressed("p"):
		var point = NavigationServer3D.map_get_random_point(navigation_region_3d.get_navigation_map(), navigation_region_3d.get_navigation_layers(), false)
		nav.set_target_position(point)
		roaming_soundloop.playing = true
		roaming_timer.start(25)
		turn_timer.start(12)
		monster_anim.play("WalkScary")
		roaming = true
		visible = true
		disabled = false
		col.disabled = false

func _physics_process(_delta):
	if !disabled:
		move_to_target()

func move_to_target():
	var destination = nav.get_next_path_position()
	var local_destination = destination - global_position
	var direction = local_destination.normalized()
	if velocity.abs() > Vector3.ZERO:
		look_at(global_position + velocity, Vector3.UP)
	if local_destination.length() < stop_threshold:
		monster_anim.stop()
		return
	if roaming:
		speed = 1.5
	else:
		speed = 5
	velocity = direction * speed
	apply_pushes()
	
	# TODO: The following wont detect the player, why? Who knows
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		if c.get_collider().name == "Player" or c.get_collider().name == "Mailcart":
			c.get_collider().hit_by_entity()
			chasing = true
			if c.get_collider().extra_life == 1:
				hit_sound.playing = true
				hit_laugh.playing = true
			else:
				hit_sound.playing = true
				AudioController.play_resource(hit_death)
			stop_chasing_player()
	move_and_slide()

func apply_pushes():
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		if c.get_collider() is RigidBody3D:
			if c.get_collider().freeze == true:
				c.get_collider().freeze = false
			c.get_collider().apply_central_force(-c.get_normal() * speed*5)

func chase_player():
	if !chasing:
		turn_timer.stop()
		roaming_soundloop.playing = false
		chase_sound_initial.playing = true
		AudioController.play_resource(chase_sound, 0)
		print("START CHASING PLAYER")
		monster_anim.play("Run")
		chasing = true
		roaming = false
		nav_timer.start()

func stop_chasing_player():
	if chasing:
		AudioController.stop_resource(sound_resource_path, 2)
		print("STOP CHASING PLAYER")
		chasing = false
		disabled = true
		visible = false
		col.disabled = true
		roaming = true
		roaming_soundloop.playing = false
		cooldown_timer.start(randi_range(15, 45))
		nav_timer.stop()

func on_player_in_vision():
	if !disabled and player_in_vision_flag == false:
		print("STOP AGGRO TIMER")
		player_in_vision_flag = true
		chase_player()
		aggro_timer.stop()

func on_player_out_of_vision():
	if !disabled and player_in_vision_flag == true:
		print("START AGGRO TIMER")
		player_in_vision_flag = false
		aggro_timer.start()

func _on_nav_timer_timeout():
	if !disabled:
		nav.set_target_position(player.global_position)

func _on_aggro_timer_timeout():
	print("AGGRO TIMER TIMEOUT...")
	if chasing and player_in_vision_flag == false:
		stop_chasing_player()
		
func _on_cooldown_timer_timeout():
	if roaming and !chasing:
		#Spawn John on a random position not in the players view
		var arr = spawnpoints.get_children()
		arr.shuffle()
		for i in arr:
			if !i.observed:
				print(i.name)
				visible = true
				col.disabled = false
				disabled = false
				set_position(i.global_position)
				set_rotation(i.rotation)
				position.y = 0
				var point = NavigationServer3D.map_get_random_point(navigation_region_3d.get_navigation_map(), navigation_region_3d.get_navigation_layers(), false)
				nav.set_target_position(point)
				monster_anim.play("WalkScary")
				roaming_soundloop.playing = true
				roaming_timer.start(25)
				turn_timer.start(12)
				AudioController.stop_resource(sound_resource_path, 2)
				return

func _on_roaming_timer_timeout() -> void:
	print("STOP CHASING PLAYER")
	chasing = false
	disabled = true
	visible = false
	col.disabled = true
	roaming = true
	roaming_soundloop.playing = false
	cooldown_timer.start(randi_range(15, 45))
	nav_timer.stop()

func _on_turn_timer_timeout() -> void:
	var point = NavigationServer3D.map_get_random_point(navigation_region_3d.get_navigation_map(), navigation_region_3d.get_navigation_layers(), false)
	nav.set_target_position(point)
