extends Node
@onready var monster_detector: Area3D = $"../Neck/Head/HeadbopRoot/MonsterDetector"
var raycaster: RayCast3D
@onready var camera: Camera3D = $"../Neck/Head/HeadbopRoot/Camera"
var current_sources: Array[Node] = []
var tween: Tween
var is_running_effect = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	raycaster = monster_detector.raycaster
	monster_detector.visiontimer_signal.connect(_search)

func _search(overlaps: Array):
	if overlaps.size() > 0:
		for overlap in overlaps:
			# If the body is an active source...
			if overlap.is_in_group("scarevision") and !overlap.is_in_group("observed") and overlap.is_visible_in_tree():
				var pos = overlap.global_transform.origin
				if overlap.find_child("raycast_look_position") != null:
					pos = overlap.get_node("raycast_look_position").global_transform.origin
				raycaster.look_at(pos)
				#raycaster.force_raycast_update()
				if raycaster.is_colliding() and raycaster.get_collider().name == overlap.name:
					if current_sources.has(overlap) and !is_running_effect:
						tween.kill()
					overlap.add_to_group("observed")
					current_sources.append(overlap)
					await _effect(overlap)

func _effect(overlap):
	var w = GameManager.we_reference as WorldEnvironment
	var we = GameManager.we_reference.get_environment() as Environment
	is_running_effect = true
	
	# Tween to the scare vision effect
	tween = create_tween()
	tween.tween_property(we, "adjustment_saturation", 0.28, 0.12);
	tween.parallel().tween_property(we, "adjustment_brightness", 0.71, 0.12);
	tween.parallel().tween_property(camera, "fov", 53.5, 0.12)
	await tween.finished
	
	# Play any existing effect-type on the current scare-vision source (StopSeeing / Delay)
	await _call_external_function(overlap)
	is_running_effect = false
	if overlap != null:
		if overlap.keep_scare_vision != null and overlap.keep_scare_vision:
			overlap.remove_from_group("observed")
	
	# Fade to standard world-environment
	tween = create_tween()
	tween.tween_property(we, "adjustment_saturation", w.properties["adjustment_saturation"], 3.25);
	tween.parallel().tween_property(we, "adjustment_brightness", w.properties["adjustment_brightness"], 1.13);
	tween.parallel().tween_property(camera, "fov", 60, 0.87)
	await tween.finished
	if overlap != null:
		current_sources.remove_at(current_sources.find(overlap))
	else:
		current_sources.remove_at(current_sources.size()-1)
	#await tween.finished
	
func _call_external_function(overlap):
	if overlap != null and overlap.has_method("scare_vision_external_callback"):
		overlap.scare_vision_external_callback()
		await overlap.external_callback

func timout(overlap: Node):
	overlap.remove_from_group("observed")
	
func reset_world_environment_visual():
	var w = GameManager.we_reference as WorldEnvironment
	var we = GameManager.we_reference.get_environment() as Environment
	we.adjustment_saturation = w.properties["adjustment_saturation"]
	we.adjustment_brightness = w.properties["adjustment_brightness"]
	camera.fov = 60
