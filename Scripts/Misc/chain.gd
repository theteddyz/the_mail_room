@tool
extends Node3D
var chain_mesh = preload("res://Scenes/Prefabs/MoveableObjects/chain_link.tscn")
@export var chain_count:int 
var previous_chain_count:int
@export var link_spacing: float = 0.1
func _ready():
	update_chain()
func _process(delta):
	if Engine.is_editor_hint():
		if  previous_chain_count != chain_count:
			update_chain()



func update_chain():
	previous_chain_count = chain_count
	for child in get_children():
		if child.name.begins_with("ChainLink"):
			child.queue_free()
	for i in range(chain_count):
		var link_instance:Node3D = chain_mesh.instantiate()
		link_instance.name = "ChainLink_%d" % i
		link_instance.rotation_degrees = Vector3(0, 0, 90) if i % 2 == 0 else Vector3(90, 0, 0)  # Alternate rotation
		link_instance.position = Vector3(0, -i * link_spacing, 0)  # Move down based on index
		add_child(link_instance)
