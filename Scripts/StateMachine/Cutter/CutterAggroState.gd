extends State
class_name CutterAggroState

var player: CharacterBody3D
var aggro_speed := 3
var player_in_vision_flag := false
var charging := false
var is_venting := false
var charge_position := Vector3.ZERO
var _fear_factor_max_range := 34.0
var _charge_kill_distance: float = 1.5
var initial_chase_sfx: Resource
var chaseloop_sfx: Resource
@onready var charge_tween: Tween

# Navigation References
@onready var navigation_region_3d: NavigationRegion3D = get_parent().get_parent().find_child("NavigationRegion3D")
@onready var navigation_agent_3d: NavigationAgent3D = get_parent().find_child("NavigationAgent3D")

# Timers
@onready var can_charge_timer: Timer = get_parent().find_child("CanChargeTimer")
@onready var de_aggro_timer: Timer = get_parent().find_child("DeAggroTimer")
@onready var navigation_timer: Timer = get_parent().find_child("IdleNavigationTimer")
@onready var get_player_position_timer: Timer = get_parent().find_child("GetPlayerPositionTimer")
@onready var fear_factor_maxxed_timer: Timer = get_parent().find_child("fear_factor_maxxed_timer")
@onready var nav_link_cooldown_timer: Timer =  get_parent().find_child("NavLinkCooldownTimer")

@onready var functional_timers = [de_aggro_timer, get_player_position_timer, navigation_timer]


# Other assets
@onready var hit_by_soundplayer: AudioStreamPlayer3D = get_parent().find_child("hit_by_soundplayer")
@onready var charge_slashing_soundplayer: AudioStreamPlayer3D = get_parent().find_child("charge_slashing_soundplayer")
@onready var aggro_sound_initial: AudioStreamPlayer3D = get_parent().find_child("AudioStreamPlayer3D")
@onready var collision_shape_3d: CollisionShape3D = get_parent().find_child("CollisionShape3D")
@onready var carcass_area_detector: Area3D = get_parent().get_parent().find_child("cutter_carcass_ai").find_child("Area3D")


func _ready() -> void:
	initial_chase_sfx = load("res://Assets/Audio/SoundFX/ChaseLoops/AggroSoundCutter.ogg")
	chaseloop_sfx = load("res://Assets/Audio/SoundFX/ChaseLoops/ChaseLoopCutter.ogg")
	player = GameManager.get_player()
	get_player_position_timer.timeout.connect(_on_get_player_position_timer_timeout)
	de_aggro_timer.timeout.connect(deAggro)
	carcass_area_detector.body_entered.connect(_on_area_3d_body_entered)
	can_charge_timer.start(1.25)
	aggro()

func get_class_custom(): return "CutterAggroState"

func aggro():
	ScareDirector.enable_intensity_flag.emit()
	aggro_sound_initial.playing = true
	
	# Stop all timers responsible for the idle behaviour
	navigation_timer.stop()
	
	# Set cutter to a standstill
	aggro_speed = 0
	
	# Play an aggro animation, sounds or the like
	await get_tree().create_timer(1.185).timeout
	AudioController.play_resource(chaseloop_sfx, 0, func(): {}, 12)
	AudioController.play_resource(initial_chase_sfx, 0, func(): {}, 17)
	aggro_speed = 3
	# Start the timer responsible for updating chase position
	get_player_position_timer.start(0.17)

func _physics_process(delta: float) -> void:
	if !charging:
		update_velocity(aggro_speed)
		update_rotation(delta)
		persistent_state.move_and_slide()
		check_if_slideto_player()
		if can_charge_timer.is_stopped() and player_in_vision_flag and !is_venting:
			charge()
	else:
		check_player_distance_for_kill()

func update_velocity(speed: float):
	var current_location = persistent_state.global_transform.origin
	var next_location = navigation_agent_3d.get_next_path_position()
	var new_velocity = (next_location - current_location).normalized() * speed
	#var distance_to_goal = abs(navigation_agent_3d.get_final_position().distance_to(current_location))
	new_velocity = Vector3(new_velocity.x, 0, new_velocity.z)
	persistent_state.velocity = new_velocity

func update_rotation(delta: float):
	if persistent_state.velocity.length() > 0.01:
		var target_rotation = Transform3D(Basis.looking_at(persistent_state.velocity.normalized(), Vector3.UP), persistent_state.global_position)
		persistent_state.global_transform.basis = persistent_state.global_transform.basis.slerp(target_rotation.basis, 10 * delta)  # Adjust 0.1 for rotation speed

