extends CharacterBody3D
@export var disable:bool = false
@onready var nav_agent = $NavigationAgent3D
var player
var SPEED = 3.0
var current_state: String = "idle"
var detection_range: float = 10.0
var patrol_points = [Vector3(1, 0, 1), Vector3(5, 0, 5), Vector3(10, 0, 1)]
var patrol_index = 0
var speed: float = 5.0
var vision_range: float = 10.0
var vision_angle: float = 45.0 # Angle in degrees
var attack_range: float = 2.0
var vision_cone: MeshInstance3D
var time_since_last_seen: float = 0.0
var lose_sight_time: float = 2.0 # Time in seconds to lose sight
var foundPlayer:bool = false
func _ready():
	await get_tree().create_timer(0.1).timeout
	player = get_parent().find_child("Player")
	vision_cone = get_node("VisionCone") as MeshInstance3D
	vision_cone.vision_range = vision_range
	vision_cone.vision_angle = vision_angle
	vision_cone.update_cone(vision_cone.patrol_material)
	set_process(true)

func _physics_process(delta):
	if !disable:
		match current_state:
			"idle":
				_idle_behavior(delta)
			"patrol":
				_patrol_behavior(delta)
			"chase":
				_chase_behavior(delta)
			"attack":
				_attack_behavior(delta)
			"flee":
				_flee_behavior(delta)
		update_timer(delta)
		handleCollisions()


func _idle_behavior(delta):
	current_state = "patrol"

func _patrol_behavior(delta):
	if player and is_player_in_vision():
		current_state = "chase"
		vision_cone.update_cone(vision_cone.chase_material)
	elif global_position.distance_to(patrol_points[patrol_index]) < 1.0:
		patrol_index = (patrol_index + 1) % patrol_points.size()
	nav_agent.target_position = (patrol_points[patrol_index])
	var direction = (nav_agent.get_next_path_position() - global_position).normalized()
	velocity = direction * speed
	rotate_monster(direction)
	move_and_slide()



func _chase_behavior(delta):
	if player:
		if foundPlayer == false:
			EventBus.emitCustomSignal("scare_event",["monster_encounter",global_position])
			print("event signaled")
			foundPlayer = true
		if global_position.distance_to(player.global_position) < attack_range:
			current_state = "attack"
		else:
			if is_player_in_vision():
				time_since_last_seen = 0.0 # Reset timer when player is in vision
				nav_agent.target_position = player.global_position
			else:
				time_since_last_seen += delta
				if time_since_last_seen > lose_sight_time:
					current_state = "patrol"
					vision_cone.update_cone(vision_cone.patrol_material)
			var direction = (nav_agent.get_next_path_position() - global_position).normalized()
			velocity = direction * speed
			rotate_monster(direction)
			move_and_slide()

func _attack_behavior(delta):
	if player and global_position.distance_to(player.global_position) > attack_range:
		current_state = "chase"

func _flee_behavior(delta):
	pass


func is_player_in_vision() -> bool:
	var to_player = player.global_position - global_position
	var distance_to_player = to_player.length()
	if distance_to_player > vision_range:
		return false
	var forward = -transform.basis.z
	var angle_to_player = rad_to_deg(forward.angle_to(to_player.normalized()))
	return angle_to_player <= vision_angle / 2



func rotate_monster(direction: Vector3):
	if direction.length() > 0:
		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, 0.1)


func update_timer(delta):
	if current_state == "chase" and !is_player_in_vision():
		time_since_last_seen += delta
	else:
		time_since_last_seen = 0.0


func handleCollisions():
	var collision = move_and_collide(velocity * get_physics_process_delta_time())
	if collision:
		var collider = collision.get_collider()
		if collider and collider is RigidBody3D: # Make sure the colliders are in a group called "rigidbodies"
			var push_direction = collision.get_normal()
			push_direction.y = 0 # Prevent pushing up or down
			collider.apply_central_impulse(push_direction * 100) # Adjust force as needed
