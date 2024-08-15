extends Node3D

var has_been_executed = false
@onready var monster_body = $"../../NavigationRegion3D/monster"
@onready var monster_collider = $"../../NavigationRegion3D/monster/CollisionShape3D"
@onready var animator = $"../../NavigationRegion3D/monster/godot_rig/AnimationPlayer"
var player

# Called when the node enters the scene tree for the first time.
func _ready():
	player = GameManager.player_reference
	monster_body.visible = false
	monster_collider.disabled = true
	#ScareDirector.connect("monster_seen", monster_seen_event)
	ScareDirector.connect("package_delivered", activate_scare)
	
func activate_scare(package_num:int):
	if package_num == 6:
		has_been_executed = true	# Variable necessary for all scares, tells other scares which ones have been executed
		monster_body.visible = true
		monster_collider.disabled = false
		animator.play("idle")
		print("SCARE ACTIVATED!")
	
	
