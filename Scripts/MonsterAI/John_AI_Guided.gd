extends CharacterBody3D

@export var disabled:bool = false
@export var speed : float = 4.75
@onready var nav:NavigationAgent3D = $NavigationAgent3D
@export var stop_threshold: float = 0.5

var callback_when_close: Callable
var player: CharacterBody3D
signal callback_for_playerhit

func _ready():
	find_child("CollisionShape3D").disabled = true
	remove_from_group("scarevision")
	player = GameManager.get_player()
	
func _set_nav_position(pos: Vector3):
	set_new_nav_position(pos)

func _physics_process(delta: float):
	if !disabled:
		move_to_target(delta)
		if check_if_slideto_player():
			callback_for_playerhit.emit()

func move_to_target(delta):
	var current_location = global_transform.origin
	var next_location = nav.get_next_path_position()
	var new_velocity = (next_location - current_location).normalized() * speed
	var distance_to_goal = abs(nav.get_final_position().distance_to(current_location))
	new_velocity = Vector3(new_velocity.x, 0, new_velocity.z)
	velocity = new_velocity
	move_and_slide()
	if velocity.length() > 0.01:
		var target_rotation = Transform3D(Basis().looking_at(velocity.normalized(), Vector3.UP), global_position)
		global_transform.basis = global_transform.basis.slerp(target_rotation.basis, 10 * delta)  # Adjust 0.1 for rotation speed
	if distance_to_goal < stop_threshold:
		callback_when_close.call()

func set_new_nav_position(pos: Vector3, callback = func(): {}):
	find_child("CollisionShape3D").disabled = false
	callback_when_close = callback
	nav.set_target_position(pos)

func check_if_slideto_player():
	if player and player.is_inside_tree():
		var my_pos = global_transform.origin
		var player_pos = player.global_transform.origin
		
		# Optionally ignore Y-axis if only horizontal distance matters
		my_pos.y = 0
		player_pos.y = 0
		
		var distance = my_pos.distance_to(player_pos)
		return distance <= 0.82
	return false
