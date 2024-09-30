extends Interactable
class_name Tape
var tape_manager
@export var tape_name:String
var radio
var player_camera_parent
var player_camera:Camera3D
var camera_position_on_insert:Vector3 = Vector3(0.46,0,0.13)
var box_position:Vector3
var box_rotation:Vector3
var inside_radio:bool = false
@export var sound:AudioStreamMP3
func _ready():
	var player = GameManager.get_player()
	var mail_cart = GameManager.mail_cart_reference
	tape_manager = mail_cart.find_child("TapeManager")
	radio = GameManager.get_player_radio()
	player_camera_parent = player.find_child("Neck").find_child("Head").find_child("HeadbopRoot")





func interact():
	grabbed()


func grabbed():
	if tape_manager != null:
		tape_manager.add_tape(self)
		var col:CollisionShape3D = get_child(0)
		col.disabled = true
		print("Tape added to the collection")
func eject():
	reparent(tape_manager)
	var tween:Tween = create_tween()
	tween.parallel().tween_property(self,"position",box_position,1)
	tween.parallel().tween_property(self,"rotation_degrees",Vector3(0,0,90),1)
	await tween.finished
	inside_radio = false
func insert_tape(camera:Camera3D):
	reparent(radio)
	inside_radio = true
	player_camera = camera
	self.freeze = true
	var camera_tween:Tween = create_tween()
	var rotate_tween:Tween = create_tween()
	var tween:Tween = create_tween()
	tween.parallel().tween_property(self,"position",Vector3(0.11,0.11,-0.07),1)
	tween.parallel().tween_property(self,"rotation_degrees",Vector3(0,90,75),1)
	camera_tween.tween_property(player_camera,"position",camera_position_on_insert,1)
	await camera_tween.finished
	var tween2 = create_tween()
	tween2.parallel().tween_property(self,"position",Vector3(0.12,-0.02,-0.025),1)
	tween2.parallel().tween_property(self,"rotation_degrees",Vector3(0,90,90),1)
	await tween2.finished
	radio.power = true
	radio.play_tape(self)
	