func check_if_slideto_player():
	for i in persistent_state.get_slide_collision_count():
		var c = persistent_state.get_slide_collision(i)
		if c.get_collider().name == "Player" or c.get_collider().name == "Mailcart":
			hit_by_soundplayer.play()
			c.get_collider().extra_life = 0
			c.get_collider().hit_by_entity()
			#hit_sound.playing = true
			#AudioController.play_resource(hit_death)
			#stop_chasing_player()

func charge():
	stopTimers()
	charging = true
	charge_position = player.global_position
	await get_tree().create_timer(1.8).timeout
	var distance_to_player = charge_position.distance_to(persistent_state.global_position)
	# Max time to travel * distance_factor(actual distance /maximum_distance)
	var time_to_travel = 1.15 * (distance_to_player / 25.5)
	charge_slashing_soundplayer.play()
	#aggro_speed = 0
	charge_tween = create_tween()
	charge_tween.tween_property(persistent_state, "global_position", Vector3(charge_position.x, persistent_state.global_position.y, charge_position.z), time_to_travel);
	await charge_tween.finished
	aggro_speed = 3
	charging = false	
	can_charge_timer.start(7.5)
	set_new_nav_position(player.global_position)
	get_player_position_timer.start(0.17)

func set_new_nav_position(pos: Vector3 = Vector3.ZERO):
	if pos == Vector3.ZERO:
		var point = NavigationServer3D.map_get_random_point(navigation_region_3d.get_navigation_map(), navigation_region_3d.get_navigation_layers(), false)
		navigation_agent_3d.set_target_position(point)
		var count = 0
		var fear_factor = ScareDirector.fear_factor
		if fear_factor <= ScareDirector._max_fear * 0.75 and fear_factor_maxxed_timer.is_stopped():
			while !navigation_agent_3d.is_target_reachable() and count < 35 and abs(persistent_state.global_position.distance_to(player.global_position)) < _fear_factor_max_range * 0.82:
				point = NavigationServer3D.map_get_random_point(navigation_region_3d.get_navigation_map(), navigation_region_3d.get_navigation_layers(), false)
				navigation_agent_3d.set_target_position(point)
				count += 1
				if count == 34:
					print("wtf")
		else:
			while !navigation_agent_3d.is_target_reachable() and count < 35 and abs(persistent_state.global_position.distance_to(player.global_position)) > _fear_factor_max_range * 2:
				point = NavigationServer3D.map_get_random_point(navigation_region_3d.get_navigation_map(), navigation_region_3d.get_navigation_layers(), false)
				navigation_agent_3d.set_target_position(point)
				count += 1
				if count == 34:
					print("wtf")
			fear_factor_maxxed_timer.start(randi_range(17, 28))
	else:
		navigation_agent_3d.set_target_position(pos)

func check_player_distance_for_kill():
	var distance_to_player = abs(persistent_state.global_position.distance_to(player.global_position))
	if distance_to_player <= _charge_kill_distance:
		hit_by_soundplayer.play()
		player.extra_life = 0
		player.hit_by_entity()

func _on_get_player_position_timer_timeout() -> void:
	if persistent_state.enabled and nav_link_cooldown_timer.is_stopped():
		set_new_nav_position(player.global_position)

func deAggro():
	change_state.call("respawning")

func on_player_unseen():
	if persistent_state.enabled and player_in_vision_flag and !charging:
		player_in_vision_flag = false
		de_aggro_timer.start(3.5)

# Used by non-instant detectors whenever the player actually is "in_view" to reset de-aggro timers
func on_player_in_vision():
	if persistent_state.enabled:
		player_in_vision_flag = true
		de_aggro_timer.stop()
		if charging:
			charge_position = player.global_position

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.get_groups().has("monster"):
		charge_tween.kill() if charge_tween != null else null
		change_state.call("carcass")
		#persistent_state.enable_carcass_behaviour()


# VENTING AND THE LIKE
func _on_navigation_agent_3d_link_reached(details: Dictionary) -> void:
	nav_link_cooldown_timer.start(0.35)
	var ow = details.owner as Node
	if ow.is_in_group("NavigationLinkVent"):
		await leave_vent() if is_venting else enter_vent()

func enter_vent():
	is_venting = true
	collision_shape_3d.set_disabled(true)
	persistent_state.motion_mode = persistent_state.MOTION_MODE_FLOATING

func leave_vent():
	# Play an Animation here of the monster getting out of the vent.
	await get_tree().create_timer(1.5).timeout
	is_venting = false
	collision_shape_3d.set_disabled(false)
	persistent_state.motion_mode = persistent_state.MOTION_MODE_GROUNDED

func stopTimers():
	for t in functional_timers:
		t.stop()
