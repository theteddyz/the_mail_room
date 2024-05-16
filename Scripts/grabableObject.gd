extends CSGBox3D


var startPosition = Vector3.ZERO

func _ready():
	startPosition = position


func _process(delta):
	rotate_x(1.35 * delta)
	rotate_z(1.85 * delta)
	
	position = Vector3(position.x, startPosition.y + sin(Time.get_ticks_msec() * delta * 0.5) * 0.05, position.z)

func interact():
	pass


