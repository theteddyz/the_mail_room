extends Interactable
class_name Usb
@export var USB_INDEX:int
var player: CharacterBody3D
var mesh_instance:MeshInstance3D
var is_being_looked_at:bool
var shader_material
var lerp_speed = 10
var being_grabbed
var lerp_pos 
var item_icon_manager
@onready var col = $CollisionShape3D

func _ready():
	mesh_instance = get_child(0)
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
	col.disabled = true
	grabbed()
	# One for scare-events, one for other possible listeners
	EventBus.emitCustomSignal("picked_up_usb", [USB_INDEX])
	ScareDirector.emit_signal("usb_pickup", [USB_INDEX])
	GameManager.save_usb_data(USB_INDEX)

func highlight(_delta):
	is_being_looked_at = true
	if shader_material == null:
		shader_material = mesh_instance.material_overlay.duplicate()
		mesh_instance.material_overlay = shader_material
		mesh_instance.material_overlay.set_shader_parameter("outline_width",5)
	else:
		mesh_instance.material_overlay.set_shader_parameter("outline_width",5)

func _process(delta):
	if is_being_looked_at:
		highlight(delta)
	else:
		reset_highlight()

func grabbed():
	player = GameManager.get_player()
	var tween = create_tween()
	tween.tween_property(self,"global_position",Vector3(player.global_position.x,(player.global_position.y+ 1.6),player.global_position.z),0.2)
	await tween.finished
	item_icon_manager.show_icon()
	queue_free()

func reset_highlight():
	if shader_material:
		mesh_instance.material_overlay.set_shader_parameter("outline_width", 0.005)
