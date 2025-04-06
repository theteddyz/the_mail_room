@tool
extends RigidBody3D

# Physics constants
@onready var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
const WATER_HEIGHT := 0.0

# Buoyancy settings
@export var float_force := 1.0
@export var water_drag := 0.005
@export var water_angular_drag := 0.015

# Movement settings
@export var thrust_force := 200
@export var turn_force := 30
@export var max_speed := 10.0
@export var row_cooldown := 0.6
@export var impulse_duration := 2.5
@export var impulse_curve := Curve.new()

# Wave settings
@export var wave_direction: Vector2 = Vector2(0.2, 0.1)
@export var wave_speed: float = 0.12
@export var wave_amplitude: float = 2.0
@export var wave_frequency: float = 1.0
@export var rock_strength: float = 5.0
@export var bob_strength: float = 0.2

# Node references
@onready var probes = $ProbeContainer.get_children()
@onready var water_mesh = $"../MeshInstance3D2"

# State variables
var submerged := false
var can_row := true
var base_rotation: Vector3
var base_height: float

# Movement state
var forward := false
var left := false
var right := false

func _ready() -> void:
	base_rotation = rotation
	base_height = global_position.y

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		_handle_key_input(event)

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		update_probes()

func _physics_process(delta: float) -> void:
	_handle_turning(delta)
	apply_buoyancy()

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if submerged:
		_apply_water_resistance(state)

# Input handling
func _handle_key_input(event: InputEventKey) -> void:
	if event.pressed:
		match event.keycode:
			KEY_UP:
				apply_row_impulse()
			KEY_LEFT:
				left = true
			KEY_RIGHT:
				right = true
	elif not event.pressed:
		match event.keycode:
			KEY_LEFT:
				left = false
			KEY_RIGHT:
				right = false

func _handle_turning(delta: float) -> void:
	if left:
		turn_left(delta)
	elif right:
		turn_right(delta)

# Movement methods
func apply_row_impulse() -> void:
	if !can_row:
		_apply_random_drift()
		return
		
	can_row = false
	var forward_vec = -global_transform.basis.z.normalized()
	
	var tween := create_tween()
	tween.tween_method(
		func(weight: float) -> void:
			var force = forward_vec * thrust_force * impulse_curve.sample(weight) * get_physics_process_delta_time()
			apply_impulse(force, Vector3.ZERO),
		0.0, 1.0, impulse_duration
	).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	
	await get_tree().create_timer(row_cooldown).timeout
	can_row = true

func _apply_random_drift() -> void:
	var random_drift = Vector3(randf() * 0.02 - 0.01, 0, randf() * 0.02 - 0.01)
	apply_central_force(random_drift)

func turn_left(delta: float) -> void:
	var turn_impulse = -global_transform.basis.x * turn_force * delta
	apply_impulse(turn_impulse, Vector3.ZERO)
	apply_torque_impulse(Vector3.UP * turn_force * delta)

func turn_right(delta: float) -> void:
	var turn_impulse = global_transform.basis.x * turn_force * delta
	apply_impulse(turn_impulse, Vector3.ZERO)
	apply_torque_impulse(Vector3.UP * -turn_force * delta)

# Buoyancy and water physics
func apply_buoyancy() -> void:
	submerged = false
	for probe in probes:
		_apply_probe_buoyancy(probe)

func _apply_probe_buoyancy(probe: Node3D) -> void:
	var world_position = probe.global_transform.origin
	var depth = clamp(WATER_HEIGHT - world_position.y, 0.0, 1.0)
	
	if depth > 0:
		submerged = true
		var probe_velocity = linear_velocity + angular_velocity.cross(world_position - global_transform.origin)
		var vertical_velocity = probe_velocity.y
		var spring_strength = float_force * gravity * depth * mass / probes.size()
		var damping = vertical_velocity * 0.8
		var force = Vector3.UP * (spring_strength - damping)
		apply_force(force, world_position - global_transform.origin)

func _apply_water_resistance(state: PhysicsDirectBodyState3D) -> void:
	var lv = state.linear_velocity
	var horizontal = Vector3(lv.x, 0, lv.z)
	var vertical = Vector3(0, lv.y, 0)
	
	horizontal = horizontal.lerp(Vector3.ZERO, water_drag * 0.25)
	if horizontal.length() > max_speed:
		horizontal = horizontal.normalized() * max_speed

	state.linear_velocity = horizontal + vertical
	state.angular_velocity *= 1.0 - water_angular_drag

# Debug visualization
func update_probes() -> void:
	for probe in probes:
		_clear_debug_spheres(probe)
		_create_debug_sphere(probe)

func _clear_debug_spheres(probe: Node3D) -> void:
	for child in probe.get_children():
		if child is MeshInstance3D:
			child.queue_free()

func _create_debug_sphere(probe: Node3D) -> void:
	var debug_sphere = MeshInstance3D.new()
	debug_sphere.mesh = SphereMesh.new()
	debug_sphere.scale = Vector3(0.1, 0.1, 0.1)
	probe.add_child(debug_sphere)
