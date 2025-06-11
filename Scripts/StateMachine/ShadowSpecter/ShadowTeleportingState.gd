extends State
class_name ShadowTeleportingState

# TODO:
# Shadowspecter needs a teleport-sighting sound, and a teleporting (roaming) loop
# Also needs a sound playing close-to the shadow, one version for the chase, and one during the stalking
# A PHATTY aggro sound
var player: CharacterBody3D
var teleporting_ambiance: Resource
@onready var teleporting_behaviour_timer: Timer = get_parent().find_child("Timers").find_child("teleporting_behaviour_timer")
@onready var stalking_timer: Timer = get_parent().find_child("Timers").find_child("stalking_timer")
@onready var collision_shape_3d: CollisionShape3D = get_parent().find_child("Collider").find_child("CollisionShape3D")
@onready var stalk_locations: Node = get_parent().get_parent().find_child("ShadowSpecterStalkLocations")
@onready var functional_timers: Array[Timer] = [teleporting_behaviour_timer,stalking_timer]
@onready var visible_on_screen_notifier_3d: VisibleOnScreenNotifier3D = get_parent().find_child("VisibleOnScreenNotifier3D")
@onready var teleport_sighting_sound: AudioStreamPlayer3D = get_parent().find_child("TeleportSightingSound")
var original_position: Vector3
var jitter_amount := 0.0115  # Max offset in units (tweak for subtlety)
@export var base_jitter := 0.005         # Minimum jitter amount
@export var max_extra_jitter := 0.0125    # Max added jitter from sine wave
@export var sine_speed := 1.66          # Speed of the sine wave (oscillations per second)
var TELEPORT_AWAY_SMOKE 
var time_passed := 0.0
func get_class_custom(): return "ShadowTeleportingState"

func _ready() -> void:
	#initial_sight_sound = load("res://Assets/Audio/SoundFX/ChaseLoops/AggroSoundCutter.ogg")
	teleporting_ambiance = load("res://Assets/Audio/Music/ShadowSpecterAggroLoop.ogg")
	TELEPORT_AWAY_SMOKE = preload("res://Scenes/Prefabs/Emission and Effects/teleport_away_smoke.tscn")
	stalking_timer.timeout.connect(on_stalking_end_timer)
	persistent_state.scare_manager.package_order_disrupted.connect(aggro)
	visible_on_screen_notifier_3d.screen_entered.connect(become_seen)
	player = GameManager.get_player()
	original_position = persistent_state.global_position
	set_enabled(persistent_state.enabled)

func aggro():
	persistent_state.player_errors += 1
	if persistent_state.player_errors >= 2:
		change_state.call("aggro")
	

func _process(delta: float) -> void:
	time_passed += delta
	apply_sine_jitter()

func set_enabled(flag: bool):
	if flag:
		persistent_state.enabled = flag
		collision_shape_3d.disabled = false
		AudioController.play_resource(teleporting_ambiance)
		teleporting_behaviour_timer.start()
		teleporting_behaviour_timer.timeout.connect(on_teleport_end_timer, 1)
		visible = true
		await get_tree().process_frame
		await get_tree().process_frame  # wait 2 frames to be safe
		find_stalking_position()
	else:
		persistent_state.enabled = flag
		visible = false
		collision_shape_3d.disabled = true
		stopTimers()

func apply_sine_jitter():
	# Sine wave modulating between 0.0 and 1.0
	var sine_mod = (sin(time_passed * sine_speed * TAU) + 1.0) / 2.0
	
	# Total jitter power based on sine wave
	var current_jitter = base_jitter + sine_mod * max_extra_jitter

	# Apply jitter on X and Z
	var offset_x = randf_range(-current_jitter, current_jitter)
	var offset_z = randf_range(-current_jitter, current_jitter)

	var jittered_position = original_position + Vector3(offset_x, 0, offset_z)
	persistent_state.global_position = jittered_position

