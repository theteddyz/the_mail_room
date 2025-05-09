extends Node3D

var scare_index = 3
var has_been_executed = false
@onready var monster_body: CharacterBody3D = $"../../monster"
@onready var animator: AnimationPlayer = $"../../monster/AnimationPlayer"
var player
@onready var monster_position: Node3D = $MonsterPosition
@onready var monster_collider: CollisionShape3D = $"../../monster/CollisionShape3D"
@onready var elevator = $"../../Elevator"
@onready var window_scare: Node3D = $"../WINDOW SCARE"
@onready var darkroom_scare: Node3D = $"../DARKROOM SCARE"

# Called when the node enters the scene tree for the first time.
func _ready():
	player = GameManager.player_reference
	monster_body.visible = false
	monster_collider.disabled = true
	#ScareDirector.connect("monster_seen", monster_seen_event)
	ScareDirector.connect("package_delivered", activate_scare)
	
func activate_scare(package_num:int):
	if package_num == 6 and (window_scare == null or darkroom_scare == null):
		#Variable necessary for all scares, tells other scares which ones have been executed
		var elevator = GameManager.get_elevator()
		elevator.light_active_button()
		has_been_executed = true
		monster_body.enable_john()
		monster_body.global_position = monster_position.global_position
		monster_body.set_rotation(monster_position.rotation)
		animator.play("Idle")
		ScareDirector.emit_signal("scare_activated", scare_index)
		elevator.locked = false
		print("SCARE ACTIVATED!")
