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
@export var aggro_sound: Resource
@export var sound_resource_path = ""
@export var aggro_sound_resource_path = ""
@onready var chase_sound_initial: AudioStreamPlayer3D = $Chase_Sound_Initial
@onready var navigation_region_3d: NavigationRegion3D = $"../NavigationRegion3D"
@onready var roaming_soundloop: AudioStreamPlayer3D = $Roaming_Soundloop
@onready var roaming_timer: Timer = $Roaming_Timer
@onready var turn_timer: Timer = $Turn_timer
@onready var hit_sound: AudioStreamPlayer3D = $Hit_Sound
@onready var hit_laugh: AudioStreamPlayer3D = $Hit_Laugh
var hit_death
var _is_visible = false
@onready var heard_sound: AudioStreamPlayer3D = $Heard_Sound
@onready var sound_heard_timer: Timer = $Sound_Heard_Timer
@onready var sound_heard_chase_timer: Timer = $Sound_Heard_Chase_Timer
@onready var draw_timer: Timer = $DrawTimer
@onready var navlink_cooldown_timer: Timer = $NavlinkCooldownTimer
@onready var window_scare: Node3D = $"../1ST FLOOR SCARES/WINDOW SCARE"
@onready var darkroom_scare: Node3D = $"../1ST FLOOR SCARES/DARKROOM SCARE"

var roaming_to_sound = false
var locations: Array[Vector3] = []
var monster_anim:AnimationPlayer
var chasing:bool
var player
var player_in_vision_flag
var curPath
var drawnObjects: Array[Node] = []
@onready var col = $CollisionShape3D

#TODO:
# JOHN NEEDS TO BE SCARIER, 
#	MORE INTENSE LUNGE AT INITIAL AGGRO
#	MORE INTENSE CHASE SOUNDS 
#	MORE DYNAMIC AUDIOS AND STATES (ANIMS AND AUDIO)
#	LESS REPEATING ROAMING SOUNDS, MORE ETHEREAL?? TALK TO THE TEAM
#	BETTER PATHFINDING BEHAVIOUR, CHECK WHY HE GETS STUCK SOMETIMES
#	OBSTRUCTION REMOVAL ANIMATION (OBSTRUCTION_THROW ANIMATION KIND OF)

func _ready():
	var meshInstance = MeshInstance3D.new()
	meshInstance.transform.origin = global_position
	
	var mesh = SphereMesh.new()
	mesh.radius = 1
	mesh.height = 1
	meshInstance.mesh = mesh
	
	hit_death = load("res://Assets/Audio/SoundFX/AmbientScares/JohnScream1.ogg")
	chase_sound = load(sound_resource_path)
	aggro_sound = load(aggro_sound_resource_path)

	player_in_vision_flag = false
	monster_anim = find_child("AnimationPlayer")
	player = GameManager.get_player()
	aggro_timer.wait_time = aggro_timeout
	ScareDirector.connect("package_delivered", enable_john)
	
func enable_john(package_num):
	if package_num == 5 and window_scare == null and darkroom_scare == null:
		cooldown_timer.start(randi_range(9, 25))

func _input(event):
	if event.is_action_pressed("p"):
		if !visible:
			set_new_nav_position()
			roaming_soundloop.playing = true
			roaming_timer.start(25)
			turn_timer.start(12)
			monster_anim.play("WalkScary")
			roaming = true
			visible = true
			disabled = false
			col.disabled = false
		else:
			set_new_nav_position()

func _physics_process(_delta):
	if !disabled:
		move_to_target()

func move_to_target():
	if roaming and !roaming_to_sound:
		speed = 1.5
	elif roaming_to_sound:
		speed = 2.85
	else:
		speed = 5.5
	var current_location = global_transform.origin
	var next_location = nav.get_next_path_position()
	var new_velocity = (next_location - current_location).normalized() * speed
	var distance_to_goal = abs(nav.get_final_position().distance_to(current_location))
	new_velocity = Vector3(new_velocity.x, 0, new_velocity.z)
	velocity = new_velocity
	move_and_slide()

	if velocity.abs() > Vector3.ZERO:
		look_at(global_position + velocity, Vector3.UP)
	if distance_to_goal < stop_threshold:
		if roaming_to_sound:
			roaming_to_sound = false
			sound_heard_chase_timer.stop()
			turn_timer.start(randi_range(1, 5))
			roaming_timer.start(randi_range(10, 35))
		monster_anim.play("Idle")
		return
	apply_pushes()
	
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

func apply_pushes():
	get_collision_exceptions()
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		if c.get_collider() is RigidBody3D:
			if c.get_collider().freeze == true:
				c.get_collider().freeze = false
			c.get_collider().set_linear_velocity(Vector3.ZERO)
			c.get_collider().apply_central_force(-c.get_normal() * 1)

func chase_player():
	if !chasing:
		turn_timer.stop()
		roaming_timer.stop()
		roaming_soundloop.playing = false
		chase_sound_initial.playing = true
		AudioController.play_resource(chase_sound, 0)
		AudioController.play_resource(aggro_sound, 0)
		monster_anim.play("Run")
		chasing = true
		roaming = false
		nav_timer.start()

