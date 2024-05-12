extends Interactable

var startPosition = Vector3.ZERO
# Called when the node enters the scene tree for the first time.
func _ready():
	startPosition = position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	rotate_x(1.35 * delta)
	rotate_z(1.85 * delta)
	position = Vector3(position.x, startPosition.y + sin(Time.get_ticks_msec() * delta * 0.5) * 0.05, position.z)
	
func interact():
	print("I've been touched!!! :()")
	
