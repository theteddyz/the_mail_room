extends CharacterBody3D
@onready var navigation_timer: Timer = $IdleNavigationTimer
@onready var navigation_region_3d: NavigationRegion3D = $"../NavigationRegion3D"
@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var spawnpoints: Node = get_parent().find_child("MonsterSpawnPositions")
@onready var can_charge_timer: Timer = $CanChargeTimer
@onready var nav_link_cooldown_timer: Timer = $NavLinkCooldownTimer
@onready var de_aggro_timer: Timer = $DeAggroTimer
@onready var respawn_timer: Timer = $RespawnTimer
@onready var get_player_position_timer: Timer = $GetPlayerPositionTimer
@onready var charge_slashing_soundplayer: AudioStreamPlayer3D = $charge_slashing_soundplayer
@onready var hit_by_soundplayer: AudioStreamPlayer3D = $hit_by_soundplayer
@onready var fear_factor_maxxed_timer: Timer = $fear_factor_maxxed_timer
@export var initial_chase_sfx: Resource
@export var chaseloop_sfx: Resource
@onready var aggro_sound_initial: AudioStreamPlayer3D = $AudioStreamPlayer3D

# Debug export
@export var enabled: bool = true
@export var can_see_player: bool = true

@onready var functional_timers = [de_aggro_timer, get_player_position_timer, navigation_timer]
var is_venting: bool = false
var _charge_kill_distance: float = 1.5
var _fear_factor_max_range: float = 34.0

var aggrod: bool = false
var charging: bool = false
var player_in_vision_flag: bool = false
var player: CharacterBody3D
var monster_speed = 5.0

#var monster_speed = 0.0
@onready var startposition = position.y
var charge_position: Vector3 = Vector3.ZERO

func stopTimers():
	for t in functional_timers:
		t.stop()

func _ready():
	#initial_chase_sfx = load(initial_chase_sfx_resource_path)
	#chaseloop_sfx = load(chaseloop_sfx_resource_path)
	player = GameManager.get_player()
	set_enabled(enabled)
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("DEBUG"):
		set_new_nav_position(player.global_position)

func set_enabled(flag: bool):
	if flag:
		enabled = flag
		collision_shape_3d.disabled = false
		visible = true
		set_new_nav_position()
		navigation_timer.start()
	else:
		enabled = flag
		visible = false
		collision_shape_3d.disabled = true
		stopTimers()

func _process(delta: float) -> void:
	if visible:
		ScareDirector.update_fear_factor(abs(player.global_position.distance_to(global_position)), delta, _fear_factor_max_range)
	else:
		# We just want to lower the fear factor naturally, so we let the distance-check do its thing
		ScareDirector.update_fear_factor(100, delta, _fear_factor_max_range)


# ACTUAL BEHAVIOUR BELOW; PUT DEBUG STUFF ABOVE THIS LINE
func _physics_process(delta: float):
	if !aggrod:
		update_velocity(monster_speed)
		update_rotation(delta)
		move_and_slide()
		check_if_slideto_player()
	else: 
		if !charging:
			update_velocity(monster_speed)
			update_rotation(delta)
			move_and_slide()
			check_if_slideto_player()
			if can_charge_timer.is_stopped() and player_in_vision_flag and !is_venting:
				charge()
		else:
			check_player_distance_for_kill()

func update_velocity(speed: float):
	var current_location = global_transform.origin
	var next_location = navigation_agent_3d.get_next_path_position()
	var new_velocity = (next_location - current_location).normalized() * speed
	#var distance_to_goal = abs(navigation_agent_3d.get_final_position().distance_to(current_location))
	new_velocity = Vector3(new_velocity.x, 0, new_velocity.z)
	velocity = new_velocity

func update_rotation(delta: float):
	if velocity.length() > 0.01:
		var target_rotation = Transform3D(Basis.looking_at(velocity.normalized(), Vector3.UP), global_position)
		global_transform.basis = global_transform.basis.slerp(target_rotation.basis, 10 * delta)  # Adjust 0.1 for rotation speed
		
func check_if_slideto_player():
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		if c.get_collider().name == "Player" or c.get_collider().name == "Mailcart":
			hit_by_soundplayer.play()
			c.get_collider().extra_life = 0
			c.get_collider().hit_by_entity()
			#hit_sound.playing = true
			#AudioController.play_resource(hit_death)
			#stop_chasing_player()

func check_player_distance_for_kill():
	var distance_to_player = abs(global_position.distance_to(player.global_position))
	if distance_to_player <= _charge_kill_distance:
		hit_by_soundplayer.play()
		player.extra_life = 0
		player.hit_by_entity()

