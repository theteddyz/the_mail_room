extends Node3D

@export var player: PlayerMachine
@export var camera: Camera3D
@export var timer: Timer
@export var closelight: SpotLight3D
# TODO: CHANGE THIS NAME WHEN YOU'VE FIXED IT TO WORK WITH DIFFERENT SCENES
@onready var we : WorldEnvironment = get_tree().root.get_node("world").find_child("WorldEnvironment")
@onready var we_saturation_bright = 1.34
@onready var we_contrast_bright = 1.16
#@onready var we_brightness_bright = 0.95
#@onready var we_brightness_dark = 3.2
@export var we_saturation_dark = 0.77
@export var we_contrast_dark = 1.16

#Debugging
@export var texture_rect: TextureRect
@export var color_rect: ColorRect
var lightvalue: float = 0
var darken: bool = false

# THIS SCRIPT IS KIND OF HEAVY, PROBABLY RELATED TO LUMINANCE CALCULATION, CURRENT REMEDY; ONLY RUNS ONCE EVER 0.75 (or whatver refresh-timer is set to)

# Called when the node enters the scene tree for the first time.
func _ready():
	var GUI_DEBUGGING = Gui.find_child("DEBUGGING")
	texture_rect = GUI_DEBUGGING.find_child("TextureRect")
	color_rect = GUI_DEBUGGING.find_child("ColorRect")
	timer = find_child("Refresh Timer")
	
func timerdown():
	global_position = player.global_position + Vector3(0, 1.2, 0)
	
	var texture = camera.get_viewport().get_texture()
	texture_rect.texture = texture
	
	var color = get_average_color(texture)
	color_rect.color = color
	
	lightvalue = color.get_luminance()
	
	
# Make camera not read the added on luminance value
func _process(delta):
	if (we != null):
		if(darken):
			we.environment.adjustment_saturation = lerp(we.environment.adjustment_saturation, we_saturation_dark, delta * 1.25)
			#we.environment.adjustment_brightness = lerp(we.environment.adjustment_brightness, we_brightness_dark, delta * 1.25)
			we.environment.adjustment_contrast = lerp(we.environment.adjustment_contrast, we_contrast_dark, delta * 1.25)
			closelight.light_energy = lerp(closelight.light_energy, 0.82, delta * 1.25)
			if(lightvalue >= 0.038):
				darken = false
		else:
			we.environment.adjustment_contrast = lerp(we.environment.adjustment_contrast, we_contrast_bright, delta * 1.25)
			#we.environment.adjustment_brightness = lerp(we.environment.adjustment_brightness, we_brightness_bright, delta * 1.25)
			we.environment.adjustment_saturation = lerp(we.environment.adjustment_saturation, we_saturation_bright, delta * 1.25)
			closelight.light_energy = lerp(closelight.light_energy, 0.0, delta * 1.25)
			if(lightvalue <= 0.01):
				darken = true

func get_average_color(texture: ViewportTexture):
	var image = texture.get_image()
	image.resize(1, 1, Image.INTERPOLATE_LANCZOS)
	return image.get_pixel(0, 0)
