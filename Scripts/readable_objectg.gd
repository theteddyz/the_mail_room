extends CSGBox3D

@onready var item_reader = $"../GUI/ItemReader"
@export var image_path:Texture2D 
@export var object_text:String

var startPosition = Vector3.ZERO

func _ready():
	startPosition = position


func _physics_process(delta):
	rotate_x(1.35 * delta)
	rotate_z(1.85 * delta)
	
	position = Vector3(position.x, startPosition.y + sin(Time.get_ticks_msec() * delta * 0.5) * 0.05, position.z)

func interact():
	item_reader.display_item("AHHHHHHHHHHHH IM BEING READ WOOOPIE",image_path)
