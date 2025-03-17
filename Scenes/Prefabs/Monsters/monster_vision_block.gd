extends RayCast3D

@export var parent: CharacterBody3D
@export var timer: Timer
@export var time_to_detect: float = 0.4
@export var should_instant_detect: bool = true
@export var max_range = 5.75
@export var max_angle = 180
@onready var cutter_ai: CharacterBody3D = $"../.."

var player: CharacterBody3D
var player_in_vision: bool = false
var detect_player: bool = false
var _time_spent_seen: float = 0

# TODO:
# The script works. Make several copies of the lookup_raycast on the cutter and make sure they all signal correctly and in the right order!

func _ready() -> void:
	timer.timeout.connect(_on_vision_refresh_timer_timeout)
	player = GameManager.get_player()

func _process(delta: float) -> void:
	if !should_instant_detect:
		if player_in_vision:
			_time_spent_seen += delta
			if _time_spent_seen > time_to_detect:
				detect_player = true
				_time_spent_seen = 0
		else:
			_time_spent_seen = 0

func _physics_process(delta: float) -> void:
	update_raycast_direction()

func _on_vision_refresh_timer_timeout() -> void:
	if should_instant_detect:
		_vision_check_instant()
	else:
		_vision_check_timed()

func _vision_check_instant():
	if parent.visible:
		var overlap = get_collider()
		if is_colliding() and overlap != null:
			if overlap.name == "Player" or (overlap.name == "Mailcart" and GameManager.player_reference.state is CartingState):
				detect_player = true
				return
	detect_player = false

func _vision_check_timed():
	if parent.visible:
		var overlap = get_collider()
		if is_colliding() and overlap != null:
			if overlap.name == "Player" or (overlap.name == "Mailcart" and GameManager.player_reference.state is CartingState):
				player_in_vision = true
				return
	player_in_vision = false

func update_raycast_direction():
	if !(abs(player.global_position.distance_to(global_position)) > max_range) and is_player_in_front(player, parent, max_angle):
		self.enabled = true
		look_at((player.global_position + Vector3(0, 0.35, 0)))
		set_target_position(Vector3(0, 0, -max_range))
	else:
		player_in_vision = false
		self.enabled = false

func is_player_in_front(player: Node3D, enemy: Node3D, max_angle: float) -> bool:
	var enemy_forward = -enemy.global_transform.basis.z # Cutter's forward direction
	var to_player = ((player.global_position + Vector3(0, 0.35, 0)) - enemy.global_position).normalized() # Vector to player
	var dot_product = enemy_forward.dot(to_player)
	# Convert max_angle to radians and get its cosine
	var cos_max_angle = cos(deg_to_rad(max_angle))
	return dot_product >= cos_max_angle # True if within max_angle, False otherwise
