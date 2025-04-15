extends State
class_name CutterCarcassState

var player: CharacterBody3D
var chaseloop_sfx: Resource
var monster_speed = 0
@onready var collision_shape_3d: CollisionShape3D = get_parent().find_child("CollisionShape3D")
@onready var cutter_ai: CharacterBody3D = get_parent()
@onready var cutter_carcass_ai_root = get_parent().get_parent().find_child("cutter_carcass_ai")
@onready var area_collider: Area3D = cutter_carcass_ai_root.find_child("Area3D")
@onready var behaviour_duration_timer: Timer = cutter_carcass_ai_root.find_child("behaviour_duration_timer")
@onready var deescalate_timer: Timer = cutter_carcass_ai_root.find_child("deescalate_timer")
@onready var cutter_model_for_animation_player: Node3D = cutter_carcass_ai_root.find_child("cutter_model_for_animations")
@onready var behaviour_soundbark_timer: Timer = cutter_carcass_ai_root.find_child("behaviour_soundbark_timer")
@onready var carcass_and_butcher_nav_ability_timer: Timer = cutter_carcass_ai_root.find_child("carcass_and_butcher_nav_ability_timer")
@onready var navigation_region_3d: NavigationRegion3D = get_parent().get_parent().find_child("NavigationRegion3D")
@onready var nav_obstacle_for_carcass_and_butcher: NavigationObstacle3D = navigation_region_3d.find_child("NavObstacleForCarcassAndButcher")
@onready var spawnpoints: Node = get_parent().get_parent().find_child("MonsterSpawnPositions")
@onready var corpses: Node3D = get_parent().get_parent().find_child("NavigationRegion3D").find_child("human_resources_carcass_and_butcher").find_child("OBJECTS").find_child("Corpses")
# Timer stuffzzzzzzzzzzzzzzzzzzzzzzz
@onready var de_aggro_timer: Timer = get_parent().find_child("DeAggroTimer")
@onready var navigation_timer: Timer = get_parent().find_child("IdleNavigationTimer")
@onready var get_player_position_timer: Timer = get_parent().find_child("GetPlayerPositionTimer")
@onready var functional_timers = [de_aggro_timer, get_player_position_timer, navigation_timer]

@onready var audio_players = [
	cutter_carcass_ai_root.find_child("AudioStreamPlayer3D", false),
	cutter_carcass_ai_root.find_child("AudioStreamPlayer3D2", false),
	cutter_carcass_ai_root.find_child("AudioStreamPlayer3D3", false),
	cutter_carcass_ai_root.find_child("AudioStreamPlayer3D4", false),
	cutter_carcass_ai_root.find_child("AudioStreamPlayer3D5", false),
	cutter_carcass_ai_root.find_child("AudioStreamPlayer3D6", false),
	cutter_carcass_ai_root.find_child("AudioStreamPlayer3D7", false),
]
var tween: Tween

func get_class_custom(): return "CutterCarcassState"

func _ready():
	behaviour_duration_timer.timeout.connect(_on_behaviour_duration_timer_timeout)
	behaviour_soundbark_timer.timeout.connect(_on_behaviour_soundbark_timer_timeout)
	carcass_and_butcher_nav_ability_timer.timeout.connect(_on_carcass_and_butcher_nav_ability_timer_timeout)
	chaseloop_sfx = load("res://Assets/Audio/SoundFX/ChaseLoops/ChaseLoopCutter.ogg")
	player = GameManager.player_reference
	monster_speed = 0
	stopTimers()
	persistent_state.visible = false
	collision_shape_3d.disabled = true
	var spawnpoint = spawnpoints.get_children().pick_random()
	persistent_state.set_position(spawnpoint.global_position)
	persistent_state.set_rotation(spawnpoint.rotation)
	persistent_state.position.y = persistent_state.startposition
	if persistent_state.previous_state == "CutterAggroState":
		AudioController.stop_resource(chaseloop_sfx.resource_path, 2)
		ScareDirector.disable_intensity_flag.emit()
		if abs(persistent_state.global_position.distance_to(player.global_position)) < 6.5:
			_instakill()
		else:
			deescalate()
	start_carcass_behaviour()

func deescalate():
	deescalate_timer.start(2.33)
	pass
	# Play a deescalate sound and other similar things

func start_carcass_behaviour():
	behaviour_duration_timer.start(randi_range(21, 32))

	behaviour_soundbark_timer.start(randi_range(1.5, 3.5))
	pass
	# start a random timer before monster leaves the area
	# play "random" ambiance sounds a bit all over the room, generally behind the player
	# afterward, play a monster "venting" sound and have the monster spawn somewhere else 
	
func on_hearing_sound():
	if behaviour_duration_timer.time_left > 0 and deescalate_timer.is_stopped():
		for key in audio_players:
			if key.playing:
				key.stop()
		var timer = get_tree().create_timer(randi_range(1.33, 2.65))
		await timer.timeout
		_instakill()

func _instakill():
	var spawnpos = player.global_transform.origin
	var player_forward_vector = player.global_transform.basis.z
	player_forward_vector = player_forward_vector.normalized()
	spawnpos -= player_forward_vector * 11.5
	cutter_model_for_animation_player.global_transform.origin = spawnpos
	cutter_model_for_animation_player.global_position.y = cutter_ai.global_position.y
	cutter_model_for_animation_player.visible = true
	cutter_model_for_animation_player.get_node("AudioStreamPlayer3D").play()
	tween = create_tween()
	tween.tween_property(cutter_model_for_animation_player, "global_position", player.global_position, 0.28);
	await tween.finished
	player.extra_life = 0
	player.hit_by_entity()
	#optimally, maybe play 1 of a random selection of animations

func _on_behaviour_duration_timer_timeout() -> void:
	behaviour_soundbark_timer.stop()
	for key in audio_players:
		if key.playing:
			key.stop()
	nav_obstacle_for_carcass_and_butcher.affect_navigation_mesh = true
	navigation_region_3d.bake_navigation_mesh(true)
	change_state.call("respawning")

func _on_behaviour_soundbark_timer_timeout() -> void:
	# Maybe make this psuedo-random for better control
	var chosen_player = audio_players.pick_random()
	if !chosen_player.playing:
		chosen_player.pitch_scale = randf_range(0.8, 1.2)
		chosen_player.play()
	behaviour_soundbark_timer.start(randf_range(1.88, 3.5))
	if randi_range(0, 100) > 75:
		var count = 0
		var chosen_corpse = corpses.get_children().pick_random() as Node3D
		while count < 35 and (abs(chosen_corpse.global_position.distance_to(player.global_position)) < 4.2 or abs(chosen_corpse.global_position.distance_to(player.global_position)) > 5.8):
			chosen_corpse = corpses.get_children().pick_random() as Node3D
			print(abs(chosen_corpse.global_position.distance_to(player.global_position)))
			count += 1
		var rb = chosen_corpse.find_child("Bodybag") as RigidBody3D
		rb.apply_impulse(Vector3(randf_range(3.5, 4.5), 0, randf_range(4.0, 4.8)))
		rb.find_child("AudioStreamPlayer3D").playing = true



func _on_carcass_and_butcher_nav_ability_timer_timeout() -> void:
	nav_obstacle_for_carcass_and_butcher.affect_navigation_mesh = false
	navigation_region_3d.bake_navigation_mesh(true)

func stopTimers():
	for t in functional_timers:
		t.stop()
