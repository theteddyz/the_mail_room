extends CharacterBody3D

@export var disabled:bool = false
@export var speed : float = 5.0
@export var push_force : float = 100.0
@onready var nav:NavigationAgent3D = $NavigationAgent3D
@onready var nav_timer:Timer = $NavigationAgent3D/Timer
@export var aggro_timeout: float = 5.0
@onready var aggro_timer: Timer = $Aggro_Timer
@export var stop_threshold: float = 1.0
@onready var monster_body = $godot_rig
var monster_anim:AnimationPlayer
var target_position
var chasing:bool
var player
@onready var col = $CollisionShape3D
func _ready():
	monster_anim = monster_body.find_child("AnimationPlayer")
	player = GameManager.get_player()
	aggro_timer.wait_time = aggro_timeout

func _input(event):
	if event.is_action_pressed("p"):
		visible = true
		disabled = false
		col.disabled = false
func _physics_process(_delta):
	if target_position and !disabled:
		move_to_target()

func move_to_target():
	var destination = nav.get_next_path_position()
	var local_destination = destination - global_position
	var direction = local_destination.normalized()
	
	if local_destination.length() < stop_threshold:
		target_position = null
		monster_anim.stop()
		return
	velocity = direction * speed
	apply_pushes()
	move_and_slide()

func apply_pushes():
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		if c.get_collider() is RigidBody3D:
			if c.get_collider().freeze == true:
				c.get_collider().freeze = false
			c.get_collider().apply_central_force(-c.get_normal() * speed*5)

func _on_timer_timeout():
	if !disabled:
		look_at(player.global_position)
		target_position = player.global_position
		nav.set_target_position(player.global_position)


func chase_player():
	if !chasing:
		monster_anim.play("Run")
		chasing = true
		nav_timer.start()


func stop_chasing_player():
	if chasing:
		chasing = false
		nav_timer.stop()


func on_player_in_vision():
	if !chasing:
		chase_player()
	aggro_timer.start()

func on_player_out_of_vision():
	aggro_timer.start()

func _on_aggro_timer_timeout():
	if chasing:
		stop_chasing_player()

func on_hearing_sound(sound_position):
	if !chasing:
		look_at(sound_position)
		target_position = sound_position
		nav.set_target_position(sound_position)
