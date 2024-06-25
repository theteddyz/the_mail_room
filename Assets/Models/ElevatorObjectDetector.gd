extends Area3D

@export var CollisionShape: CollisionShape3D = null
var game_objects = []
var blacklist = ["Mailcart", "Radio", "Player"]
var mailcart_exists_in_elevator = false

func _on_body_entered(body):
	print("ENTERED: " + body.name)
	if(!blacklist.has(body.name)):
		game_objects.append(body)
	elif(body.name == "Player" and body.state is CartingState):
		if(body.get_node("Mailcart") != null):
			print("IN COLLIDER")
			mailcart_exists_in_elevator = true


func _on_body_exited(body):
	print("EXITED: " + body.name)
	if(!blacklist.has(body.name)):
		game_objects = game_objects.filter(func(item): return item.name != body.name)
	elif(body.name == "Player" and body.state is CartingState):
		mailcart_exists_in_elevator = false
		 

