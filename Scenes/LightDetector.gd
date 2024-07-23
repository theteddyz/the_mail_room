extends Node3D

@export var sub_viewport: SubViewport
@export var player: PlayerMachine

#Debugging
@export var texture_rect: TextureRect
@export var color_rect: ColorRect

var lightvalue: float = 0

#TODO: Optimize...

# Called when the node enters the scene tree for the first time.
func _ready():
	var GUI_DEBUGGING = Gui.find_child("DEBUGGING")
	texture_rect = GUI_DEBUGGING.find_child("TextureRect")
	color_rect = GUI_DEBUGGING.find_child("ColorRect")
	sub_viewport.debug_draw = 2

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	global_position = player.global_position + Vector3(0, 1.2, 0)
	
	var texture = sub_viewport.get_texture()
	texture_rect.texture = texture
	
	var color = get_average_color(texture)
	color_rect.color = color
	
	lightvalue = color.get_luminance()
	print(lightvalue)
	
func get_average_color(texture: ViewportTexture):
	var image = texture.get_image()
	image.resize(1, 1, Image.INTERPOLATE_LANCZOS)
	return image.get_pixel(0, 0)
