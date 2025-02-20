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

# Debug export
@export var enabled: bool = true
@export var can_see_player: bool = true


@onready var functional_timers = [de_aggro_timer, get_player_position_timer, navigation_timer]
var is_venting: bool = false
var aggrod: bool = false
var charging: bool = false
var player_in_vision_flag: bool = false
var player: CharacterBody3D
var monster_speed = 5.0
@onready var startposition = position.y
var charge_position: Vector3 = Vector3.ZERO

func stopTimers():
	for t in functional_timers:
		t.stop()

func _ready():
	player = GameManager.get_player()
	set_enabled(enabled)
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("DEBUG"):
		set_new_nav_position(player.global_position)

func set_enabled(enabled: bool):
	if enabled:
		visible = true
		set_new_nav_position()
		navigation_timer.start()
	else:
		visible = false
		stopTimers()



# ACTUAL BEHAVIOUR BELOW; PUT DEBUG STUFF ABOVE THIS LINE
func _physics_process(delta: float):
	if !aggrod:
		update_velocity(monster_speed)
		update_rotation(delta)
		move_and_slide()
	else: 
		if !charging:
			update_velocity(monster_speed)
			update_rotation(delta)
			move_and_slide()
			if can_charge_timer.is_stopped() and player_in_vision_flag and !is_venting:
				charge()

func update_velocity(speed: float):
	var current_location = global_transform.origin
	var next_location = navigation_agent_3d.get_next_path_position()
	var new_velocity = (next_location - current_location).normalized() * speed
	var distance_to_goal = abs(navigation_agent_3d.get_final_position().distance_to(current_location))
	new_velocity = Vector3(new_velocity.x, 0, new_velocity.z)
	velocity = new_velocity

func update_rotation(delta: float):
	if velocity.length() > 0.01:
		var target_rotation = Transform3D(Basis().looking_at(velocity.normalized(), Vector3.UP), global_position)
		global_transform.basis = global_transform.basis.slerp(target_rotation.basis, 10 * delta)  # Adjust 0.1 for rotation speed

func set_new_nav_position(pos: Vector3 = Vector3.ZERO):
	if pos == Vector3.ZERO:
		var point = NavigationServer3D.map_get_random_point(navigation_region_3d.get_navigation_map(), navigation_region_3d.get_navigation_layers(), false)
		navigation_agent_3d.set_target_position(point)
		var count = 0
		while !navigation_agent_3d.is_target_reachable() and count < 15:
			point = NavigationServer3D.map_get_random_point(navigation_region_3d.get_navigation_map(), navigation_region_3d.get_navigation_layers(), false)
			navigation_agent_3d.set_target_position(point)
			count += 1
			if count == 14:
				print("wtf")
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
	tween.tween_property(self, "global_position", Vector3(charge_position.x, global_position.y, charge_position.z), time_to_travel);
	await tween.finished
	can_charge_timer.start()
	set_new_nav_position(player.global_position)
	get_player_position_timer.start()
	charging = false


# VISION FUNCTION
func on_player_in_vision():
	if enabled and !player_in_vision_flag and can_see_player:
		de_aggro_timer.stop()
		player_in_vision_flag = true
		if !aggrod:
			aggro()
	
	if enabled and charging:
		charge_position = player.global_position

func on_player_out_of_vision():
	if enabled and player_in_vision_flag and !charging:
		player_in_vision_flag = false
		de_aggro_timer.start()


# AGGRO BEHAVIOUR
func aggro():
	ScareDirector.enable_intensity_flag.emit()

	aggrod = true
	
	# Stop all timers responsible for the idle behaviour
	navigation_timer.stop()
	
	# Set cutter to a standstill
	monster_speed = 0
	
	# Play an aggro animation, sounds or the like
	await get_tree().create_timer(1.185).timeout
	monster_speed = 6.5
	# Start the timer responsible for updating chase position
	get_player_position_timer.start()

func deAggro():
	aggrod = false
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
				navigation_timer.start()
				set_new_nav_position()
				collision_shape_3d.disabled = false
				return

# VENTING AND THE LIKE
func _on_navigation_agent_3d_link_reached(details: Dictionary) -> void:
	nav_link_cooldown_timer.start()
	var owner = details.owner as Node
	if owner.is_in_group("NavigationLinkVent"):
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
