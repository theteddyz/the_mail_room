extends RigidBody3D

@export var player: Node3D  # Assign the player's Node3D
@export var follow_strength: float = 10.0  # Adjust for smooth following
@export var rotation_strength: float = 5.0
@export var max_speed: float = 5.0
@export var damping: float = 0.95  # Reduces wobbling

var is_grabbed = false
var target_offset := Vector3.FORWARD * 1.5  # Position in front of player
func _ready():
	player = GameManager.get_player()
func _physics_process(delta):
	if is_grabbed and player:
		move_towards_player(delta)
		rotate_towards_player(delta)

func move_towards_player(delta):
	var target_position = player.global_transform.origin + (player.global_transform.basis * target_offset)
	var direction = (target_position - global_transform.origin).normalized()
	
	# Apply force in the direction of the target position
	var velocity_change = direction * follow_strength
	apply_force(velocity_change)
	
	# Limit speed
	if linear_velocity.length() > max_speed:
		linear_velocity = linear_velocity.normalized() * max_speed
	
	# Apply damping to reduce excessive movement
	linear_velocity *= damping

func rotate_towards_player(delta):
	var target_rotation = player.global_transform.basis.get_euler().y  # Get player's yaw rotation
	var current_rotation = rotation.y
	var new_rotation = lerp_angle(current_rotation, target_rotation, rotation_strength * delta)
	
	rotation.y = new_rotation  # Apply smoothed rotation

func grab_cart():
	is_grabbed = true
	freeze = false

func release_cart():
	is_grabbed = false
	freeze = false  # Optional: Set true if you want it to stay in place


func _on_body_entered(body):
	if body is RigidBody3D:
		body.freeze = false
