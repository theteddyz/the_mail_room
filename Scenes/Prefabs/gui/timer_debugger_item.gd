extends Control
@export var node_to_debug: Node
var timer_array: Array[Timer]
var labels_array: Array[Label]

func _ready() -> void:
	node_to_debug = get_tree().root.get_node("world").find_child("cutter_ai")
	if node_to_debug != null:
		var children = node_to_debug.get_children(true)
		for c in children:
			if c is Timer:
				# Create a new label object
				timer_array.append(c)
				
				var label = Label.new()
				label.text = c.name + ": " + str(c.time_left) + "s"
				labels_array.append(label)
				add_child(label)
				

func _process(delta: float) -> void:
	var index = 0
	var active_indexes = 0
	for t in timer_array:
		if t.time_left > 0 and !t.is_stopped():
			labels_array[index].position = Vector2(200, 15 * active_indexes + 150)
			labels_array[index].visible = true
			labels_array[index].text = t.name + ": " + str(t.time_left) + "s"
			active_indexes += 1
		else:
			labels_array[index].visible = false
		index += 1
		
