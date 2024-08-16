extends Interactable
class_name Key
@export var unlock_num:int
var player: CharacterBody3D
var is_being_looked_at:bool
var shader_material
var key_material:MeshInstance3D
var lerp_speed = 10
var being_grabbed
var lerp_pos 
var item_icon_manager
func _ready():
	key_material = get_child(0)
	item_icon_manager = Gui.get_item_icon_displayer()
	player = GameManager.player_reference
	lerp_pos = player.find_child("ItemHolder")
	EventBus.connect("object_looked_at",on_seen)
	EventBus.connect("no_object_found",on_unseen)


func on_seen(node):
	if node == self:
		is_being_looked_at = true
	else:
		is_being_looked_at = false

func on_unseen(_node):
	if is_being_looked_at:
		is_being_looked_at = false


func interact():
	being_grabbed = true
	EventBus.emitCustomSignal("picked_up_key",[self])
	ScareDirector.emit_signal("key_pickedup", unlock_num)

func highlight(_delta):
	is_being_looked_at = true
	if shader_material == null:
		shader_material = key_material.material_overlay.duplicate()
		key_material.material_overlay = shader_material
		key_material.material_overlay.set_shader_parameter("outline_width",5)
	else:
		key_material.material_overlay.set_shader_parameter("outline_width",5)

func _process(delta):
	if being_grabbed:
		grabbed(delta)
	if is_being_looked_at:
		highlight(delta)
	else:
		reset_highlight()
func grabbed(delta):
	position = position.lerp(lerp_pos.global_position, lerp_speed * delta)
	if position.distance_to(lerp_pos.global_position) < 0.1:
		item_icon_manager.show_icon()
		queue_free()

func reset_highlight():
	if shader_material:
		key_material.material_overlay.set_shader_parameter("outline_width", 0)
