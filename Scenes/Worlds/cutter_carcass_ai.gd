extends Node3D

@onready var cutter_ai: CharacterBody3D = $"../cutter_ai"
var player: CharacterBody3D
@onready var behaviour_duration_timer: Timer = $behaviour_duration_timer
@onready var deescalate_timer: Timer = $deescalate_timer
@onready var cutter_model_for_animation_player: Node3D = $cutter_model_for_animations

var tween: Tween

func _ready():
	player = GameManager.player_reference

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.get_groups().has("monster"):
		cutter_ai.enable_carcass_behaviour()
		if cutter_ai.aggrod:
			if abs(cutter_ai.global_position.distance_to(player.global_position)) < 5:
				_instakill()
			else:
				deescalate()
				start_carcass_behaviour()
		else:
			start_carcass_behaviour()
		# Check if we are currently chasing the player
		# 	if we are, check if we are close enough to instakill him
		#		if we are, instakill him (spawn in front, lock player movement, rush him) (add a swerve sound effect or similar to show I run around)
		#		if not, play a de-escalate state and return to normal carcass behaviour
		#	if we are not chasing, assume normal carcass behaviour
			
func deescalate():
	deescalate_timer.start(2.33)
	cutter_ai.aggrod = false
	pass
	# Play a deescalate sound and other similar things

func start_carcass_behaviour():
	behaviour_duration_timer.start(randi_range(16, 28))
	pass
	# start a random timer before monster leaves the area
	# play "random" ambiance sounds a bit all over the room, generally behind the player
	# afterward, play a monster "venting" sound and have the monster spawn somewhere else 
	
func on_hearing_sound():
	if behaviour_duration_timer.time_left > 0 and deescalate_timer.is_stopped():
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
	cutter_ai.respawn_timer.start(randi_range(4, 9))
