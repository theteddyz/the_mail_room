extends State
class_name CartingState

@onready var head = get_parent().get_node("Head")
@onready var headbop_root = head.get_node("HeadbopRoot")
@onready var crosshair = headbop_root.get_node("Camera").get_node("Control").get_node("Crosshair")
#TODO: Un-link mouse-rotation when cart-movement is happening, input right and left should cause rotation

# Called when the node enters the scene tree for the first time.
func _ready():
	crosshair.visible = false
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _physics_process(delta):
	if Input.is_action_pressed("drive"):
		releaseCart()
		
func releaseCart():
	#¤mailcart.reparent(get_parent())
	#persistent_state.set_collision_mask_value(5, true)
