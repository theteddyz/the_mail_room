extends Area3D

@onready var audio:AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var collider:CollisionShape3D = $CollisionShape3D
@export var has_tape = false
var held_tape
var power = false
var radio_stations = []
var current_index = 0
var attached_to_cart = false
var being_held = false
func _ready():
	power = true
	EventBus.connect("object_held",check_held)
	EventBus.connect("dropped_object",check_dropped)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if held_tape:
		held_tape.global_position = global_position



func change_station_up():
	if current_index < radio_stations.size() - 1:
		current_index += 1
	else:
		current_index = 0
	print("Current Index after scrolling up: ", current_index)

# Function to scroll the package down
func change_station_down():
	if radio_stations.size() != 0:
		if current_index > 0:
			current_index -= 1
		else:
			current_index = radio_stations.size() - 1
	print("Current Index after scrolling down: ", current_index)

func playTape(tape):
	if power:
		held_tape = tape
		var sound  = held_tape.sound
		print(held_tape)
		has_tape = true
		audio.set_stream(sound)
		audio.play()

func check_tape():
	if has_tape:
		eject_tape()
	else:
		toggle_power()

func eject_tape():
	audio.stop()
	held_tape.show()
	has_tape = false
	held_tape = null
	audio.stream = null

func toggle_power():
	if power:
		audio.play()
	else:
		audio.stop()

func remove_from_cart():
	var root = get_tree().root.get_child(1)
	var mailcart = root.find_child("Mailcart")
	var mailcartPosition = mailcart.find_child("RadioPosition")
	mailcartPosition.remove_child(self)
	root.add_child(self)
	attached_to_cart = false

func check_dropped(_mass,object):
	if object.name == "Radio":
		print("dropped")
		collider.disabled = false
func check_held(_mass,object):
	if object.name == "Radio":
		being_held = true
		collider.disabled = true
		if attached_to_cart:
			remove_from_cart()
