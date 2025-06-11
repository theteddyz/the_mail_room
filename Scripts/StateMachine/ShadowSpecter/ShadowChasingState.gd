extends State
class_name ShadowChasingState

var player: CharacterBody3D
var roaming_speed := 5.1

# Timer References
@onready var timers = []

# Other assets / nodes
@onready var collision_shape_3d: CollisionShape3D = get_parent().find_child("CollisionShape3D")
@onready var hit_by_soundplayer: AudioStreamPlayer3D = get_parent().find_child("HitBySound")
@onready var chasing_behaviour_timer: Timer = get_parent().find_child("chasing_behaviour_timer")

func get_class_custom(): return "ShadowChasingState"

func _ready() -> void:
	player = GameManager.get_player()
	persistent_state.set_visible(true)
	collision_shape_3d.disabled = true
	chasing_behaviour_timer.start(randf_range(17.0, 26.0))
	chasing_behaviour_timer.timeout.connect(_respawn)
	
func _respawn():
	change_state.call("respawning")

func _process(_delta):
	update_position(_delta)
	update_rotation()
	if check_if_slideto_player():
		hit_by_soundplayer.play()
		player.extra_life = 0
		player.hit_by_entity()

func update_position(delta): 
	if player and player.is_inside_tree():
		var my_pos = persistent_state.global_position
		var target_pos = player.global_position
		
		# Ignore Y-axis (stay at the same height)
		target_pos.y = my_pos.y
		
		# Move towards the player
		var direction = (target_pos - my_pos).normalized()
		persistent_state.global_translate(direction * roaming_speed * delta)

func update_rotation():
	if player and player.is_inside_tree():
		persistent_state.look_at(player.global_transform.origin, Vector3.UP)

func check_if_slideto_player():
	if player and player.is_inside_tree():
		var my_pos = persistent_state.global_transform.origin
		var player_pos = player.global_transform.origin
		
		# Optionally ignore Y-axis if only horizontal distance matters
		my_pos.y = 0
		player_pos.y = 0
		
		var distance = my_pos.distance_to(player_pos)
		return distance <= 0.82
	return false

func stopTimers():
	for t in timers:
		t.stop()
