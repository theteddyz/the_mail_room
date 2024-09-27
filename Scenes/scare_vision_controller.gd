extends Node
@onready var monster_detector: Area3D = $"../Neck/Head/HeadbopRoot/MonsterDetector"
var raycaster: RayCast3D
@onready var camera: Camera3D = $"../Neck/Head/HeadbopRoot/Camera"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	raycaster = monster_detector.raycaster
	monster_detector.visiontimer_signal.connect(_search)

func _search(overlaps: Array):
	print(overlaps)
	if overlaps.size() > 0:
		for overlap in overlaps:
			if overlap.is_in_group("scarevision") and !overlap.is_in_group("observed"):
				var pos = overlap.global_transform.origin
				if overlap.find_child("raycast_look_position") != null:
					pos = overlap.get_node("raycast_look_position").global_transform.origin
				raycaster.look_at(pos)
				raycaster.force_raycast_update()
				if raycaster.is_colliding() and raycaster.get_collider().name == overlap.name:
					overlap.add_to_group("observed")
					var w = GameManager.we_reference as WorldEnvironment
					var we = GameManager.we_reference.get_environment() as Environment
					var start_fov = camera.fov
					var start_sat = we.adjustment_saturation
					var start_bright = we.adjustment_brightness
					#we.adjustment_saturation = 0.48
					#we.adjustment_brightness = 0.71
					#camera.fov = 53.5
					var tween = get_tree().create_tween()
					tween.tween_property(we, "adjustment_saturation", 0.28, 0.12);
					tween.parallel().tween_property(we, "adjustment_brightness", 0.71, 0.12);
					tween.parallel().tween_property(camera, "fov", 53.5, 0.12)
					
					tween.tween_property(we, "adjustment_saturation", w.properties["adjustment_saturation"], 3.25);
					tween.parallel().tween_property(we, "adjustment_brightness", w.properties["adjustment_brightness"], 1.13);
					tween.parallel().tween_property(camera, "fov", 60, 0.87)
					
					# For Debugging
					get_tree().create_timer(3).timeout.connect(timout.bind(overlap))

func timout(overlap: Node):
	overlap.remove_from_group("observed")