func stop_chasing_player():
	if chasing:
		AudioController.stop_resource(sound_resource_path, 2)
		chasing = false
		disabled = true
		visible = false
		col.disabled = true
		roaming = true
		roaming_soundloop.playing = false
		cooldown_timer.start(randi_range(15, 35))
		nav_timer.stop()

func on_player_in_vision():
	if !disabled and player_in_vision_flag == false:
		roaming_to_sound = false
		player_in_vision_flag = true
		chase_player()
		aggro_timer.stop()

func on_player_out_of_vision():
	if !disabled and player_in_vision_flag == true:
		player_in_vision_flag = false
		aggro_timer.start()
		
func on_hearing_sound(pos):
	if !chasing and sound_heard_timer.time_left <= 0:
		sound_heard_chase_timer.start(9)
		sound_heard_timer.start(5)
		heard_sound.playing = true
		monster_anim.play("Walk_001")
		nav_timer.stop()
		turn_timer.stop()
		roaming_timer.stop()
		roaming_to_sound = true
		set_new_nav_position(Vector3(pos.x + randf_range(-2.5, 2.5), 0, pos.z + randf_range(-2.5, 2.5)))

func _on_nav_timer_timeout():
	if !disabled and navlink_cooldown_timer.time_left <= 0:
		set_new_nav_position(player.global_position)

func _on_aggro_timer_timeout():
	if chasing and player_in_vision_flag == false:
		stop_chasing_player()
		
# Spawn a roaming John
func _on_cooldown_timer_timeout():
	if roaming and !chasing:
		#Spawn John on a random position not in the players view
		var arr = spawnpoints.get_children()
		arr.shuffle()
		for i in arr:
			if !i.observed:
				visible = true
				col.disabled = false
				disabled = false
				set_position(i.global_position)
				set_rotation(i.rotation)
				position.y = 0
				set_new_nav_position()
				monster_anim.play("WalkScary")
				roaming_soundloop.playing = true
				roaming_timer.start(25)
				turn_timer.start(12)
				AudioController.stop_resource(sound_resource_path, 2)
				return

# Check if we should despawn John
func _on_roaming_timer_timeout() -> void:
	if !is_visible:
		chasing = false
		disabled = true
		visible = false
		col.disabled = true
		roaming = true
		roaming_soundloop.playing = false
		cooldown_timer.start(randi_range(15, 35))
		nav_timer.stop()
	else:
		roaming_timer.start(randi_range(7, 20))
		turn_timer.start(randi_range(2, 5))

# Set a new direction for roaming John
func _on_turn_timer_timeout() -> void:
	roaming = true
	set_new_nav_position()
	monster_anim.play("WalkScary")

func _on_visible_on_screen_notifier_3d_screen_entered() -> void:
	_is_visible = true

func _on_visible_on_screen_notifier_3d_screen_exited() -> void:
	_is_visible = false

func _on_sound_heard_chase_timer_timeout() -> void:
	if roaming_to_sound:
		roaming_to_sound = false
		turn_timer.start(0.5)
		roaming_timer.start(randi_range(10, 35))
		monster_anim.play("Idle")

func set_new_nav_position(pos: Vector3 = Vector3.ZERO):
	if pos == Vector3.ZERO:
		var point = NavigationServer3D.map_get_random_point(navigation_region_3d.get_navigation_map(), navigation_region_3d.get_navigation_layers(), false)
		nav.set_target_position(point)
		var count = 0
		while !nav.is_target_reachable() and count < 15:
			point = NavigationServer3D.map_get_random_point(navigation_region_3d.get_navigation_map(), navigation_region_3d.get_navigation_layers(), false)
			nav.set_target_position(point)
			count += 1
	else:
		nav.set_target_position(pos)
		var count = 0
		while !nav.is_target_reachable() and count < 15:
			var point = pos + Vector3(randf_range(-3.5, 3.5), 0, randf_range(-3.5, 3.5))
			nav.set_target_position(point)
			count += 1


func _on_navigation_agent_3d_link_reached(_details: Dictionary) -> void:
	navlink_cooldown_timer.start()
	
	
# Enum-like dictionary to map effect names to numbers
enum Effect { NONE, MONSTER_SEEN, DELAY }

# Export this variable so you can select from the editor
@export var effect_type: Effect = Effect.NONE
@export var delay_length: float = 0
var keep_scare_vision: bool = true
signal external_callback
var _running_callback = false
#signal callback_done

# External callback function that could have some delay or complex operations
func scare_vision_external_callback() -> void:
	_running_callback = true
	match effect_type:
		Effect.MONSTER_SEEN:
			await _seen_check_for(false)
		Effect.DELAY:
			await delay_length
	emit_signal("external_callback")
	_running_callback = false

func _exit_tree() -> void:
	if _running_callback:
		emit_signal("external_callback")
		_running_callback = false
	
func _seen_check_for(seen: bool):
	var flag = !seen 
	while flag != seen:
		flag = await ScareDirector.monster_seen
