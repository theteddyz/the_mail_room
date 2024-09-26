extends SpotLight3D

var rot
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rot = global_rotation


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	global_rotation.y = rot.y
