extends Node3D

var has_been_executed = false
@onready var monster_body: CharacterBody3D = $"../../monster"
@onready var animator: AnimationPlayer = $"../../monster/AnimationPlayer"
var player
@onready var monster_position: Node3D = $MonsterPosition
@onready var monster_collider: CollisionShape3D = $"../../monster/CollisionShape3D"

# Called when the node enters the scene tree for the first time.
func _ready():
	player = GameManager.player_reference
	monster_body.visible = false
	monster_collider.disabled = true
	#ScareDirector.connect("monster_seen", monster_seen_event)
	ScareDirector.connect("package_delivered", activate_scare)
	
func activate_scare(package_num:int):
	if package_num == 6:
		#Variable necessary for all scares, tells other scares which ones have been executed
		has_been_executed = true
		monster_body.visible = true
		monster_collider.disabled = false
		monster_body.disabled = false
		monster_body.set_position(monster_position.position)
		monster_body.set_rotation(monster_position.rotation)
		animator.play("Idle")
		print("SCARE ACTIVATED!")