func find_stalking_position():
	var player_pos = player.global_position
	if stalk_locations != null:
		var arr = stalk_locations.get_children()
		arr.sort_custom(func(a: Marker3D, b: Marker3D): return a.position.distance_to(player_pos) < b.position.distance_to(player_pos))
		arr = arr.slice(0, 5)
		arr.shuffle()
		for i in arr:
			if !i.observed:
				persistent_state.set_position(i.global_position)
				persistent_state.set_rotation(i.rotation)
				persistent_state.position.y = persistent_state.startposition
				collision_shape_3d.disabled = false
				persistent_state.visible = true
				stalking_timer.start()
				break

func get_random_sighting_effect():
	pass
	## Try to keep total time to roughly 1.2 seconds, max
	#var i = randi_range(0, 3)
	#match i:
		#0:
			#await get_tree().create_timer(1.185).timeout
		#1: 
			#await get_tree().create_timer(0.86).timeout
		#2: 
			#await get_tree().create_timer(0.48).timeout
			#AudioController.play_resource(static_sfx, 0, func(): {}, 10)
			#overlay_cutter_eyes.visible = true
			#overlay_static_effect.visible = true
			#await get_tree().create_timer(0.08).timeout
			#overlay_cutter_eyes.visible = false
			#await get_tree().create_timer(0.38).timeout
			#AudioController.stop_resource(static_sfx.resource_path)
			#overlay_static_effect.visible = false
			#await get_tree().create_timer(0.08).timeout
		#3: 
			#await get_tree().create_timer(0.68).timeout
			#overlay_cutter_eyes.visible = true
			#await get_tree().create_timer(0.03).timeout
			#overlay_cutter_eyes.visible = false
			#
			#await get_tree().create_timer(0.33).timeout
			#overlay_cutter_eyes.visible = true
			#await get_tree().create_timer(0.045).timeout
			#overlay_cutter_eyes.visible = false
			#
			#await get_tree().create_timer(0.14).timeout
			#AudioController.play_resource(static_sfx, 0, func(): {}, 10)
			#overlay_static_effect.visible = true
			#overlay_cutter_eyes.visible = true
			#await get_tree().create_timer(0.06).timeout
			#overlay_cutter_eyes.visible = false
			#
			#await get_tree().create_timer(0.095).timeout
			#overlay_cutter_eyes.visible = true
			#await get_tree().create_timer(0.10).timeout
			#overlay_cutter_eyes.visible = false
			#
			#await get_tree().create_timer(0.045).timeout
			#overlay_cutter_eyes.visible = true
			#await get_tree().create_timer(0.13).timeout
			#overlay_cutter_eyes.visible = false
			#AudioController.stop_resource(static_sfx.resource_path)
			#overlay_static_effect.visible = false

func _physics_process(delta: float):
	update_rotation_to_face_player(delta)

func update_rotation_to_face_player(delta: float):
	if player and player.is_inside_tree():
		persistent_state.look_at(player.global_transform.origin, Vector3.UP)

func on_stalking_end_timer():
	persistent_state.set_visible(false)
	collision_shape_3d.disabled = true
	await get_tree().create_timer(6.0).timeout
	find_stalking_position()

func on_teleport_end_timer():
	stopTimers()
	AudioController.stop_resource(teleporting_ambiance.resource_path, 2)
	change_state.call("respawning")

func become_seen():
	if persistent_state.visible and !stalking_timer.is_stopped():
		await get_tree().create_timer(randf_range(0.245, 0.38)).timeout
		#await get_tree().create_timer(50).timeout
		stopTimers()
		persistent_state.set_visible(false)
		collision_shape_3d.disabled = true
		teleport_sighting_sound.playing = true
		AudioController.stop_resource(teleporting_ambiance.resource_path, 2)
		var particles_instance = TELEPORT_AWAY_SMOKE.instantiate()
		particles_instance.global_position = get_parent().find_child("SmokeVFX").global_position
		get_tree().current_scene.add_child(particles_instance)
		particles_instance.emitting = true
		var lifetime = particles_instance.lifetime  # wait for particle lifetime
		await get_tree().create_timer(lifetime).timeout
		particles_instance.queue_free()
		change_state.call("respawning")
		
func stopTimers():
	for t in functional_timers:
		t.stop()
