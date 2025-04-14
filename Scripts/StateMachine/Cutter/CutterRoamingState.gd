extends State
class_name CutterRoamingState

var player: CharacterBody3D
var _fear_factor_max_range := 34.0
var roaming_speed := 5.0
var is_venting := false
var player_in_vision_flag := false

# Navigation References
@onready var navigation_region_3d: NavigationRegion3D = get_parent().get_parent().find_child("NavigationRegion3D")
@onready var navigation_agent_3d: NavigationAgent3D = get_parent().find_child("NavigationAgent3D")

# Timer References
@onready var navigation_timer: Timer = get_parent().find_child("IdleNavigationTimer")
@onready var fear_factor_maxxed_timer: Timer = get_parent().find_child("fear_factor_maxxed_timer")
@onready var nav_link_cooldown_timer: Timer =  get_parent().find_child("NavLinkCooldownTimer")
@onready var functional_timers = [navigation_timer]

# Other assets / nodes
@onready var hit_by_soundplayer: AudioStreamPlayer3D = get_parent().find_child("hit_by_soundplayer")
@onready var collision_shape_3d: CollisionShape3D = get_parent().find_child("CollisionShape3D")
@onready var carcass_area_detector: Area3D = get_parent().get_parent().find_child("cutter_carcass_ai").find_child("Area3D")

#@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
#@onready var de_aggro_timer: Timer = $DeAggroTimer
#@onready var respawn_timer: Timer = $RespawnTimer
#@onready var get_player_position_timer: Timer = $GetPlayerPositionTimer
#@onready var charge_slashing_soundplayer: AudioStreamPlayer3D = $charge_slashing_soundplayer
#@onready var hit_by_soundplayer: AudioStreamPlayer3D = $hit_by_soundplayer
#@export var initial_chase_sfx: Resource
#@export var chaseloop_sfx: Resource
#@onready var aggro_sound_initial: AudioStreamPlayer3D = $AudioStreamPlayer3D

func get_class_custom(): return "CutterRoamingState"

func _ready() -> void:
	navigation_agent_3d.link_reached.connect(_on_navigation_agent_3d_link_reached)
	carcass_area_detector.body_entered.connect(_on_area_3d_body_entered)
	player = GameManager.get_player()
	navigation_timer.timeout.connect(_on_navigation_timer_timeout)
	set_enabled(persistent_state.enabled)

func set_enabled(flag: bool):
	if flag:
		persistent_state.enabled = flag
		collision_shape_3d.disabled = false
		visible = true
		set_new_nav_position()
		navigation_timer.start()
	else:
		persistent_state.enabled = flag
		visible = false
		collision_shape_3d.disabled = true
		stopTimers()

func _process(delta: float) -> void:
	if visible:
		ScareDirector.update_fear_factor(abs(player.global_position.distance_to(persistent_state.global_position)), delta, _fear_factor_max_range)
	else:
		# We just want to lower the fear factor naturally, so we let the distance-check do its thing
		ScareDirector.update_fear_factor(100, delta, _fear_factor_max_range)

func _physics_process(delta: float):
	update_velocity(roaming_speed)
	update_rotation(delta)
	persistent_state.move_and_slide()
	check_if_slideto_player()
	#else: 
		#if !charging:
			#update_velocity(monster_speed)
			#update_rotation(delta)
			#move_and_slide()
			#check_if_slideto_player()
			#if can_charge_timer.is_stopped() and player_in_vision_flag and !is_venting:
				#charge()
		#else:
			#check_player_distance_for_kill()

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

func _on_navigation_timer_timeout() -> void:
	if persistent_state.enabled and nav_link_cooldown_timer.is_stopped():
		set_new_nav_position()

# VISION FUNCTION
func on_detect_player():
	if persistent_state.enabled and persistent_state.can_see_player:
		change_state.call("aggro")

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.get_groups().has("monster"):
		change_state.call("carcass")
		#persistent_state.enable_carcass_behaviour()
		#if cutter_ai.aggrod:
			#cutter_ai.deAggro()
			#cutter_ai.stopTimers()
			#if abs(cutter_ai.global_position.distance_to(player.global_position)) < 6.5:
				#_instakill()
			#else:
				#deescalate()
				#start_carcass_behaviour()
		#else:
			#start_carcass_behaviour()

#func on_player_unseen():
	#if persistent_state.enabled and player_in_vision_flag and !charging:
		#player_in_vision_flag = false
		#if aggrod:
			#de_aggro_timer.start()

# Used by non-instant detectors whenever the player actually is "in_view" to reset de-aggro timers
#func on_player_in_vision():
	#if persistent_state.enabled:
		#player_in_vision_flag = true
		#if aggrod:
			#de_aggro_timer.stop()
			#if charging:
				#charge_position = player.global_position

# VENTING AND THE LIKE
func _on_navigation_agent_3d_link_reached(details: Dictionary) -> void:
	nav_link_cooldown_timer.start()
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

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("DEBUG"):
		#set_new_nav_position(player.global_position)
		change_state.call("respawning")

func stopTimers():
	for t in functional_timers:
		t.stop()
