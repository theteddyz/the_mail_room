extends State
class_name CutterRespawningState

var chaseloop_sfx: Resource
var monster_speed := 5
var _fear_factor_max_range := 34.0
var player: CharacterBody3D
@onready var de_aggro_timer: Timer = get_parent().find_child("DeAggroTimer")
@onready var navigation_timer: Timer = get_parent().find_child("IdleNavigationTimer")
@onready var get_player_position_timer: Timer = get_parent().find_child("GetPlayerPositionTimer")
@onready var respawn_timer: Timer = get_parent().find_child("RespawnTimer")
@onready var functional_timers = [de_aggro_timer, navigation_timer, get_player_position_timer]
@onready var collision_shape_3d: CollisionShape3D = get_parent().find_child("CollisionShape3D")
@onready var spawnpoints: Node = get_parent().get_parent().find_child("MonsterSpawnPositions")
@onready var fear_factor_maxxed_timer: Timer = get_parent().find_child("fear_factor_maxxed_timer")

# Navigation References
@onready var navigation_region_3d: NavigationRegion3D = get_parent().get_parent().find_child("NavigationRegion3D")
@onready var navigation_agent_3d: NavigationAgent3D = get_parent().find_child("NavigationAgent3D")

func get_class_custom(): return "CutterRespawningState"

func _ready() -> void:
	player = GameManager.get_player()
	chaseloop_sfx = load("res://Assets/Audio/SoundFX/ChaseLoops/ChaseLoopCutter.ogg")
	AudioController.stop_resource(chaseloop_sfx.resource_path, 2)
	ScareDirector.disable_intensity_flag.emit()
	stopTimers()
	persistent_state.visible = false
	collision_shape_3d.disabled = true
	respawn_timer.timeout.connect(_on_respawn_timer_timeout)
	respawn_timer.start(randi_range(19, 33))

func stopTimers():
	for t in functional_timers:
		t.stop()

func _on_respawn_timer_timeout() -> void:
	if !persistent_state.visible and collision_shape_3d.disabled:
		#Spawn Cutter on a random position not in the players view
		var arr = spawnpoints.get_children()
		arr.shuffle()
		for i in arr:
			if !i.observed:
				persistent_state.visible = true
				stopTimers()
				set_position(i.global_position)
				set_rotation(i.rotation)
				persistent_state.position.y = persistent_state.startposition
				monster_speed = 5.0
				navigation_timer.start()
				set_new_nav_position()
				collision_shape_3d.disabled = false
				change_state.call("roaming")
		printerr("Could not find a respawn point, cutter has been disabled.")

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
