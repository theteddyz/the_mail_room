extends State
class_name ShadowChasingState

var player: CharacterBody3D
var roaming_speed := 4.55

# Timer References
@onready var timers = [chasing_juke_timer,chasing_behaviour_timer]
var chasing_ambiance: Resource

# Other assets / nodes
@onready var collision_shape_3d: CollisionShape3D = get_parent().find_child("CollisionShape3D")
@onready var hit_by_soundplayer: AudioStreamPlayer3D = get_parent().find_child("HitBySound")
@onready var chasing_behaviour_timer: Timer = get_parent().find_child("chasing_behaviour_timer")
@onready var chasing_juke_timer: Timer = get_parent().find_child("chasing_juke_timer")
@onready var navigation_region_3d: NavigationRegion3D = get_parent().get_parent().find_child("NavigationRegion3D")
@onready var juke_soundplayer: AudioStreamPlayer3D = get_parent().find_child("JukeSound")
var just_juked = false
func get_class_custom(): return "ShadowChasingState"

func _ready() -> void:
	chasing_ambiance = load("res://Assets/Audio/Music/ShadowSpecterAggroChasingLoop.ogg")
	AudioController.play_resource(chasing_ambiance, 1, func(): {}, 10.5)
	player = GameManager.get_player()
	persistent_state.set_visible(true)
	collision_shape_3d.disabled = true
	chasing_behaviour_timer.start(randf_range(8.0*3, 16.0*3))
	chasing_juke_timer.start(randf_range(1.85, 4.5))
	chasing_juke_timer.timeout.connect(juke)
	chasing_behaviour_timer.timeout.connect(_respawn)
	
func _respawn():
	AudioController.stop_resource(chasing_ambiance.resource_path, 2)
	change_state.call("respawning")

func _process(_delta):
	if !just_juked:
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

func juke():
	just_juked = true
	var my_pos := persistent_state.global_position
	var original_distance := player.global_position.distance_to(my_pos)
	var best_point := my_pos
	var best_score := -INF
	
	for i in 7:
		var random_angle = randf() * TAU  # 0 to 2π
		var direction = Vector3(cos(random_angle), 0, sin(random_angle))
		var target_point = player.global_position + direction * original_distance
		
		var nav_point = NavigationServer3D.map_get_closest_point(navigation_region_3d.get_navigation_map(), target_point)
		if nav_point == Vector3.ZERO:
			continue  # skip invalid result
			
		var new_player_distance = player.global_position.distance_to(nav_point)
		var distance_to_player_diff = abs(original_distance - new_player_distance)
		var distance_from_original_position = my_pos.distance_to(nav_point)
		
		# Compute a score: maximize dist from old pos, minimize change in player distance
		var score = distance_from_original_position - (1 * distance_to_player_diff)
		if score > best_score:
			best_score = score
			best_point = nav_point
	persistent_state.global_position = Vector3(best_point.x, my_pos.y, best_point.z)
	juke_soundplayer.playing = true
	chasing_juke_timer.start(randf_range(1.85, 4.5)) if randf() <= 0.8 else chasing_juke_timer.start(randf_range(0.25, 0.6))
	get_tree().create_timer(0.6).timeout.connect(func(): just_juked = false)
