extends CharacterBody3D

@export var disabled:bool = false
@export var speed : float = 5.0
var player
@onready var nav:NavigationAgent3D = $NavigationAgent3D
func _ready():
	player = GameManager.get_player()


func _physics_process(delta):
	if player:
		look_at(player.position)
	var destination = nav.get_next_path_position()
	var local_destination = destination - global_position
	var direction = local_destination.normalized()
	velocity = direction * speed
	move_and_slide()


func _on_timer_timeout():
	if !disabled:
		nav.set_target_position(player.global_position)
