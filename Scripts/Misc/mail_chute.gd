extends StaticBody3D
@onready var chute_light:MeshInstance3D = $Chute_Light
@onready var chute_light_red:OmniLight3D = $Chute_Light/OmniLight3D
@onready var chute_light_green:OmniLight3D = $Chute_Light/OmniLight3D2
@onready var audio_player:AudioStreamPlayer3D = $AudioStreamPlayer3D
var green_material = preload("res://Assets/Materials/chute_green.tres")
var red_material = preload("res://Assets/Materials/chute_red.tres")
@export var active:bool = false
@export var game_objects: Array[Node] = []
func _ready():
	if !active:
		chute_light.material_override = red_material
		chute_light_red.visible = true
	else:
		chute_light.material_override = green_material
		chute_light_green.visible = true

func drop_packages():
	if active:
		for game_object in game_objects:
			audio_player.play()
			await !audio_player.playing
			game_object.visible = true
			game_object.freeze = false
