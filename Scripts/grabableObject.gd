extends CSGBox3D

@onready var playPos = $"../Player"
@export var offset: Vector3 = Vector3(0, 0, -0.3)  # Define the offset
@onready var original_parent = get_parent()
@export var mass: float = 1.0
var is_picked_up = false
var startPosition = Vector3.ZERO

func _ready():
	startPosition = position


func _physics_process(delta):
	position = Vector3(position.x, startPosition.y + sin(Time.get_ticks_msec() * delta * 0.5) * 0.05, position.z)

func interact():
	pickmeUp()


func pickmeUp():
	if is_picked_up:
		drop_me()
		return
	is_picked_up = true
	original_parent = get_parent()
	original_parent.remove_child(self)
	playPos.add_child(self)
	self.position = offset  # Set position with offset


func drop_me():
	is_picked_up = false
	playPos.remove_child(self)
	original_parent.add_child(self)
	self.global_position = playPos.global_position
	