func set_new_nav_position(pos: Vector3 = Vector3.ZERO):
	if pos == Vector3.ZERO:
		var point = NavigationServer3D.map_get_random_point(navigation_region_3d.get_navigation_map(), navigation_region_3d.get_navigation_layers(), false)
		navigation_agent_3d.set_target_position(point)
		var count = 0
		var fear_factor = ScareDirector.fear_factor
		if fear_factor <= ScareDirector._max_fear * 0.75 and fear_factor_maxxed_timer.is_stopped():
			while !navigation_agent_3d.is_target_reachable() and count < 35 and abs(global_position.distance_to(player.global_position)) < _fear_factor_max_range * 0.82:
				point = NavigationServer3D.map_get_random_point(navigation_region_3d.get_navigation_map(), navigation_region_3d.get_navigation_layers(), false)
				navigation_agent_3d.set_target_position(point)
				count += 1
				if count == 34:
					print("wtf")
		else:
			while !navigation_agent_3d.is_target_reachable() and count < 35 and abs(global_position.distance_to(player.global_position)) > _fear_factor_max_range * 2:
				point = NavigationServer3D.map_get_random_point(navigation_region_3d.get_navigation_map(), navigation_region_3d.get_navigation_layers(), false)
				navigation_agent_3d.set_target_position(point)
				count += 1
				if count == 34:
					print("wtf")
			fear_factor_maxxed_timer.start(randi_range(17, 28))
	else:
		navigation_agent_3d.set_target_position(pos)

func charge():
	stopTimers()
	charging = true
	charge_position = player.global_position
	await get_tree().create_timer(1.8).timeout
	var tween = create_tween()
	var distance_to_player = charge_position.distance_to(global_position)
	# Max time to travel * distance_factor(actual distance /maximum_distance)
	var time_to_travel = 1.15 * (distance_to_player / 25.5)
	charge_slashing_soundplayer.play()
	tween.tween_property(self, "global_position", Vector3(charge_position.x, global_position.y, charge_position.z), time_to_travel);
	await tween.finished
	charging = false	
	if aggrod:
		can_charge_timer.start()
		set_new_nav_position(player.global_position)
		get_player_position_timer.start()


# VISION FUNCTION
func on_detect_player():
	if enabled and can_see_player and !aggrod:
		aggro()

func on_player_unseen():
	if enabled and player_in_vision_flag and !charging:
		player_in_vision_flag = false
		if aggrod:
			de_aggro_timer.start()

# Used by non-instant detectors whenever the player actually is "in_view" to reset de-aggro timers
func on_player_in_vision():
	if enabled:
		player_in_vision_flag = true
		if aggrod:
			de_aggro_timer.stop()
			if charging:
				charge_position = player.global_position

# AGGRO BEHAVIOUR
func aggro():
	ScareDirector.enable_intensity_flag.emit()
	aggro_sound_initial.playing = true
	aggrod = true
	
	# Stop all timers responsible for the idle behaviour
	navigation_timer.stop()
	
	# Set cutter to a standstill
	monster_speed = 0
	
	# Play an aggro animation, sounds or the like
	await get_tree().create_timer(1.185).timeout
	AudioController.play_resource(chaseloop_sfx, 0, func(): {}, 12)
	AudioController.play_resource(initial_chase_sfx, 0, func(): {}, 17)
	monster_speed = 3.2
	# Start the timer responsible for updating chase position
	get_player_position_timer.start()

func deAggro():
	aggrod = false
	AudioController.stop_resource(chaseloop_sfx.resource_path, 2)
	ScareDirector.disable_intensity_flag.emit()
	visible = false
	collision_shape_3d.disabled = true
	stopTimers()
	respawn_timer.start(randi_range(19, 33))
	
func enable_carcass_behaviour():
	monster_speed = 0
	stopTimers()
	visible = false
	collision_shape_3d.disabled = true
	var spawnpoint = spawnpoints.get_children().pick_random()
	set_position(spawnpoint.global_position)
	set_rotation(spawnpoint.rotation)
	position.y = startposition


# TIMERS
func _on_navigation_timer_timeout() -> void:
	if enabled and nav_link_cooldown_timer.is_stopped():
		set_new_nav_position()

func _on_get_player_position_timer_timeout() -> void:
	if enabled and nav_link_cooldown_timer.is_stopped():
		set_new_nav_position(player.global_position)

func _on_de_aggro_timer_timeout() -> void:
	if aggrod and !player_in_vision_flag:
		deAggro()

func _on_respawn_timer_timeout() -> void:
	if !visible and collision_shape_3d.disabled and !aggrod:
		#Spawn John on a random position not in the players view
		var arr = spawnpoints.get_children()
		arr.shuffle()
		for i in arr:
			if !i.observed:
				visible = true
				stopTimers()
				set_position(i.global_position)
				set_rotation(i.rotation)
				position.y = startposition
				monster_speed = 5.0
				navigation_timer.start()
				set_new_nav_position()
				collision_shape_3d.disabled = false
				return

# VENTING AND THE LIKE
func _on_navigation_agent_3d_link_reached(details: Dictionary) -> void:
	nav_link_cooldown_timer.start()
	var ow = details.owner as Node
	if ow.is_in_group("NavigationLinkVent"):
		await leave_vent() if is_venting else enter_vent()

func enter_vent():
	is_venting = true
	collision_shape_3d.set_disabled(true)
	self.motion_mode = MotionMode.MOTION_MODE_FLOATING

func leave_vent():
	# Play an Animation here of the monster getting out of the vent.
	await get_tree().create_timer(1.5).timeout
	is_venting = false
	collision_shape_3d.set_disabled(false)
	self.motion_mode = MotionMode.MOTION_MODE_GROUNDED

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
