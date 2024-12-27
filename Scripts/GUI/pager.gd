extends Control
@onready var gui_panel: ColorRect = $Panel2/ColorRect
@onready var text1:RichTextLabel = $Panel/Text1
@onready var text2:RichTextLabel = $Panel/Text2
var pager_hide_position
### Text variables
var scroll_speed: float = 100.0
var text_width: float = 0.0
var start_position: float = 0.0
var end_position: float = 0.0
var inital_text_position
var pager_showing:bool = false
###Package variables
var target_object: Node3D
var player_camera: Camera3D
var dot_threshold: float = 0.9
var color_looking_at_object: Color = Color(0, 1, 0)  # Green
var pulse_color:Color = Color.BLACK
var color_not_looking_at_object: Color = Color(1, 0, 0)  # Red
var pager_active:bool = false
var min_distance: float = 1.0   # Close distance
var max_distance: float = 30.0  # Far distance
var min_pulse_speed: float = 3.0  # Slower pulse when far
var max_pulse_speed: float = 15.0  # Faster pulse when close
var time_passed: float = 0.0  # Variable to track time for the sine wave
var target_objects = []
var tween1_running
var tween2_running
var message_playing:bool
var player
func _ready():
	player = GameManager.get_player()
	var world = get_tree().root.get_node("world")
	pager_hide_position = position
	inital_text_position = text1.position
	#target_object = world.find_child("Package")
	if player:
		player_camera = player.find_child("Neck").find_child("Head").find_child("HeadbopRoot").find_child("Camera")

func add_package_to_queue(object: Node3D):
	target_objects.append(object)
	check_pager_status() 
func remove_package(object: Node3D):
	target_objects.erase(object)
	target_object = null
	set_pager_text("",false)
	check_pager_status()

func check_pager_status():
	if player_camera:
		if target_objects.size() > 0:
			await ensure_message_finished()
			var closest_object = target_objects[0]
			var closest_distance = player_camera.global_transform.origin.distance_to(closest_object.global_transform.origin)
			for object in target_objects:
				var distance = player_camera.global_transform.origin.distance_to(object.global_transform.origin)
				if distance < closest_distance:
					closest_distance = distance
					closest_object = object
			target_object = closest_object
			activate_package_tracker(target_object) 
			set_pager_text("Tracking: " + target_object.name,false)
			if !pager_showing:
				toggle_pager(true)
		else:
			if pager_active:
				toggle_pager(false)

func activate_package_tracker(object):
	target_object = object
	pager_active = true

func set_pager_text(_text:String,message:bool):
	if message:
		message_playing = true
		toggle_pager(true)
	text1.text = _text
	text2.text = _text
	await ensure_tweens_finished()
	scroll_text1(message)

func _process(delta: float) -> void:
	if !message_playing and pager_active:
		update_gui_panel_color(delta)
func ensure_message_finished() -> void:
	while message_playing:
		await get_tree().process_frame
func ensure_tweens_finished() -> void:
	while tween1_running or tween2_running:
		await get_tree().process_frame
func scroll_text1(message:bool)->void:
	if pager_active:
		tween1_running = true
		var text_width = text1.get_content_width() + 100
		var distance_to_travel = text_width + get_parent().size.x
		var duration = distance_to_travel / scroll_speed
		var scroll_tween1 = create_tween()
		scroll_tween1.tween_property(text1, "position", Vector2(-text_width, text1.position.y), duration)
		await get_tree().create_timer(duration * 0.6).timeout
		if !message:
			scroll_text2(message)
		else:
			await scroll_tween1.finished
			scroll_text2(true)
		tween1_running = false
		text1.position = inital_text_position
func scroll_text2(message:bool)->void:
	if pager_active:
		tween2_running = true
		var text_width = text2.get_content_width() + 100
		var distance_to_travel = text_width + get_parent().size.x
		var duration = distance_to_travel / scroll_speed
		var scroll_tween2 = create_tween()
		scroll_tween2.tween_property(text2, "position", Vector2(-text_width, text2.position.y), duration)
		await get_tree().create_timer(duration * 0.6).timeout
		if !message:
			scroll_text1(message)
		await scroll_tween2.finished
		if message:
			message_playing = false
			toggle_pager(false)
		tween2_running = false
		text2.position = inital_text_position

func update_gui_panel_color(delta) -> void:
	if pager_active and target_object:
		var player_forward: Vector3 = -player.transform.basis.z.normalized()
		var dir_to_object: Vector3 = (target_object.global_transform.origin - player_camera.global_transform.origin).normalized()
		var dot_product: float = player_forward.dot(dir_to_object)
		if dot_product > dot_threshold:
			var distance: float = player_camera.global_transform.origin.distance_to(target_object.global_transform.origin)
			distance = clamp(distance, min_distance, max_distance)  # Clamp distance
			var pulse_speed: float = lerp(max_pulse_speed, min_pulse_speed, (distance - min_distance) / (max_distance - min_distance))
			time_passed += delta * pulse_speed
			var pulse_value: float = 0.5 + 0.5 * sin(time_passed)
			gui_panel.color = color_looking_at_object.lerp(pulse_color, pulse_value)
		else:
			gui_panel.color = color_not_looking_at_object




func toggle_pager(_show:bool):
	if _show and !pager_showing:
		pager_showing = true
		pager_active = true
		var pager_tween:Tween = create_tween()
		var final_position: Vector2 = Vector2(241, 532)
		var overshoot_position: Vector2 = final_position + Vector2(0, -20)
		pager_tween.tween_property(self, "position", overshoot_position, 0.7).set_ease(Tween.EASE_OUT)
		pager_tween.chain().tween_property(self, "position", final_position, 0.3).set_ease(Tween.EASE_IN)
		await pager_tween
		
	elif pager_showing:
		pager_showing = false
		var pager_tween:Tween = create_tween()
		pager_tween.tween_property(self, "position", pager_hide_position, 0.7).set_ease(Tween.EASE_OUT)
		await pager_tween
		pager_active = false
		await ensure_tweens_finished()
		text1.position = inital_text_position
		text2.position = inital_text_position
	
