extends Interactable

var mail_cart
@onready var joint:Generic6DOFJoint3D = $"../Generic6DOFJoint3D"
var player:CharacterBody3D
var is_grabbed:bool = false
func _ready():
	player = GameManager.get_player()
	mail_cart = get_parent()

func interact():
	joint.node_a = player.get_path()
	is_grabbed = true
	 # Limit movement but allow pushing/pulling

	pass
	mail_cart.is_grabbed = true

func _input(event):
	if is_grabbed:
		if event.is_action_released("interact"):
			joint.node_a = NodePath("")
			is_grabbed = false
